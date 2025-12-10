# Sample Workshop

This is a sample workshop repository that demonstrates the standard structure for use with **ps-image-builder**.

## Structure

```
sample-workshop/
├── docker-compose.yml          # Service definitions
├── start.sh                    # Startup script
├── build.sh                    # Build-time setup
├── nginx.conf.template         # Nginx configuration template
├── html/                       # Static HTML files
│   └── index.html
├── app/                        # Node.js application
│   ├── package.json
│   └── server.js
└── README.md
```

## Services

- **Nginx** (port 80): Reverse proxy and landing page
- **Redis** (port 6379): Redis database
- **RedisInsight** (port 5540): Redis GUI
- **App** (port 3000): Sample Node.js application

## Testing Locally

```bash
# Set environment variables
export DOMAIN="nip.io"
export HOSTNAME="127.0.0.1"
export HOST_IP="127.0.0.1"

# Run build script
bash build.sh

# Start services
bash start.sh

# Access the workshop
open http://localhost
```

## Building a GCP Image

Use the ps-image-builder workflow:

1. Push this repository to GitHub
2. Go to ps-image-builder repository
3. Run the "Build GCP Image" workflow
4. Enter:
   - Source repo URL: `https://github.com/yourorg/sample-workshop`
   - Branch: `main`
   - Image name: `sample-workshop`
   - Image family: `sample-workshop-v1`
   - GCP project ID: `your-project-id`

## Accessing the Workshop

After deploying the image:

- **Main Page**: `http://<vm-ip>`
- **RedisInsight**: `http://<vm-ip>/redisinsight`
- **Application**: `http://<vm-ip>/app`

## Customization

Modify this template for your own workshop:

1. Update `docker-compose.yml` with your services
2. Customize `start.sh` for your startup logic
3. Add your content to `html/` or create your own app
4. Update `nginx.conf.template` for routing

