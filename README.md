# Multi-Platform Live Streaming Relay

**Stream once, broadcast everywhere!** This setup allows you to stream from OBS/Streamlabs OBS to a single VPS server, which then relays your stream to **Kick**, **YouTube**, and **Twitch** simultaneously, each with optimized bitrates.

## Features

- ✅ **Single Upload**: Stream once from your PC, relay to multiple platforms
- ✅ **Optimized Bitrates**: Platform-specific encoding (Twitch 6Mbps, YouTube 12Mbps, Kick 10Mbps)
- ✅ **Real-time Monitoring**: Web dashboard to monitor all streams
- ✅ **Auto-restart**: Systemd service for automatic startup
- ✅ **Easy Configuration**: Automated scripts for setup and key management
- ✅ **Cost Effective**: No third-party service fees, you control everything

## Architecture

```
[ OBS / Streamlabs OBS ]
         |
         v (12-15 Mbps)
[ VPS with Nginx RTMP + FFmpeg ]
         |------------> Twitch (6 Mbps)
         |------------> YouTube (12 Mbps)
         |------------> Kick (10 Mbps)
```

## Requirements

### VPS Specifications
- **Minimum**: 2 vCPU, 4 GB RAM, 20 GB SSD
- **Recommended**: 4 vCPU, 8 GB RAM, 40 GB SSD
- **Operating System**: Ubuntu 22.04 LTS
- **Network**: Unlimited bandwidth or high data allowance

