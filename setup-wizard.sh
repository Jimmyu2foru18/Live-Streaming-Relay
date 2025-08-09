#!/bin/bash

# Interactive Setup Wizard for Multi-Platform Streaming Relay
# This script collects user information and configures the entire system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration variables
VPS_IP=""
TWITCH_KEY=""
YOUTUBE_KEY=""
KICK_KEY=""
STREAM_NAME="main"
MAX_BITRATE="15000"
SERVER_NAME="streaming-relay"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print banner
print_banner() {
    clear
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "║        🎥 Multi-Platform Streaming Setup Wizard 🎥          ║"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "║          Complete Configuration & Testing Tool              ║"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [[ $i -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function to validate stream key
validate_stream_key() {
    local key=$1
    local platform=$2
    
    if [ -z "$key" ]; then
        print_color $RED "❌ Empty key provided for $platform"
        return 1
    fi
    
    if [ ${#key} -lt 8 ]; then
        print_color $YELLOW "⚠️  Warning: $platform key seems too short (${#key} characters)"
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Function to collect VPS information
collect_vps_info() {
    print_color $BLUE "🌐 VPS Configuration"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    while true; do
        read -p "Enter your VPS IP address: " VPS_IP
        
        if validate_ip "$VPS_IP"; then
            print_color $GREEN "✅ Valid IP address: $VPS_IP"
            break
        else
            print_color $RED "❌ Invalid IP address format. Please try again."
        fi
    done
    
    echo
    read -p "Enter a name for your streaming server (default: streaming-relay): " input_name
    if [ -n "$input_name" ]; then
        SERVER_NAME="$input_name"
    fi
    
    echo
    read -p "Enter your preferred stream name (default: main): " input_stream
    if [ -n "$input_stream" ]; then
        STREAM_NAME="$input_stream"
    fi
    
    echo
    read -p "Enter maximum bitrate for your upload (default: 15000 kbps): " input_bitrate
    if [ -n "$input_bitrate" ] && [[ $input_bitrate =~ ^[0-9]+$ ]]; then
        MAX_BITRATE="$input_bitrate"
    fi
    
    print_color $GREEN "✅ VPS configuration collected!"
}

# Function to collect streaming platform keys
collect_stream_keys() {
    print_color $BLUE "🔑 Streaming Platform Keys"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    print_color $YELLOW "📝 You'll need stream keys from each platform:"
    echo
    
    # Twitch
    print_color $PURPLE "🟣 Twitch Stream Key"
    echo "   Get it from: https://dashboard.twitch.tv/settings/stream"
    while true; do
        read -p "   Enter Twitch key: " TWITCH_KEY
        if validate_stream_key "$TWITCH_KEY" "Twitch"; then
            break
        fi
    done
    echo
    
    # YouTube
    print_color $RED "🔴 YouTube Stream Key"
    echo "   Get it from: https://studio.youtube.com → Go Live → Stream"
    while true; do
        read -p "   Enter YouTube key: " YOUTUBE_KEY
        if validate_stream_key "$YOUTUBE_KEY" "YouTube"; then
            break
        fi
    done
    echo
    
    # Kick
    print_color $GREEN "🟢 Kick Stream Key"
    echo "   Get it from: https://kick.com/dashboard/settings/stream"
    while true; do
        read -p "   Enter Kick key: " KICK_KEY
        if validate_stream_key "$KICK_KEY" "Kick"; then
            break
        fi
    done
    echo
    
    print_color $GREEN "✅ All stream keys collected!"
}

# Function to show configuration summary
show_configuration_summary() {
    print_color $BLUE "📋 Configuration Summary"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    print_color $YELLOW "🌐 Server Configuration:"
    echo "   VPS IP: $VPS_IP"
    echo "   Server Name: $SERVER_NAME"
    echo "   Stream Name: $STREAM_NAME"
    echo "   Max Bitrate: $MAX_BITRATE kbps"
    echo
    
    print_color $YELLOW "🔑 Platform Keys:"
    echo "   Twitch: ${TWITCH_KEY:0:8}... (${#TWITCH_KEY} chars)"
    echo "   YouTube: ${YOUTUBE_KEY:0:8}... (${#YOUTUBE_KEY} chars)"
    echo "   Kick: ${KICK_KEY:0:8}... (${#KICK_KEY} chars)"
    echo
    
    print_color $YELLOW "🎥 OBS Configuration:"
    echo "   Service: Custom"
    echo "   Server: rtmp://$VPS_IP/live"
    echo "   Stream Key: $STREAM_NAME"
    echo "   Recommended Bitrate: $MAX_BITRATE kbps"
    echo
    
    print_color $YELLOW "🌐 Monitoring:"
    echo "   Web Interface: http://$VPS_IP:8080"
    echo "   Statistics: http://$VPS_IP:8080/stat"
    echo
}

# Function to update configuration files
update_configuration_files() {
    print_color $BLUE "🔧 Updating Configuration Files"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    # Backup original nginx.conf
    if [ -f "nginx.conf" ]; then
        cp nginx.conf nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
        print_color $GREEN "✅ Backed up original nginx.conf"
    fi
    
    # Update nginx configuration
    print_color $BLUE "📝 Updating nginx configuration..."
    
    # Replace stream keys in nginx.conf
    sed -i "s/YOUR_TWITCH_KEY/$TWITCH_KEY/g" nginx.conf
    sed -i "s/YOUR_YOUTUBE_KEY/$YOUTUBE_KEY/g" nginx.conf
    sed -i "s/YOUR_KICK_KEY/$KICK_KEY/g" nginx.conf
    
    print_color $GREEN "✅ Stream keys updated in nginx.conf"
    
    # Create OBS configuration file
    print_color $BLUE "📝 Creating OBS configuration file..."
    
    cat > obs-config.txt << EOF
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
EOF
    
    print_color $GREEN "✅ Created obs-config.txt"
    
    # Create Streamlabs OBS configuration file
    cat > streamlabs-config.txt << EOF
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
EOF
    
    print_color $GREEN "✅ Created streamlabs-config.txt"
    
    # Update test script with VPS IP
    if [ -f "test-obs-connection.bat" ]; then
        # Create a customized version of the test script
        sed "s/Enter your VPS IP address: /Enter your VPS IP address (default: $VPS_IP): /g" test-obs-connection.bat > test-obs-connection-configured.bat
        print_color $GREEN "✅ Created configured test script"
    fi
    
    echo
    print_color $GREEN "🎉 All configuration files updated successfully!"
}

# Function to run installation
run_installation() {
    print_color $BLUE "🚀 Running Installation"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    if [ ! -f "install.sh" ]; then
        print_color $RED "❌ install.sh not found"
        return 1
    fi
    
    print_color $YELLOW "📦 This will install:"
    echo "   - Nginx with RTMP module"
    echo "   - FFmpeg for stream processing"
    echo "   - Systemd service"
    echo "   - Web monitoring interface"
    echo
    
    read -p "Proceed with installation? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        chmod +x install.sh
        ./install.sh
        
        if [ $? -eq 0 ]; then
            print_color $GREEN "✅ Installation completed successfully!"
            return 0
        else
            print_color $RED "❌ Installation failed"
            return 1
        fi
    else
        print_color $YELLOW "Installation skipped"
        return 1
    fi
}

# Function to deploy configuration
deploy_configuration() {
    print_color $BLUE "📋 Deploying Configuration"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    # Copy configuration to nginx directory
    if [ -f "/usr/local/nginx/conf/nginx.conf" ]; then
        print_color $BLUE "📝 Backing up existing configuration..."
        sudo cp /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        print_color $BLUE "📝 Deploying new configuration..."
        sudo cp nginx.conf /usr/local/nginx/conf/nginx.conf
        
        # Test configuration
        if sudo /usr/local/nginx/sbin/nginx -t; then
            print_color $GREEN "✅ Configuration deployed and validated"
            
            # Restart service
            print_color $BLUE "🔄 Restarting nginx service..."
            sudo systemctl restart nginx-rtmp
            
            if systemctl is-active --quiet nginx-rtmp; then
                print_color $GREEN "✅ Service restarted successfully"
                return 0
            else
                print_color $RED "❌ Service failed to start"
                return 1
            fi
        else
            print_color $RED "❌ Configuration validation failed"
            return 1
        fi
    else
        print_color $YELLOW "⚠️  Nginx not installed. Configuration saved for later deployment."
        return 1
    fi
}

# Function to run comprehensive tests
run_tests() {
    print_color $BLUE "🧪 Running Comprehensive Tests"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    # Test 1: Service status
    print_color $BLUE "[1/5] Testing service status..."
    if systemctl is-active --quiet nginx-rtmp; then
        print_color $GREEN "✅ nginx-rtmp service is running"
    else
        print_color $RED "❌ nginx-rtmp service is not running"
        return 1
    fi
    
    # Test 2: Port accessibility
    print_color $BLUE "[2/5] Testing port accessibility..."
    if netstat -tuln | grep -q ":1935 "; then
        print_color $GREEN "✅ RTMP port (1935) is listening"
    else
        print_color $RED "❌ RTMP port (1935) not accessible"
    fi
    
    if netstat -tuln | grep -q ":8080 "; then
        print_color $GREEN "✅ Web interface port (8080) is listening"
    else
        print_color $RED "❌ Web interface port (8080) not accessible"
    fi
    
    # Test 3: Configuration validation
    print_color $BLUE "[3/5] Testing configuration..."
    if sudo /usr/local/nginx/sbin/nginx -t 2>/dev/null; then
        print_color $GREEN "✅ Nginx configuration is valid"
    else
        print_color $RED "❌ Nginx configuration has errors"
    fi
    
    # Test 4: Stream key configuration
    print_color $BLUE "[4/5] Testing stream key configuration..."
    if [ -f "/usr/local/nginx/conf/nginx.conf" ]; then
        if ! grep -q "YOUR_TWITCH_KEY" /usr/local/nginx/conf/nginx.conf && \
           ! grep -q "YOUR_YOUTUBE_KEY" /usr/local/nginx/conf/nginx.conf && \
           ! grep -q "YOUR_KICK_KEY" /usr/local/nginx/conf/nginx.conf; then
            print_color $GREEN "✅ All stream keys are configured"
        else
            print_color $YELLOW "⚠️  Some stream keys may not be configured"
        fi
    fi
    
    # Test 5: RTMP connection test
    print_color $BLUE "[5/5] Testing RTMP connection..."
    if command -v ffmpeg >/dev/null 2>&1; then
        timeout 10 ffmpeg -f lavfi -i testsrc2=duration=3:size=320x240:rate=30 \
            -f lavfi -i sine=frequency=1000:duration=3 \
            -c:v libx264 -preset ultrafast -b:v 1000k \
            -c:a aac -b:a 128k \
            -f flv rtmp://localhost/live/test_stream -y /dev/null 2>/dev/null && \
            print_color $GREEN "✅ RTMP connection test successful" || \
            print_color $YELLOW "⚠️  RTMP connection test failed (may be normal)"
    else
        print_color $YELLOW "⚠️  FFmpeg not available for connection testing"
    fi
    
    echo
    print_color $GREEN "🎉 Testing completed!"
}

# Function to show final instructions
show_final_instructions() {
    print_color $BLUE "🎯 Setup Complete - Next Steps"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    print_color $GREEN "🎉 Your multi-platform streaming relay is ready!"
    echo
    
    print_color $YELLOW "📱 OBS/Streamlabs OBS Configuration:"
    echo "   Service: Custom"
    echo "   Server: rtmp://$VPS_IP/live"
    echo "   Stream Key: $STREAM_NAME"
    echo "   Bitrate: $MAX_BITRATE kbps"
    echo
    
    print_color $YELLOW "📊 Monitoring & Management:"
    echo "   Web Dashboard: http://$VPS_IP:8080"
    echo "   Statistics: http://$VPS_IP:8080/stat"
    echo "   Real-time Monitor: ./monitor-streams.sh"
    echo
    
    print_color $YELLOW "📁 Configuration Files Created:"
    echo "   obs-config.txt - OBS Studio settings"
    echo "   streamlabs-config.txt - Streamlabs OBS settings"
    echo "   nginx.conf.backup.* - Configuration backups"
    echo
    
    print_color $YELLOW "🔧 Useful Commands:"
    echo "   Restart service: sudo systemctl restart nginx-rtmp"
    echo "   View logs: sudo journalctl -u nginx-rtmp -f"
    echo "   Test setup: ./test-stream.sh"
    echo "   Monitor streams: ./monitor-streams.sh"
    echo
    
    print_color $BLUE "💡 Pro Tips:"
    echo "   1. Test with a private stream first"
    echo "   2. Monitor the web dashboard during streaming"
    echo "   3. Keep your stream keys secure"
    echo "   4. Check platform-specific requirements"
    echo
    
    print_color $GREEN "🚀 Happy streaming to multiple platforms!"
}

# Main function
main() {
    print_banner
    
    print_color $BLUE "Welcome to the Multi-Platform Streaming Setup Wizard!"
    print_color $YELLOW "This wizard will guide you through the complete setup process."
    echo
    
    # Step 1: Collect VPS information
    collect_vps_info
    echo
    
    # Step 2: Collect streaming platform keys
    collect_stream_keys
    echo
    
    # Step 3: Show configuration summary
    show_configuration_summary
    
    read -p "Is this configuration correct? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_color $YELLOW "Setup cancelled. Run the script again to reconfigure."
        exit 0
    fi
    
    echo
    
    # Step 4: Update configuration files
    update_configuration_files
    echo
    
    # Step 5: Ask about installation
    print_color $BLUE "🤔 Installation Options"
    echo "1. Run full installation now (recommended for new setups)"
    echo "2. Skip installation (if already installed)"
    echo "3. Exit and install manually later"
    echo
    
    read -p "Choose option (1-3): " install_choice
    
    case $install_choice in
        1)
            echo
            if run_installation; then
                echo
                if deploy_configuration; then
                    echo
                    run_tests
                    echo
                    show_final_instructions
                else
                    print_color $YELLOW "⚠️  Configuration deployment failed. You may need to deploy manually."
                fi
            else
                print_color $YELLOW "⚠️  Installation failed. Please check the errors and try again."
            fi
            ;;
        2)
            echo
            if deploy_configuration; then
                echo
                run_tests
                echo
                show_final_instructions
            else
                print_color $YELLOW "⚠️  Configuration deployment failed. You may need to deploy manually."
            fi
            ;;
        3)
            print_color $BLUE "📋 Configuration files have been prepared."
            print_color $YELLOW "To complete setup later:"
            echo "   1. Run: ./install.sh"
            echo "   2. Copy nginx.conf to /usr/local/nginx/conf/"
            echo "   3. Restart service: sudo systemctl restart nginx-rtmp"
            echo "   4. Test with: ./test-stream.sh"
            ;;
        *)
            print_color $RED "❌ Invalid option"
            exit 1
            ;;
    esac
    
    echo
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    print_color $GREEN "🎬 Setup wizard completed! Thank you for using our streaming relay!"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_color $RED "❌ This script should not be run as root!"
    print_color $YELLOW "💡 Please run as a regular user with sudo privileges."
    exit 1
fi

# Run main function
main "$@"