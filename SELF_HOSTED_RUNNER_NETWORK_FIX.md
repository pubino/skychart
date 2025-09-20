# GitHub Actions Self-Hosted Runner Network Issues

## Problem
Self-hosted runners failing to upload artifacts with `ECONNREFUSED` errors when connecting to GitHub's blob storage endpoints.

## Root Cause
The runner is behind a firewall, VPN, or corporate network that blocks access to:
- Azure Blob Storage: `*.blob.core.windows.net`
- AWS S3: `github-production-user-asset-*.s3.amazonaws.com`

## Solutions

### Solution 1: Network Configuration (Recommended)
Configure your firewall/proxy to allow access to GitHub's artifact storage endpoints:

#### Firewall Rules
```bash
# Allow Azure Blob Storage (GitHub Actions artifacts)
*.blob.core.windows.net:443

# Allow GitHub S3 assets
github-production-user-asset-*.s3.amazonaws.com:443
```

#### Proxy Configuration
If using a corporate proxy, configure the runner:

```bash
# System-wide proxy (add to ~/.bashrc or ~/.zshrc)
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1,.local

# Or configure just for the runner service
sudo launchctl setenv HTTP_PROXY http://proxy.company.com:8080
sudo launchctl setenv HTTPS_PROXY http://proxy.company.com:8080
```

### Solution 2: VPN Configuration
If using a VPN, ensure it allows access to the required endpoints, or:

1. **Split Tunneling**: Configure VPN to not route GitHub traffic
2. **VPN Bypass**: Add exceptions for GitHub domains
3. **Alternative VPN**: Use a VPN that doesn't block these endpoints

### Solution 3: Local Artifact Storage (Fallback)
The workflow now includes automatic fallback storage:

```bash
# Artifacts stored locally on runner machine
/tmp/skychart-artifacts-{run_number}/
~/Desktop/skychart-builds/

# Download via SCP
scp user@runner-host:~/Desktop/skychart-builds/skychart-macos-arm64-{run_number}.tar.gz .
```

### Solution 4: Alternative Artifact Storage
Consider using external storage services:

#### Option A: AWS S3 Bucket
```yaml
- name: Upload to S3
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1

- name: Upload artifacts to S3
  run: |
    aws s3 cp *.dmg s3://your-bucket/skychart-builds/
```

#### Option B: Azure Storage
```yaml
- name: Upload to Azure
  uses: azure/CLI@v1
  with:
    inlineScript: |
      az storage blob upload-batch \
        --account-name ${{ secrets.AZURE_STORAGE_ACCOUNT }} \
        --account-key ${{ secrets.AZURE_STORAGE_KEY }} \
        --destination artifacts \
        --source .
```

## Diagnostics

Run the included diagnostic script:
```bash
./network_diagnostics.sh
```

This will test connectivity to all required endpoints and provide specific recommendations.

## Testing

After implementing any solution:

1. **Test Network**: Run `./network_diagnostics.sh`
2. **Test Workflow**: Trigger a build and check artifact upload
3. **Verify Access**: Confirm artifacts are accessible

## Prevention

For future-proofing:

1. **Monitor Network**: Regularly test endpoint accessibility
2. **Document Configuration**: Keep network settings documented
3. **Alternative Plans**: Always have fallback storage options
4. **Update Rules**: Keep firewall rules current with GitHub's endpoints

## Quick Fix

If you need artifacts immediately, the workflow now creates local archives:
- Location: `~/Desktop/skychart-builds/`
- Format: `skychart-macos-arm64-{run_number}.tar.gz`
- Access: Via SCP or direct file access on the runner machine