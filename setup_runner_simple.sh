#!/bin/bash

# Simplified GitHub Self-Hosted Runner Setup for SkyChart ARM64
set -e

echo "🚀 Setting up GitHub Self-Hosted Runner for SkyChart ARM64 builds"
echo "=================================================================="

# Get repository information
echo "Setting up runner for your fork: https://github.com/pubino/skychart"
github_owner="pubino"
github_repo="skychart"

# Create runner directory
runner_dir="$HOME/github-runner"
echo "📁 Creating runner directory: $runner_dir"

if [[ -d "$runner_dir" ]]; then
    echo "Runner directory exists. Removing old installation..."
    rm -rf "$runner_dir"
fi

mkdir -p "$runner_dir"
cd "$runner_dir"

# Download latest runner
echo "⬇️ Downloading GitHub Actions runner..."

# Get latest runner version
latest_version=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
runner_file="actions-runner-osx-arm64-${latest_version}.tar.gz"
runner_url="https://github.com/actions/runner/releases/download/v${latest_version}/${runner_file}"

echo "📦 Downloading runner version: $latest_version"
curl -L -o "$runner_file" "$runner_url"

# Extract runner
echo "📦 Extracting runner..."
tar xzf "$runner_file"
rm "$runner_file"

echo ""
echo "🔑 Runner Configuration"
echo "======================"
echo ""
echo "To complete the setup, you need to get a registration token:"
echo "1. Open: https://github.com/pubino/skychart/settings/actions/runners"
echo "2. Click 'New self-hosted runner'"
echo "3. Select 'macOS' and 'ARM64'"
echo "4. Copy the token from the configuration command"
echo ""
echo "Then run this command with your token:"
echo ""
echo "cd ~/github-runner && ./config.sh \\"
echo "  --url https://github.com/pubino/skychart \\"
echo "  --token YOUR_TOKEN_HERE \\"
echo "  --name \"$(hostname)-arm64\" \\"
echo "  --labels \"macos,ARM64,skychart\" \\"
echo "  --work \"_work\" \\"
echo "  --replace"
echo ""
echo "After configuration, start the runner with:"
echo "cd ~/github-runner && ./run.sh"
echo ""
echo "🎯 Setup completed! Ready for manual configuration."