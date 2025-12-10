# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-10

### Added
- Initial release of ps-image-builder
- Reusable workflow for building GCP Compute Engine images
- Support for `workflow_call` (reusable workflows)
- Support for `workflow_dispatch` (manual triggers)
- Image outputs: `image_id`, `image_name`, `image_self_link`
- Image manifest artifact with complete build metadata
- Packer HCL template for generic image building
- Automated dependency installation (Docker, Docker Compose)
- Pre-caching of Docker images for fast VM startup
- Systemd service for automatic startup
- Comprehensive documentation
- Sample workshop example
- GCP service account setup automation script
- Repository structure validation

### Features
- Build images from any Git repository
- Standard repository structure (docker-compose.yml + start.sh)
- Configurable GCP project, region, zone, disk size
- Image family support for versioning
- Metadata-driven configuration via GCP metadata service
- Fast VM provisioning (~30 seconds vs 10-15 minutes)

### Documentation
- README.md - Main documentation
- docs/QUICK_START.md - Quick start guide
- docs/REPOSITORY_STRUCTURE.md - Repository structure guide
- docs/ARCHITECTURE.md - Architecture overview
- docs/SETUP_CHECKLIST.md - Setup checklist
- docs/TRIGGER_FROM_REPO.md - How to trigger from other repos
- SETUP_INSTRUCTIONS.md - Complete setup instructions
- examples/trigger-workflow-example.yml - Example workflow

## [Unreleased]

### Planned
- Webhook support for automatic builds
- Semantic versioning based on git tags
- Multi-region image replication
- Automated testing of built images
- Cost optimization (cleanup old images)
- Multi-cloud support (AWS, Azure)

