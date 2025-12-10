#!/bin/bash
# setup-gcp-service-account.sh
# Creates a GCP service account for image building

set -e

echo "=== GCP Service Account Setup for Image Builder ==="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ ERROR: gcloud CLI is not installed"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get current project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)

if [ -z "$CURRENT_PROJECT" ]; then
    echo "No default project set. Please enter your GCP project ID:"
    read -p "Project ID: " PROJECT_ID
else
    echo "Current project: $CURRENT_PROJECT"
    read -p "Use this project? (y/n): " USE_CURRENT
    if [ "$USE_CURRENT" = "y" ] || [ "$USE_CURRENT" = "Y" ]; then
        PROJECT_ID=$CURRENT_PROJECT
    else
        read -p "Enter GCP project ID: " PROJECT_ID
    fi
fi

echo ""
echo "Using project: $PROJECT_ID"
echo ""

# Set the project
gcloud config set project $PROJECT_ID

# Service account details
SA_NAME="image-builder"
SA_DISPLAY_NAME="Image Builder Service Account"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="image-builder-key.json"

echo "Step 1: Creating service account..."
if gcloud iam service-accounts describe $SA_EMAIL &>/dev/null; then
    echo "✅ Service account already exists: $SA_EMAIL"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="$SA_DISPLAY_NAME" \
        --description="Service account for building GCP compute images"
    echo "✅ Service account created: $SA_EMAIL"
fi

echo ""
echo "Step 2: Granting required roles..."

# Grant roles
ROLES=(
    "roles/compute.instanceAdmin.v1"
    "roles/iam.serviceAccountUser"
    "roles/compute.imageUser"
)

for ROLE in "${ROLES[@]}"; do
    echo "  Granting $ROLE..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$ROLE" \
        --quiet > /dev/null
done

echo "✅ All roles granted"

echo ""
echo "Step 3: Creating service account key..."

if [ -f "$KEY_FILE" ]; then
    echo "⚠️  Key file already exists: $KEY_FILE"
    read -p "Overwrite? (y/n): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo "Skipping key creation"
        KEY_FILE=""
    else
        rm -f $KEY_FILE
    fi
fi

if [ -n "$KEY_FILE" ]; then
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SA_EMAIL
    echo "✅ Key created: $KEY_FILE"
fi

echo ""
echo "Step 4: Enabling required APIs..."

APIS=(
    "compute.googleapis.com"
    "iam.googleapis.com"
)

for API in "${APIS[@]}"; do
    echo "  Enabling $API..."
    gcloud services enable $API --quiet
done

echo "✅ APIs enabled"

echo ""
echo "==================================="
echo "✅ Setup Complete!"
echo "==================================="
echo ""
echo "Service Account: $SA_EMAIL"
if [ -n "$KEY_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo "Key File: $KEY_FILE"
    echo ""
    echo "⚠️  IMPORTANT: Keep this key file secure!"
    echo ""
    echo "Next steps:"
    echo "1. Copy the contents of $KEY_FILE"
    echo "2. Go to your GitHub repository: Settings > Secrets and variables > Actions"
    echo "3. Click 'New repository secret'"
    echo "4. Name: GCP_SA_KEY"
    echo "5. Value: Paste the entire contents of $KEY_FILE"
    echo "6. Click 'Add secret'"
    echo ""
    echo "To copy the key to clipboard (macOS):"
    echo "  cat $KEY_FILE | pbcopy"
    echo ""
    echo "To view the key:"
    echo "  cat $KEY_FILE"
fi
echo ""

