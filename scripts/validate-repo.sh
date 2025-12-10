#!/bin/bash
# validate-repo.sh
# Validates that a repository follows the required structure

set -e

REPO_PATH=${1:-.}

echo "=== Validating Repository Structure ==="
echo "Repository path: $REPO_PATH"
echo ""

# Check if directory exists
if [ ! -d "$REPO_PATH" ]; then
    echo "❌ ERROR: Directory does not exist: $REPO_PATH"
    exit 1
fi

# Track validation status
VALID=true

# Check for required files
echo "Checking required files..."

if [ ! -f "$REPO_PATH/docker-compose.yml" ]; then
    echo "❌ MISSING: docker-compose.yml"
    VALID=false
else
    echo "✅ Found: docker-compose.yml"
    
    # Validate docker-compose.yml syntax
    if command -v docker-compose &> /dev/null; then
        if docker-compose -f "$REPO_PATH/docker-compose.yml" config > /dev/null 2>&1; then
            echo "   ✅ Valid YAML syntax"
        else
            echo "   ⚠️  WARNING: docker-compose.yml has syntax errors"
            VALID=false
        fi
    fi
fi

if [ ! -f "$REPO_PATH/start.sh" ]; then
    echo "❌ MISSING: start.sh"
    VALID=false
else
    echo "✅ Found: start.sh"
    
    # Check if start.sh is executable
    if [ -x "$REPO_PATH/start.sh" ]; then
        echo "   ✅ Executable"
    else
        echo "   ⚠️  WARNING: start.sh is not executable (will be fixed during build)"
    fi
fi

# Check for optional files
echo ""
echo "Checking optional files..."

if [ -f "$REPO_PATH/build.sh" ]; then
    echo "✅ Found: build.sh (optional)"
else
    echo "ℹ️  Not found: build.sh (optional - skipping)"
fi

if [ -f "$REPO_PATH/.image-builder.yml" ]; then
    echo "✅ Found: .image-builder.yml (optional)"
else
    echo "ℹ️  Not found: .image-builder.yml (optional - using defaults)"
fi

# Check for port 80 listener in docker-compose.yml
echo ""
echo "Checking for port 80 listener..."

if [ -f "$REPO_PATH/docker-compose.yml" ]; then
    if grep -q "80:80" "$REPO_PATH/docker-compose.yml" || grep -q '"80:80"' "$REPO_PATH/docker-compose.yml"; then
        echo "✅ Found service listening on port 80"
    else
        echo "⚠️  WARNING: No service appears to be listening on port 80"
        echo "   The platform requires a service on port 80 for HTTP access"
        VALID=false
    fi
fi

# Summary
echo ""
echo "==================================="
if [ "$VALID" = true ]; then
    echo "✅ Repository structure is VALID"
    echo "==================================="
    exit 0
else
    echo "❌ Repository structure is INVALID"
    echo "==================================="
    echo ""
    echo "Please fix the issues above and try again."
    echo "See docs/REPOSITORY_STRUCTURE.md for more information."
    exit 1
fi

