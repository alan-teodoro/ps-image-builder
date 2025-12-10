# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Workshop Repository                         │
│  (External - Created by workshop authors)                       │
│                                                                  │
│  ├── docker-compose.yml    (Required)                          │
│  ├── start.sh              (Required)                          │
│  ├── build.sh              (Optional)                          │
│  └── .image-builder.yml    (Optional - Future)                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 1. Trigger Build (Manual or Webhook)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   GitHub Actions Workflow                        │
│  (ps-image-builder repository)                                  │
│                                                                  │
│  Steps:                                                         │
│  1. Clone workshop repository                                  │
│  2. Validate structure (docker-compose.yml, start.sh)          │
│  3. Setup Packer                                               │
│  4. Authenticate to GCP                                        │
│  5. Run Packer build                                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 2. Execute Packer
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Packer Build Process                        │
│  (Temporary GCP VM)                                             │
│                                                                  │
│  Provisioning Steps:                                            │
│  1. Create temporary VM from Ubuntu base image                 │
│  2. Copy workshop content to /content                          │
│  3. Copy shared scripts (start_image.sh)                       │
│  4. Install dependencies (Docker, Docker Compose, etc.)        │
│  5. Run build.sh (if exists)                                   │
│  6. Pre-cache Docker images (docker-compose pull)              │
│  7. Setup systemd service                                      │
│  8. Create GCP image from VM                                   │
│  9. Delete temporary VM                                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 3. Image Created
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GCP Compute Image                           │
│  (Stored in GCP project)                                        │
│                                                                  │
│  Contents:                                                      │
│  ├── /content/                  (Workshop files)               │
│  │   ├── docker-compose.yml                                    │
│  │   ├── start.sh                                              │
│  │   ├── start_image.sh                                        │
│  │   └── ... (all workshop files)                             │
│  ├── Docker + Docker Compose    (Pre-installed)               │
│  ├── Docker images              (Pre-cached)                   │
│  └── systemd service            (Auto-start enabled)           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 4. Deploy VM
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Running VM Instance                         │
│  (Deployed by user)                                             │
│                                                                  │
│  Boot Sequence:                                                 │
│  1. VM starts                                                   │
│  2. systemd starts ts-service                                  │
│  3. ts-service runs start_image.sh                            │
│  4. start_image.sh fetches GCP metadata                       │
│  5. start_image.sh runs /content/start.sh                     │
│  6. start.sh runs docker-compose up                           │
│  7. Services are running! (~30 seconds total)                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Interaction

### Build Time

```
GitHub Actions → Packer → GCP Compute Engine
     │              │              │
     │              │              ├─ Create temp VM
     │              │              ├─ Provision VM
     │              │              ├─ Create image
     │              │              └─ Delete temp VM
     │              │
     │              └─ Orchestrates provisioning
     │
     └─ Triggers and monitors build
```

### Runtime

```
VM Boot → systemd → ts-service → start_image.sh → start.sh → docker-compose
                                       │
                                       └─ Fetches GCP metadata
                                          (DOMAIN, HOSTNAME, etc.)
```

## Data Flow

### 1. Build Phase

```
Workshop Repo (GitHub)
    │
    ├─ Clone ──────────────────────┐
    │                              │
    ▼                              ▼
Validation                    Packer Build
    │                              │
    ├─ Check docker-compose.yml    ├─ Copy to /content
    ├─ Check start.sh              ├─ Install Docker
    └─ Check port 80               ├─ Run build.sh
                                   ├─ Pull Docker images
                                   └─ Create GCP image
```

### 2. Deployment Phase

```
GCP Image
    │
    └─ Deploy VM ──────────────────┐
                                   │
                                   ▼
                            VM Instance
                                   │
                                   ├─ Boot
                                   ├─ Start systemd
                                   ├─ Run ts-service
                                   ├─ Fetch metadata
                                   ├─ Run start.sh
                                   └─ Start services
```

## Key Design Decisions

### 1. Pre-caching Docker Images
**Why**: Dramatically reduces startup time from 10-15 minutes to ~30 seconds
**How**: Run `docker-compose pull` during image build
**Trade-off**: Larger image size, but much faster deployment

### 2. Systemd Service
**Why**: Ensures services start automatically on boot
**How**: Enable ts-service.service during provisioning
**Benefit**: No manual intervention needed after VM creation

### 3. GCP Metadata for Configuration
**Why**: Allows dynamic configuration without rebuilding images
**How**: Fetch metadata in start_image.sh and export as env vars
**Benefit**: Same image can be used with different configurations

### 4. Standardized Structure
**Why**: Makes the builder truly generic and reusable
**How**: Require only docker-compose.yml and start.sh
**Benefit**: Any workshop can be built with minimal changes

### 5. Separation of Concerns
**Why**: Clear separation between builder and workshop code
**How**: Builder repo contains only build logic, workshop repos contain only workshop code
**Benefit**: Easy to maintain and update independently

## Security Considerations

### Build Time
- GCP service account with minimal required permissions
- Secrets stored in GitHub Secrets (encrypted)
- Temporary VMs deleted after build
- No sensitive data in images

### Runtime
- Metadata service only accessible from VM
- Firewall rules control network access
- Docker containers run with appropriate permissions
- Logs available via systemd journal

## Scalability

### Concurrent Builds
- GitHub Actions supports multiple concurrent workflows
- Each build uses isolated temporary VM
- No shared state between builds

### Image Storage
- Images stored in GCP with automatic replication
- Image families allow versioning
- Old images can be automatically cleaned up

### Deployment
- Images can be deployed to any number of VMs
- Each VM is independent
- Horizontal scaling supported

## Performance

### Build Time
- ~10-15 minutes per image
- Depends on:
  - Number of Docker images to cache
  - Size of workshop content
  - Network speed for pulling images

### Startup Time
- ~30 seconds from VM creation to services running
- Pre-cached images eliminate download time
- Systemd ensures automatic startup

### Resource Usage
- Build VM: n1-standard-2 (2 vCPU, 7.5 GB RAM)
- Runtime VM: Configurable based on workshop needs
- Disk: Default 100 GB, configurable

## Future Enhancements

### Phase 2: Webhooks
- Add repository_dispatch trigger
- Allow external repos to trigger builds
- Implement build status notifications

### Phase 3: Versioning
- Semantic versioning based on git tags
- Automated changelog generation
- Image metadata with build info

### Phase 4: Advanced Features
- Multi-region image replication
- Automated testing of built images
- Cost optimization (cleanup old images)
- Multi-cloud support (AWS, Azure)

