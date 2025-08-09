# StreamRelay Desktop Application Build Script
# This script builds and packages the Windows desktop application

param(
    [string]$Configuration = "Release",
    [string]$Platform = "win-x64",
    [switch]$SelfContained = $true,
    [switch]$SingleFile = $false,
    [switch]$IncludeDependencies = $true,
    [switch]$CreateInstaller = $false,
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
Write-ColorOutput "=== StreamRelay Desktop Application Build Script ===" $InfoColor
Write-ColorOutput "Configuration: $Configuration" $InfoColor
Write-ColorOutput "Platform: $Platform" $InfoColor
Write-ColorOutput "Self-Contained: $SelfContained" $InfoColor
Write-ColorOutput "Single File: $SingleFile" $InfoColor
Write-ColorOutput "" 

# Check prerequisites
Write-ColorOutput "Checking prerequisites..." $InfoColor

if (-not (Test-Command "dotnet")) {
    Write-ColorOutput "Error: .NET SDK not found. Please install .NET 6.0 SDK or later." $ErrorColor
    Write-ColorOutput "" 
    Write-ColorOutput "To fix this issue:" $WarningColor
    Write-ColorOutput "1. Visit: https://dotnet.microsoft.com/download/dotnet/6.0" $InfoColor
    Write-ColorOutput "2. Download and install the .NET 6.0 SDK (not just runtime)" $InfoColor
    Write-ColorOutput "3. Restart PowerShell after installation" $InfoColor
    Write-ColorOutput "4. Run this script again" $InfoColor
    Write-ColorOutput "" 
    Write-ColorOutput "Or run the Windows setup script: .\setup-windows.ps1" $InfoColor
    exit 1
}

# Get .NET version
$dotnetVersion = dotnet --version
Write-ColorOutput "Found .NET SDK version: $dotnetVersion" $SuccessColor

# Check if project file exists
if (-not (Test-Path "StreamRelay.csproj")) {
    Write-ColorOutput "Error: StreamRelay.csproj not found in current directory." $ErrorColor
    Write-ColorOutput "Please run this script from the project root directory." $InfoColor
    exit 1
}

# Clean previous builds if requested
if ($Clean) {
    Write-ColorOutput "Cleaning previous builds..." $InfoColor
    if (Test-Path "bin") {
        Remove-Item -Path "bin" -Recurse -Force
    }
    if (Test-Path "obj") {
        Remove-Item -Path "obj" -Recurse -Force
    }
    if (Test-Path "publish") {
        Remove-Item -Path "publish" -Recurse -Force
    }
}

# Restore NuGet packages
Write-ColorOutput "Restoring NuGet packages..." $InfoColor
dotnet restore
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Error: Failed to restore NuGet packages." $ErrorColor
    exit 1
}

# Build the application
Write-ColorOutput "Building application..." $InfoColor
$buildArgs = @(
    "build"
    "--configuration", $Configuration
    "--no-restore"
)

dotnet @buildArgs
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Error: Build failed." $ErrorColor
    exit 1
}

Write-ColorOutput "Build completed successfully!" $SuccessColor

# Publish the application
Write-ColorOutput "Publishing application..." $InfoColor
$publishArgs = @(
    "publish"
    "--configuration", $Configuration
    "--runtime", $Platform
    "--output", "publish"
    "--no-restore"
    "--no-build"
)

if ($SelfContained) {
    $publishArgs += "--self-contained", "true"
} else {
    $publishArgs += "--self-contained", "false"
}

if ($SingleFile) {
    $publishArgs += "-p:PublishSingleFile=true"
    $publishArgs += "-p:IncludeNativeLibrariesForSelfExtract=true"
}

dotnet @publishArgs
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Error: Publish failed." $ErrorColor
    exit 1
}

Write-ColorOutput "Publish completed successfully!" $SuccessColor

