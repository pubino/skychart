#!/bin/bash

# GitHub Self-Hosted Runner Setup for SkyChart ARM64 Builds
# This script sets up your Mac as a GitHub Actions self-hosted runner

set -e

echo "🚀 Setting up GitHub Self-Hosted Runner for SkyChart ARM64 builds"
echo "=================================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get user confirmation
confirm() {
    read -p "$1 (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check system requirements
echo "📋 Checking system requirements..."

# Verify ARM64 architecture
if [[ $(uname -m) != "arm64" ]]; then
    echo "❌ Error: This setup is designed for ARM64 (Apple Silicon) Macs"
    echo "   Current architecture: $(uname -m)"
    exit 1
fi

echo "✅ ARM64 (Apple Silicon) architecture confirmed"

# Verify macOS version
macos_version=$(sw_vers -productVersion)
echo "✅ macOS version: $macos_version"

# Check available disk space
available_space=$(df -h / | tail -1 | awk '{print $4}')
echo "✅ Available disk space: $available_space"

echo ""
echo "📦 Checking required dependencies..."

# Check Homebrew
if ! command_exists brew; then
    echo "❌ Homebrew not found"
    if confirm "Install Homebrew now?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew is required. Please install it first."
        exit 1
    fi
fi
echo "✅ Homebrew available"

# Check Free Pascal Compiler
if ! command_exists fpc; then
    echo "⚠️ Free Pascal Compiler not found"
    if confirm "Install FPC via Homebrew?"; then
        brew install fpc
    fi
fi

if command_exists fpc; then
    fpc_version=$(fpc -iV)
    echo "✅ Free Pascal Compiler: $fpc_version"
else
    echo "❌ FPC installation failed or not available"
    exit 1
fi

# Check Qt5
qt5_version=$(brew list --versions qt@5 2>/dev/null || echo "not installed")
if [[ $qt5_version == "not installed" ]]; then
    echo "⚠️ Qt5 not found"
    if confirm "Install Qt5 via Homebrew?"; then
        brew install qt@5
    fi
fi

if brew list qt@5 >/dev/null 2>&1; then
    qt5_version=$(brew list --versions qt@5)
    echo "✅ Qt5: $qt5_version"
else
    echo "❌ Qt5 installation failed"
    exit 1
fi

# Check Lazarus
if ! command_exists lazbuild; then
    echo "⚠️ Lazarus not found"
    if confirm "Install Lazarus IDE via Homebrew?"; then
        brew install lazarus-ide
    fi
fi

if command_exists lazbuild; then
    echo "✅ Lazarus IDE available"
else
    echo "❌ Lazarus installation failed"
fi

echo ""
echo "🔧 GitHub Runner Setup"
echo "======================"

# Get repository information
echo "Please provide your GitHub repository information:"
read -p "GitHub username/organization: " github_owner
read -p "Repository name: " github_repo

if [[ -z "$github_owner" || -z "$github_repo" ]]; then
    echo "❌ GitHub repository information is required"
    exit 1
fi

# Create runner directory
runner_dir="$HOME/github-runner"
echo "📁 Creating runner directory: $runner_dir"

if [[ -d "$runner_dir" ]]; then
    if confirm "Runner directory exists. Remove and recreate?"; then
        rm -rf "$runner_dir"
    else
        echo "Please remove existing runner directory or choose a different location"
        exit 1
    fi
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

# Configure runner
echo ""
echo "🔑 Runner Configuration"
echo "======================"
echo ""
echo "You'll need to configure the runner with a registration token."
echo "To get the token:"
echo "1. Go to: https://github.com/${github_owner}/${github_repo}/settings/actions/runners"
echo "2. Click 'New self-hosted runner'"
echo "3. Select 'macOS' and 'ARM64'"
echo "4. Copy the token from the configuration command"
echo ""
read -p "Enter your registration token: " registration_token

if [[ -z "$registration_token" ]]; then
    echo "❌ Registration token is required"
    exit 1
fi

# Configure the runner
echo "⚙️ Configuring runner..."
./config.sh \
    --url "https://github.com/${github_owner}/${github_repo}" \
    --token "$registration_token" \
    --name "$(hostname)-arm64" \
    --labels "macos,ARM64,skychart" \
    --work "_work" \
    --replace

echo ""
echo "🎯 Testing Runner Setup"
echo "======================="

# Test the runner
if confirm "Test the runner configuration?"; then
    echo "🧪 Running test..."
    ./run.sh --once &
    runner_pid=$!
    
    # Wait a moment then check if process is still running
    sleep 5
    if kill -0 $runner_pid 2>/dev/null; then
        echo "✅ Runner is working correctly"
        kill $runner_pid 2>/dev/null || true
    else
        echo "⚠️ Runner test completed (check GitHub Actions tab for results)"
    fi
fi

echo ""
echo "🔄 Setting up Runner Service"
echo "============================"

if confirm "Install runner as a system service (recommended)?"; then
    echo "Installing runner service..."
    sudo ./svc.sh install
    
    if confirm "Start the runner service now?"; then
        sudo ./svc.sh start
        echo "✅ Runner service started"
        
        # Show service status
        sudo ./svc.sh status
    fi
fi

echo ""
echo "📝 Creating runner management scripts..."

# Create start script
cat > "$HOME/start-github-runner.sh" << 'EOF'
#!/bin/bash
cd ~/github-runner
sudo ./svc.sh start
sudo ./svc.sh status
EOF
chmod +x "$HOME/start-github-runner.sh"

# Create stop script  
cat > "$HOME/stop-github-runner.sh" << 'EOF'
#!/bin/bash
cd ~/github-runner
sudo ./svc.sh stop
EOF
chmod +x "$HOME/stop-github-runner.sh"

# Create status script
cat > "$HOME/github-runner-status.sh" << 'EOF'
#!/bin/bash
cd ~/github-runner
echo "GitHub Runner Status:"
sudo ./svc.sh status
echo ""
echo "Recent runner activity:"
tail -20 _diag/Runner_*.log 2>/dev/null || echo "No recent logs found"
EOF
chmod +x "$HOME/github-runner-status.sh"

echo "✅ Management scripts created:"
echo "   ~/start-github-runner.sh"
echo "   ~/stop-github-runner.sh" 
echo "   ~/github-runner-status.sh"

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Your Mac is now configured as a GitHub Actions self-hosted runner for:"
echo "Repository: https://github.com/${github_owner}/${github_repo}"
echo "Runner name: $(hostname)-arm64"
echo "Labels: macos, ARM64, skychart"
echo ""
echo "Next Steps:"
echo "1. Verify runner appears in GitHub repository settings"
echo "2. Test the workflow by pushing a commit" 
echo "3. Monitor builds in the Actions tab"
echo ""
echo "Runner Management:"
echo "• Start: ~/start-github-runner.sh"
echo "• Stop: ~/stop-github-runner.sh" 
echo "• Status: ~/github-runner-status.sh"
echo ""
echo "Troubleshooting:"
echo "• Logs: ~/github-runner/_diag/"
echo "• Configuration: ~/github-runner/.runner"
echo "• GitHub docs: https://docs.github.com/en/actions/hosting-your-own-runners"
echo ""
echo "🚀 Ready for automated ARM64 builds!"