# Reusable Workflow Guide

## Overview

The `ps-image-builder` workflow is designed as a **reusable workflow** that can be called from other repositories. This approach provides several advantages over API-based triggers:

### Benefits

✅ **Synchronous Execution** - Calling workflow waits for completion  
✅ **Direct Outputs** - Image ID and details returned directly  
✅ **No PAT Required** - Uses GitHub's built-in authentication  
✅ **Versioned** - Pin to specific versions for stability  
✅ **Type-Safe** - Input validation and type checking  
✅ **Cleaner Code** - No curl commands or API calls  

## How It Works

```mermaid
graph LR
    A[Workshop Repo] -->|calls| B[ps-image-builder@v1.0.0]
    B -->|validates| C[Repository Structure]
    C -->|builds| D[Packer Image]
    D -->|outputs| E[Image ID]
    E -->|returns to| A
    A -->|uses| F[Deploy VM]
```

## Quick Start

### 1. Add Secrets to Your Workshop Repository

Go to your workshop repository settings and add:

- **GCP_SA_KEY**: Your GCP service account key JSON
- **GCP_PROJECT_ID**: Your GCP project ID

### 2. Create Workflow File

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
      gcp_region: 'us-east1'
      gcp_zone: 'us-east1-b'
      disk_size: '100'
    secrets:
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

### 3. Use the Outputs

```yaml
jobs:
  build-image:
    uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@v1.0.0
    # ... inputs and secrets ...
  
  deploy:
    needs: build-image
    runs-on: ubuntu-latest
    steps:
      - name: Deploy VM
        run: |
          echo "Image ID: ${{ needs.build-image.outputs.image_id }}"
          echo "Image Name: ${{ needs.build-image.outputs.image_name }}"
          
          gcloud compute instances create my-vm \
            --image=${{ needs.build-image.outputs.image_name }} \
            --project=${{ secrets.GCP_PROJECT_ID }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `source_repo_url` | Yes | - | Full URL of the workshop repository |
| `source_repo_ref` | No | `main` | Branch, tag, or commit SHA |
| `image_name` | Yes | - | Base name for the image |
| `image_family` | No | `generic-workshop` | Image family for versioning |
| `gcp_project_id` | Yes | - | GCP project ID |
| `gcp_region` | No | `us-east1` | GCP region |
| `gcp_zone` | No | `us-east1-b` | GCP zone |
| `disk_size` | No | `100` | Disk size in GB |

## Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `GCP_SA_KEY` | Yes | GCP service account key JSON |

## Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `image_id` | GCP image ID | `1234567890123456789` |
| `image_name` | Full image name | `my-workshop-20231210-123456` |
| `image_self_link` | GCP self link | `https://www.googleapis.com/compute/v1/projects/...` |

## Versioning

**Always use a specific version in production!**

```yaml
# ❌ DON'T - unstable, can break
uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@main

# ✅ DO - stable, pinned version
uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@v1.0.0

# ✅ ALSO GOOD - latest patch version
uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@v1
```

### Available Versions

- **v1.0.0** - Initial stable release
- **v1** - Latest v1.x.x (auto-updates to latest patch)
- **main** - Development branch (not recommended)

### Semantic Versioning

We follow [Semantic Versioning](https://semver.org/):

- **Major (v2.0.0)** - Breaking changes, requires updates
- **Minor (v1.1.0)** - New features, backward compatible
- **Patch (v1.0.1)** - Bug fixes, backward compatible

## Complete Example

Here's a complete example with build and deploy:

```yaml
name: Build and Deploy

on:
  push:
    tags: ['v*']

jobs:
  build-image:
    name: Build GCP Image
    uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@v1.0.0
    with:
      source_repo_url: ${{ github.server_url }}/${{ github.repository }}
      source_repo_ref: ${{ github.ref_name }}
      image_name: ${{ github.event.repository.name }}
      image_family: ${{ format('{0}-{1}', github.event.repository.name, github.ref_name) }}
      gcp_project_id: ${{ secrets.GCP_PROJECT_ID }}
    secrets:
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
  
  deploy-vm:
    name: Deploy VM
    needs: build-image
    runs-on: ubuntu-latest
    steps:
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Deploy VM
        run: |
          gcloud compute instances create workshop-vm \
            --image=${{ needs.build-image.outputs.image_name }} \
            --project=${{ secrets.GCP_PROJECT_ID }} \
            --zone=us-east1-b \
            --machine-type=n1-standard-2 \
            --metadata=DOMAIN=nip.io,HOSTNAME=workshop \
            --tags=http-server
      
      - name: Get VM IP
        id: get_ip
        run: |
          IP=$(gcloud compute instances describe workshop-vm \
            --zone=us-east1-b \
            --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
          echo "ip=$IP" >> $GITHUB_OUTPUT
      
      - name: Display URL
        run: |
          echo "🎉 Workshop deployed!"
          echo "URL: http://${{ steps.get_ip.outputs.ip }}"
```

## Troubleshooting

### Build Fails with "Repository not found"

Make sure your workshop repository is:
- Public, OR
- The GCP service account has access to it

### Outputs are Empty

Check that:
- The build completed successfully
- You're using `needs.build-image.outputs.*` syntax
- The job has `needs: build-image` dependency

### Version Not Found

Make sure you're using a valid version:
```bash
# List available versions
git ls-remote --tags https://github.com/alan-teodoro/ps-image-builder
```

## Best Practices

1. **Pin Versions**: Always use `@v1.0.0` in production
2. **Use Image Families**: Easier to reference latest image
3. **Tag Releases**: Trigger builds on git tags (`v1.0.0`)
4. **Monitor Builds**: Check Actions tab for build status
5. **Test First**: Test with `@main` in dev, then pin version

## See Also

- [Quick Start Guide](QUICK_START.md)
- [Repository Structure](REPOSITORY_STRUCTURE.md)
- [Triggering from Repos](TRIGGER_FROM_REPO.md)
- [CHANGELOG](../CHANGELOG.md)

