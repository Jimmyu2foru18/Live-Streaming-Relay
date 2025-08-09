#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build script for StreamRelay OBS Studio Plugin

.DESCRIPTION
    This script provides options to build the plugin in different modes:
    1. Standalone mode (for development/testing without OBS SDK)
    2. Full OBS plugin mode (requires OBS Studio SDK and Qt)

.PARAMETER Mode
    Build mode: 'standalone' or 'obs-plugin'

.PARAMETER Clean
    Clean build directory before building

.EXAMPLE
    .\build-plugin.ps1 -Mode standalone
    .\build-plugin.ps1 -Mode obs-plugin -Clean
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('standalone', 'obs-plugin')]
    [string]$Mode,
    
    [switch]$Clean
)

# Colors for output
$ErrorColor = 'Red'
$SuccessColor = 'Green'
$InfoColor = 'Cyan'
$WarningColor = 'Yellow'

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

Write-ColorOutput "StreamRelay OBS Plugin Build Script" $InfoColor
Write-ColorOutput "Mode: $Mode" $InfoColor

# Check prerequisites
if ($Mode -eq 'obs-plugin') {
    Write-ColorOutput "`nChecking prerequisites for OBS plugin build..." $InfoColor
    
    if (!(Test-Command 'cmake')) {
        Write-ColorOutput "ERROR: CMake not found. Please install CMake." $ErrorColor
        exit 1
    }
    
    # Check for OBS Studio SDK
    $obsPath = $env:OBS_STUDIO_PATH
    if (!$obsPath -or !(Test-Path $obsPath)) {
        Write-ColorOutput "ERROR: OBS Studio SDK not found. Set OBS_STUDIO_PATH environment variable." $ErrorColor
        Write-ColorOutput "   Example: `$env:OBS_STUDIO_PATH = 'C:\\obs-studio'" $WarningColor
        exit 1
    }
    
    # Check for Qt
    $qtPath = $env:Qt6_DIR
    if (!$qtPath -or !(Test-Path $qtPath)) {
        Write-ColorOutput "ERROR: Qt6 not found. Set Qt6_DIR environment variable." $ErrorColor
        Write-ColorOutput "   Example: `$env:Qt6_DIR = 'C:\\Qt\\6.5.0\\msvc2019_64'" $WarningColor
        exit 1
    }
    
    Write-ColorOutput "SUCCESS: Prerequisites check passed" $SuccessColor
}

# Create build directory
$buildDir = "build-$Mode"
if ($Clean -and (Test-Path $buildDir)) {
    Write-ColorOutput "Cleaning build directory..." $InfoColor
    Remove-Item $buildDir -Recurse -Force
}

if (!(Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Set-Location $buildDir

try {
    if ($Mode -eq 'standalone') {
        Write-ColorOutput "`nBuilding in standalone mode (development/testing)..." $InfoColor
        
        # Simple compilation without OBS SDK - try multiple compilers
        $compiled = $false
        
        # Try Microsoft C++ compiler first (Visual Studio)
        if (Test-Command 'cl') {
            Write-ColorOutput "Using Microsoft C++ compiler (cl.exe)..." $InfoColor
            $compileCmd = "cl /c ../stream-relay-plugin.cpp /I.. /std:c++17 /DSTANDALONE_BUILD /EHsc"
            Write-ColorOutput "Running: $compileCmd" $InfoColor
            Invoke-Expression $compileCmd
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "SUCCESS: Standalone compilation successful!" $SuccessColor
                Write-ColorOutput "   Object file: stream-relay-plugin.obj" $InfoColor
                $compiled = $true
            }
        }
        
        # Try GCC if MSVC failed or not available
        if (!$compiled -and (Test-Command 'g++')) {
            Write-ColorOutput "Using GCC compiler (g++)..." $InfoColor
            $compileCmd = "g++ -c ../stream-relay-plugin.cpp -I.. -std=c++17 -DSTANDALONE_BUILD"
            Write-ColorOutput "Running: $compileCmd" $InfoColor
            Invoke-Expression $compileCmd
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "SUCCESS: Standalone compilation successful!" $SuccessColor
                Write-ColorOutput "   Object file: stream-relay-plugin.o" $InfoColor
                $compiled = $true
            }
        }
        
        # Try Clang if others failed
        if (!$compiled -and (Test-Command 'clang++')) {
            Write-ColorOutput "Using Clang compiler (clang++)..." $InfoColor
            $compileCmd = "clang++ -c ../stream-relay-plugin.cpp -I.. -std=c++17 -DSTANDALONE_BUILD"
            Write-ColorOutput "Running: $compileCmd" $InfoColor
            Invoke-Expression $compileCmd
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "SUCCESS: Standalone compilation successful!" $SuccessColor
                Write-ColorOutput "   Object file: stream-relay-plugin.o" $InfoColor
                $compiled = $true
            }
        }
        
        if (!$compiled) {
            Write-ColorOutput "ERROR: No suitable C++ compiler found." $ErrorColor
            Write-ColorOutput "Please install one of the following:" $WarningColor
            Write-ColorOutput "  - Visual Studio 2019/2022 (includes MSVC)" $WarningColor
            Write-ColorOutput "  - Visual Studio Build Tools" $WarningColor
            Write-ColorOutput "  - MinGW-w64 (includes GCC)" $WarningColor
            Write-ColorOutput "  - LLVM/Clang" $WarningColor
            Write-ColorOutput "\nNote: This is just a syntax check. The plugin requires OBS SDK to function." $InfoColor
            exit 1
        }
        
    } else {
        Write-ColorOutput "`nBuilding OBS Studio plugin..." $InfoColor
        
        # CMake configuration
        $cmakeArgs = @(
            ".."
            "-DCMAKE_BUILD_TYPE=Release"
            "-DOBS_STUDIO_PATH=$env:OBS_STUDIO_PATH"
            "-DQt6_DIR=$env:Qt6_DIR"
        )
        
        Write-ColorOutput "Configuring with CMake..." $InfoColor
        & cmake @cmakeArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "ERROR: CMake configuration failed" $ErrorColor
            exit 1
        }
        
        Write-ColorOutput "Building plugin..." $InfoColor
        & cmake --build . --config Release
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "SUCCESS: OBS plugin build successful!" $SuccessColor
            
            # Find the built plugin
            $pluginFile = Get-ChildItem -Recurse -Filter "*.dll" | Where-Object { $_.Name -like "*stream-relay*" } | Select-Object -First 1
            if ($pluginFile) {
                Write-ColorOutput "   Plugin file: $($pluginFile.FullName)" $InfoColor
                
                # Installation instructions
                Write-ColorOutput "`nInstallation Instructions:" $InfoColor
                Write-ColorOutput "1. Copy the plugin DLL to your OBS plugins directory:" $InfoColor
                Write-ColorOutput "   %APPDATA%\\obs-studio\\plugins\\stream-relay-plugin\\bin\\64bit\\" $WarningColor
                Write-ColorOutput "2. Restart OBS Studio" $InfoColor
                Write-ColorOutput "3. The plugin should appear in Tools menu" $InfoColor
            }
        } else {
            Write-ColorOutput "ERROR: Build failed" $ErrorColor
            exit 1
        }
    }
    
} finally {
    Set-Location ..
}

Write-ColorOutput "`nBuild completed successfully!" $SuccessColor