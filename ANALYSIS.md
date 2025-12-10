# Generic Image Builder - Analysis & Implementation Plan

## Analysis of Technical Seminars Images Repository

### Current Architecture

The `technical-seminars-images` repository uses a **monolithic approach** where:

1. **Single Repository Structure**:
   - Multiple demo/workshop directories (genai-workshop, redt, rdi, etc.)
   - Each directory contains: `docker-compose.yml`, `start.sh`, `build.sh` (optional)
   - Shared files at root: `packer.json`, `cloudbuild.yaml`, `start_image.sh`, `ts-service.service`

2. **Build Process** (via Cloud Build):
   ```
   Cloud Build Trigger → cloudbuild.yaml → Packer → GCP Image
   ```
   - Fetches GCP secret for authentication
   - Runs Packer with variables: `project_id`, `image_name`, `image_family`, `zone`, `region`
   - Packer copies the specific directory to `/content` on the VM
   - Installs Docker, Docker Compose, and dependencies
   - Runs `build.sh` if present (for custom build steps)
   - Pulls all Docker images from `docker-compose.yml` (caching)
   - Enables systemd service `ts-service`

3. **Runtime Process**:
   - VM boots → systemd starts `ts-service`
   - Service runs `start_image.sh` which:
     - Fetches metadata from GCP (environment variables)
     - Executes `/content/start.sh` (workshop-specific startup)
   - `start.sh` typically runs `docker-compose up`

### Key Insights

**What Makes It Work:**
- ✅ Pre-caches Docker images at build time (fast startup)
- ✅ Uses GCP metadata for runtime configuration
- ✅ Systemd service for automatic startup
- ✅ Standardized structure (docker-compose + start.sh)

**Limitations:**
- ❌ Monolithic repo (all demos in one place)
- ❌ Manual trigger per image directory
- ❌ No versioning of individual images
- ❌ Cannot be called from external repos

---

## Proposed Generic Image Builder Architecture

### Vision
Create a **centralized, reusable image builder** that:
1. Can be triggered manually with parameters
2. Can be called from other repositories via API/webhook
3. Supports versioning
4. Works with any repository following a standard structure

### Architecture Overview

```
External Repo (Demo/Workshop)     →     ps-image-builder (This Repo)     →     GCP Image
├── docker-compose.yml                  ├── .github/workflows/
├── start.sh                            │   ├── build-image.yml (manual + webhook)
├── build.sh (optional)                 │   └── ...
└── README.md                           ├── packer/
                                        │   ├── base-template.pkr.hcl
                                        │   └── scripts/
                                        ├── scripts/
                                        │   ├── start_image.sh
                                        │   └── install-dependencies.sh
                                        └── config/
                                            └── ts-service.service
```

### Implementation Plan

#### Phase 1: Manual Trigger (MVP)
**Goal**: Build images manually via GitHub Actions with input parameters

**Inputs**:
- `source_repo_url`: Git repository URL (e.g., https://github.com/user/demo-repo)
- `source_repo_ref`: Branch/tag/commit (default: main)
- `image_name`: Name for the GCP image
- `image_family`: Image family (for versioning)
- `gcp_project_id`: Target GCP project
- `gcp_region`: GCP region (default: us-east1)
- `gcp_zone`: GCP zone (default: us-east1-b)

**Workflow**:
1. Checkout ps-image-builder repo
2. Clone source repository to temp directory
3. Validate structure (check for docker-compose.yml, start.sh)
4. Setup Packer
5. Run Packer build with source code
6. Output: Image name and family

**Benefits**:
- ✅ Decouples image builder from demo code
- ✅ Any repo can be built
- ✅ Manual control and testing

#### Phase 2: Webhook/API Trigger
**Goal**: Allow external repos to trigger builds automatically

**Approaches**:

**Option A: GitHub Actions Workflow Dispatch**
- External repo triggers via GitHub API
- Requires GitHub token
- Simple, native integration

**Option B: Cloud Build Trigger**
- Use GCP Cloud Build with HTTP trigger
- More flexible, cloud-native
- Better for production

**Recommended**: Start with Option A, migrate to Option B

#### Phase 3: Versioning & Tagging
**Goal**: Semantic versioning for images

**Strategy**:
- Use `image_family` for major versions (e.g., `demo-v1`, `demo-v2`)
- Append timestamp or git commit SHA to `image_name`
- Store metadata in GCP image labels

---

## Standard Repository Structure

### Required Files

```
your-demo-repo/
├── docker-compose.yml    # Required: Defines all services
├── start.sh              # Required: Startup script
├── build.sh              # Optional: Build-time setup
└── .image-builder.yml    # Optional: Configuration for image builder
```

### `.image-builder.yml` (Optional Config)
```yaml
version: 1
image:
  family: my-demo
  base_image: ubuntu-2004-lts
  disk_size: 100
build:
  pre_build_commands:
    - apt-get install -y custom-package
  skip_docker_cache: false
runtime:
  required_metadata:
    - DOMAIN
    - HOSTNAME
```

---

## Next Steps

1. **Extract and adapt** `packer.json` → `base-template.pkr.hcl` (HCL format)
2. **Create GitHub Actions workflow** for manual trigger
3. **Test with sample repository**
4. **Document** usage for external repos
5. **Add webhook support** (Phase 2)
6. **Implement versioning** (Phase 3)

