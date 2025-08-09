# 🎥 OBS & Streamlabs OBS Setup Guide

This guide will walk you through setting up **OBS Studio** and **Streamlabs OBS** to work with your multi-platform streaming relay server.

## 📋 Prerequisites

- ✅ VPS server running with nginx-rtmp configured
- ✅ Stream keys configured for Twitch, YouTube, and Kick
- ✅ OBS Studio or Streamlabs OBS installed
- ✅ Stable internet connection (upload speed ≥ 20 Mbps recommended)

---

## 🎮 OBS Studio Setup

### Step 1: Download and Install OBS Studio

1. **Download OBS Studio** from: https://obsproject.com/
2. **Install** following the setup wizard
3. **Launch OBS Studio**

### Step 2: Configure Stream Settings

1. **Open Settings**
   - Click `File` → `Settings` (or press `Ctrl+,`)

2. **Go to Stream Tab**
   - Click `Stream` in the left sidebar

3. **Configure Stream Settings**:
   ```
   Service: Custom...
   Server: rtmp://YOUR_VPS_IP/live
   Stream Key: your_stream_name
   ```
   
   **Example**:
   ```
   Service: Custom...
   Server: rtmp://203.0.113.1/live
   Stream Key: main_stream
   ```

4. **Click Apply**

### Step 3: Configure Output Settings

1. **Go to Output Tab**
   - Click `Output` in the left sidebar

2. **Set Output Mode**
   - Change `Output Mode` to `Advanced`

3. **Configure Streaming Tab**:
   ```
   Encoder: x264 (or Hardware if available)
   Rate Control: CBR
   Bitrate: 12000 Kbps
   Keyframe Interval: 2
   CPU Usage Preset: veryfast
   Profile: high
   Tune: (none)
   ```

4. **Configure Audio Tab**:
   ```
   Audio Bitrate: 160
   ```

### Step 4: Configure Video Settings

1. **Go to Video Tab**
   - Click `Video` in the left sidebar

2. **Configure Video Settings**:
   ```
   Base (Canvas) Resolution: 1920x1080
   Output (Scaled) Resolution: 1920x1080
   Downscale Filter: Lanczos
   Common FPS Values: 30 or 60
   ```

### Step 5: Configure Advanced Settings

1. **Go to Advanced Tab**
   - Click `Advanced` in the left sidebar

2. **Configure Network Settings**:
   ```
   Bind to IP: Default
   Enable Dynamic Bitrate: ✅ (checked)
   ```

3. **Click OK** to save all settings

### Step 6: Test Your Setup

1. **Add a Source**
   - Click `+` in Sources box
   - Add `Display Capture` or `Window Capture`

2. **Start Streaming**
   - Click `Start Streaming` button
   - Check your server dashboard at `http://YOUR_VPS_IP:8080`

---

## 🌟 Streamlabs OBS Setup

### Step 1: Download and Install Streamlabs OBS

1. **Download Streamlabs OBS** from: https://streamlabs.com/
2. **Install** following the setup wizard
3. **Launch Streamlabs OBS**

### Step 2: Configure Stream Settings

1. **Open Settings**
   - Click the gear icon ⚙️ in the bottom left

2. **Go to Stream Tab**
   - Click `Stream` in the left sidebar

3. **Configure Stream Settings**:
   ```
   Stream Type: Custom Ingest
   URL: rtmp://YOUR_VPS_IP/live
   Stream Key: your_stream_name
   ```

4. **Click Done**

### Step 3: Configure Output Settings

1. **Go to Output Tab**
   - Click `Output` in the left sidebar

2. **Configure Video Settings**:
   ```
   Video Bitrate: 12000 Kbps
   Encoder: x264 (Software) or Hardware
   ```

3. **Configure Audio Settings**:
   ```
   Audio Bitrate: 160 Kbps
   Sample Rate: 44.1 kHz
   ```

### Step 4: Configure Video Settings

1. **Go to Video Tab**
   - Click `Video` in the left sidebar

2. **Configure Video Settings**:
   ```
   Base Resolution: 1920x1080
   Output Resolution: 1920x1080
   FPS: 30 or 60
   ```

3. **Click Done**

### Step 5: Test Your Setup

1. **Add a Source**
   - Click `+` in Sources
   - Add `Display Capture` or `Game Capture`

2. **Start Streaming**
   - Click `Go Live` button
   - Monitor at `http://YOUR_VPS_IP:8080`

---

## ⚙️ Optimal Settings by Hardware

### 🖥️ High-End PC (RTX 3070+, i7-9700K+)
```
Encoder: NVENC H.264 (Hardware)
Bitrate: 15000 Kbps
Preset: Quality
Profile: High
Keyframe Interval: 2
B-frames: 2
```

### 💻 Mid-Range PC (GTX 1660+, i5-8400+)
```
Encoder: x264 (Software)
Bitrate: 12000 Kbps
CPU Preset: fast
Profile: high
Keyframe Interval: 2
```

### 📱 Budget PC (GTX 1050+, i3-8100+)
```
Encoder: x264 (Software)
Bitrate: 8000 Kbps
CPU Preset: veryfast
Profile: main
Keyframe Interval: 2
```

---

## 🔧 Advanced Configuration

### Hardware Encoding (NVIDIA)

If you have an NVIDIA GPU (GTX 1050 or newer):

1. **In OBS Output Settings**:
   ```
   Encoder: NVENC H.264
   Rate Control: CBR
   Bitrate: 12000
   Keyframe Interval: 2
   Preset: Quality
   Profile: high
   Look-ahead: ✅ (checked)
   Psycho Visual Tuning: ✅ (checked)
   ```

### Hardware Encoding (AMD)

