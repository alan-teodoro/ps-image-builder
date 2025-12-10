# Triggering Image Builds from Other Repositories

This guide explains how to trigger image builds from your workshop repository automatically.

## Overview

The `ps-image-builder` workflow can be triggered in three ways:
1. **Reusable Workflow** (RECOMMENDED): Call as a reusable workflow with `workflow_call`
2. **Manual Trigger**: Via GitHub Actions UI (workflow_dispatch)
3. **Programmatic Trigger**: Via GitHub API from another repository (deprecated)

## Method 1: Reusable Workflow (RECOMMENDED)

This is the **recommended approach** as it:
- ✅ Waits for the build to complete
- ✅ Returns the image ID and details
- ✅ Supports versioning via git tags
- ✅ No need for PAT tokens
- ✅ Cleaner and more maintainable

### Prerequisites

Add these secrets to your workshop repository:
- `GCP_SA_KEY`: GCP service account key (same as in ps-image-builder)
- `GCP_PROJECT_ID`: Your GCP project ID

### Create Workflow in Your Workshop Repository

Create `.github/workflows/build-image.yml`:

```yaml
name: Build GCP Image

on:
  push:
    branches: [main]
    tags: ['v*']
  workflow_dispatch:

jobs:
  build-image:
    name: Build GCP Image
    # IMPORTANT: Use a specific version tag in production
    # Example: @v1.0.0 instead of @main
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

  display-results:
    name: Display Results
    needs: build-image
    runs-on: ubuntu-latest
    steps:
      - name: Show image info
        run: |
          echo "Image ID: ${{ needs.build-image.outputs.image_id }}"
          echo "Image Name: ${{ needs.build-image.outputs.image_name }}"
          echo "Self Link: ${{ needs.build-image.outputs.image_self_link }}"
```

### Versioning

**Always use a specific version tag in production!**

```yaml
# ❌ DON'T use @main in production (unstable)
uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@main

# ✅ DO use a specific version tag
uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@v1.0.0

# ✅ Or use a major version (gets latest patch)
uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@v1
```

**Available versions:**
- `v1.0.0` - Initial stable release
- `v1` - Latest v1.x.x release
- `main` - Latest development (not recommended for production)

### Outputs

The workflow provides these outputs:
- `image_id` - GCP image ID (e.g., "1234567890123456789")
- `image_name` - Full image name (e.g., "my-workshop-20231210-123456")
- `image_self_link` - GCP self link URL

Use them in subsequent jobs:

```yaml
jobs:
  build-image:
    uses: alan-teodoro/ps-image-builder/.github/workflows/build-image.yml@v1.0.0
    # ... inputs and secrets ...

  deploy-vm:
    needs: build-image
    runs-on: ubuntu-latest
    steps:
      - name: Deploy VM
        run: |
          gcloud compute instances create my-vm \
            --image=${{ needs.build-image.outputs.image_name }} \
            --project=${{ secrets.GCP_PROJECT_ID }}
```

## Method 2: Manual Trigger (GitHub UI)

1. Go to: https://github.com/alan-teodoro/ps-image-builder/actions
2. Click "Build GCP Image" workflow
3. Click "Run workflow"
4. Fill in parameters and run

## Method 3: Programmatic Trigger (Deprecated)

### Prerequisites

1. **GitHub Personal Access Token (PAT)**
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scopes: `repo` (full control)
   - Copy the token

2. **Add Token to Your Workshop Repository**
   - Go to your workshop repo settings
   - Navigate to: Settings > Secrets and variables > Actions
   - Add secret: `IMAGE_BUILDER_TOKEN` with your PAT

### Create Workflow in Your Workshop Repository

Create `.github/workflows/build-image.yml` in your workshop repository:

```yaml
name: Build GCP Image

on:
  push:
    branches:
      - main
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  trigger-image-build:
    name: Trigger Image Builder
    runs-on: ubuntu-latest
    
    steps:
      - name: Trigger ps-image-builder workflow
        run: |
          curl -X POST \
            -H "Accept: application/vnd.github.v3+json" \
            -H "Authorization: token ${{ secrets.IMAGE_BUILDER_TOKEN }}" \
            https://api.github.com/repos/alan-teodoro/ps-image-builder/dispatches \
            -d '{
              "event_type": "build-image",
              "client_payload": {
                "source_repo_url": "${{ github.server_url }}/${{ github.repository }}",
                "source_repo_ref": "${{ github.ref_name }}",
                "image_name": "my-workshop",
                "image_family": "my-workshop-v1",
                "gcp_project_id": "${{ secrets.GCP_PROJECT_ID }}",
                "gcp_region": "us-east1",
                "gcp_zone": "us-east1-b",
                "disk_size": "100"
              }
            }'
      
      - name: Wait for image build
        run: |
          echo "Image build triggered!"
          echo "Monitor progress at: https://github.com/alan-teodoro/ps-image-builder/actions"
```

