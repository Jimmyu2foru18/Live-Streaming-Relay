# StreamRelay - Windows Setup Guide

## Important Notice

This project contains **three different solutions**:

1. **Linux Server Solution** (`install.sh`, `setup-wizard.sh`) - For Ubuntu/Linux VPS
2. **Windows Desktop Application** (`StreamRelay.exe.cs`, `build-desktop-app.ps1`) - For Windows users
3. **OBS Studio Plugin** (`stream-relay-plugin.cpp`, `build-obs-plugin.ps1`) - Cross-platform OBS plugin

## Windows Users - Quick Start

### Option 1: Windows Desktop Application (Recommended)

1. **Install .NET 6.0 SDK**:
   - Visit: https://dotnet.microsoft.com/download/dotnet/6.0
   - Download and install the **SDK** (not just runtime)
   - Restart your command prompt/PowerShell after installation

2. **Run the setup**:
   ```batch
   # Double-click setup.bat for guided setup
   # OR run in PowerShell:
   .\setup-windows.ps1
   ```

3. **Build the desktop app**:
   ```powershell
   .\build-desktop-app.ps1 -IncludeDependencies
   ```

### Option 2: OBS Studio Plugin

1. **Install prerequisites**:
   - Visual Studio 2019/2022 with C++ tools
   - CMake
   - Qt6 (optional, auto-detected)

2. **Build the plugin**:
   ```powershell
   .\build-obs-plugin.ps1
   ```

## Common Issues and Solutions

### Issue 1: "The token '&&' is not a valid statement separator"
**Problem**: You tried to run Linux bash scripts on Windows PowerShell
**Solution**: Use the Windows-specific files:
- `setup.bat` or `setup-windows.ps1` instead of `install.sh && setup-wizard.sh`

### Issue 2: "No .NET SDKs were found"
**Problem**: .NET SDK is not installed
**Solution**: 
1. Install .NET 6.0 SDK from https://dotnet.microsoft.com/download/dotnet/6.0
2. Restart PowerShell
3. Verify with: `dotnet --version`

### Issue 3: PowerShell execution policy
**Problem**: "Execution of scripts is disabled on this system"
**Solution**: Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## File Guide

### For Windows Users:
- `setup.bat` - Simple batch file with instructions
- `setup-windows.ps1` - Interactive PowerShell setup script
- `build-desktop-app.ps1` - Build the Windows desktop application
- `build-obs-plugin.ps1` - Build the OBS Studio plugin
- `StreamRelay.exe.cs` - Desktop application source code
- `StreamRelay.csproj` - .NET project file

### For Linux Users (VPS/Server):
- `install.sh` - Install Nginx with RTMP module on Ubuntu
- `setup-wizard.sh` - Interactive configuration wizard
- `nginx.conf.template` - Nginx configuration template

### Cross-Platform:
- `stream-relay-plugin.cpp` - OBS Studio plugin source
- `CMakeLists.txt` - CMake build configuration
- Various documentation files

## Next Steps

1. **For Streamers**: Use the Windows Desktop Application or OBS Plugin
2. **For Advanced Users**: Set up the Linux server solution on a VPS
3. **For Developers**: Contribute to the project or customize the code

## Support

If you encounter issues:
1. Check this README for common solutions
2. Ensure you're using the correct files for your platform
3. Verify all prerequisites are installed
4. Check the build logs for specific error messages

---

**Remember**: Linux scripts (`.sh` files) won't work on Windows. Use the Windows-specific files (`.ps1`, `.bat`, `.exe`) instead.