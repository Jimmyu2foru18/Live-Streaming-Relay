# StreamRelay OBS Plugin Build Script
# This script builds and packages the OBS Studio plugin

param(
    [string]$Configuration = "Release",
    [string]$Platform = "x64",
    [string]$OBSPath = "",
    [string]$Qt6Path = "",
    [switch]$AutoDetect = $true,
    [switch]$CreatePackage = $true,
    [switch]$InstallPlugin = $false,
    [switch]$Clean = $false
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Find-OBSStudio {
    $possiblePaths = @(
        "C:\Program Files\obs-studio",
        "C:\Program Files (x86)\obs-studio",
        "$env:ProgramFiles\obs-studio",
        "${env:ProgramFiles(x86)}\obs-studio"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $binPath = Join-Path $path "bin\64bit"
            if (Test-Path $binPath) {
                return $path
            }
        }
    }
    
    return $null
}

function Find-Qt6 {
    $possiblePaths = @(
        "C:\Qt\6.5.0\msvc2019_64",
        "C:\Qt\6.4.0\msvc2019_64",
        "C:\Qt\6.3.0\msvc2019_64",
        "C:\Qt\6.2.0\msvc2019_64"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    try {
        Write-ColorOutput "Downloading $Url..." $InfoColor
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
        return $true
    } catch {
        Write-ColorOutput "Failed to download $Url : $($_.Exception.Message)" $ErrorColor
        return $false
    }
}

function Extract-Archive {
    param(
        [string]$ArchivePath,
        [string]$DestinationPath
    )
    try {
        Write-ColorOutput "Extracting $ArchivePath to $DestinationPath..." $InfoColor
        Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force
        return $true
    } catch {
        Write-ColorOutput "Failed to extract $ArchivePath : $($_.Exception.Message)" $ErrorColor
        return $false
    }
}

# Main build script
Write-ColorOutput "=== StreamRelay OBS Plugin Build Script ===" $InfoColor
Write-ColorOutput "Configuration: $Configuration" $InfoColor
Write-ColorOutput "Platform: $Platform" $InfoColor
Write-ColorOutput "" 

# Check prerequisites
Write-ColorOutput "Checking prerequisites..." $InfoColor

if (-not (Test-Command "cmake")) {
    Write-ColorOutput "Error: CMake not found. Please install CMake." $ErrorColor
    Write-ColorOutput "Download from: https://cmake.org/download/" $InfoColor
    exit 1
}

# Get CMake version
$cmakeVersion = cmake --version | Select-Object -First 1
Write-ColorOutput "Found CMake: $cmakeVersion" $SuccessColor

# Check for Visual Studio Build Tools
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsInstallation = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vsInstallation) {
        Write-ColorOutput "Found Visual Studio: $vsInstallation" $SuccessColor
    } else {
        Write-ColorOutput "Error: Visual Studio with C++ tools not found." $ErrorColor
        Write-ColorOutput "Please install Visual Studio 2019 or later with C++ development tools." $InfoColor
        exit 1
    }
} else {
    Write-ColorOutput "Warning: Visual Studio installer not found. Assuming build tools are available." $WarningColor
}

# Auto-detect OBS Studio path
if ($AutoDetect -and [string]::IsNullOrEmpty($OBSPath)) {
    Write-ColorOutput "Auto-detecting OBS Studio..." $InfoColor
    $OBSPath = Find-OBSStudio
    if ($OBSPath) {
        Write-ColorOutput "Found OBS Studio: $OBSPath" $SuccessColor
    } else {
        Write-ColorOutput "Warning: OBS Studio not found automatically." $WarningColor
        Write-ColorOutput "Please specify -OBSPath parameter or install OBS Studio." $InfoColor
    }
}

# Auto-detect Qt6 path
if ($AutoDetect -and [string]::IsNullOrEmpty($Qt6Path)) {
    Write-ColorOutput "Auto-detecting Qt6..." $InfoColor
    $Qt6Path = Find-Qt6
    if ($Qt6Path) {
        Write-ColorOutput "Found Qt6: $Qt6Path" $SuccessColor
    } else {
        Write-ColorOutput "Warning: Qt6 not found automatically." $WarningColor
        Write-ColorOutput "Please specify -Qt6Path parameter or install Qt6." $InfoColor
    }
}

# Check if CMakeLists.txt exists
if (-not (Test-Path "obs-plugin\CMakeLists.txt")) {
    Write-ColorOutput "Error: obs-plugin\CMakeLists.txt not found." $ErrorColor
    Write-ColorOutput "Please run this script from the project root directory." $InfoColor
    exit 1
}

# Clean previous builds if requested
if ($Clean) {
    Write-ColorOutput "Cleaning previous builds..." $InfoColor
    $buildDir = "obs-plugin\build"
    if (Test-Path $buildDir) {
        Remove-Item -Path $buildDir -Recurse -Force
    }
}

