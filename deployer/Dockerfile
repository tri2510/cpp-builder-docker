FROM python:3.12-slim

LABEL maintainer="AosCloud"
LABEL description="AosEdge Deployer - Uploads signed binaries to AosEdge API"

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir requests && \
    rm -rf /root/.cache

# Copy deployer script
COPY deploy.py /app/deploy.py
RUN chmod +x /app/deploy.py

# Create input directory
RUN mkdir -p /input

# Set entrypoint
ENTRYPOINT ["python", "/app/deploy.py"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"
