# Multi-Platform Live Streaming Relay (Kick + YouTube + Twitch)

## Overview
This setup lets you stream **once** from OBS (or any RTMP-capable software) to a single VPS, and have the VPS relay your stream to **Kick**, **YouTube**, and **Twitch**, each at its own optimal bitrate.

---

## Why This Setup?
- **Single Upload from Your PC** → Less home bandwidth usage.
- **Platform-Specific Bitrates** → Best quality for Kick & YouTube, Twitch-safe bitrate.
- **Private Relay Server** → No third-party service fees, you control everything.

---

## Architecture
[ OBS / Streamlabs ]  
       |  
       v  
[ VPS with Nginx RTMP + FFmpeg ]  
       |------------> Twitch (6 Mbps)  
       |------------> YouTube (12 Mbps)  
       |------------> Kick (10 Mbps)  

---

## Requirements
- **VPS Specs**
  - Minimum: 2 vCPU, 4 GB RAM (pure relay)
  - Recommended: 4 vCPU, 8 GB RAM (real-time re-encoding)
- **Operating System**: Ubuntu 22.04 LTS
- **Software**: Nginx with RTMP module, FFmpeg

---

## Platform Bitrate Recommendations
| Platform  | Max Bitrate (1080p60) | Codec     | Notes                          |
|-----------|-----------------------|-----------|--------------------------------|
| Kick      | 8,000–10,000 kbps      | H.264     | More lenient than Twitch       |
| Twitch    | 6,000 kbps             | H.264     | Hard limit for non-partners    |
| YouTube   | 8,000–15,000 kbps      | H.264/VP9 | Supports higher quality        |

---

## Installation Steps

### 1. Get a VPS
Choose providers like DigitalOcean, Vultr, Linode, or Hetzner.

### 2. Install Dependencies
    sudo apt update && sudo apt upgrade -y
    sudo apt install build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev ffmpeg -y

### 3. Build Nginx with RTMP Module
    cd /usr/local/src
    wget http://nginx.org/download/nginx-1.25.5.tar.gz
    tar -xvzf nginx-1.25.5.tar.gz
    git clone https://github.com/arut/nginx-rtmp-module.git
    cd nginx-1.25.5
    ./configure --with-http_ssl_module --add-module=../nginx-rtmp-module
    make
    sudo make install

### 4. Configure Nginx
    sudo nano /usr/local/nginx/conf/nginx.conf

Paste this configuration:

    worker_processes auto;
    events { worker_connections 1024; }

    rtmp {
        server {
            listen 1935;
            chunk_size 4096;

            application live {
                live on;
                record off;
            }

            application twitch {
                live on;
                record off;
                exec ffmpeg -i rtmp://localhost/live/$name \
                    -c:v libx264 -preset veryfast -b:v 6000k -maxrate 6000k -bufsize 6000k \
                    -c:a aac -b:a 160k -ar 44100 \
                    -f flv rtmp://live.twitch.tv/app/YOUR_TWITCH_KEY;
            }

            application youtube {
                live on;
                record off;
                exec ffmpeg -i rtmp://localhost/live/$name \
                    -c:v libx264 -preset veryfast -b:v 12000k -maxrate 12000k -bufsize 12000k \
                    -c:a aac -b:a 160k -ar 44100 \
                    -f flv rtmp://a.rtmp.youtube.com/live2/YOUR_YOUTUBE_KEY;
            }

            application kick {
                live on;
                record off;
                exec ffmpeg -i rtmp://localhost/live/$name \
                    -c:v libx264 -preset veryfast -b:v 10000k -maxrate 10000k -bufsize 10000k \
                    -c:a aac -b:a 160k -ar 44100 \
                    -f flv rtmp://fa.kick.com/app/YOUR_KICK_KEY;
            }
        }
    }

    http {
        server {
            listen 8080;
            location /stat {
                rtmp_stat all;
                rtmp_stat_stylesheet stat.xsl;
            }
            location /stat.xsl {
                root /usr/local/nginx/html;
            }
        }
    }

Replace:
- `YOUR_TWITCH_KEY` → Twitch Stream Key  
- `YOUR_YOUTUBE_KEY` → YouTube Stream Key  
- `YOUR_KICK_KEY` → Kick Stream Key  

---

## 5. Start Nginx
    sudo /usr/local/nginx/sbin/nginx

---

## 6. OBS Setup
1. **Service**: Custom  
2. **Server URL**: `rtmp://YOUR_VPS_IP/live`  
3. **Stream Key**: `streamname` (example: `main`)  
4. **OBS Output Bitrate**: ~12–15 Mbps for best quality.  

---

## 7. How It Works
1. OBS sends one high-quality stream to VPS → `/live`.  
2. VPS re-encodes and sends:  
   - `/twitch` at 6 Mbps → Twitch  
   - `/youtube` at 12 Mbps → YouTube  
   - `/kick` at 10 Mbps → Kick  

---

## Optional: Pass-Through Mode (No Re-Encoding)
If your source bitrate is ≤6 Mbps (Twitch limit), skip FFmpeg and just push the same stream to all three:

    application live {
        live on;
        record off;
        push rtmp://live.twitch.tv/app/YOUR_TWITCH_KEY;
        push rtmp://a.rtmp.youtube.com/live2/YOUR_YOUTUBE_KEY;
        push rtmp://fa.kick.com/app/YOUR_KICK_KEY;
    }

This saves CPU but reduces quality for Kick and YouTube.

---

## Auto-Restart After VPS Reboot
Create a systemd service so Nginx starts automatically:

    sudo nano /etc/systemd/system/nginx-rtmp.service

Paste:

    [Unit]
    Description=Nginx RTMP Relay
    After=network.target

    [Service]
    ExecStart=/usr/local/nginx/sbin/nginx -g 'daemon off;'
    ExecReload=/usr/local/nginx/sbin/nginx -s reload
    ExecStop=/usr/local/nginx/sbin/nginx -s stop
    Restart=always

    [Install]
    WantedBy=multi-user.target

Enable and start:
    sudo systemctl daemon-reload
    sudo systemctl enable nginx-rtmp
    sudo systemctl start nginx-rtmp

---

## Final Tips
- Always test with a private stream key before going live.
- Monitor `http://YOUR_VPS_IP:8080/stat` to see connected streams.
- If your VPS supports GPUs, consider NVENC for lower CPU usage.