# Create build directory
$buildDir = "obs-plugin\build"
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
Set-Location $buildDir

# Configure CMake
Write-ColorOutput "Configuring CMake..." $InfoColor
$cmakeArgs = @(
    "..",
    "-G", "Visual Studio 16 2019",
    "-A", $Platform,
    "-DCMAKE_BUILD_TYPE=$Configuration"
)

if (-not [string]::IsNullOrEmpty($OBSPath)) {
    $cmakeArgs += "-DOBS_STUDIO_DIR=$OBSPath"
}

if (-not [string]::IsNullOrEmpty($Qt6Path)) {
    $cmakeArgs += "-DQt6_DIR=$Qt6Path\lib\cmake\Qt6"
    $cmakeArgs += "-DCMAKE_PREFIX_PATH=$Qt6Path"
}

cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Error: CMake configuration failed." $ErrorColor
    Set-Location ..\..
    exit 1
}

Write-ColorOutput "CMake configuration completed successfully!" $SuccessColor

# Build the plugin
Write-ColorOutput "Building plugin..." $InfoColor
cmake --build . --config $Configuration
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Error: Build failed." $ErrorColor
    Set-Location ..\..
    exit 1
}

Write-ColorOutput "Build completed successfully!" $SuccessColor

# Return to project root
Set-Location ..\..

