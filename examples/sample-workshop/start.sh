#!/bin/bash
# Sample Workshop Startup Script

set -e

echo "=== Starting Sample Workshop ==="
echo "Timestamp: $(date)"

# Environment variables from GCP metadata are already exported
# Common variables: DOMAIN, HOSTNAME, HOST_IP

# Set defaults if not provided
export DOMAIN=${DOMAIN:-"nip.io"}
export HOSTNAME=${HOSTNAME:-"localhost"}
export HOST_IP=${HOST_IP:-"127.0.0.1"}

echo "Configuration:"
echo "  DOMAIN: $DOMAIN"
echo "  HOSTNAME: $HOSTNAME"
echo "  HOST_IP: $HOST_IP"

# Generate nginx configuration with environment variables
echo "Generating nginx configuration..."
envsubst '${HOSTNAME} ${DOMAIN}' < nginx.conf.template > nginx.conf

# Start all services
echo "Starting Docker services..."
docker-compose up -d

# Wait for services to be healthy
echo "Waiting for services to start..."
sleep 10

# Check if services are running
echo "Checking service health..."
docker-compose ps

# Display access information
echo ""
echo "=== Workshop Started Successfully ==="
echo ""
echo "Access your workshop at:"
echo "  Main Page:      http://${HOSTNAME}.${DOMAIN}"
echo "  RedisInsight:   http://${HOSTNAME}.${DOMAIN}/redisinsight"
echo "  Application:    http://${HOSTNAME}.${DOMAIN}/app"
echo ""
echo "Logs available at: /content/start.log"
echo "==================================="

