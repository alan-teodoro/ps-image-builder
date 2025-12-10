# Quick Start Guide

Get your first GCP image built in 5 minutes!

## Step 1: Prepare Your Workshop Repository

Create a new repository with these two files:

### `docker-compose.yml`
```yaml
version: '3'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./index.html:/usr/share/nginx/html/index.html
```

### `start.sh`
```bash
#!/bin/bash
set -e

echo "Starting workshop..."
docker-compose up -d
echo "Workshop started!"
```

### `index.html` (optional)
```html
<!DOCTYPE html>
<html>
<head><title>My Workshop</title></head>
<body>
  <h1>Welcome to My Workshop!</h1>
</body>
</html>
```

## Step 2: Push to GitHub

```bash
git init
git add .
git commit -m "Initial workshop setup"
git remote add origin https://github.com/yourorg/my-workshop
git push -u origin main
```

## Step 3: Setup GCP Service Account

1. Go to [GCP Console](https://console.cloud.google.com)
2. Navigate to **IAM & Admin > Service Accounts**
3. Click **Create Service Account**
4. Name: `image-builder`
5. Grant roles:
   - Compute Instance Admin (v1)
   - Service Account User
   - Compute Image User
6. Click **Create Key** → JSON
7. Download the JSON key file

## Step 4: Add GitHub Secret

1. Go to your **ps-image-builder** repository on GitHub
2. Navigate to **Settings > Secrets and variables > Actions**
3. Click **New repository secret**
4. Name: `GCP_SA_KEY`
5. Value: Paste the entire contents of the JSON key file
6. Click **Add secret**

## Step 5: Build Your Image

1. Go to **Actions** tab in ps-image-builder repository
2. Click **Build GCP Image** workflow
3. Click **Run workflow**
4. Fill in:
   ```
   Source repo URL:    https://github.com/yourorg/my-workshop
   Branch:             main
   Image name:         my-workshop
   Image family:       my-workshop-v1
   GCP project ID:     your-gcp-project-id
   GCP region:         us-east1
   GCP zone:           us-east1-b
   Disk size:          100
   ```
5. Click **Run workflow**

## Step 6: Monitor the Build

1. Click on the running workflow
2. Watch the progress (takes ~10-15 minutes)
3. Check for any errors in the logs

## Step 7: Deploy Your Image

Once the build completes, deploy a VM:

```bash
gcloud compute instances create my-workshop-vm \
  --image-family=my-workshop-v1 \
  --project=your-gcp-project-id \
  --zone=us-east1-b \
  --machine-type=n1-standard-2 \
  --metadata=DOMAIN=nip.io,HOSTNAME=my-workshop \
  --tags=http-server
```

## Step 8: Access Your Workshop

1. Get the VM's external IP:
   ```bash
   gcloud compute instances describe my-workshop-vm \
     --zone=us-east1-b \
     --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
   ```

2. Open in browser:
   ```
   http://<EXTERNAL_IP>
   ```

## Troubleshooting

### Build fails with "Permission denied"
- Check that GCP service account has correct roles
- Verify `GCP_SA_KEY` secret is set correctly

### Can't access VM on port 80
- Add firewall rule:
  ```bash
  gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --target-tags http-server
  ```

### Services not starting
- SSH into VM:
  ```bash
  gcloud compute ssh my-workshop-vm --zone=us-east1-b
  ```
- Check logs:
  ```bash
  sudo journalctl -u ts-service -f
  sudo docker-compose -f /content/docker-compose.yml logs
  ```

## Next Steps

- Add more services to `docker-compose.yml`
- Customize `start.sh` with your logic
- Add `build.sh` for build-time setup
- See [Repository Structure Guide](REPOSITORY_STRUCTURE.md) for advanced features

## Example Repositories

Check out these examples:
- [Sample Workshop](../examples/sample-workshop) - Complete example with Redis, RedisInsight, and Node.js app
- [Technical Seminars Images](https://github.com/Redislabs-Solution-Architects/technical-seminars-images) - Production examples

## Common Patterns

### Pattern 1: Simple Static Site
```yaml
# docker-compose.yml
version: '3'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

### Pattern 2: App + Database
```yaml
# docker-compose.yml
version: '3'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
  app:
    image: node:18-alpine
    command: npm start
  redis:
    image: redis:alpine
```

### Pattern 3: Workshop with Jupyter
```yaml
# docker-compose.yml
version: '3'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
  jupyter:
    image: jupyter/datascience-notebook
    environment:
      - JUPYTER_ENABLE_LAB=yes
  redis:
    image: redis:alpine
```

Happy building! 🚀

