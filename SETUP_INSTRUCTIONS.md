# Setup Instructions

## ✅ Repositories Created

Both repositories have been successfully created and pushed to GitHub:

1. **ps-image-builder** (Image Builder)
   - URL: https://github.com/alan-teodoro/ps-image-builder
   - Type: Private
   - Purpose: Generic GCP image builder

2. **sample-workshop-demo** (Sample Workshop)
   - URL: https://github.com/alan-teodoro/sample-workshop-demo
   - Type: Private
   - Purpose: Demo workshop to test the image builder

## 🚀 Next Steps

### Step 1: Setup GCP Service Account

Run the automated setup script:

```bash
cd /Users/alan/workspaces/alan-teodoro/ps-image-builder
bash scripts/setup-gcp-service-account.sh
```

This script will:
- Create a service account named `image-builder`
- Grant required permissions (Compute Instance Admin, Service Account User, Compute Image User)
- Enable required APIs (Compute Engine, IAM)
- Generate a JSON key file: `image-builder-key.json`

**Important**: Keep the key file secure and never commit it to git!

### Step 2: Add GitHub Secret

1. Copy the service account key to clipboard:
   ```bash
   cat image-builder-key.json | pbcopy
   ```

2. Go to: https://github.com/alan-teodoro/ps-image-builder/settings/secrets/actions

3. Click **"New repository secret"**

4. Fill in:
   - **Name**: `GCP_SA_KEY`
   - **Value**: Paste the entire JSON content from clipboard

5. Click **"Add secret"**

### Step 3: Test the Image Builder

1. Go to: https://github.com/alan-teodoro/ps-image-builder/actions

2. Click on **"Build GCP Image"** workflow

3. Click **"Run workflow"** button

4. Fill in the parameters:
   ```
   Source repo URL:    https://github.com/alan-teodoro/sample-workshop-demo
   Branch/tag:         main
   Image name:         sample-workshop
   Image family:       sample-workshop-v1
   GCP project ID:     [YOUR_GCP_PROJECT_ID]
   GCP region:         us-east1
   GCP zone:           us-east1-b
   Disk size (GB):     100
   ```

5. Click **"Run workflow"**

6. Monitor the build progress (takes ~10-15 minutes)

### Step 4: Deploy the Image

Once the build completes successfully:

1. Create a firewall rule (if not exists):
   ```bash
   gcloud compute firewall-rules create allow-http \
     --allow tcp:80 \
     --target-tags http-server \
     --project [YOUR_GCP_PROJECT_ID]
   ```

2. Deploy a VM from the image:
   ```bash
   gcloud compute instances create sample-workshop-vm \
     --image-family=sample-workshop-v1 \
     --project=[YOUR_GCP_PROJECT_ID] \
     --zone=us-east1-b \
     --machine-type=n1-standard-2 \
     --metadata=DOMAIN=nip.io,HOSTNAME=sample-workshop \
     --tags=http-server
   ```

3. Get the external IP:
   ```bash
   gcloud compute instances describe sample-workshop-vm \
     --zone=us-east1-b \
     --project=[YOUR_GCP_PROJECT_ID] \
     --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
   ```

4. Wait ~30 seconds for services to start, then access:
   ```
   http://[EXTERNAL_IP]
   ```

### Step 5: Verify Services

You should see:
- **Landing Page**: http://[EXTERNAL_IP]
- **RedisInsight**: http://[EXTERNAL_IP]/redisinsight
- **Application**: http://[EXTERNAL_IP]/app

## 📋 Quick Reference

### Repository URLs
- **Image Builder**: https://github.com/alan-teodoro/ps-image-builder
- **Sample Workshop**: https://github.com/alan-teodoro/sample-workshop-demo

### Key Files
- **Service Account Key**: `image-builder-key.json` (keep secure!)
- **Setup Script**: `scripts/setup-gcp-service-account.sh`
- **Validation Script**: `scripts/validate-repo.sh`

### Important Commands

**Setup GCP Service Account**:
```bash
bash scripts/setup-gcp-service-account.sh
```

**Copy Key to Clipboard**:
```bash
cat image-builder-key.json | pbcopy
```

**Validate Workshop Repository**:
```bash
bash scripts/validate-repo.sh /path/to/workshop
```

**List GCP Images**:
```bash
gcloud compute images list --project=[YOUR_GCP_PROJECT_ID] --filter="family:sample-workshop-v1"
```

**Delete Test VM**:
```bash
gcloud compute instances delete sample-workshop-vm --zone=us-east1-b --project=[YOUR_GCP_PROJECT_ID]
```

## 🔒 Security Notes

1. **Never commit** `image-builder-key.json` to git (already in .gitignore)
2. **Keep GitHub secret** `GCP_SA_KEY` secure
3. **Rotate keys** periodically for security
4. **Delete old images** to reduce costs

## 📚 Documentation

- **Main README**: [README.md](README.md)
- **Quick Start**: [docs/QUICK_START.md](docs/QUICK_START.md)
- **Repository Structure**: [docs/REPOSITORY_STRUCTURE.md](docs/REPOSITORY_STRUCTURE.md)
- **Architecture**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Setup Checklist**: [docs/SETUP_CHECKLIST.md](docs/SETUP_CHECKLIST.md)

## 🎯 What's Next?

After successful testing:
1. Create your own workshop repositories
2. Build images for different workshops
3. Deploy to production
4. Consider implementing Phase 2 (webhooks) for automated builds

## ❓ Troubleshooting

If you encounter issues, check:
- [docs/SETUP_CHECKLIST.md](docs/SETUP_CHECKLIST.md) - Complete checklist
- GitHub Actions logs for build errors
- GCP Console for service account permissions
- [docs/QUICK_START.md](docs/QUICK_START.md) - Troubleshooting section

Good luck! 🚀

