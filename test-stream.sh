#!/bin/bash

# Stream Testing Script
# This script helps test your streaming setup

set -e

echo "=== Multi-Platform Streaming Test ==="
echo "This script will help you test your streaming setup"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a service is running
check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        print_status $GREEN "✅ $service is running"
        return 0
    else
        print_status $RED "❌ $service is not running"
        return 1
    fi
}

# Function to check if a port is listening
check_port() {
    local port=$1
    local description=$2
    if netstat -tuln | grep -q ":$port "; then
        print_status $GREEN "✅ Port $port ($description) is listening"
        return 0
    else
        print_status $RED "❌ Port $port ($description) is not listening"
        return 1
    fi
}

# Function to test RTMP endpoint
test_rtmp() {
    local endpoint=$1
    local description=$2
    
    print_status $BLUE "🧪 Testing $description..."
    
    # Use ffmpeg to test RTMP connection
    timeout 10 ffmpeg -f lavfi -i testsrc2=duration=5:size=320x240:rate=30 \
        -f lavfi -i sine=frequency=1000:duration=5 \
        -c:v libx264 -preset ultrafast -tune zerolatency \
        -b:v 1000k -c:a aac -b:a 128k \
        -f flv "$endpoint" -y /dev/null 2>/dev/null && \
        print_status $GREEN "✅ $description connection successful" || \
        print_status $YELLOW "⚠️  $description connection failed (this might be normal if keys aren't configured)"
}

echo "🔍 System Check"
echo "================="

# Check if running as non-root
if [[ $EUID -eq 0 ]]; then
    print_status $YELLOW "⚠️  Running as root. Consider using a non-root user."
else
    print_status $GREEN "✅ Running as non-root user"
fi

# Check system resources
echo ""
echo "💻 System Resources"
echo "==================="

# CPU cores
cpu_cores=$(nproc)
print_status $BLUE "🔧 CPU Cores: $cpu_cores"
if [ $cpu_cores -ge 4 ]; then
    print_status $GREEN "✅ Sufficient CPU cores for streaming"
elif [ $cpu_cores -ge 2 ]; then
    print_status $YELLOW "⚠️  Minimum CPU cores. Consider upgrading for better performance."
else
    print_status $RED "❌ Insufficient CPU cores. Upgrade recommended."
fi

# Memory
mem_total=$(free -m | awk 'NR==2{printf "%.0f", $2}')
print_status $BLUE "🧠 Total Memory: ${mem_total}MB"
if [ $mem_total -ge 8000 ]; then
    print_status $GREEN "✅ Excellent memory for streaming"
elif [ $mem_total -ge 4000 ]; then
    print_status $GREEN "✅ Sufficient memory for streaming"
elif [ $mem_total -ge 2000 ]; then
    print_status $YELLOW "⚠️  Minimum memory. Monitor usage closely."
else
    print_status $RED "❌ Insufficient memory. Upgrade recommended."
fi

# Disk space
disk_free=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
print_status $BLUE "💾 Free Disk Space: ${disk_free}GB"
if [ $disk_free -ge 20 ]; then
    print_status $GREEN "✅ Sufficient disk space"
else
    print_status $YELLOW "⚠️  Low disk space. Consider cleanup."
fi

echo ""
echo "🔧 Service Status"
echo "================="

# Check nginx-rtmp service
check_service "nginx-rtmp" || {
    print_status $YELLOW "💡 Try: sudo systemctl start nginx-rtmp"
}

echo ""
echo "🌐 Network Status"
echo "================="

# Check ports
check_port "1935" "RTMP"
check_port "8080" "Web Interface"

# Get public IP
public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to detect")
print_status $BLUE "🌍 Public IP: $public_ip"

echo ""
echo "📋 Configuration Check"
echo "======================"

# Check if nginx config exists
if [ -f "/usr/local/nginx/conf/nginx.conf" ]; then
    print_status $GREEN "✅ Nginx configuration found"
    
    # Check if keys are configured
    if grep -q "YOUR_TWITCH_KEY" /usr/local/nginx/conf/nginx.conf; then
        print_status $YELLOW "⚠️  Twitch key not configured"
    else
        print_status $GREEN "✅ Twitch key configured"
    fi
    
    if grep -q "YOUR_YOUTUBE_KEY" /usr/local/nginx/conf/nginx.conf; then
        print_status $YELLOW "⚠️  YouTube key not configured"
    else
        print_status $GREEN "✅ YouTube key configured"
    fi
    
    if grep -q "YOUR_KICK_KEY" /usr/local/nginx/conf/nginx.conf; then
        print_status $YELLOW "⚠️  Kick key not configured"
    else
        print_status $GREEN "✅ Kick key configured"
    fi
else
    print_status $RED "❌ Nginx configuration not found"
fi

# Test nginx configuration
if [ -f "/usr/local/nginx/sbin/nginx" ]; then
    if sudo /usr/local/nginx/sbin/nginx -t 2>/dev/null; then
        print_status $GREEN "✅ Nginx configuration is valid"
    else
        print_status $RED "❌ Nginx configuration has errors"
    fi
else
    print_status $RED "❌ Nginx binary not found"
fi

echo ""
echo "🧪 Connection Tests"
echo "==================="

# Test local RTMP endpoint
if command -v ffmpeg >/dev/null 2>&1; then
    print_status $GREEN "✅ FFmpeg is available for testing"
    
    # Test local RTMP
    test_rtmp "rtmp://localhost/live/test" "Local RTMP"
else
    print_status $YELLOW "⚠️  FFmpeg not found. Cannot perform connection tests."
fi

echo ""
echo "📊 Current Statistics"
echo "====================="

# Show current connections if nginx is running
if systemctl is-active --quiet nginx-rtmp; then
    print_status $BLUE "📈 Checking current streams..."
    curl -s "http://localhost:8080/stat" | grep -E "(name|publishing|clients)" | head -10 || \
        print_status $YELLOW "⚠️  No active streams or stats unavailable"
else
    print_status $YELLOW "⚠️  Service not running, cannot show statistics"
fi

echo ""
echo "🎯 OBS Configuration"
echo "===================="
print_status $BLUE "📺 OBS/Streamlabs OBS Settings:"
echo "   Service: Custom"
echo "   Server: rtmp://$public_ip/live"
echo "   Stream Key: your_stream_name (any name you choose)"
echo "   Bitrate: 12000-15000 kbps"
echo ""
print_status $BLUE "🌐 Monitor streams at: http://$public_ip:8080"

echo ""
echo "💡 Quick Commands"
echo "================="
echo "Start service:    sudo systemctl start nginx-rtmp"
echo "Stop service:     sudo systemctl stop nginx-rtmp"
echo "Restart service:  sudo systemctl restart nginx-rtmp"
echo "View logs:        sudo journalctl -u nginx-rtmp -f"
echo "Test config:      sudo /usr/local/nginx/sbin/nginx -t"
echo "Configure keys:   ./configure-keys.sh"

echo ""
if systemctl is-active --quiet nginx-rtmp && \
   [ -f "/usr/local/nginx/conf/nginx.conf" ] && \
   ! grep -q "YOUR_TWITCH_KEY" /usr/local/nginx/conf/nginx.conf; then
    print_status $GREEN "🎉 System appears ready for streaming!"
    print_status $GREEN "🚀 You can now start streaming from OBS/Streamlabs OBS"
else
    print_status $YELLOW "⚠️  System needs configuration. Run ./configure-keys.sh to set up your stream keys."
fi

echo ""
print_status $BLUE "📋 Test completed! Check the results above."