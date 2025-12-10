# Setup Checklist

Use this checklist to ensure everything is configured correctly before building your first image.

## Prerequisites Checklist

### GCP Setup
- [ ] GCP account created
- [ ] GCP project created
- [ ] Billing enabled on project
- [ ] Compute Engine API enabled
- [ ] Service account created with name `image-builder` (or similar)
- [ ] Service account has required roles:
  - [ ] `roles/compute.instanceAdmin.v1`
  - [ ] `roles/iam.serviceAccountUser`
  - [ ] `roles/compute.imageUser`
- [ ] Service account JSON key downloaded

### GitHub Setup (ps-image-builder repository)
- [ ] Repository forked or cloned
- [ ] `GCP_SA_KEY` secret added to repository
  - Go to Settings > Secrets and variables > Actions
  - Click "New repository secret"
  - Name: `GCP_SA_KEY`
  - Value: Paste entire JSON key content
- [ ] Actions enabled on repository

### Workshop Repository Setup
- [ ] Repository created (can be private or public)
- [ ] `docker-compose.yml` file created
- [ ] `start.sh` file created
- [ ] `start.sh` is executable (`chmod +x start.sh`)
- [ ] At least one service listens on port 80
- [ ] Repository pushed to GitHub/GitLab

## Pre-Build Validation

### Validate Workshop Repository Locally
```bash
# Clone your workshop repository
git clone https://github.com/yourorg/your-workshop
cd your-workshop

# Run validation script
bash /path/to/ps-image-builder/scripts/validate-repo.sh .

# Test docker-compose syntax
docker-compose config

# Test locally
export DOMAIN="nip.io"
export HOSTNAME="127.0.0.1"
export HOST_IP="127.0.0.1"
bash start.sh

# Verify services are running
docker-compose ps
curl http://localhost
```

### Checklist for Workshop Repository
- [ ] `docker-compose.yml` is valid YAML
- [ ] `docker-compose.yml` has at least one service on port 80
- [ ] `start.sh` exists and is executable
- [ ] `start.sh` runs without errors locally
- [ ] All Docker images in docker-compose.yml are accessible
- [ ] Services start successfully with `docker-compose up`
- [ ] Port 80 is accessible (test with curl)

## Build Process Checklist

### Before Triggering Build
- [ ] Workshop repository is pushed to GitHub
- [ ] All changes are committed
- [ ] Branch/tag to build from is specified (e.g., `main`)
- [ ] GCP project ID is ready
- [ ] Image name decided (lowercase, no spaces)
- [ ] Image family decided (for versioning)

### Trigger Build
- [ ] Go to ps-image-builder repository on GitHub
- [ ] Click "Actions" tab
- [ ] Select "Build GCP Image" workflow
- [ ] Click "Run workflow"
- [ ] Fill in all required parameters:
  - [ ] Source repo URL
  - [ ] Source repo ref (branch/tag)
  - [ ] Image name
  - [ ] Image family
  - [ ] GCP project ID
  - [ ] GCP region (default: us-east1)
  - [ ] GCP zone (default: us-east1-b)
  - [ ] Disk size (default: 100)
- [ ] Click "Run workflow"

### Monitor Build
- [ ] Click on running workflow
- [ ] Monitor progress through steps
- [ ] Check for errors in logs
- [ ] Wait for completion (~10-15 minutes)
- [ ] Verify success message

## Post-Build Checklist

### Verify Image in GCP
- [ ] Go to GCP Console
- [ ] Navigate to Compute Engine > Images
- [ ] Filter by image family
- [ ] Verify image exists
- [ ] Check image size and creation date
- [ ] Review image labels

### Deploy Test VM
```bash
# Create firewall rule (if not exists)
gcloud compute firewall-rules create allow-http \
  --allow tcp:80 \
  --target-tags http-server \
  --project your-gcp-project

# Create VM instance
gcloud compute instances create test-workshop-vm \
  --image-family=your-image-family \
  --project=your-gcp-project \
  --zone=us-east1-b \
  --machine-type=n1-standard-2 \
  --metadata=DOMAIN=nip.io,HOSTNAME=test-workshop \
  --tags=http-server
```

### Test Deployment
- [ ] VM created successfully
- [ ] VM is running
- [ ] Get external IP address
- [ ] Wait 1-2 minutes for services to start
- [ ] Access via browser: `http://<EXTERNAL_IP>`
- [ ] Verify landing page loads
- [ ] Test all service endpoints
- [ ] Check service functionality

### Verify Services
```bash
# SSH into VM
gcloud compute ssh test-workshop-vm --zone=us-east1-b

# Check systemd service status
sudo systemctl status ts-service

# Check service logs
sudo journalctl -u ts-service -f

# Check Docker containers
sudo docker-compose -f /content/docker-compose.yml ps

# Check Docker logs
sudo docker-compose -f /content/docker-compose.yml logs

# Verify port 80
curl http://localhost
```

## Troubleshooting Checklist

### Build Fails
- [ ] Check GitHub Actions logs for errors
- [ ] Verify GCP service account permissions
- [ ] Verify `GCP_SA_KEY` secret is correct
- [ ] Check workshop repository structure
- [ ] Validate docker-compose.yml syntax
- [ ] Check Packer logs in workflow output

### Services Don't Start
- [ ] SSH into VM
- [ ] Check systemd service: `sudo systemctl status ts-service`
- [ ] Check service logs: `sudo journalctl -u ts-service -f`
- [ ] Check Docker: `sudo docker ps`
- [ ] Check Docker Compose: `sudo docker-compose -f /content/docker-compose.yml ps`
- [ ] Check start.sh logs: `cat /content/start.log`
- [ ] Verify environment variables are set

### Can't Access Port 80
- [ ] Check firewall rules in GCP
- [ ] Verify VM has `http-server` tag
- [ ] Check if service is listening: `sudo netstat -tlnp | grep :80`
- [ ] Check nginx/proxy configuration
- [ ] Verify external IP is correct

### Docker Images Not Cached
- [ ] Check if docker-compose pull ran during build
- [ ] Verify Docker images are accessible
- [ ] Check for authentication issues with private registries
- [ ] Review Packer build logs

## Cleanup Checklist

### After Testing
- [ ] Delete test VM:
  ```bash
  gcloud compute instances delete test-workshop-vm --zone=us-east1-b
  ```
- [ ] Keep or delete test image based on needs
- [ ] Document any issues found
- [ ] Update workshop repository if needed

### Regular Maintenance
- [ ] Delete old/unused images to save costs
- [ ] Update base image periodically
- [ ] Review and update dependencies
- [ ] Test with latest Packer version

## Success Criteria

Your setup is complete when:
- [x] GCP service account configured with correct permissions
- [x] GitHub secret `GCP_SA_KEY` is set
- [x] Workshop repository has valid structure
- [x] Image builds successfully via GitHub Actions
- [x] Image appears in GCP Console
- [x] VM deploys from image successfully
- [x] Services start automatically on VM boot
- [x] Port 80 is accessible from browser
- [x] All workshop functionality works as expected

## Next Steps

Once everything is working:
1. Document your workshop setup
2. Create additional workshop repositories
3. Build images for different versions
4. Set up automated builds (Phase 2)
5. Implement versioning strategy (Phase 3)

## Support

If you encounter issues:
1. Check this checklist again
2. Review documentation in `docs/`
3. Check example in `examples/sample-workshop/`
4. Review GitHub Actions logs
5. Check GCP Console for errors
6. Open an issue in ps-image-builder repository

