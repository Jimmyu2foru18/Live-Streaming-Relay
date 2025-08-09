# 🚀 StreamRelay Quick Start Guide

**Get streaming to multiple platforms in under 5 minutes!**

This guide will help you choose and set up the best StreamRelay solution for your needs.

## 🎯 Which Solution is Right for You?

### 🥇 **OBS Plugin** (Recommended for Most Users)

**✅ Choose this if you:**
- Already use OBS Studio for streaming
- Want the easiest setup experience
- Prefer familiar OBS interface
- Don't want to pay monthly VPS costs
- Stream occasionally or regularly

**⏱️ Setup Time:** 2-3 minutes

### 🥈 **Windows Desktop App** (Great Alternative)

**✅ Choose this if you:**
- Don't use OBS Studio
- Want a standalone application
- Prefer a dedicated streaming tool
- Use other streaming software (Streamlabs, XSplit, etc.)
- Want maximum compatibility

**⏱️ Setup Time:** 3-5 minutes

### 🥉 **Server Solution** (For Advanced Users)

**✅ Choose this if you:**
- Have technical Linux experience
- Want maximum control and customization
- Need 24/7 streaming capabilities
- Have a VPS or dedicated server
- Want to host for multiple streamers

**⏱️ Setup Time:** 10-15 minutes
**💰 Cost:** $5-20/month for VPS

---

## 🎮 Option 1: OBS Plugin Setup (Recommended)

### Step 1: Prerequisites

1. **Install OBS Studio** (if not already installed):
   - Download from: https://obsproject.com/
   - Version 28.0 or newer required

2. **Get Your Stream Keys**:
   - **Twitch**: https://dashboard.twitch.tv/settings/stream
   - **YouTube**: https://studio.youtube.com/ → Go Live → Stream
   - **Kick**: https://kick.com/dashboard/settings/stream

### Step 2: Build and Install Plugin

1. **Open PowerShell as Administrator** in the project folder

2. **Build and install the plugin**:
   ```powershell
   .\build-obs-plugin.ps1 -InstallPlugin -AutoDetect
   ```

3. **If auto-detection fails, specify paths manually**:
   ```powershell
   .\build-obs-plugin.ps1 -InstallPlugin -OBSPath "C:\Program Files\obs-studio" -Qt6Path "C:\Qt\6.5.0\msvc2019_64"
   ```

### Step 3: Configure in OBS

1. **Restart OBS Studio** completely

2. **Open StreamRelay**:
   - Go to **Tools** → **StreamRelay**

3. **Configure Stream Keys**:
   - Enter your Twitch stream key
   - Enter your YouTube stream key
   - Enter your Kick stream key (optional)
   - Click **Save Configuration**

4. **Start Multi-Platform Streaming**:
   - Click **Start RTMP Server**
   - Configure OBS streaming settings:
     - **Server**: `rtmp://localhost:1935/live`
     - **Stream Key**: `live`
   - Click **Start Streaming** in OBS

### Step 4: Verify Streaming

- Check the **Monitor** tab in StreamRelay
- Verify streams are live on all platforms
- Monitor viewer counts and stream health

---

## 💻 Option 2: Windows Desktop App Setup

### Step 1: Build the Application

1. **Open PowerShell as Administrator** in the project folder

2. **Build with all dependencies**:
   ```powershell
   .\build-desktop-app.ps1 -IncludeDependencies -CreateInstaller
   ```

3. **Wait for build to complete** (may take 5-10 minutes for first build)

### Step 2: Install and Configure

1. **Run the application**:
   - Navigate to `publish` folder
   - Run `StreamRelay.exe`

2. **Configure Stream Keys**:
   - Enter your platform stream keys
   - Set your preferred local RTMP port (default: 1935)
   - Click **Save Settings**

### Step 3: Start Streaming

1. **Start the relay server**:
   - Click **Start Streaming** in StreamRelay
   - Wait for "Server Running" status

2. **Configure your streaming software**:
   - **OBS Studio / Streamlabs / XSplit**:
     - Server: `rtmp://localhost:1935/live`
     - Stream Key: `live`
   - Start streaming in your software

3. **Monitor streams**:
   - Check real-time status in StreamRelay
   - Verify streams are live on all platforms

---

## 🖥️ Option 3: Server Solution Setup

### Step 1: Get a VPS

**Recommended Providers:**
- **DigitalOcean**: $6/month droplet
- **Vultr**: $6/month instance
- **Linode**: $5/month nanode
- **AWS EC2**: t3.micro (free tier eligible)

**Minimum Requirements:**
- Ubuntu 22.04 LTS
- 1GB RAM
- 1 CPU core
- 25GB storage

