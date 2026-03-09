# AosEdge Build & Deploy Pipeline

Complete Docker Compose workflow for building, signing, and deploying C++ applications to AosEdge units.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Docker Compose Pipeline                         │
│                                                                          │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐            │
│  │ cpp-builder │ ───▶ │ aos-signer  │ ───▶ │  deployer   │            │
│  │             │      │             │      │             │            │
│  │ • CMake     │      │ • Azure KV  │      │ • AosEdge   │            │
│  │ • Cross-cmp │      │ • Sign bin  │      │   API       │            │
│  └─────────────┘      └─────────────┘      └─────────────┘            │
│         │                     │                     │                   │
│         ▼                     ▼                     ▼                   │
│  artifacts/build/      artifacts/signed/      AosEdge Units            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Setup Environment

```bash
# Copy environment template
cp .env.aosedge.template .env

# Edit with your values
nano .env
```

Required variables:
```bash
# Azure Key Vault
VAULT_URL=https://your-vault.vault.azure.net
CERT_NAME=your-certificate-name

# Local development (client credentials)
AZURE_TENANT_ID=xxx
AZURE_CLIENT_ID=xxx
AZURE_CLIENT_SECRET=xxx

# Or for Azure Functions
USE_MANAGED_ID=true
```

### 2. Run Pipeline

```bash
# Build Docker images first
docker-compose -f docker-compose.aosedge.yml build

# Run full pipeline
docker-compose -f docker-compose.aosedge.yml up

# Run in detached mode
docker-compose -f docker-compose.aosedge.yml up -d

# View logs
docker-compose -f docker-compose.aosedge.yml logs -f
```

### 3. Output

```
artifacts/
├── build/           # Compiled binaries from cpp-builder
│   └── usr/local/bin/aos-agent
├── signed/          # Signed binaries from aos-signer
│   └── aos-agent.signed
```

## Pipeline Stages

### Stage 1: Build (cpp-builder)

Compiles C++ code for target architecture.

```yaml
builder:
  image: ghcr.io/tri2510/cpp-builder:1.0.2
  environment:
    - TARGET=amd64  # or arm64, armhf
```

**Supported targets:**
- `amd64` - Standard PC/Server
- `arm64` - Raspberry Pi 4/5, AWS Graviton
- `armhf` - Raspberry Pi 2/3

### Stage 2: Sign (aos-signer)

Signs binary with Azure Key Vault certificate.

```yaml
signer:
  image: aos-signer:latest
  environment:
    - VAULT_URL=https://your-vault.vault.azure.net
    - CERT_NAME=my-cert
    - USE_MANAGED_ID=false
```

**Authentication methods:**
- **Managed Identity**: Azure Functions, VMs, AKS
- **Client Credentials**: Service principal
- **Azure CLI**: Local development

### Stage 3: Deploy (deployer)

Uploads signed binary to AosEdge units.

```yaml
deployer:
  image: aos-deployer:latest
  environment:
    - AOS_API_URL=https://aoscloud.io:10000/api/v10
    - UNIT_ID=aos-unit-001
```

## Local Development

### Build Individual Components

```bash
# Just build C++ app
docker run --rm \
  -v $(pwd)/example/aosservice:/project/src:ro \
  -v $(pwd)/artifacts/build:/project/output \
  ghcr.io/tri2510/cpp-builder:1.0.2

# Just sign binary
docker run --rm \
  -v $(pwd)/artifacts/build/usr/local/bin/aos-agent:/input:ro \
  -v $(pwd)/artifacts/signed:/output \
  -e VAULT_URL=$VAULT_URL \
  -e CERT_NAME=$CERT_NAME \
  -e AZURE_CLIENT_ID=$AZURE_CLIENT_ID \
  -e AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET \
  -e AZURE_TENANT_ID=$AZURE_TENANT_ID \
  aos-signer:latest \
  --vault-url=$VAULT_URL --cert=$CERT_NAME \
  --input=/input --output=/output/aos-agent.signed
```

### Manual Deployment

```bash
# Using curl
curl -X POST https://aoscloud.io:10000/api/v10/subjects/ \
  -H "Authorization: Bearer $AOS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"label": "Production Fleet", "is_group": true}'
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Build & Deploy AosEdge

on:
  push:
    tags:
      - 'v*'

jobs:
  pipeline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build, Sign, Deploy
        env:
          VAULT_URL: ${{ secrets.VAULT_URL }}
          CERT_NAME: ${{ secrets.CERT_NAME }}
          AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          AOS_API_KEY: ${{ secrets.AOS_API_KEY }}
        run: |
          docker-compose -f docker-compose.aosedge.yml up
```

### Azure DevOps

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: DockerCompose@0
  inputs:
    dockerComposeFile: 'docker-compose.aosedge.yml'
    dockerComposeCommand: 'up'
    env:
      VAULT_URL: $(VAULT_URL)
      CERT_NAME: $(CERT_NAME)
      AZURE_CLIENT_ID: $(AZURE_CLIENT_ID)
      AZURE_CLIENT_SECRET: $(AZURE_CLIENT_SECRET)
      AZURE_TENANT_ID: $(AZURE_TENANT_ID)
```

## Azure Function Integration

For serverless signing, deploy aos-signer as an Azure Function:

```python
import azure.functions as func
import subprocess
import os

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Save uploaded binary
    input_path = "/tmp/binary"
    output_path = "/tmp/binary.signed"

    with open(input_path, "wb") as f:
        f.write(req.get_body())

    # Sign using aos-signer Docker container
    result = subprocess.run([
        "docker", "run", "--rm",
        "-v", f"{input_path}:/input:ro",
        "-v", f"{os.path.dirname(output_path)}:/output",
        "aos-signer:latest",
        "--vault-url", os.environ["VAULT_URL"],
        "--cert", os.environ["CERT_NAME"],
        "--input", "/input",
        "--output", "/output/binary.signed",
        "--use-managed-id"
    ], capture_output=True)

    if result.returncode != 0:
        return func.HttpResponse(
            f"Signing failed: {result.stderr.decode()}",
            status_code=500
        )

    # Return signed binary
    with open(output_path, "rb") as f:
        return func.HttpResponse(
            f.read(),
            mimetype="application/octet-stream"
        )
```

## Troubleshooting

### Build Fails

```bash
# Check builder logs
docker-compose -f docker-compose.aosedge.yml logs builder

# Run builder interactively
docker run --rm -it \
  -v $(pwd)/example/aosservice:/project/src \
  ghcr.io/tri2510/cpp-builder:1.0.2 /bin/bash
```

### Signing Fails

```bash
# Test Azure credentials
az login --service-principal \
  -u $AZURE_CLIENT_ID \
  -p $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

# Verify Key Vault access
az keyvault secret show \
  --vault-name your-vault \
  --name your-cert
```

### Deployment Fails

```bash
# Test API connectivity
curl -H "Authorization: Bearer $AOS_API_KEY" \
  https://aoscloud.io:10000/api/v10/units/

# Check deployer logs
docker-compose -f docker-compose.aosedge.yml logs deployer
```

## Files Reference

| File | Purpose |
|------|---------|
| `docker-compose.aosedge.yml` | Main pipeline orchestration |
| `.env.aosedge.template` | Configuration template |
| `example/aosservice/` | Sample C++ application |
| `aos-signer/` | Go signing tool |
| `deployer/` | Python deployment script |
| `docs/AosEdge_API_Guide.md` | API documentation |
