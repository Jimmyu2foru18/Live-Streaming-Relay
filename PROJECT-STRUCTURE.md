# StreamRelay Project Structure

This document outlines the complete structure of the StreamRelay multi-platform streaming project, which includes both server-based and client-based solutions.

## 📁 Project Overview

The StreamRelay project provides three different solutions for multi-platform streaming:

1. **Server-Based Solution** - VPS/Linux server setup
2. **Windows Desktop Application** - Standalone Windows app
3. **OBS Studio Plugin** - Integration with OBS Studio

## 📂 Directory Structure

```
StreamRelay/
├── 📄 README-StreamRelay.md          # Main project documentation
├── 📄 PROJECT-STRUCTURE.md           # This file
├── 📄 build-desktop-app.ps1          # Windows app build script
├── 📄 build-obs-plugin.ps1           # OBS plugin build script
├── 📄 validate-project.ps1           # Project validation script
├── 📄 setup-wizard.ps1               # Windows setup wizard
│
├── 📁 server-solution/                # VPS/Linux server setup
│   ├── 📄 install.sh                 # Main installation script
│   ├── 📄 setup-wizard.sh            # Interactive setup wizard
│   ├── 📄 nginx.conf                 # Nginx RTMP configuration
│   ├── 📄 README.md                  # Server solution documentation
│   └── 📁 scripts/                   # Helper scripts
│       ├── 📄 start-stream.sh        # Start streaming service
│       ├── 📄 stop-stream.sh         # Stop streaming service
│       ├── 📄 monitor.sh             # Stream monitoring
│       └── 📄 update.sh              # Update system
│
├── 📁 desktop-app/                   # Windows Desktop Application
│   ├── 📄 StreamRelay.exe.cs         # Main application code
│   ├── 📄 StreamRelay.csproj         # Project configuration
│   ├── 📄 build-desktop-app.ps1      # Build script
│   └── 📁 publish/                   # Build output (generated)
│       ├── 📄 StreamRelay.exe         # Main executable
│       ├── 📁 nginx/                  # Nginx with RTMP module
│       ├── 📁 ffmpeg/                 # FFmpeg binaries
│       └── 📄 streamrelay.config     # Configuration file
│
├── 📁 obs-plugin/                    # OBS Studio Plugin
│   ├── 📄 stream-relay-plugin.cpp    # Plugin source code
│   ├── 📄 CMakeLists.txt             # CMake build configuration
│   ├── 📄 plugin-macros.h.in         # Plugin configuration template
│   ├── 📄 build-obs-plugin.ps1       # Build script
│   ├── 📁 data/                      # Plugin data files
│   │   ├── 📄 nginx.conf.template    # Nginx configuration template
│   │   └── 📄 README.txt             # Data files documentation
│   └── 📁 build/                     # Build output (generated)
│       └── 📄 stream-relay-plugin.dll # Plugin binary
│
└── 📁 docs/                          # Additional documentation
    ├── 📄 INSTALLATION.md            # Installation guides
    ├── 📄 CONFIGURATION.md           # Configuration reference
    ├── 📄 TROUBLESHOOTING.md         # Common issues and solutions
    └── 📄 API.md                     # API documentation
```

## 🔧 Solution Components

### 1. Server-Based Solution

**Purpose**: Traditional VPS/Linux server setup for advanced users

**Key Files**:
- `install.sh` - Automated installation script for Ubuntu 22.04 LTS
- `setup-wizard.sh` - Interactive configuration wizard
- `nginx.conf` - Pre-configured Nginx RTMP server
- `README.md` - Comprehensive setup documentation

**Features**:
- Multi-platform streaming (Twitch, YouTube, Kick)
- Hardware acceleration support
- Real-time monitoring
- Auto-restart capabilities
- Cost-effective VPS hosting

### 2. Windows Desktop Application

**Purpose**: User-friendly Windows application for streamers

**Key Files**:
- `StreamRelay.exe.cs` - C# Windows Forms application
- `StreamRelay.csproj` - .NET 6.0 project configuration
- `build-desktop-app.ps1` - Automated build and packaging script

**Features**:
- Modern GUI interface
- One-click streaming setup
- Built-in Nginx and FFmpeg
- Real-time status monitoring
- No monthly costs
- Easy installation

### 3. OBS Studio Plugin

**Purpose**: Seamless integration with OBS Studio