# Download and include dependencies if requested
if ($IncludeDependencies) {
    Write-ColorOutput "Downloading dependencies..." $InfoColor
    
    $publishDir = "publish"
    $nginxDir = Join-Path $publishDir "nginx"
    $ffmpegDir = Join-Path $publishDir "ffmpeg"
    
    # Create directories
    New-Item -ItemType Directory -Path $nginxDir -Force | Out-Null
    New-Item -ItemType Directory -Path $ffmpegDir -Force | Out-Null
    
    # Download nginx with RTMP module (Windows)
    $nginxUrl = "https://github.com/illuspas/nginx-rtmp-win32/releases/download/1.2.1/nginx-rtmp-win32-1.2.1.zip"
    $nginxZip = Join-Path $env:TEMP "nginx-rtmp.zip"
    
    if (Download-File $nginxUrl $nginxZip) {
        if (Extract-Archive $nginxZip $nginxDir) {
            Write-ColorOutput "Nginx with RTMP module downloaded successfully!" $SuccessColor
        }
        Remove-Item $nginxZip -Force -ErrorAction SilentlyContinue
    } else {
        Write-ColorOutput "Warning: Failed to download nginx. Please download manually." $WarningColor
    }
    
    # Download FFmpeg (Windows)
    $ffmpegUrl = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    $ffmpegZip = Join-Path $env:TEMP "ffmpeg.zip"
    
    if (Download-File $ffmpegUrl $ffmpegZip) {
        $tempExtractDir = Join-Path $env:TEMP "ffmpeg-extract"
        if (Extract-Archive $ffmpegZip $tempExtractDir) {
            # Find the extracted FFmpeg directory
            $ffmpegExtracted = Get-ChildItem -Path $tempExtractDir -Directory | Select-Object -First 1
            if ($ffmpegExtracted) {
                # Copy FFmpeg binaries
                $ffmpegBinSource = Join-Path $ffmpegExtracted.FullName "bin"
                if (Test-Path $ffmpegBinSource) {
                    Copy-Item -Path "$ffmpegBinSource\*" -Destination $ffmpegDir -Recurse -Force
                    Write-ColorOutput "FFmpeg downloaded successfully!" $SuccessColor
                }
            }
        }
        Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-ColorOutput "Warning: Failed to download FFmpeg. Please download manually." $WarningColor
    }
    
    # Create sample configuration
    $configContent = @"
TwitchKey=
YouTubeKey=
KickKey=
LocalPort=1935
"@
    $configPath = Join-Path $publishDir "streamrelay.config"
    Set-Content -Path $configPath -Value $configContent
    
    Write-ColorOutput "Sample configuration file created: $configPath" $InfoColor
}

