# SkyChart / Cartes du Ciel

**Free software to draw sky charts**

SkyChart is a software to draw chart of the night sky for the amateur astronomer from a bunch of stars and nebulae catalogs.

## Table of Contents

- [About SkyChart](#about-skychart)
- [macOS ARM64 Build System](#macos-arm64-apple-silicon-build-system)
  - [Quick Start](#quick-start)
  - [Build System Components](#build-system-components)
- [Prerequisites](#prerequisites)
  - [System Requirements](#system-requirements)
  - [Install Dependencies](#install-dependencies)
- [Build Process](#build-process)
  - [1. Dependency Build](#1-dependency-build-automated)
  - [2. Main Application Build](#2-main-application-build)
  - [3. Create Distribution Package](#3-create-distribution-package)
- [Advanced Usage](#advanced-usage)
  - [Code Signing](#code-signing)
  - [Apple Notarization](#apple-notarization)
  - [Clean Build](#clean-build)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
  - [Verification](#verification)
- [App Bundle Architecture](#app-bundle-architecture)
- [Build Results](#build-results)

## About SkyChart

See main web page for more information and full download:  
🌐 https://www.ap-i.net/skychart

Please report any issue at:  
🐛 https://www.ap-i.net/mantis/set_project.php?project_id=1

This software is part of a full suite for astronomical observation:
- [CCDciel](https://github.com/pchev/ccdciel) - CCD/CMOS camera capture
- [INDI Starter](https://github.com/pchev/indistarter) - INDI server management
- [EQMod GUI](https://github.com/pchev/eqmodgui) - Mount control interface

**Requirement**: [libpasastro](https://github.com/pchev/libpasastro)

---

## macOS ARM64 (Apple Silicon) Build System

This repository includes a complete build and distribution system for SkyChart on macOS ARM64 (Apple Silicon) with **automated CI/CD pipeline support via GitHub Actions**.

### Quick Start

**For Users:**
```bash
./launch_skychart.sh
```

**For Developers:**
```bash
# 1. Build dependencies
./build_dependencies.sh

# 2. Build main application  
./build_macos_arm64.sh

# 3. Create distribution package
./package_macos.sh all
```

### Build System Components

**Automated Scripts:**
- **`build_dependencies.sh`** - Automated dependency package building (7 packages)
- **`build_macos_arm64.sh`** - Complete application build with Qt5 support
- **`package_macos.sh`** - App bundle creation and distribution packaging
- **`launch_skychart.sh`** - Runtime launcher with proper environment
- **`test_build.sh`** - Build validation and testing

**What's Built:**
- ✅ **Native ARM64 Performance** - True ARM64 compilation (no Rosetta 2)
- ✅ **Complete Functionality** - Star charts, telescope control, WCS support  
- ✅ **Professional Distribution** - macOS app bundles with code signing support
- ✅ **Full Astronomical Data** - Complete star catalogs (Hipparcos, GAIA, Tycho, etc.)

## Prerequisites

### System Requirements
- macOS 11.0+ (Big Sur or later)
- Apple Silicon Mac (M1/M2/M3/M4)
- Xcode Command Line Tools
- Homebrew package manager

### Install Dependencies
```bash
# Install required packages
brew install fpc qt@5

# Verify installations
fpc -v
qmake --version
```

## Build Process

### 1. Dependency Build (Automated)
```bash
./build_dependencies.sh
```
**Builds 7 dependency packages:**
- `bgrabitmappack` - Graphics bitmap manipulation
- `laz_synapse` - Network communication library  
- `indiclient` - INDI telescope control protocol
- `xmlparser` - XML parsing utilities
- `enhedit` - Enhanced edit controls
- `uniqueinstance_package` - Single instance management
- `lazvo` - Virtual Observatory tools

### 2. Main Application Build
```bash
./build_macos_arm64.sh
```
**Build Process:**
1. **Environment Setup** - Verifies prerequisites and paths
2. **Lazarus IDE Setup** - Clones and builds with Qt5 support
3. **Qt5Pas Framework** - Builds Qt5 bindings for Pascal
4. **Dependencies** - Compiles all required packages
5. **WCS Library** - Builds coordinate system library (520KB ARM64)
6. **Main Application** - Compiles SkyChart executable (22MB ARM64)
7. **Data Setup** - Configures astronomical data directories
8. **Verification** - Ensures all components are properly built

### 3. Create Distribution Package
```bash
./package_macos.sh all
```
**Creates complete app bundle with:**
- Proper macOS `.app` structure
- All dependencies embedded
- Complete astronomical data (193MB)
- DMG distribution package (61MB)

## Automated CI/CD Pipeline

### GitHub Actions Integration

This repository includes a complete **GitHub Actions CI/CD pipeline** for automated ARM64 builds:

**Pipeline Features:**
- ✅ **Native ARM64 cloud runners** (when available)
- ✅ **Self-hosted runner support** (your Mac)
- ✅ **Automated dependency installation**
- ✅ **Complete build automation** 
- ✅ **Professional DMG distribution**
- ✅ **Artifact management and releases**

**Setup Self-Hosted Runner:**
```bash
# Automated setup script
./setup_github_runner.sh
```

**Workflow Triggers:**
- Push to `main`, `master`, or `macos-arm64` branches
- Pull requests to main branches  
- Manual workflow dispatch

**Build Matrix:**
- **Primary**: GitHub-hosted `macos-15-arm64` runners
- **Fallback**: Self-hosted ARM64 Mac runners
- **Output**: Professional DMG packages with automatic releases

For detailed CI/CD setup and analysis, see: [`GITHUB_ACTIONS_ANALYSIS.md`](GITHUB_ACTIONS_ANALYSIS.md)

## Advanced Usage

### Code Signing
```bash
./package_macos.sh sign "Developer ID Application: Your Name"
```

### Apple Notarization  
```bash
./package_macos.sh notarize your@email.com app-password TEAM_ID
```

### Clean Build
```bash
./build_macos_arm64.sh clean
./build_macos_arm64.sh
```

## Troubleshooting

### Common Issues

**Qt5 Framework Not Found:**
```bash
export DYLD_FRAMEWORK_PATH="/Users/$(whoami)/homebrew/Cellar/qt@5/5.15.17/lib:$DYLD_FRAMEWORK_PATH"
```

**Missing WCS Library:**
```bash
# Copy library to runtime location
cp skychart/library/wcs/libcdcwcs.dylib ~/homebrew/lib/
```

**Build Failures:**
```bash
# Clean and rebuild dependencies
./build_dependencies.sh
./build_macos_arm64.sh clean
./build_macos_arm64.sh
```

### Verification
```bash
# Test build components
./test_build.sh

# Check executable architecture
file skychart/units/aarch64-darwin-qt5/skychart

# Verify app bundle
ls -la dist/SkyChart.app/Contents/
```

## App Bundle Architecture

```
SkyChart.app/
├── Contents/
│   ├── Info.plist                    # Bundle metadata
│   ├── MacOS/
│   │   ├── SkyChart                  # Launcher script  
│   │   └── SkyChart_bin              # Main executable (ARM64)
│   ├── Frameworks/
│   │   └── Qt5Pas.framework/         # Qt5 Pascal bindings
│   ├── Libraries/
│   │   └── libcdcwcs.dylib          # WCS library (ARM64)
│   └── Resources/
│       └── tools/                    # Complete astronomical data
│           ├── data/                 # Basic configuration
│           └── cat/                  # Star catalogs (31 catalogs)
```

## Build Results

### Successful Build Output
- **SkyChart executable**: 22MB ARM64 native binary
- **WCS library**: 520KB coordinate system library  
- **Complete app bundle**: 193MB with all astronomical data
- **Distribution DMG**: 61MB compressed package
- **Code signing ready**: Developer ID certificate support

### File Locations
- **Executable**: `skychart/units/aarch64-darwin-qt5/skychart`
- **App Bundle**: `dist/SkyChart.app` 
- **DMG Package**: `dist/SkyChart-*.dmg`
- **Launcher**: `launch_skychart.sh`

## Build Success Verification

After successful build, you should have:
- ✅ Native ARM64 SkyChart executable
- ✅ Complete Qt5 framework integration
- ✅ All 7 dependency packages compiled
- ✅ WCS library built and deployed
- ✅ Complete astronomical data catalogs (31 catalogs, 43MB)
- ✅ Proper macOS app bundle structure
- ✅ Distribution-ready DMG package

**Verification Command:** `./test_build.sh`

---

## Build Status

✅ **Complete and ready** for production use, packaging, and distribution.

This build system provides a fully automated, reproducible process for creating native ARM64 SkyChart applications on Apple Silicon Macs.
Testing CI/CD: Fri Sep 19 21:32:15 EDT 2025
