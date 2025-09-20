#!/bin/bash

# GitHub Actions Network Diagnostics for Self-Hosted Runners
# Tests connectivity to required GitHub endpoints

set -e

echo "🔍 GitHub Actions Network Diagnostics"
echo "======================================"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Test basic connectivity
test_connectivity() {
    local endpoint="$1"
    local description="$2"

    log_info "Testing $description: $endpoint"

    if curl -I --connect-timeout 10 --max-time 30 "$endpoint" &>/dev/null; then
        log_success "✓ $description accessible"
        return 0
    else
        log_error "✗ $description blocked: $endpoint"
        return 1
    fi
}

# Test GitHub endpoints
log_info "Testing GitHub API endpoints..."
test_connectivity "https://api.github.com" "GitHub API"
test_connectivity "https://github.com" "GitHub Web"
test_connectivity "https://codeload.github.com" "GitHub Code Load"

echo ""
log_info "Testing GitHub Actions endpoints..."
test_connectivity "https://github.com/actions/runner/releases/latest" "Actions Runner"
test_connectivity "https://pipelines.actions.githubusercontent.com" "Actions Pipelines"

echo ""
log_info "Testing artifact storage endpoints..."

# Azure Blob Storage endpoints (used by upload-artifact)
BLOB_ENDPOINTS=(
    "https://productionresultssa0.blob.core.windows.net/"
    "https://productionresultssa1.blob.core.windows.net/"
    "https://productionresultssa2.blob.core.windows.net/"
    "https://productionresultssa3.blob.core.windows.net/"
    "https://productionresultssa4.blob.core.windows.net/"
    "https://productionresultssa5.blob.core.windows.net/"
)

BLOB_ACCESSIBLE=0
for endpoint in "${BLOB_ENDPOINTS[@]}"; do
    if test_connectivity "$endpoint" "Blob Storage"; then
        ((BLOB_ACCESSIBLE++))
    fi
done

echo ""
log_info "Testing AWS S3 endpoints (alternative storage)..."
test_connectivity "https://github-production-user-asset-6210df.s3.amazonaws.com/" "GitHub S3 Assets"

echo ""
echo "📊 Diagnostics Summary:"
echo "======================"

if [ $BLOB_ACCESSIBLE -gt 0 ]; then
    log_success "✓ $BLOB_ACCESSIBLE blob storage endpoints accessible"
else
    log_error "✗ All blob storage endpoints blocked"
    echo ""
    log_warning "This will cause artifact upload failures in GitHub Actions"
    echo ""
    echo "🔧 Solutions:"
    echo "1. Configure firewall/proxy to allow access to:"
    echo "   *.blob.core.windows.net"
    echo "   github-production-user-asset-*.s3.amazonaws.com"
    echo ""
    echo "2. Use VPN/proxy that allows these endpoints"
    echo ""
    echo "3. Use the local artifact storage fallback in the workflow"
    echo ""
    echo "4. Configure system proxy:"
    echo "   export http_proxy=http://proxy.company.com:8080"
    echo "   export https_proxy=http://proxy.company.com:8080"
fi

# Check current proxy settings
echo ""
log_info "Current proxy configuration:"
echo "HTTP_PROXY: ${HTTP_PROXY:-Not set}"
echo "HTTPS_PROXY: ${HTTPS_PROXY:-Not set}"
echo "http_proxy: ${http_proxy:-Not set}"
echo "https_proxy: ${https_proxy:-Not set}"

# Test DNS resolution
echo ""
log_info "Testing DNS resolution..."
if nslookup productionresultssa0.blob.core.windows.net &>/dev/null; then
    log_success "✓ DNS resolution working"
else
    log_error "✗ DNS resolution failed"
fi

echo ""
log_info "Network diagnostics complete."