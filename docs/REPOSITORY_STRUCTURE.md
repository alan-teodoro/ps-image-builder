# Repository Structure Guide

This guide explains how to structure your workshop/demo repository to work with the **ps-image-builder**.

## Overview

The image builder can create GCP Compute Engine images from any Git repository that follows a simple, standardized structure. Your repository needs just two required files to get started.

## Required Files

### 1. `docker-compose.yml` (Required)

Defines all services that will run in your workshop/demo.

**Requirements:**
- Must have at least one service listening on **port 80** (for HTTP access)
- All Docker images will be pre-cached during image build for fast startup

**Example:**
```yaml
version: '3'
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
  
  redis:
    image: redis:latest
    ports:
      - "6379:6379"
  
  app:
    build: .
    depends_on:
      - redis
```

### 2. `start.sh` (Required)

Startup script that runs when the VM boots.

**Requirements:**
- Must be executable
- Should start your services (typically `docker-compose up`)
- Can use environment variables from GCP metadata

**Example:**
```bash
#!/bin/bash
set -e

# Environment variables are automatically exported from GCP metadata
# Common variables: DOMAIN, HOSTNAME, HOST_IP, etc.

echo "Starting workshop services..."

# Start all services
docker-compose up -d

echo "Services started successfully!"
```

## Optional Files

### 3. `build.sh` (Optional)

Build-time setup script that runs during image creation.

**Use cases:**
- Install system packages
- Download large files
- Pre-build Docker images
- Setup configuration files

**Example:**
```bash
#!/bin/bash
set -e

# Install additional packages
apt-get update
apt-get install -y jq curl

# Pre-download large datasets
wget https://example.com/large-dataset.zip -O /content/data.zip

# Build custom Docker images
docker build -t my-custom-app:latest .
```

### 4. `.image-builder.yml` (Optional - Future)

Configuration file for advanced image builder options.

**Example:**
```yaml
version: 1
image:
  family: my-workshop
  disk_size: 150
  base_image: ubuntu-2204-lts

build:
  pre_build_commands:
    - apt-get install -y custom-package
  skip_docker_cache: false

runtime:
  required_metadata:
    - DOMAIN
    - HOSTNAME
    - API_KEY
```

## Complete Example Structure

```
my-workshop-repo/
├── docker-compose.yml          # Required: Service definitions
├── start.sh                    # Required: Startup script
├── build.sh                    # Optional: Build-time setup
├── .image-builder.yml          # Optional: Builder configuration
├── Dockerfile                  # Optional: Custom app container
├── nginx.conf                  # Optional: Configuration files
├── scripts/                    # Optional: Helper scripts
│   └── setup-database.sh
├── data/                       # Optional: Static data
│   └── sample-data.json
└── README.md                   # Recommended: Documentation
```

## Environment Variables

Your `start.sh` script has access to environment variables from GCP metadata:

### Automatically Available
- `DOMAIN`: Domain for the VM (e.g., `nip.io`)
- `HOSTNAME`: VM hostname
- `HOST_IP`: VM's internal IP address

### Custom Variables
You can pass custom variables when creating the VM instance in GCP:
```bash
gcloud compute instances create my-instance \
  --image-family=my-workshop \
  --metadata=API_KEY=secret123,DATABASE_URL=postgres://...
```

These will be automatically exported in `start.sh`.

## Best Practices

### 1. Keep Images Small
- Only include necessary files
- Use `.dockerignore` to exclude build artifacts
- Clean up temporary files in `build.sh`

### 2. Fast Startup
- Pre-cache all Docker images in `docker-compose.yml`
- Avoid downloading large files in `start.sh`
- Use `build.sh` for time-consuming operations

### 3. Port 80 Requirement
- Always expose a service on port 80
- Use nginx as a reverse proxy if needed
- This allows the platform to route traffic to your VM

### 4. Idempotent Scripts
- Make `start.sh` safe to run multiple times
- Check if services are already running
- Use `docker-compose up -d` (detached mode)

### 5. Logging
- Log to stdout/stderr for systemd journal
- Create log files in `/content/` for debugging
- Use `docker-compose logs` for container logs

## Testing Locally

Before building an image, test your repository locally:

```bash
# Clone your repo
git clone https://github.com/yourorg/my-workshop
cd my-workshop

# Set required environment variables
export DOMAIN="nip.io"
export HOSTNAME="127.0.0.1"
export HOST_IP="127.0.0.1"

# Run build script (if present)
bash build.sh

# Run startup script
bash start.sh

# Test your services
curl http://localhost
```

## Common Patterns

### Pattern 1: Simple Web App
```
├── docker-compose.yml    # nginx + app + database
└── start.sh              # docker-compose up -d
```

### Pattern 2: Workshop with Jupyter
```
├── docker-compose.yml    # jupyter + redis + nginx
├── start.sh              # Setup notebooks, start services
├── build.sh              # Install Python packages
└── notebooks/            # Jupyter notebooks
```

### Pattern 3: Multi-Service Demo
```
├── docker-compose.yml    # Multiple microservices
├── start.sh              # Start services, run migrations
├── build.sh              # Build custom images
└── config/               # Service configurations
```

## Troubleshooting

### Image build fails
- Check that `docker-compose.yml` is valid: `docker-compose config`
- Ensure `start.sh` is executable: `chmod +x start.sh`
- Verify all referenced files exist

### Services don't start
- Check logs: `journalctl -u ts-service -f`
- Check Docker logs: `docker-compose logs`
- Verify environment variables are set

### Port 80 not accessible
- Ensure a service is listening on port 80
- Check firewall rules in GCP
- Verify nginx configuration if using reverse proxy

## Next Steps

1. Create your repository with `docker-compose.yml` and `start.sh`
2. Test locally
3. Push to GitHub
4. Use ps-image-builder to create a GCP image
5. Deploy and test the image

For more information, see the [main README](../README.md).

