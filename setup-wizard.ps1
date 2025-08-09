# Interactive Setup Wizard for Multi-Platform Streaming Relay
# PowerShell version for Windows users
# This script collects user information and configures the entire system

param(
    [switch]$SkipInstall,
    [switch]$TestOnly
)

# Configuration variables
$VPS_IP = ""
$TWITCH_KEY = ""
$YOUTUBE_KEY = ""
$KICK_KEY = ""
$STREAM_NAME = "main"
$MAX_BITRATE = "15000"
$SERVER_NAME = "streaming-relay"

# Function to print colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Blue"
        "Magenta" = "Magenta"
        "Cyan" = "Cyan"
        "White" = "White"
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

# Function to print banner
function Show-Banner {
    Clear-Host
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                                                              ║" "Cyan"
    Write-ColorOutput "║        🎥 Multi-Platform Streaming Setup Wizard 🎥          ║" "Cyan"
    Write-ColorOutput "║                                                              ║" "Cyan"
    Write-ColorOutput "║          Complete Configuration & Testing Tool              ║" "Cyan"
    Write-ColorOutput "║                                                              ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

# Function to validate IP address
function Test-IPAddress {
    param([string]$IP)
    
    try {
        $ipObj = [System.Net.IPAddress]::Parse($IP)
        return $ipObj.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
    }
    catch {
        return $false
    }
}

# Function to validate stream key
function Test-StreamKey {
    param(
        [string]$Key,
        [string]$Platform
    )
    
    if ([string]::IsNullOrWhiteSpace($Key)) {
        Write-ColorOutput "❌ Empty key provided for $Platform" "Red"
        return $false
    }
    
    if ($Key.Length -lt 8) {
        Write-ColorOutput "⚠️  Warning: $Platform key seems too short ($($Key.Length) characters)" "Yellow"
        $confirm = Read-Host "Continue anyway? (y/N)"
        if ($confirm -notmatch "^[Yy]$") {
            return $false
        }
    }
    
    return $true
}

# Function to collect VPS information
function Get-VPSInfo {
    Write-ColorOutput "🌐 VPS Configuration" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    do {
        $script:VPS_IP = Read-Host "Enter your VPS IP address"
        
        if (Test-IPAddress $script:VPS_IP) {
            Write-ColorOutput "✅ Valid IP address: $($script:VPS_IP)" "Green"
            break
        } else {
            Write-ColorOutput "❌ Invalid IP address format. Please try again." "Red"
        }
    } while ($true)
    
    Write-Host ""
    $inputName = Read-Host "Enter a name for your streaming server (default: streaming-relay)"
    if (![string]::IsNullOrWhiteSpace($inputName)) {
        $script:SERVER_NAME = $inputName
    }
    
    Write-Host ""
    $inputStream = Read-Host "Enter your preferred stream name (default: main)"
    if (![string]::IsNullOrWhiteSpace($inputStream)) {
        $script:STREAM_NAME = $inputStream
    }
    
    Write-Host ""
    $inputBitrate = Read-Host "Enter maximum bitrate for your upload (default: 15000 kbps)"
    if (![string]::IsNullOrWhiteSpace($inputBitrate) -and $inputBitrate -match "^\d+$") {
        $script:MAX_BITRATE = $inputBitrate
    }
    
    Write-ColorOutput "✅ VPS configuration collected!" "Green"
}

# Function to collect streaming platform keys
function Get-StreamKeys {
    Write-ColorOutput "🔑 Streaming Platform Keys" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-ColorOutput "📝 You'll need stream keys from each platform:" "Yellow"
    Write-Host ""
    
    # Twitch
    Write-ColorOutput "🟣 Twitch Stream Key" "Magenta"
    Write-Host "   Get it from: https://dashboard.twitch.tv/settings/stream"
    do {
        $script:TWITCH_KEY = Read-Host "   Enter Twitch key"
    } while (!(Test-StreamKey $script:TWITCH_KEY "Twitch"))
    Write-Host ""
    
    # YouTube
    Write-ColorOutput "🔴 YouTube Stream Key" "Red"
    Write-Host "   Get it from: https://studio.youtube.com → Go Live → Stream"
    do {
        $script:YOUTUBE_KEY = Read-Host "   Enter YouTube key"
    } while (!(Test-StreamKey $script:YOUTUBE_KEY "YouTube"))
    Write-Host ""
    
    # Kick
    Write-ColorOutput "🟢 Kick Stream Key" "Green"
    Write-Host "   Get it from: https://kick.com/dashboard/settings/stream"
    do {
        $script:KICK_KEY = Read-Host "   Enter Kick key"
    } while (!(Test-StreamKey $script:KICK_KEY "Kick"))
    Write-Host ""
    
    Write-ColorOutput "✅ All stream keys collected!" "Green"
}

# Function to show configuration summary
function Show-ConfigurationSummary {
    Write-ColorOutput "📋 Configuration Summary" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-ColorOutput "🌐 Server Configuration:" "Yellow"
    Write-Host "   VPS IP: $VPS_IP"
    Write-Host "   Server Name: $SERVER_NAME"
    Write-Host "   Stream Name: $STREAM_NAME"
    Write-Host "   Max Bitrate: $MAX_BITRATE kbps"
    Write-Host ""
    
    Write-ColorOutput "🔑 Platform Keys:" "Yellow"
    Write-Host "   Twitch: $($TWITCH_KEY.Substring(0, [Math]::Min(8, $TWITCH_KEY.Length)))... ($($TWITCH_KEY.Length) chars)"
    Write-Host "   YouTube: $($YOUTUBE_KEY.Substring(0, [Math]::Min(8, $YOUTUBE_KEY.Length)))... ($($YOUTUBE_KEY.Length) chars)"
    Write-Host "   Kick: $($KICK_KEY.Substring(0, [Math]::Min(8, $KICK_KEY.Length)))... ($($KICK_KEY.Length) chars)"
    Write-Host ""
    
    Write-ColorOutput "🎥 OBS Configuration:" "Yellow"
    Write-Host "   Service: Custom"
    Write-Host "   Server: rtmp://$VPS_IP/live"
    Write-Host "   Stream Key: $STREAM_NAME"
    Write-Host "   Recommended Bitrate: $MAX_BITRATE kbps"
    Write-Host ""
    
    Write-ColorOutput "🌐 Monitoring:" "Yellow"
    Write-Host "   Web Interface: http://$VPS_IP:8080"
    Write-Host "   Statistics: http://$VPS_IP:8080/stat"
    Write-Host ""
}

# Function to update configuration files
function Update-ConfigurationFiles {
    Write-ColorOutput "🔧 Updating Configuration Files" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    # Backup original nginx.conf
    if (Test-Path "nginx.conf") {
        $backupName = "nginx.conf.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item "nginx.conf" $backupName
        Write-ColorOutput "✅ Backed up original nginx.conf to $backupName" "Green"
    }
    
    # Update nginx configuration
    Write-ColorOutput "📝 Updating nginx configuration..." "Blue"
    
    if (Test-Path "nginx.conf") {
        # Replace stream keys in nginx.conf
        $content = Get-Content "nginx.conf" -Raw
        $content = $content -replace "YOUR_TWITCH_KEY", $TWITCH_KEY
        $content = $content -replace "YOUR_YOUTUBE_KEY", $YOUTUBE_KEY
        $content = $content -replace "YOUR_KICK_KEY", $KICK_KEY
        Set-Content "nginx.conf" $content
        
        Write-ColorOutput "✅ Stream keys updated in nginx.conf" "Green"
    } else {
        Write-ColorOutput "⚠️  nginx.conf not found in current directory" "Yellow"
    }
    
    # Create OBS configuration file
    Write-ColorOutput "📝 Creating OBS configuration file..." "Blue"
    
    $obsConfig = @"
# OBS Studio Configuration
# Copy these settings to your OBS

Service: Custom
Server: rtmp://$VPS_IP/live
Stream Key: $STREAM_NAME

# Recommended Output Settings:
Output Mode: Advanced
Encoder: x264 (or Hardware if available)
Rate Control: CBR
Bitrate: $MAX_BITRATE Kbps
Keyframe Interval: 2
CPU Usage Preset: veryfast
Profile: high

# Video Settings:
Base Resolution: 1920x1080
Output Resolution: 1920x1080
FPS: 30 or 60

# Audio Settings:
Audio Bitrate: 160 Kbps
Sample Rate: 44.1 kHz
"@
    
    Set-Content "obs-config.txt" $obsConfig
    Write-ColorOutput "✅ Created obs-config.txt" "Green"
    
    # Create Streamlabs OBS configuration file
    $streamlabsConfig = @"
# Streamlabs OBS Configuration
# Copy these settings to your Streamlabs OBS

Stream Type: Custom Ingest
URL: rtmp://$VPS_IP/live
Stream Key: $STREAM_NAME

# Output Settings:
Video Bitrate: $MAX_BITRATE Kbps
Audio Bitrate: 160 Kbps
Encoder: x264 (Software) or Hardware

# Video Settings:
Base Resolution: 1920x1080
Output Resolution: 1920x1080
FPS: 30 or 60
"@
    
    Set-Content "streamlabs-config.txt" $streamlabsConfig
    Write-ColorOutput "✅ Created streamlabs-config.txt" "Green"
    
    # Create Windows-specific test script
    $testScript = @"
@echo off
echo Testing connection to VPS: $VPS_IP
echo.
echo Testing RTMP port (1935)...
telnet $VPS_IP 1935
echo.
echo Testing Web interface port (8080)...
start http://$VPS_IP:8080
echo.
echo OBS Configuration:
echo Service: Custom
echo Server: rtmp://$VPS_IP/live
echo Stream Key: $STREAM_NAME
echo.
pause
"@
    
    Set-Content "test-connection.bat" $testScript
    Write-ColorOutput "✅ Created test-connection.bat" "Green"
    
    Write-Host ""
    Write-ColorOutput "🎉 All configuration files updated successfully!" "Green"
}

# Function to test FFmpeg availability
function Test-FFmpeg {
    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to run local tests
function Invoke-LocalTests {
    Write-ColorOutput "🧪 Running Local Tests" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    # Test 1: Check configuration files
    Write-ColorOutput "[1/4] Checking configuration files..." "Blue"
    if (Test-Path "nginx.conf") {
        Write-ColorOutput "✅ nginx.conf exists" "Green"
        
        $content = Get-Content "nginx.conf" -Raw
        if ($content -notmatch "YOUR_TWITCH_KEY" -and $content -notmatch "YOUR_YOUTUBE_KEY" -and $content -notmatch "YOUR_KICK_KEY") {
            Write-ColorOutput "✅ Stream keys are configured" "Green"
        } else {
            Write-ColorOutput "⚠️  Some stream keys may not be configured" "Yellow"
        }
    } else {
        Write-ColorOutput "❌ nginx.conf not found" "Red"
    }
    
    # Test 2: Check OBS config files
    Write-ColorOutput "[2/4] Checking OBS configuration files..." "Blue"
    if (Test-Path "obs-config.txt") {
        Write-ColorOutput "✅ obs-config.txt created" "Green"
    }
    if (Test-Path "streamlabs-config.txt") {
        Write-ColorOutput "✅ streamlabs-config.txt created" "Green"
    }
    
    # Test 3: Check FFmpeg availability
    Write-ColorOutput "[3/4] Checking FFmpeg availability..." "Blue"
    if (Test-FFmpeg) {
        Write-ColorOutput "✅ FFmpeg is available" "Green"
    } else {
        Write-ColorOutput "⚠️  FFmpeg not found in PATH" "Yellow"
        Write-ColorOutput "   Download from: https://ffmpeg.org/download.html" "Yellow"
    }
    
    # Test 4: Network connectivity test
    Write-ColorOutput "[4/4] Testing network connectivity to VPS..." "Blue"
    try {
        $ping = Test-Connection -ComputerName $VPS_IP -Count 2 -Quiet
        if ($ping) {
            Write-ColorOutput "✅ VPS is reachable" "Green"
        } else {
            Write-ColorOutput "❌ VPS is not reachable" "Red"
        }
    }
    catch {
        Write-ColorOutput "⚠️  Could not test VPS connectivity" "Yellow"
    }
    
    Write-Host ""
    Write-ColorOutput "🎉 Local testing completed!" "Green"
}

# Function to show final instructions
function Show-FinalInstructions {
    Write-ColorOutput "🎯 Setup Complete - Next Steps" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-ColorOutput "🎉 Your multi-platform streaming configuration is ready!" "Green"
    Write-Host ""
    
    Write-ColorOutput "📱 OBS/Streamlabs OBS Configuration:" "Yellow"
    Write-Host "   Service: Custom"
    Write-Host "   Server: rtmp://$VPS_IP/live"
    Write-Host "   Stream Key: $STREAM_NAME"
    Write-Host "   Bitrate: $MAX_BITRATE kbps"
    Write-Host ""
    
    Write-ColorOutput "📊 Monitoring & Management:" "Yellow"
    Write-Host "   Web Dashboard: http://$VPS_IP:8080"
    Write-Host "   Statistics: http://$VPS_IP:8080/stat"
    Write-Host ""
    
    Write-ColorOutput "📁 Configuration Files Created:" "Yellow"
    Write-Host "   obs-config.txt - OBS Studio settings"
    Write-Host "   streamlabs-config.txt - Streamlabs OBS settings"
    Write-Host "   test-connection.bat - Windows connection test"
    Write-Host "   nginx.conf.backup.* - Configuration backups"
    Write-Host ""
    
    Write-ColorOutput "🔧 VPS Setup (if not done yet):" "Yellow"
    Write-Host "   1. Upload all files to your VPS"
    Write-Host "   2. Run: chmod +x install.sh && ./install.sh"
    Write-Host "   3. Copy nginx.conf to /usr/local/nginx/conf/"
    Write-Host "   4. Restart: sudo systemctl restart nginx-rtmp"
    Write-Host ""
    
    Write-ColorOutput "💡 Pro Tips:" "Blue"
    Write-Host "   1. Test with a private stream first"
    Write-Host "   2. Monitor the web dashboard during streaming"
    Write-Host "   3. Keep your stream keys secure"
    Write-Host "   4. Check platform-specific requirements"
    Write-Host ""
    
    Write-ColorOutput "🚀 Happy streaming to multiple platforms!" "Green"
}

# Main function
function Main {
    Show-Banner
    
    Write-ColorOutput "Welcome to the Multi-Platform Streaming Setup Wizard!" "Blue"
    Write-ColorOutput "This wizard will guide you through the complete configuration process." "Yellow"
    Write-Host ""
    
    if ($TestOnly) {
        Write-ColorOutput "🧪 Running in test-only mode..." "Blue"
        Invoke-LocalTests
        return
    }
    
    # Step 1: Collect VPS information
    Get-VPSInfo
    Write-Host ""
    
    # Step 2: Collect streaming platform keys
    Get-StreamKeys
    Write-Host ""
    
    # Step 3: Show configuration summary
    Show-ConfigurationSummary
    
    $confirm = Read-Host "Is this configuration correct? (y/N)"
    if ($confirm -notmatch "^[Yy]$") {
        Write-ColorOutput "Setup cancelled. Run the script again to reconfigure." "Yellow"
        return
    }
    
    Write-Host ""
    
    # Step 4: Update configuration files
    Update-ConfigurationFiles
    Write-Host ""
    
    # Step 5: Run local tests
    Invoke-LocalTests
    Write-Host ""
    
    # Step 6: Show final instructions
    Show-FinalInstructions
    
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-ColorOutput "🎬 Setup wizard completed! Thank you for using our streaming relay!" "Green"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-ColorOutput "❌ PowerShell 5.0 or higher is required!" "Red"
    Write-ColorOutput "💡 Please upgrade your PowerShell version." "Yellow"
    exit 1
}

# Run main function
Main