**Key Files**:
- `stream-relay-plugin.cpp` - C++ plugin implementation
- `CMakeLists.txt` - Cross-platform build configuration
- `plugin-macros.h.in` - Plugin configuration template
- `build-obs-plugin.ps1` - Windows build script

**Features**:
- Native OBS integration
- Familiar OBS interface
- Automatic configuration
- Real-time stream management
- Cross-platform support (Windows, macOS, Linux)

## 🚀 Quick Start Guide

### For Streamers (Recommended)

1. **OBS Plugin** (Easiest):
   ```powershell
   .\build-obs-plugin.ps1 -InstallPlugin
   ```

2. **Windows Desktop App** (Alternative):
   ```powershell
   .\build-desktop-app.ps1 -IncludeDependencies
   ```

### For Advanced Users

3. **Server Solution** (Most Flexible):
   ```bash
   chmod +x install.sh setup-wizard.sh
   ./install.sh
   ./setup-wizard.sh
   ```

## 🔨 Build Scripts

### Desktop Application Build

```powershell
# Basic build
.\build-desktop-app.ps1

# Full build with dependencies and installer
.\build-desktop-app.ps1 -IncludeDependencies -CreateInstaller -Clean

# Self-contained single file
.\build-desktop-app.ps1 -SingleFile -SelfContained
```

### OBS Plugin Build

```powershell
# Basic build
.\build-obs-plugin.ps1

# Build and install to OBS
.\build-obs-plugin.ps1 -InstallPlugin -OBSPath "C:\Program Files\obs-studio"

# Create distribution package
.\build-obs-plugin.ps1 -CreatePackage -Clean
```

## 📋 Requirements

### Desktop Application
- Windows 10/11 (64-bit)
- .NET 6.0 Runtime (included in self-contained builds)
- 100MB+ free disk space
- 5+ Mbps upload internet connection

### OBS Plugin
- OBS Studio 28.0+ (Windows/macOS/Linux)
- Qt6 (for building)
- CMake 3.16+
- Visual Studio 2019+ (Windows)
- Xcode (macOS)
- GCC/Clang (Linux)

### Server Solution
- Ubuntu 22.04 LTS VPS
- 1GB+ RAM
- 1 CPU core
- 10GB+ storage
- Root access

## 🔧 Configuration

### Stream Keys Setup

All solutions require platform-specific stream keys:

1. **Twitch**: Get from https://dashboard.twitch.tv/settings/stream
2. **YouTube**: Get from https://studio.youtube.com/channel/UC.../livestreaming
3. **Kick**: Get from https://kick.com/dashboard/settings/stream

### RTMP Settings

- **Server**: `rtmp://localhost:1935/live` (desktop/plugin) or `rtmp://YOUR_VPS_IP:1935/live` (server)
- **Stream Key**: `live`
- **Bitrate**: Recommended 3000-6000 kbps
- **Resolution**: 1920x1080 or 1280x720
- **FPS**: 30 or 60

## 🐛 Troubleshooting

### Common Issues

1. **Port 1935 in use**:
   - Change RTMP port in configuration
   - Check for other streaming software

2. **Plugin not loading in OBS**:
   - Verify OBS Studio version compatibility
   - Check plugin installation path
   - Review OBS logs

3. **Stream connection failed**:
   - Verify stream keys
   - Check internet connection
   - Confirm platform streaming settings

4. **Build errors**:
   - Ensure all dependencies are installed
   - Check Visual Studio/CMake versions
   - Review build script output

### Log Files

- **Desktop App**: `%APPDATA%\StreamRelay\logs\`
- **OBS Plugin**: OBS Studio log files
- **Server**: `/var/log/nginx/` and `journalctl -u nginx`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Setup

```powershell
# Clone repository
git clone https://github.com/streamrelay/streamrelay.git
cd streamrelay

# Build all components
.\build-desktop-app.ps1 -Clean
.\build-obs-plugin.ps1 -Clean
```

## 📄 License

This project is licensed under the MIT License. See LICENSE file for details.

## 🆘 Support

- **GitHub Issues**: https://github.com/streamrelay/streamrelay/issues
- **Documentation**: See README-StreamRelay.md
- **Community**: Discord/Reddit (links in main README)

## 🔄 Version History

- **v1.0.0** - Initial release with all three solutions
- **v1.1.0** - Enhanced OBS plugin with more platforms
- **v1.2.0** - Desktop app improvements and auto-updater

---

**Note**: This project provides multiple solutions to accommodate different user preferences and technical expertise levels. Choose the solution that best fits your needs and technical comfort level.