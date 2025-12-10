# Generic Image Builder Template
# This template builds GCP Compute Engine images from any repository
# following the standard structure (docker-compose.yml + start.sh)

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

# Variables
variable "project_id" {
  type        = string
  description = "GCP project ID where the image will be created"
}

variable "image_name" {
  type        = string
  description = "Name for the GCP image (will be appended with timestamp)"
}

variable "image_family" {
  type        = string
  description = "Image family for versioning and grouping"
  default     = "generic-workshop"
}

variable "zone" {
  type        = string
  description = "GCP zone for the build instance"
  default     = "us-east1-b"
}

variable "region" {
  type        = string
  description = "GCP region for the image"
  default     = "us-east1"
}

variable "source_image_family" {
  type        = string
  description = "Base image family to use"
  default     = "ubuntu-2204-lts"
}

variable "source_image_project" {
  type        = string
  description = "Project containing the source image"
  default     = "ubuntu-os-cloud"
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB"
  default     = 100
}

variable "machine_type" {
  type        = string
  description = "Machine type for the build instance"
  default     = "n1-standard-2"
}

variable "source_content_path" {
  type        = string
  description = "Local path to the source content directory (cloned repo)"
  default     = "./source"
}

# Locals
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  image_name = "${var.image_name}-${local.timestamp}"
}

# Source configuration
source "googlecompute" "generic_image" {
  project_id              = var.project_id
  source_image_family     = var.source_image_family
  source_image_project_id = [var.source_image_project]
  zone                    = var.zone
  region                  = var.region
  machine_type            = var.machine_type
  disk_size               = var.disk_size
  
  image_name              = local.image_name
  image_family            = var.image_family
  image_description       = "Generic workshop/demo image built from external repository"
  
  ssh_username            = "packer"
  
  # Image labels for tracking
  image_labels = {
    builder     = "packer"
    environment = "workshop"
    managed_by  = "ps-image-builder"
  }
}

# Build configuration
build {
  name    = "generic-image-build"
  sources = ["source.googlecompute.generic_image"]

  # Copy source content to /content
  provisioner "file" {
    source      = var.source_content_path
    destination = "/tmp/content"
  }

  # Copy shared scripts
  provisioner "file" {
    source      = "${path.root}/../scripts/start_image.sh"
    destination = "/tmp/start_image.sh"
  }

  # Copy systemd service file
  provisioner "file" {
    source      = "${path.root}/../config/ts-service.service"
    destination = "/tmp/ts-service.service"
  }

  # Install base dependencies
  provisioner "shell" {
    script = "${path.root}/../scripts/install-dependencies.sh"
  }

  # Setup content directory and systemd service
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/content /content",
      "sudo mv /tmp/start_image.sh /content/start_image.sh",
      "sudo mv /tmp/ts-service.service /etc/systemd/system/ts-service.service",
      "sudo chmod +x /content/start_image.sh",
      "sudo chmod -R ugo+rw /content"
    ]
  }

  # Run build.sh if it exists
  provisioner "shell" {
    inline = [
      "if [ -f /content/build.sh ]; then",
      "  echo 'Running build.sh...'",
      "  cd /content && sudo bash build.sh",
      "else",
      "  echo 'No build.sh found, skipping...'",
      "fi"
    ]
  }

  # Pre-cache Docker images from docker-compose.yml
  provisioner "shell" {
    inline = [
      "if [ -f /content/docker-compose.yml ]; then",
      "  echo 'Pre-caching Docker images...'",
      "  cd /content && sudo docker-compose pull || true",
      "  cd /content && sudo docker-compose build || true",
      "else",
      "  echo 'No docker-compose.yml found, skipping image cache...'",
      "fi"
    ]
  }

  # Enable systemd service
  provisioner "shell" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable ts-service"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}

