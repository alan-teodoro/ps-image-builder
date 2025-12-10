#!/bin/bash
# install-dependencies.sh
# Installs all required dependencies for the generic image builder
# Based on the technical-seminars-images packer.json provisioning steps

set -e

echo "=== Installing Base Dependencies ==="

# Remove lock files that might interfere
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock
sudo rm -f /var/cache/apt/archives/lock

# Update package lists
echo "Updating package lists..."
sudo apt-get clean
sudo apt-get update -y

# Install prerequisites for Docker
echo "Installing Docker prerequisites..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Add Docker GPG key and repository
echo "Adding Docker repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package lists again
sudo apt-get update -y

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="1.29.2"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify Docker Compose installation
docker-compose --version

# Install Python pip
echo "Installing Python pip..."
curl https://bootstrap.pypa.io/pip/3.8/get-pip.py -o /tmp/get-pip.py
sudo python3 /tmp/get-pip.py
rm /tmp/get-pip.py

# Install additional utilities
echo "Installing additional utilities..."
sudo apt-get install -y \
    zip \
    unzip \
    jq \
    git \
    wget

# Start Docker service
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Configure Docker to start on boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Configure gcloud docker authentication (if gcloud is available)
if command -v gcloud &> /dev/null; then
    echo "Configuring gcloud Docker authentication..."
    gcloud auth configure-docker --quiet || true
fi

echo "=== Dependencies installation complete ==="
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker-compose --version)"
echo "Python version: $(python3 --version)"
echo "Pip version: $(pip3 --version)"

