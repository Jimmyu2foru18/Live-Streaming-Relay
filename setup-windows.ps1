# Windows Setup Script for StreamRelay
# This script sets up the StreamRelay project on Windows

param(
    [switch]$InstallDotNet = $false,
    [switch]$BuildDesktopApp = $false,
    [switch]$BuildOBSPlugin = $false,
    [switch]$DownloadDependencies = $false
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

function Install-DotNetSDK {
    Write-ColorOutput "Installing .NET 6.0 SDK..." $InfoColor
    
    # Download .NET 6.0 SDK installer
    $dotnetUrl = "https://download.microsoft.com/download/c/6/d/c6da75c5-6c8a-4b05-8db0-4e9a4f8b8b8b/dotnet-sdk-6.0.417-win-x64.exe"
    $installerPath = "$env:TEMP\dotnet-sdk-installer.exe"
    
    try {
        Write-ColorOutput "Opening .NET SDK download page..." $InfoColor
        Write-ColorOutput "Please download and install .NET 6.0 SDK from: https://dotnet.microsoft.com/download/dotnet/6.0" $WarningColor
        Start-Process "https://dotnet.microsoft.com/download/dotnet/6.0"
        
        Write-ColorOutput "After installation, restart PowerShell and run this script again." $WarningColor
        
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        Write-ColorOutput ".NET SDK installation completed!" $SuccessColor
        return $true
    } catch {
        Write-ColorOutput "Failed to install .NET SDK: $($_.Exception.Message)" $ErrorColor
        return $false
    }
}

function Test-DotNetSDK {
    if (Test-Command "dotnet") {
        try {
            $version = dotnet --version 2>$null
            if ($version) {
                Write-ColorOutput ".NET SDK version $version is installed" $SuccessColor
                return $true
            }
        } catch {
            # Continue to installation
        }
    }
    
    Write-ColorOutput ".NET SDK is not installed or not working properly" $WarningColor
    return $false
}

function Download-Dependencies {
    Write-ColorOutput "Downloading dependencies..." $InfoColor
    
    # Create dependencies directory
    $depsDir = "dependencies"
    if (!(Test-Path $depsDir)) {
        New-Item -ItemType Directory -Path $depsDir | Out-Null
    }
    
    # Download Nginx for Windows
    $nginxUrl = "http://nginx.org/download/nginx-1.24.0.zip"
    $nginxPath = "$depsDir\nginx.zip"
    
    try {
        Write-ColorOutput "Downloading Nginx..." $InfoColor
        Invoke-WebRequest -Uri $nginxUrl -OutFile $nginxPath -UseBasicParsing
        Expand-Archive -Path $nginxPath -DestinationPath $depsDir -Force
        Remove-Item $nginxPath
        Write-ColorOutput "Nginx downloaded successfully" $SuccessColor
    } catch {
        Write-ColorOutput "Failed to download Nginx: $($_.Exception.Message)" $ErrorColor
    }
    
    # Download FFmpeg for Windows
    $ffmpegUrl = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    $ffmpegPath = "$depsDir\ffmpeg.zip"
    
    try {
        Write-ColorOutput "Downloading FFmpeg..." $InfoColor
        Invoke-WebRequest -Uri $ffmpegUrl -OutFile $ffmpegPath -UseBasicParsing
        Expand-Archive -Path $ffmpegPath -DestinationPath $depsDir -Force
        Remove-Item $ffmpegPath
        Write-ColorOutput "FFmpeg downloaded successfully" $SuccessColor
    } catch {
        Write-ColorOutput "Failed to download FFmpeg: $($_.Exception.Message)" $ErrorColor
    }
}

function Show-Menu {
    Clear-Host
    Write-ColorOutput "=== StreamRelay Windows Setup ==="  $InfoColor
    Write-ColorOutput "" 
    Write-ColorOutput "Choose an option:" $InfoColor
    Write-ColorOutput "1. Install .NET SDK" $InfoColor
    Write-ColorOutput "2. Download Dependencies (Nginx, FFmpeg)" $InfoColor
    Write-ColorOutput "3. Build Desktop Application" $InfoColor
    Write-ColorOutput "4. Build OBS Plugin" $InfoColor
    Write-ColorOutput "5. Complete Setup (All of the above)" $InfoColor
    Write-ColorOutput "6. Exit" $InfoColor
    Write-ColorOutput "" 
}

function Main {
    if ($InstallDotNet) {
        if (!(Test-DotNetSDK)) {
            Install-DotNetSDK
        }
        return
    }
    
    if ($DownloadDependencies) {
        Download-Dependencies
        return
    }
    
    if ($BuildDesktopApp) {
        if (Test-DotNetSDK) {
            .\build-desktop-app.ps1 -IncludeDependencies
        } else {
            Write-ColorOutput "Please install .NET SDK first" $ErrorColor
        }
        return
    }
    
    if ($BuildOBSPlugin) {
        .\build-obs-plugin.ps1
        return
    }
    
    # Interactive mode
    do {
        Show-Menu
        $choice = Read-Host "Enter your choice (1-6)"
        
        switch ($choice) {
            "1" {
                if (!(Test-DotNetSDK)) {
                    Install-DotNetSDK
                } else {
                    Write-ColorOutput ".NET SDK is already installed" $SuccessColor
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                Download-Dependencies
                Read-Host "Press Enter to continue"
            }
            "3" {
                if (Test-DotNetSDK) {
                    .\build-desktop-app.ps1 -IncludeDependencies
                } else {
                    Write-ColorOutput "Please install .NET SDK first (option 1)" $ErrorColor
                }
                Read-Host "Press Enter to continue"
            }
            "4" {
                .\build-obs-plugin.ps1
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-ColorOutput "Running complete setup..." $InfoColor
                
                # Install .NET SDK
                if (!(Test-DotNetSDK)) {
                    Install-DotNetSDK
                }
                
                # Download dependencies
                Download-Dependencies
                
                # Build desktop app
                if (Test-DotNetSDK) {
                    .\build-desktop-app.ps1 -IncludeDependencies
                }
                
                # Build OBS plugin
                .\build-obs-plugin.ps1
                
                Write-ColorOutput "Complete setup finished!" $SuccessColor
                Read-Host "Press Enter to continue"
            }
            "6" {
                Write-ColorOutput "Exiting..." $InfoColor
                break
            }
            default {
                Write-ColorOutput "Invalid choice. Please try again." $ErrorColor
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "6")
}

# Run main function
Main