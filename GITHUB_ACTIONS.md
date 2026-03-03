# GitHub Actions Setup Guide

This project includes GitHub Actions workflows for automatic Docker image building and publishing on releases.

## Workflows

### CI Workflow (`.github/workflows/ci.yml`)

Runs on every push and pull request to `main` and `develop` branches.

**Jobs:**
- **test-native** - Builds and tests the native Docker image
- **test-cross** - Builds and tests the cross-compiler image
- **lint** - Validates shell scripts and YAML files

### Release Workflow (`.github/workflows/docker-release.yml`)

Triggered when you push a version tag (e.g., `v1.0.0`).

**Builds and publishes:**
| Image | Platforms | Tag Example |
|-------|-----------|-------------|
| `cpp-builder:latest` | linux/amd64 | `v1.0.0`, `latest` |
| `cpp-builder:cross` | linux/amd64, linux/arm64, linux/arm/v7 | `v1.0.0-cross`, `cross` |

## Setup

### 1. Configure Secrets

Go to your repository **Settings → Secrets and variables → Actions** and add:

#### For Docker Hub:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DOCKER_USERNAME` | Your Docker Hub username | e.g., `johndoe` |
| `DOCKER_PASSWORD` | Docker Hub access token | Create at https://hub.docker.com/settings/security |

#### For GitHub Container Registry (GHCR):

If using GHCR instead, update `.github/workflows/docker-release.yml`:

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
```

Then use these secrets:

| Secret Name | Value |
|-------------|-------|
| `DOCKER_USERNAME` | Your GitHub username |
| `DOCKER_PASSWORD` | GitHub Personal Access Token (with `write:packages` scope) |

### 2. Create a Release Tag

```bash
# Tag your release
git tag -a v1.0.0 -m "Release v1.0.0"

# Push the tag to trigger the workflow
git push origin v1.0.0
```

The workflow will:
1. Build native and cross-compiler images
2. Push them to your registry
3. Create a GitHub Release with usage instructions

### 3. Use the Published Images

After release, pull and use:

```bash
# Pull specific version
docker pull yourusername/cpp-builder:1.0.0
docker pull yourusername/cpp-builder:1.0.0-cross

# Pull latest
docker pull yourusername/cpp-builder:latest
docker pull yourusername/cpp-builder:cross
```

## Workflow Configuration

### Customizing Image Name

Edit the env variables in `.github/workflows/docker-release.yml`:

```yaml
env:
  IMAGE_NAME: my-cpp-builder  # Change this
  REGISTRY: docker.io         # or ghcr.io
```

### Customizing Trigger Tags

By default, tags matching `v*.*.*` trigger releases (e.g., `v1.0.0`, `v2.1.3`).

To change this, edit the `on.push.tags` section:

```yaml
on:
  push:
    tags:
      - 'v*.*.*'     # v1.0.0
      - 'release-*'  # release-2024-03-03
```

### Adding Multi-Platform Support

The cross-compiler image already builds for multiple platforms:

```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

To add more platforms, ensure:
1. The base image supports them
2. Cross-compilers are available in Ubuntu 24.04
3. QEMU is configured (handled by Docker Buildx automatically)

## Manual Trigger

You can also trigger the release workflow manually:

1. Go to **Actions** tab in your repository
2. Select **Docker Image Release** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**

## Badge

Add a status badge to your README:

```markdown
[![Docker](https://github.com/username/cpp-builder-docker/actions/workflows/docker-release.yml/badge.svg)](https://github.com/username/cpp-builder-docker/actions/workflows/docker-release.yml)
```

## Troubleshooting

### "Permission denied" errors

Ensure your secrets are correctly set:
- Go to Settings → Secrets and variables → Actions
- Verify `DOCKER_USERNAME` and `DOCKER_PASSWORD` exist
- For Docker Hub, use an access token, not your password

### Build fails on ARM platforms

The CI uses `ubuntu-latest` (amd64) runners with QEMU emulation for ARM. This is slower but works. For faster ARM builds, you can use self-hosted ARM runners.

### "Tag not found" error

Make sure you're pushing annotated tags:
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Not lightweight tags:
```bash
# This won't work
git tag v1.0.0
```

## Example Release Process

```bash
# 1. Make your changes
git add .
git commit -m "Add feature X"

# 2. Create and push release tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin main --tags

# 3. GitHub Actions builds and publishes images
# Check Actions tab for progress

# 4. Images are available at:
# docker.io/yourusername/cpp-builder:1.0.0
# docker.io/yourusername/cpp-builder:1.0.0-cross
```
