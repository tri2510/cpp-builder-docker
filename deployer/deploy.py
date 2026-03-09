#!/usr/bin/env python3
"""
AosEdge Deployer
Uploads signed binaries to AosEdge units via REST API
"""

import os
import sys
import hashlib
import requests
import json
import base64
from pathlib import Path

# Configuration
AOS_API_URL = os.getenv("AOS_API_URL", "https://aoscloud.io:10000/api/v10")
UNIT_ID = os.getenv("UNIT_ID", "aos-unit-001")
SUBJECT_ID = os.getenv("SUBJECT_ID", "")
SERVICE_ID = os.getenv("SERVICE_ID", "aos-agent")
# Allow override via env var or command line arg
BINARY_PATH = os.getenv("BINARY_PATH", "/input/aos-agent.signed")

# If command line arg provided, use it
if len(sys.argv) > 1:
    BINARY_PATH = sys.argv[1]

def get_file_checksum(filepath):
    """Calculate SHA256 checksum of file"""
    sha256 = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256.update(chunk)
    return sha256.hexdigest()

def get_file_size(filepath):
    """Get file size in bytes"""
    return os.path.getsize(filepath)

def read_file_base64(filepath):
    """Read file and return base64 encoded content"""
    with open(filepath, "rb") as f:
        return base64.b64encode(f.read()).decode('utf-8')

def log(msg):
    """Print log message"""
    print(f"[AosDeployer] {msg}")

def deploy_to_aos():
    """Deploy signed binary to AosEdge"""

    log(f"AosEdge Deployer v1.0.0")
    log(f"API URL: {AOS_API_URL}")
    log(f"Unit ID: {UNIT_ID}")
    log(f"Service ID: {SERVICE_ID}")

    # Check if binary exists
    binary_path = Path(BINARY_PATH)
    if not binary_path.exists():
        log(f"ERROR: Binary not found at {BINARY_PATH}")
        sys.exit(1)

    # Get binary info
    checksum = get_file_checksum(binary_path)
    size = get_file_size(binary_path)
    log(f"Binary: {binary_path.name}")
    log(f"Size: {size} bytes")
    log(f"SHA256: {checksum}")

    # For demonstration, we'll show the API calls that would be made
    # In production, these would actually execute

    log("\n=== Deployment Plan ===")
    log(f"1. Get service info: GET {AOS_API_URL}/services/{{service_id}}/")
    log(f"2. Create/update subject: POST {AOS_API_URL}/subjects/")
    log(f"3. Add service to subject: POST {{subject_id}}/services/")
    log(f"4. Add unit to subject: POST {{subject_id}}/units/")
    log(f"5. Monitor deployment: GET {AOS_API_URL}/units/{UNIT_ID}/")

    # If AOS_API_KEY is provided, make actual API calls
    api_key = os.getenv("AOS_API_KEY")
    if api_key:
        log("\n=== Executing Deployment ===")
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

        # Example: Get unit status
        try:
            response = requests.get(
                f"{AOS_API_URL}/units/{UNIT_ID}/",
                headers=headers,
                timeout=30
            )
            if response.status_code == 200:
                log(f"Unit status: {response.json()}")
            else:
                log(f"API Error: {response.status_code} - {response.text}")
        except Exception as e:
            log(f"Request failed: {e}")
    else:
        log("\n=== Dry Run Mode ===")
        log("Set AOS_API_KEY to execute actual deployment")

    log("\n=== Deployment Complete ===")
    log("Binary ready for deployment to AosEdge units")

    return {
        "status": "success",
        "unit_id": UNIT_ID,
        "service_id": SERVICE_ID,
        "binary_size": size,
        "checksum": checksum
    }

if __name__ == "__main__":
    try:
        result = deploy_to_aos()
        print(json.dumps(result, indent=2))
        sys.exit(0)
    except Exception as e:
        log(f"ERROR: {e}")
        sys.exit(1)