# Create installer if requested
if ($CreateInstaller) {
    Write-ColorOutput "Creating installer..." $InfoColor
    
    # Check if NSIS is available
    $nsisPath = "C:\Program Files (x86)\NSIS\makensis.exe"
    if (-not (Test-Path $nsisPath)) {
        $nsisPath = "C:\Program Files\NSIS\makensis.exe"
    }
    
    if (Test-Path $nsisPath) {
        # Create NSIS script
        $nsisScript = @"
!define APP_NAME "StreamRelay"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "StreamRelay Team"
!define APP_URL "https://github.com/streamrelay"
!define APP_EXECUTABLE "StreamRelay.exe"

Name "`${APP_NAME}"
OutFile "StreamRelay-Setup.exe"
InstallDir "`$PROGRAMFILES\`${APP_NAME}"
RequestExecutionLevel admin

Page directory
Page instfiles

Section "Install"
    SetOutPath "`$INSTDIR"
    File /r "publish\*"
    
    CreateDirectory "`$SMPROGRAMS\`${APP_NAME}"
    CreateShortCut "`$SMPROGRAMS\`${APP_NAME}\`${APP_NAME}.lnk" "`$INSTDIR\`${APP_EXECUTABLE}"
    CreateShortCut "`$DESKTOP\`${APP_NAME}.lnk" "`$INSTDIR\`${APP_EXECUTABLE}"
    
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\`${APP_NAME}" "DisplayName" "`${APP_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\`${APP_NAME}" "UninstallString" "`$INSTDIR\uninstall.exe"
    WriteUninstaller "`$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "`$INSTDIR\*"
    RMDir /r "`$INSTDIR"
    Delete "`$SMPROGRAMS\`${APP_NAME}\*"
    RMDir "`$SMPROGRAMS\`${APP_NAME}"
    Delete "`$DESKTOP\`${APP_NAME}.lnk"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\`${APP_NAME}"
SectionEnd
"@
        
        $nsisScriptPath = "installer.nsi"
        Set-Content -Path $nsisScriptPath -Value $nsisScript
        
        # Run NSIS
        & $nsisPath $nsisScriptPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Installer created successfully: StreamRelay-Setup.exe" $SuccessColor
        } else {
            Write-ColorOutput "Error: Failed to create installer." $ErrorColor
        }
        
        Remove-Item $nsisScriptPath -Force -ErrorAction SilentlyContinue
    } else {
        Write-ColorOutput "Warning: NSIS not found. Installer not created." $WarningColor
        Write-ColorOutput "Download NSIS from: https://nsis.sourceforge.io/" $InfoColor
    }
}

# Create README for the published application
$readmeContent = @"
StreamRelay Desktop Application
==============================

Thank you for using StreamRelay!

Quick Start:
1. Run StreamRelay.exe
2. Enter your stream keys for Twitch, YouTube, and/or Kick
3. Click 'Start Streaming'
4. Configure your streaming software (OBS, etc.) to use:
   - Server: rtmp://localhost:1935/live
   - Stream Key: live
5. Start streaming in your software

Requirements:
- Windows 10/11 (64-bit)
- Stable internet connection (5+ Mbps upload recommended)
- Stream keys from your platforms

Troubleshooting:
- If port 1935 is in use, change it in the application settings
- Ensure your firewall allows StreamRelay
- Check that nginx and ffmpeg are in their respective folders

Support:
- GitHub: https://github.com/streamrelay
- Documentation: See README-StreamRelay.md

Version: 1.0.0
Build Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$readmePath = Join-Path "publish" "README.txt"
Set-Content -Path $readmePath -Value $readmeContent

# Display build summary
Write-ColorOutput "" 
Write-ColorOutput "=== Build Summary ===" $InfoColor
Write-ColorOutput "Configuration: $Configuration" $InfoColor
Write-ColorOutput "Platform: $Platform" $InfoColor
Write-ColorOutput "Output Directory: $(Resolve-Path 'publish')" $InfoColor

if (Test-Path "publish\StreamRelay.exe") {
    $exeSize = (Get-Item "publish\StreamRelay.exe").Length
    Write-ColorOutput "Executable Size: $([math]::Round($exeSize / 1MB, 2)) MB" $InfoColor
}

$publishSize = (Get-ChildItem "publish" -Recurse | Measure-Object -Property Length -Sum).Sum
Write-ColorOutput "Total Package Size: $([math]::Round($publishSize / 1MB, 2)) MB" $InfoColor

Write-ColorOutput "" 
Write-ColorOutput "Build completed successfully! 🎉" $SuccessColor
Write-ColorOutput "You can now run the application from the 'publish' directory." $InfoColor

if ($CreateInstaller -and (Test-Path "StreamRelay-Setup.exe")) {
    Write-ColorOutput "Installer created: StreamRelay-Setup.exe" $SuccessColor
}

Write-ColorOutput "" 
Write-ColorOutput "Next steps:" $InfoColor
Write-ColorOutput "1. Test the application by running publish\StreamRelay.exe" $InfoColor
Write-ColorOutput "2. Configure your stream keys" $InfoColor
Write-ColorOutput "3. Test streaming to your platforms" $InfoColor
Write-ColorOutput "4. Share with other streamers!" $InfoColor