If you have an AMD GPU (RX 400 series or newer):

1. **In OBS Output Settings**:
   ```
   Encoder: AMD HW H.264
   Rate Control: CBR
   Bitrate: 12000
   Keyframe Interval: 2
   Quality Preset: Quality
   Profile: high
   ```

### Intel Quick Sync

If you have Intel integrated graphics (7th gen or newer):

1. **In OBS Output Settings**:
   ```
   Encoder: Intel Quick Sync H.264
   Rate Control: CBR
   Bitrate: 12000
   Keyframe Interval: 2
   Target Usage: quality
   Profile: high
   ```

---

## 🎯 Platform-Specific Recommendations

### For Gaming Streams
```
Resolution: 1920x1080
FPS: 60
Bitrate: 12000-15000 Kbps
Encoder: Hardware (NVENC/AMD/QuickSync)
Game Capture: Use "Game Capture" source
```

### For Just Chatting/IRL
```
Resolution: 1920x1080
FPS: 30
Bitrate: 8000-12000 Kbps
Encoder: x264 (Software)
Camera: Use "Video Capture Device"
```

### For Music/Audio Focus
```
Resolution: 1280x720
FPS: 30
Bitrate: 6000-8000 Kbps
Audio Bitrate: 320 Kbps
Audio Sample Rate: 48 kHz
```

---

## 🚨 Troubleshooting

### Common Issues

#### ❌ "Failed to connect to server"

**Solutions**:
1. Check VPS IP address is correct
2. Verify nginx-rtmp service is running: `sudo systemctl status nginx-rtmp`
3. Check firewall allows port 1935: `sudo ufw status`
4. Test connection: Run `test-obs-connection.bat` (Windows)

#### ❌ "Dropped frames" or "High encoding"

**Solutions**:
1. Lower bitrate (try 8000 Kbps)
2. Change encoder preset to "veryfast"
3. Reduce resolution to 1280x720
4. Close unnecessary programs
5. Use hardware encoding if available

#### ❌ "Stream appears offline on platforms"

**Solutions**:
1. Verify stream keys are correctly configured
2. Check server logs: `sudo journalctl -u nginx-rtmp -f`
3. Test each platform individually
4. Ensure platforms allow your stream settings

#### ❌ "Audio out of sync"

**Solutions**:
1. Set keyframe interval to 2 seconds
2. Use CBR (Constant Bitrate)
3. Check audio sample rate (44.1 kHz recommended)
4. Disable "Enable Dynamic Bitrate" in Advanced settings

### Performance Optimization

#### For Better Quality
```
1. Increase bitrate (up to 15000 Kbps)
2. Use "fast" or "medium" x264 preset
3. Enable "Psycho Visual Tuning" (NVENC)
4. Use 60 FPS for gaming content
```

#### For Better Performance
```
1. Use hardware encoding (NVENC/AMD/QuickSync)
2. Lower resolution to 1280x720
3. Use "veryfast" or "ultrafast" preset
4. Reduce FPS to 30
5. Close browser and unnecessary apps
```

---

## 📊 Monitoring Your Stream

### OBS Statistics

1. **View → Stats**
   - Monitor dropped frames
   - Check network status
   - Watch CPU usage

2. **Key Metrics to Watch**:
   ```
   Dropped Frames: Should be < 1%
   CPU Usage: Should be < 80%
   Memory Usage: Monitor for leaks
   Network: Should show stable connection
   ```

### Server Dashboard

Monitor your streams at: `http://YOUR_VPS_IP:8080`

**What to check**:
- ✅ All three platforms receiving stream
- ✅ Bitrates are correct for each platform
- ✅ No connection errors
- ✅ Server CPU/memory usage is reasonable

---

## 🎉 Going Live Checklist

### Before You Stream

- [ ] **Test connection** with `test-obs-connection.bat`
- [ ] **Check server status** at dashboard
- [ ] **Verify all platforms** are configured
- [ ] **Test audio levels** and quality
- [ ] **Check scene transitions** work properly
- [ ] **Start with private stream** to test

### During Stream

- [ ] **Monitor dropped frames** in OBS stats
- [ ] **Check server dashboard** periodically
- [ ] **Watch chat** on all platforms
- [ ] **Monitor audio levels** for consistency

### After Stream

- [ ] **Stop streaming** in OBS
- [ ] **Check server logs** for any errors
- [ ] **Review stream quality** on each platform
- [ ] **Note any issues** for next time

---

## 💡 Pro Tips

### Stream Quality
1. **Use 2-second keyframe interval** for best compatibility
2. **Test different bitrates** to find your sweet spot
3. **Monitor all platforms** during stream
4. **Have backup scenes** ready for technical issues

### Performance
1. **Close unnecessary programs** before streaming
2. **Use Game Mode** on Windows 10/11
3. **Set OBS to High Priority** in Task Manager
4. **Use wired internet** connection when possible

### Reliability
1. **Always test before going live**
2. **Have backup streaming method** ready
3. **Monitor server resources** regularly
4. **Keep stream keys secure** and private

---

## 🆘 Getting Help

If you encounter issues:

1. **Check the logs**:
   ```bash
   sudo journalctl -u nginx-rtmp -f
   ```

2. **Test your connection**:
   ```bash
   ./test-stream.sh
   ```

3. **Monitor in real-time**:
   ```bash
   ./monitor-streams.sh
   ```

4. **Common solutions**:
   - Restart nginx: `sudo systemctl restart nginx-rtmp`
   - Check configuration: `sudo /usr/local/nginx/sbin/nginx -t`
   - Verify keys: `./configure-keys.sh`

---

**🎬 Happy Streaming! You're now ready to broadcast to multiple platforms simultaneously!**