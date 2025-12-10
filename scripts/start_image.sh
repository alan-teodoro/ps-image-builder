#!/bin/bash
# start_image.sh
# This script is executed by the systemd service on VM boot
# It fetches GCP metadata and runs the workshop-specific start.sh

set -e

echo "=== Starting Technical Seminars Image ==="
echo "Timestamp: $(date)"

# Fetch all metadata from GCP and export as environment variables
echo "Fetching GCP metadata..."
for i in $(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/" -H "Metadata-Flavor: Google" | grep -v -e "-")
do
    export $i="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/$i -H Metadata-Flavor:Google)"
    echo "Exported: $i"
done

# Change to content directory
cd /content

# Check if start.sh exists
if [ ! -f "./start.sh" ]; then
    echo "ERROR: start.sh not found in /content"
    echo "Please ensure your repository includes a start.sh file"
    exit 1
fi

# Make start.sh executable
chmod +x ./start.sh

# Run the workshop-specific start script
echo "=== Running start.sh ==="
./start.sh > start.log 2>&1 &

echo "=== Image startup complete ==="
echo "Logs available at /content/start.log"

