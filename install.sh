#!/bin/bash

# Multi-Platform Live Streaming Relay Installation Script
# For Ubuntu 22.04 LTS

set -e

echo "=== Multi-Platform Live Streaming Relay Setup ==="
echo "This script will install and configure Nginx with RTMP module for streaming to Kick, YouTube, and Twitch"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Update system
echo "[1/7] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "[2/7] Installing dependencies..."
sudo apt install -y build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev \
    ffmpeg git wget curl unzip software-properties-common

# Create directories
echo "[3/7] Creating directories..."
sudo mkdir -p /usr/local/src
sudo mkdir -p /tmp/hls
sudo chmod 755 /tmp/hls

# Download and compile Nginx with RTMP module
echo "[4/7] Downloading and compiling Nginx with RTMP module..."
cd /usr/local/src

# Download Nginx
sudo wget -q http://nginx.org/download/nginx-1.25.5.tar.gz
sudo tar -xzf nginx-1.25.5.tar.gz

# Clone RTMP module
sudo git clone https://github.com/arut/nginx-rtmp-module.git

# Compile Nginx
cd nginx-1.25.5
sudo ./configure \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_slice_module \
    --with-file-aio \
    --with-http_v2_module \
    --add-module=../nginx-rtmp-module

sudo make -j$(nproc)
sudo make install

# Create nginx user
echo "[5/7] Creating nginx user..."
sudo useradd --system --home /var/cache/nginx --shell /sbin/nologin --comment "nginx user" --user-group nginx || true

# Copy configuration file
echo "[6/7] Installing configuration..."
sudo cp /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.backup
sudo cp nginx.conf /usr/local/nginx/conf/nginx.conf

# Install systemd service
echo "[7/7] Installing systemd service..."
sudo cp nginx-rtmp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable nginx-rtmp

# Create web interface
echo "Creating web monitoring interface..."
sudo mkdir -p /usr/local/nginx/html
sudo tee /usr/local/nginx/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>RTMP Streaming Relay Status</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0; }
        .status-card { background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #007bff; }
        .status-card h3 { margin-top: 0; color: #495057; }
        .btn { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; margin: 5px; }
        .btn:hover { background: #0056b3; }
        iframe { width: 100%; height: 600px; border: 1px solid #ddd; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎥 Multi-Platform Streaming Relay</h1>
        
        <div class="status-grid">
            <div class="status-card">
                <h3>📊 Server Status</h3>
                <p>Monitor active streams and server statistics</p>
                <a href="/stat" class="btn" target="_blank">View Statistics</a>
            </div>
            
            <div class="status-card">
                <h3>🔧 Configuration</h3>
                <p>RTMP URL: <code>rtmp://YOUR_SERVER_IP/live</code></p>
                <p>Stream Key: <code>your_stream_name</code></p>
            </div>
            
            <div class="status-card">
                <h3>🎯 Platforms</h3>
                <p>✅ Twitch (6 Mbps)</p>
                <p>✅ YouTube (12 Mbps)</p>
                <p>✅ Kick (10 Mbps)</p>
            </div>
        </div>
        
        <h2>📈 Live Statistics</h2>
        <iframe src="/stat"></iframe>
    </div>
</body>
</html>
EOF

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Next steps:"
echo "1. Edit /usr/local/nginx/conf/nginx.conf and replace:"
echo "   - YOUR_TWITCH_KEY with your Twitch stream key"
echo "   - YOUR_YOUTUBE_KEY with your YouTube stream key"
echo "   - YOUR_KICK_KEY with your Kick stream key"
echo ""
echo "2. Start the service:"
echo "   sudo systemctl start nginx-rtmp"
echo ""
echo "3. Check status:"
echo "   sudo systemctl status nginx-rtmp"
echo ""
echo "4. Monitor streams at: http://$(curl -s ifconfig.me):8080"
echo ""
echo "5. Configure OBS:"
echo "   - Service: Custom"
echo "   - Server: rtmp://$(curl -s ifconfig.me)/live"
echo "   - Stream Key: your_stream_name"
echo ""
echo "🎉 Happy streaming!"