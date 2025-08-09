#!/bin/bash

# Stream Keys Configuration Script
# This script helps you configure your streaming platform keys

set -e

echo "=== Stream Keys Configuration ==="
echo "This script will help you configure your streaming platform keys"
echo ""

# Check if nginx config exists
if [ ! -f "/usr/local/nginx/conf/nginx.conf" ]; then
    echo "❌ Nginx configuration not found. Please run the installation script first."
    exit 1
fi

# Function to validate stream key format
validate_key() {
    local key="$1"
    local platform="$2"
    
    if [ -z "$key" ]; then
        echo "❌ Empty key provided for $platform"
        return 1
    fi
    
    if [ ${#key} -lt 10 ]; then
        echo "⚠️  Warning: $platform key seems too short (${#key} characters)"
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Get stream keys from user
echo "📝 Please enter your streaming platform keys:"
echo "(You can find these in your platform's streaming/creator dashboard)"
echo ""

echo "🟣 Twitch Stream Key:"
echo "   Get it from: https://dashboard.twitch.tv/settings/stream"
read -p "   Enter key: " twitch_key
echo ""

echo "🔴 YouTube Stream Key:"
echo "   Get it from: https://studio.youtube.com/channel/UC.../livestreaming"
read -p "   Enter key: " youtube_key
echo ""

echo "🟢 Kick Stream Key:"
echo "   Get it from: https://kick.com/dashboard/settings/stream"
read -p "   Enter key: " kick_key
echo ""

# Validate keys
echo "🔍 Validating keys..."
validate_key "$twitch_key" "Twitch" || exit 1
validate_key "$youtube_key" "YouTube" || exit 1
validate_key "$kick_key" "Kick" || exit 1

echo "✅ All keys validated!"
echo ""

# Backup original config
echo "📋 Creating backup of current configuration..."
sudo cp /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)

# Replace keys in configuration
echo "🔧 Updating configuration with your keys..."
sudo sed -i "s/YOUR_TWITCH_KEY/$twitch_key/g" /usr/local/nginx/conf/nginx.conf
sudo sed -i "s/YOUR_YOUTUBE_KEY/$youtube_key/g" /usr/local/nginx/conf/nginx.conf
sudo sed -i "s/YOUR_KICK_KEY/$kick_key/g" /usr/local/nginx/conf/nginx.conf

# Test configuration
echo "🧪 Testing nginx configuration..."
if sudo /usr/local/nginx/sbin/nginx -t; then
    echo "✅ Configuration test passed!"
else
    echo "❌ Configuration test failed! Restoring backup..."
    sudo cp /usr/local/nginx/conf/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) /usr/local/nginx/conf/nginx.conf
    exit 1
fi

# Restart service
echo "🔄 Restarting nginx service..."
if sudo systemctl restart nginx-rtmp; then
    echo "✅ Service restarted successfully!"
else
    echo "❌ Failed to restart service. Check logs with: sudo journalctl -u nginx-rtmp -f"
    exit 1
fi

# Show status
echo ""
echo "📊 Service Status:"
sudo systemctl status nginx-rtmp --no-pager -l

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "🎯 Your streaming setup:"
echo "   📡 RTMP URL: rtmp://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')/live"
echo "   🔑 Stream Key: your_stream_name (use any name you want)"
echo ""
echo "🌐 Monitor your streams at:"
echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP'):8080"
echo ""
echo "🎥 OBS/Streamlabs OBS Settings:"
echo "   Service: Custom"
echo "   Server: rtmp://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')/live"
echo "   Stream Key: your_stream_name"
echo "   Bitrate: 12000-15000 kbps (recommended)"
echo ""
echo "🔥 Ready to stream to all platforms simultaneously!"
echo "💡 Tip: Test with a private stream first before going live"