### Recommended VPS Providers
- [DigitalOcean](https://digitalocean.com) - $24/month (4 vCPU, 8GB RAM)
- [Vultr](https://vultr.com) - $24/month (4 vCPU, 8GB RAM)
- [Linode](https://linode.com) - $24/month (4 vCPU, 8GB RAM)
- [Hetzner](https://hetzner.com) - €15.29/month (4 vCPU, 8GB RAM)

## Start

### Step 1: Get Your VPS Ready

1. **Create a VPS** with Ubuntu 22.04 LTS
2. **Connect via SSH**:
   ```bash
   ssh root@YOUR_VPS_IP
   ```
3. **Create a non-root user** (if not already done):
   ```bash
   adduser streamuser
   usermod -aG sudo streamuser
   su - streamuser
   ```

### Step 2: Download and Run Installation

1. **Download the setup files**:
   ```bash
   wget https://github.com/yourusername/streaming-relay/archive/main.zip
   unzip main.zip
   cd streaming-relay-main
   ```
   
   *Or if you have the files locally, upload them to your VPS:*
   ```bash
   scp *.sh *.conf streamuser@YOUR_VPS_IP:~/
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x *.sh
   ```

3. **Run the installation**:
   ```bash
   ./install.sh
   ```

   This will:
   - Update your system
   - Install all dependencies (FFmpeg, build tools)
   - Download and compile Nginx with RTMP module
   - Set up systemd service
   - Create monitoring web interface

### Step 3: Configure Your Stream Keys

1. **Get your stream keys** from each platform:
   - **Twitch**: https://dashboard.twitch.tv/settings/stream
   - **YouTube**: https://studio.youtube.com → Go Live → Stream
   - **Kick**: https://kick.com/dashboard/settings/stream

2. **Run the configuration script**:
   ```bash
   ./configure-keys.sh
   ```
   
   Follow the prompts to enter your stream keys.

3. **Start the service**:
   ```bash
   sudo systemctl start nginx-rtmp
   sudo systemctl status nginx-rtmp
   ```

## OBS/Streamlabs OBS Setup

### OBS Studio Configuration

1. **Open OBS Studio**
2. **Go to Settings → Stream**
3. **Configure as follows**:
   - **Service**: Custom
   - **Server**: `rtmp://YOUR_VPS_IP/live`
   - **Stream Key**: `your_stream_name` (can be anything, e.g., "main", "stream1")

4. **Go to Settings → Output**
   - **Output Mode**: Advanced
   - **Encoder**: x264 (or NVENC if you have NVIDIA GPU)
   - **Bitrate**: 12000-15000 kbps
   - **Keyframe Interval**: 2 seconds
   - **Preset**: veryfast (for x264)

### Streamlabs OBS Configuration

1. **Open Streamlabs OBS**
2. **Go to Settings → Stream**
3. **Configure as follows**:
   - **Stream Type**: Custom Ingest
   - **URL**: `rtmp://YOUR_VPS_IP/live`
   - **Stream Key**: `your_stream_name`

4. **Go to Settings → Output**
   - **Video Bitrate**: 12000-15000 kbps
   - **Audio Bitrate**: 160 kbps
   - **Encoder**: x264 (or Hardware if available)

## Monitoring Your Streams

### Web Dashboard
Access your streaming dashboard at: `http://YOUR_VPS_IP:8080`

### Command Line Monitoring
```bash
# Check service status
sudo systemctl status nginx-rtmp

# View real-time logs
sudo journalctl -u nginx-rtmp -f

# Check nginx processes
ps aux | grep nginx

# Monitor system resources
htop
```

## Configuration

### Custom Bitrates
Edit `/usr/local/nginx/conf/nginx.conf` to adjust bitrates:

```nginx
# For Twitch (adjust -b:v value)
exec ffmpeg -i rtmp://localhost/twitch/$name 
    -c:v libx264 -preset veryfast -tune zerolatency
    -b:v 5000k -maxrate 5000k -bufsize 5000k  # Change this line
    ...
```

### GPU Acceleration
If your VPS has an NVIDIA GPU, enable NVENC:

```nginx
# Replace libx264 with h264_nvenc
exec ffmpeg -i rtmp://localhost/twitch/$name 
    -c:v h264_nvenc -preset fast
    -b:v 6000k -maxrate 6000k -bufsize 6000k
    ...
```

### Pass-Through Mode (No Re-encoding)
For lower CPU usage, edit the `live` application:

```nginx
application live {
    live on;
    record off;
    
    # Direct push without re-encoding
    push rtmp://live.twitch.tv/app/YOUR_TWITCH_KEY;
    push rtmp://a.rtmp.youtube.com/live2/YOUR_YOUTUBE_KEY;
    push rtmp://fa.kick.com/app/YOUR_KICK_KEY;
}
```

**Note**: This sends the same bitrate to all platforms (limited by Twitch's 6Mbps)

## Troubleshooting

### Common Issues

**1. Stream not starting**
```bash
# Check if nginx is running
sudo systemctl status nginx-rtmp

# Check configuration syntax
sudo /usr/local/nginx/sbin/nginx -t

# View error logs
sudo journalctl -u nginx-rtmp -n 50
```

**2. High CPU usage**
- Reduce bitrates in configuration
- Use hardware encoding (NVENC/QuickSync)
- Upgrade VPS specifications

**3. Stream dropping/buffering**
- Check VPS bandwidth limits
- Reduce output bitrates
- Check network connectivity: `ping google.com`

**4. Platform-specific issues**
- Verify stream keys are correct
- Check platform-specific requirements
- Test with one platform at a time

### Commands

```bash
# Restart the service
sudo systemctl restart nginx-rtmp

# Reload configuration without stopping streams
sudo /usr/local/nginx/sbin/nginx -s reload

# Stop all streams
sudo systemctl stop nginx-rtmp

# View configuration
cat /usr/local/nginx/conf/nginx.conf

# Check disk space
df -h

# Check memory usage
free -h

# Monitor network usage
iftop
```

## Security Considerations

### Firewall Setup
```bash
# Install UFW
sudo apt install ufw

# Allow SSH
sudo ufw allow ssh

# Allow RTMP (port 1935)
sudo ufw allow 1935

# Allow web interface (port 8080)
sudo ufw allow 8080

# Enable firewall
sudo ufw enable
```

### Stream Key Security
- Never share your stream keys publicly
- Regenerate keys if compromised
- Use strong, unique keys for each platform
- Consider IP whitelisting for additional security

## Performance Optimization

### VPS Optimization
```bash
# Increase file descriptor limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize network settings
echo "net.core.rmem_max = 134217728" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 134217728" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### FFmpeg Optimization
- Use `-preset veryfast` for lowest latency
- Use `-preset fast` for better quality
- Use `-tune zerolatency` for live streaming
- Adjust `-threads` based on CPU cores

---

**Made with ❤️ for the streaming community**
