# PS Image Builder

A **generic, reusable image builder** for creating GCP Compute Engine images from any workshop or demo repository.

## Overview

This project allows you to build pre-configured VM images from **any Git repository** that follows a simple standard structure. Instead of installing software at boot time (10-15 minutes), images are pre-built with all dependencies and Docker images cached, enabling instance provisioning in ~30 seconds.

### Key Features

- ✅ **Generic & Reusable**: Works with any repository following the standard structure
- ✅ **Fast Provisioning**: Pre-caches Docker images for instant startup
- ✅ **Manual & Automated**: Trigger builds manually or via webhooks
- ✅ **Versioned**: Support for image families and semantic versioning
- ✅ **Simple Structure**: Only requires `docker-compose.yml` and `start.sh`

## Quick Start

### 1. Prepare Your Repository

Your workshop/demo repository needs just two files:

```
your-workshop-repo/
├── docker-compose.yml    # Required: Service definitions
└── start.sh              # Required: Startup script
```

See [Repository Structure Guide](docs/REPOSITORY_STRUCTURE.md) for details.

### 2. Build an Image

#### Option A: GitHub Actions (Manual Trigger)

1. Go to **Actions** tab in this repository
2. Select **"Build GCP Image"** workflow
3. Click **"Run workflow"**
4. Fill in the parameters:
   - **Source repo URL**: `https://github.com/yourorg/your-workshop`
   - **Branch/tag**: `main`
   - **Image name**: `my-workshop`
   - **Image family**: `my-workshop-v1`
   - **GCP project ID**: `your-gcp-project`
5. Click **"Run workflow"**

#### Option B: Local Build (Advanced)

```bash
# Clone your workshop repository
git clone https://github.com/yourorg/your-workshop source

# Initialize Packer
cd packer
packer init generic-image.pkr.hcl

# Build the image
packer build \
  -var "project_id=your-gcp-project" \
  -var "image_name=my-workshop" \
  -var "image_family=my-workshop-v1" \
  -var "source_content_path=../source" \
  generic-image.pkr.hcl
```

### 3. Deploy the Image

The image will be available in GCP Console:
**Compute Engine > Images > Filter by family**

Deploy with `gcloud`:

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

- [Repository Structure Guide](docs/REPOSITORY_STRUCTURE.md) - How to structure your workshop repo
- [Analysis Document](ANALYSIS.md) - Technical analysis and architecture

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

