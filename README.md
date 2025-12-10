# PS Image Builder

A **generic, reusable GitHub Actions workflow** for creating GCP Compute Engine images from any workshop or demo repository.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/alan-teodoro/ps-image-builder/releases/tag/v1.0.0)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Overview

This project provides a **reusable GitHub Actions workflow** that builds pre-configured VM images from **any Git repository** following a simple standard structure. Instead of installing software at boot time (10-15 minutes), images are pre-built with all dependencies and Docker images cached, enabling instance provisioning in ~30 seconds.

### Key Features

- ✅ **Reusable Workflow**: Call from any repository, get image ID back
- ✅ **Synchronous**: Waits for build completion, returns results
- ✅ **Versioned**: Pin to specific versions for stability
- ✅ **Fast Provisioning**: Pre-caches Docker images for instant startup
- ✅ **Simple Structure**: Only requires `docker-compose.yml` and `start.sh`
- ✅ **No PAT Required**: Uses GitHub's built-in authentication

## Quick Start

### 1. Add to Your Workshop Repository

Create `.github/workflows/build-image.yml` in your workshop repository:

```yaml
name: Build GCP Image

on:
  push:
    branches: [main]
    tags: ['v*']
  workflow_dispatch:

jobs:
  build-image:
    uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@v1.0.0
    with:
      source_repo_url: ${{ github.server_url }}/${{ github.repository }}
      source_repo_ref: ${{ github.ref_name }}
      image_name: ${{ github.event.repository.name }}
      image_family: ${{ format('{0}-{1}', github.event.repository.name, github.ref_name) }}
      gcp_project_id: ${{ secrets.GCP_PROJECT_ID }}
    secrets:
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}

  display-results:
    needs: build-image
    runs-on: ubuntu-latest
    steps:
      - run: echo "Image ID: ${{ needs.build-image.outputs.image_id }}"
```

### 2. Add Required Secrets

In your workshop repository settings, add:
- `GCP_SA_KEY` - GCP service account key JSON
- `GCP_PROJECT_ID` - Your GCP project ID

### 3. Prepare Your Repository Structure

Your workshop repository needs just two files:

```
your-workshop-repo/
├── docker-compose.yml    # Required: Service definitions
└── start.sh              # Required: Startup script
```

See [Repository Structure Guide](docs/REPOSITORY_STRUCTURE.md) for details.

### 4. Trigger the Build

Push to `main` or create a tag starting with `v`:

```bash
git tag v1.0.0
git push --tags
```

The workflow will:
1. ✅ Build the GCP image
2. ✅ Pre-cache all Docker images
3. ✅ Return the image ID
4. ✅ Make it available for deployment

## Alternative: Manual Trigger

If you prefer manual control:

1. Go to **Actions** tab in this repository
2. Select **"Build GCP Image"** workflow
3. Click **"Run workflow"**
4. Fill in the parameters and run

## Using the Image

### Deploy with gcloud

```bash
gcloud compute instances create my-workshop-vm \
  --image-family=my-workshop-v1 \
  --project=your-gcp-project \
  --zone=us-east1-b \
  --metadata=DOMAIN=nip.io,HOSTNAME=my-vm
```

Or use in Terraform:

```hcl
data "google_compute_image" "workshop" {
  family  = "my-workshop-v1"
  project = var.project_id
}

resource "google_compute_instance" "workshop" {
  boot_disk {
    initialize_params {
      image = data.google_compute_image.workshop.self_link
    }
  }
}
```

## Directory Structure

```
ps-image-builder/
├── .github/workflows/
│   └── build-image.yml           # GitHub Actions workflow
├── packer/
│   └── generic-image.pkr.hcl     # Packer template
├── scripts/
│   ├── start_image.sh            # VM startup script
│   └── install-dependencies.sh   # Dependency installation
├── config/
│   └── ts-service.service        # Systemd service
├── docs/
│   └── REPOSITORY_STRUCTURE.md   # Repository structure guide
├── examples/
│   └── sample-workshop/          # Sample workshop repository
└── README.md
```

## How It Works

```
┌─────────────────────────┐
│  Your Workshop Repo     │
│  ├── docker-compose.yml │
│  └── start.sh           │
└──────────┬──────────────┘
           │
           │ Trigger Build
           ▼
┌─────────────────────────┐
│  ps-image-builder       │
│  1. Clone repo          │
│  2. Validate structure  │
│  3. Run Packer          │
│  4. Build GCP image     │
└──────────┬──────────────┘
           │
           │ Image Created
           ▼
┌─────────────────────────┐
│  GCP Compute Image      │
│  - Docker installed     │
│  - Images pre-cached    │
│  - Ready to deploy      │
└─────────────────────────┘
```

## Prerequisites

### For Building Images

1. **GCP Service Account** with permissions:
   - `roles/compute.instanceAdmin.v1`
   - `roles/iam.serviceAccountUser`
   - `roles/compute.imageUser`

2. **GitHub Secret**: `GCP_SA_KEY`
   - Add your GCP service account JSON key to repository secrets

3. **Packer** (for local builds):
   ```bash
   brew install packer  # macOS
   # or download from https://www.packer.io/downloads
   ```

### For Workshop Repositories

- Git repository (GitHub, GitLab, etc.)
- `docker-compose.yml` with service definitions
- `start.sh` with startup logic
- At least one service listening on port 80

## Examples

See the [examples/sample-workshop](examples/sample-workshop) directory for a complete working example with:
- Nginx reverse proxy
- Redis database
- RedisInsight GUI
- Node.js application

## Documentation

- 📘 [Reusable Workflow Guide](docs/REUSABLE_WORKFLOW.md) - **START HERE** - How to use this workflow
- 📘 [Repository Structure Guide](docs/REPOSITORY_STRUCTURE.md) - How to structure your workshop repo
- 📘 [Quick Start Guide](docs/QUICK_START.md) - Step-by-step setup
- 📘 [Triggering from Repos](docs/TRIGGER_FROM_REPO.md) - All trigger methods
- 📘 [Architecture](docs/ARCHITECTURE.md) - Technical architecture
- 📘 [Setup Checklist](docs/SETUP_CHECKLIST.md) - Complete setup checklist
- 📘 [CHANGELOG](CHANGELOG.md) - Version history

## Troubleshooting

### Build Fails

**Validation Error**: Missing `docker-compose.yml` or `start.sh`
- Ensure both files exist in your repository root

**Packer Error**: Permission denied
- Check GCP service account has required roles
- Verify `GCP_SA_KEY` secret is set correctly

**Docker Pull Fails**: Network timeout
- Increase timeout in Packer template
- Check GCP network/firewall settings

### Image Doesn't Start

**Services not running**:
```bash
# SSH into VM and check logs
sudo journalctl -u ts-service -f
sudo docker-compose -f /content/docker-compose.yml logs
```

**Port 80 not accessible**:
- Ensure a service is listening on port 80
- Check GCP firewall rules allow HTTP traffic

## Roadmap

- [x] Phase 1: Manual trigger via GitHub Actions
- [ ] Phase 2: Webhook support for automatic builds
- [ ] Phase 3: Semantic versioning and tagging
- [ ] Phase 4: Multi-cloud support (AWS, Azure)

## Contributing

Contributions welcome! Please open an issue or PR.

## License

MIT