### Step 2: Server Installation

1. **Connect to your VPS**:
   ```bash
   ssh root@YOUR_VPS_IP
   ```

2. **Upload and run installation**:
   ```bash
   wget https://raw.githubusercontent.com/streamrelay/streamrelay/main/install.sh
   chmod +x install.sh
   ./install.sh
   ```

3. **Run setup wizard**:
   ```bash
   ./setup-wizard.sh
   ```

4. **Follow the interactive prompts** to configure your stream keys

### Step 3: Start Streaming

1. **Configure your streaming software**:
   - Server: `rtmp://YOUR_VPS_IP:1935/live`
   - Stream Key: `live`

2. **Monitor your streams**:
   ```bash
   ./monitor.sh
   ```

---

## 🔧 Common Configuration

### Optimal Streaming Settings

**For 1080p 60fps:**
- **Resolution**: 1920x1080
- **FPS**: 60
- **Bitrate**: 6000 kbps
- **Encoder**: x264 or NVENC (if available)
- **Keyframe Interval**: 2 seconds

**For 720p 30fps (recommended for beginners):**
- **Resolution**: 1280x720
- **FPS**: 30
- **Bitrate**: 3000 kbps
- **Encoder**: x264
- **Keyframe Interval**: 2 seconds

### Platform-Specific Notes

**Twitch:**
- Maximum bitrate: 6000 kbps
- Supports up to 1080p 60fps
- Transcoding available for Partners/Affiliates

**YouTube:**
- Maximum bitrate: 9000 kbps
- Supports up to 4K 60fps
- Automatic transcoding for all streams

**Kick:**
- Maximum bitrate: 6000 kbps
- Supports up to 1080p 60fps
- Growing platform with good discoverability

---

## 🐛 Troubleshooting

### "Port 1935 is already in use"

**Solution 1** (Desktop App/Plugin):
- Change RTMP port to 1936 or 1937 in settings
- Update your streaming software accordingly

**Solution 2** (Find conflicting process):
```powershell
netstat -ano | findstr :1935
taskkill /PID [PID_NUMBER] /F
```

### "Stream key invalid" or "Connection failed"

1. **Double-check stream keys**:
   - Copy-paste directly from platform dashboards
   - Ensure no extra spaces or characters

2. **Verify platform settings**:
   - Enable streaming on YouTube (may require phone verification)
   - Check Twitch stream key hasn't expired
   - Ensure Kick account is in good standing

### "Plugin not loading in OBS"

1. **Check OBS version**: Must be 28.0 or newer
2. **Verify installation path**: Plugin should be in `obs-plugins\64bit\`
3. **Check OBS logs**: Help → Log Files → Current Log
4. **Reinstall plugin**:
   ```powershell
   .\build-obs-plugin.ps1 -InstallPlugin -Clean
   ```

### "Build failed" errors

**For Desktop App:**
1. Install .NET 6.0 SDK: https://dotnet.microsoft.com/download
2. Run as Administrator
3. Check Windows Defender isn't blocking

**For OBS Plugin:**
1. Install Visual Studio 2019+ with C++ tools
2. Install CMake: https://cmake.org/download/
3. Install Qt6: https://www.qt.io/download

---

## 🎉 Success! You're Multi-Platform Streaming!

### What's Next?

1. **Test your setup**:
   - Do a short test stream to verify everything works
   - Check stream quality on all platforms
   - Test stopping and starting streams

2. **Optimize your settings**:
   - Adjust bitrate based on your upload speed
   - Fine-tune encoder settings for your hardware
   - Set up scenes and sources in OBS

3. **Engage your audience**:
   - Announce multi-platform streaming to your followers
   - Use platform-specific features (chat, polls, etc.)
   - Monitor analytics across all platforms

4. **Advanced features**:
   - Set up stream alerts and notifications
   - Configure automatic recording
   - Explore platform-specific integrations

### 📊 Monitoring Your Success

- **Real-time viewers**: Check each platform's dashboard
- **Stream health**: Monitor bitrate and dropped frames
- **Growth metrics**: Track follower growth across platforms
- **Revenue**: Compare monetization across platforms

---

## 🆘 Need Help?

- **GitHub Issues**: https://github.com/streamrelay/streamrelay/issues
- **Documentation**: README-StreamRelay.md
- **Project Structure**: PROJECT-STRUCTURE.md
- **Build Scripts**: Use `-help` parameter for detailed options

**Happy Streaming! 🎮📺🎬**

---

*StreamRelay - Making multi-platform streaming accessible to everyone!*