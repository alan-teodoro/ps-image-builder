#!/bin/bash
# Sample Workshop Build Script
# This runs during image creation (build time)

set -e

echo "=== Running build-time setup ==="

# Install additional system packages if needed
echo "Installing additional packages..."
apt-get update
apt-get install -y \
    gettext-base \
    curl \
    jq

# Pre-create directories
echo "Creating directories..."
mkdir -p /content/logs
mkdir -p /content/data

# Any other build-time setup
echo "Build setup complete!"