### Add Required Secrets to Your Workshop Repository

1. `IMAGE_BUILDER_TOKEN` - GitHub PAT with repo access
2. `GCP_PROJECT_ID` - Your GCP project ID

### Trigger Automatically

The workflow will trigger automatically when:
- You push to `main` branch
- You create a tag starting with `v` (e.g., `v1.0.0`)
- You manually trigger it via GitHub Actions UI

## Method 3: Using GitHub CLI

You can also trigger from command line:

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_github_pat"

# Trigger the build
gh api repos/alan-teodoro/ps-image-builder/dispatches \
  -X POST \
  -f event_type='build-image' \
  -f client_payload[source_repo_url]='https://github.com/alan-teodoro/sample-workshop-demo' \
  -f client_payload[source_repo_ref]='main' \
  -f client_payload[image_name]='sample-workshop' \
  -f client_payload[image_family]='sample-workshop-v1' \
  -f client_payload[gcp_project_id]='your-gcp-project' \
  -f client_payload[gcp_region]='us-east1' \
  -f client_payload[gcp_zone]='us-east1-b' \
  -f client_payload[disk_size]='100'
```

## Getting the Image ID After Build

The workflow outputs the image information in multiple ways:

### 1. GitHub Actions Output

The workflow sets these outputs:
- `image_id` - GCP image ID
- `image_name` - Full image name
- `image_self_link` - GCP self link

### 2. Image Manifest Artifact

Download the `image-manifest.json` artifact from the workflow run:

```json
{
  "image_id": "1234567890123456789",
  "image_name": "sample-workshop-20231210-123456",
  "image_family": "sample-workshop-v1",
  "image_self_link": "https://www.googleapis.com/compute/v1/projects/...",
  "gcp_project_id": "your-project",
  "gcp_region": "us-east1",
  "gcp_zone": "us-east1-b",
  "source_repo": "https://github.com/alan-teodoro/sample-workshop-demo",
  "source_ref": "main",
  "build_timestamp": "2023-12-10T12:34:56Z",
  "workflow_run_id": "123456789",
  "workflow_run_number": "42"
}
```

### 3. Query via GCP API

```bash
# Get latest image from family
gcloud compute images describe-from-family sample-workshop-v1 \
  --project=your-gcp-project \
  --format='get(name,id,selfLink)'
```

## Example: Complete CI/CD Pipeline

Here's a complete example that builds an image and deploys a VM:

```yaml
name: Build and Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  build-image:
    runs-on: ubuntu-latest
    outputs:
      run_id: ${{ steps.trigger.outputs.run_id }}
    
    steps:
      - name: Trigger image build
        id: trigger
        run: |
          RESPONSE=$(curl -X POST \
            -H "Authorization: token ${{ secrets.IMAGE_BUILDER_TOKEN }}" \
            https://api.github.com/repos/alan-teodoro/ps-image-builder/dispatches \
            -d '{"event_type":"build-image","client_payload":{...}}')
          
          echo "Build triggered!"
  
  deploy-vm:
    needs: build-image
    runs-on: ubuntu-latest
    
    steps:
      - name: Wait for image build (manual check)
        run: |
          echo "Check build status at:"
          echo "https://github.com/alan-teodoro/ps-image-builder/actions"
          echo ""
          echo "Once complete, the image will be available in GCP"
      
      - name: Deploy VM
        run: |
          gcloud compute instances create my-vm \
            --image-family=my-workshop-v1 \
            --project=${{ secrets.GCP_PROJECT_ID }} \
            --zone=us-east1-b
```

## Best Practices

1. **Use Image Families**: Always use image families instead of specific image names
2. **Version Your Images**: Use semantic versioning in image family names (e.g., `my-workshop-v1`, `my-workshop-v2`)
3. **Tag Your Releases**: Trigger builds on git tags for versioned releases
4. **Monitor Builds**: Check the ps-image-builder Actions page for build status
5. **Download Manifests**: Save the image manifest artifact for reference

## Troubleshooting

**Build not triggering?**
- Check that `IMAGE_BUILDER_TOKEN` has `repo` scope
- Verify the token hasn't expired
- Check the ps-image-builder Actions page for errors

**Can't find the image?**
- Wait for the build to complete (~10-15 minutes)
- Check GCP Console: Compute Engine > Images
- Filter by image family name

**Need to rebuild?**
- Trigger the workflow again
- Images in the same family will be versioned automatically