# Create package if requested
if ($CreatePackage) {
    Write-ColorOutput "Creating plugin package..." $InfoColor
    
    $packageDir = "obs-plugin-package"
    $pluginDir = Join-Path $packageDir "stream-relay-plugin"
    $binDir = Join-Path $pluginDir "bin\64bit"
    $dataDir = Join-Path $pluginDir "data\stream-relay-plugin"
    
    # Create directories
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    
    # Copy plugin binary
    $pluginBinary = "obs-plugin\build\$Configuration\stream-relay-plugin.dll"
    if (Test-Path $pluginBinary) {
        Copy-Item -Path $pluginBinary -Destination $binDir
        Write-ColorOutput "Plugin binary copied to package." $SuccessColor
    } else {
        Write-ColorOutput "Warning: Plugin binary not found at $pluginBinary" $WarningColor
    }
    
    # Copy data files
    $dataFiles = @(
        "obs-plugin\data\nginx.conf.template",
        "obs-plugin\data\README.txt"
    )
    
    foreach ($file in $dataFiles) {
        if (Test-Path $file) {
            $fileName = Split-Path $file -Leaf
            Copy-Item -Path $file -Destination (Join-Path $dataDir $fileName)
        }
    }
    
    # Download dependencies
    Write-ColorOutput "Downloading dependencies for package..." $InfoColor
    
    $depsDir = Join-Path $pluginDir "deps"
    $nginxDir = Join-Path $depsDir "nginx"
    $ffmpegDir = Join-Path $depsDir "ffmpeg"
    
    New-Item -ItemType Directory -Path $nginxDir -Force | Out-Null
    New-Item -ItemType Directory -Path $ffmpegDir -Force | Out-Null
    
    # Download nginx with RTMP module
    $nginxUrl = "https://github.com/illuspas/nginx-rtmp-win32/releases/download/1.2.1/nginx-rtmp-win32-1.2.1.zip"
    $nginxZip = Join-Path $env:TEMP "nginx-rtmp.zip"
    
    if (Download-File $nginxUrl $nginxZip) {
        if (Extract-Archive $nginxZip $nginxDir) {
            Write-ColorOutput "Nginx with RTMP module packaged successfully!" $SuccessColor
        }
        Remove-Item $nginxZip -Force -ErrorAction SilentlyContinue
    }
    
    # Download FFmpeg
    $ffmpegUrl = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    $ffmpegZip = Join-Path $env:TEMP "ffmpeg.zip"
    
    if (Download-File $ffmpegUrl $ffmpegZip) {
        $tempExtractDir = Join-Path $env:TEMP "ffmpeg-extract"
        if (Extract-Archive $ffmpegZip $tempExtractDir) {
            $ffmpegExtracted = Get-ChildItem -Path $tempExtractDir -Directory | Select-Object -First 1
            if ($ffmpegExtracted) {
                $ffmpegBinSource = Join-Path $ffmpegExtracted.FullName "bin"
                if (Test-Path $ffmpegBinSource) {
                    Copy-Item -Path "$ffmpegBinSource\*" -Destination $ffmpegDir -Recurse -Force
                    Write-ColorOutput "FFmpeg packaged successfully!" $SuccessColor
                }
            }
        }
        Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Create installation instructions
    $installInstructions = @"
StreamRelay OBS Plugin Installation
==================================

Installation Steps:
1. Close OBS Studio completely
2. Copy the 'stream-relay-plugin' folder to your OBS plugins directory:
   - Default location: C:\Program Files\obs-studio\obs-plugins\64bit\
   - Or your custom OBS installation\obs-plugins\64bit\
3. Restart OBS Studio
4. The plugin will appear in Tools > StreamRelay

Manual Installation:
- Copy stream-relay-plugin.dll to: obs-plugins\64bit\
- Copy data files to: data\obs-plugins\stream-relay-plugin\
- Copy dependencies to: deps\ (or ensure nginx and ffmpeg are in PATH)

Troubleshooting:
- Ensure OBS Studio is completely closed during installation
- Check that you have the correct architecture (64-bit)
- Verify that Visual C++ Redistributable is installed
- Check OBS Studio logs if the plugin doesn't load

Support:
- GitHub: https://github.com/streamrelay
- Documentation: See README-StreamRelay.md

Version: 1.0.0
Build Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    $installPath = Join-Path $packageDir "INSTALL.txt"
    Set-Content -Path $installPath -Value $installInstructions
    
    # Create ZIP package
    $zipPath = "StreamRelay-OBS-Plugin.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Compress-Archive -Path "$packageDir\*" -DestinationPath $zipPath
    Write-ColorOutput "Plugin package created: $zipPath" $SuccessColor
}

# Install plugin if requested
if ($InstallPlugin -and -not [string]::IsNullOrEmpty($OBSPath)) {
    Write-ColorOutput "Installing plugin to OBS Studio..." $InfoColor
    
    $obsPluginDir = Join-Path $OBSPath "obs-plugins\64bit"
    $obsDataDir = Join-Path $OBSPath "data\obs-plugins\stream-relay-plugin"
    
    if (Test-Path $obsPluginDir) {
        # Copy plugin binary
        $pluginBinary = "obs-plugin\build\$Configuration\stream-relay-plugin.dll"
        if (Test-Path $pluginBinary) {
            Copy-Item -Path $pluginBinary -Destination $obsPluginDir -Force
            Write-ColorOutput "Plugin binary installed." $SuccessColor
        }
        
        # Copy data files
        New-Item -ItemType Directory -Path $obsDataDir -Force | Out-Null
        $dataFiles = Get-ChildItem "obs-plugin\data" -File
        foreach ($file in $dataFiles) {
            Copy-Item -Path $file.FullName -Destination $obsDataDir -Force
        }
        
        Write-ColorOutput "Plugin installed successfully!" $SuccessColor
        Write-ColorOutput "Please restart OBS Studio to load the plugin." $InfoColor
    } else {
        Write-ColorOutput "Error: OBS plugin directory not found: $obsPluginDir" $ErrorColor
    }
}

# Display build summary
Write-ColorOutput "" 
Write-ColorOutput "=== Build Summary ===" $InfoColor
Write-ColorOutput "Configuration: $Configuration" $InfoColor
Write-ColorOutput "Platform: $Platform" $InfoColor

if (-not [string]::IsNullOrEmpty($OBSPath)) {
    Write-ColorOutput "OBS Studio Path: $OBSPath" $InfoColor
}

if (-not [string]::IsNullOrEmpty($Qt6Path)) {
    Write-ColorOutput "Qt6 Path: $Qt6Path" $InfoColor
}

$pluginBinary = "obs-plugin\build\$Configuration\stream-relay-plugin.dll"
if (Test-Path $pluginBinary) {
    $binarySize = (Get-Item $pluginBinary).Length
    Write-ColorOutput "Plugin Binary: $(Resolve-Path $pluginBinary)" $InfoColor
    Write-ColorOutput "Binary Size: $([math]::Round($binarySize / 1KB, 2)) KB" $InfoColor
}

if ($CreatePackage -and (Test-Path "StreamRelay-OBS-Plugin.zip")) {
    $packageSize = (Get-Item "StreamRelay-OBS-Plugin.zip").Length
    Write-ColorOutput "Package Created: StreamRelay-OBS-Plugin.zip" $SuccessColor
    Write-ColorOutput "Package Size: $([math]::Round($packageSize / 1MB, 2)) MB" $InfoColor
}

Write-ColorOutput "" 
Write-ColorOutput "Build completed successfully! 🎉" $SuccessColor

if ($CreatePackage) {
    Write-ColorOutput "Plugin package is ready for distribution." $InfoColor
}

if ($InstallPlugin) {
    Write-ColorOutput "Plugin has been installed to OBS Studio." $InfoColor
    Write-ColorOutput "Please restart OBS Studio to load the plugin." $InfoColor
}

Write-ColorOutput "" 
Write-ColorOutput "Next steps:" $InfoColor
Write-ColorOutput "1. Install the plugin in OBS Studio" $InfoColor
Write-ColorOutput "2. Restart OBS Studio" $InfoColor
Write-ColorOutput "3. Find StreamRelay in Tools menu" $InfoColor
Write-ColorOutput "4. Configure your stream keys and start streaming!" $InfoColor