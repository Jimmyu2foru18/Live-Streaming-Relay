# StreamRelay - Multi-Platform Streaming Solutions

🎥 **Easy-to-use tools for streaming to multiple platforms simultaneously**

StreamRelay provides two user-friendly solutions for streamers who want to broadcast to multiple platforms (Twitch, YouTube, Kick) at once:

1. **Windows Desktop Application** - Standalone GUI application
2. **OBS Studio Plugin** - Native integration with OBS Studio

## 🚀 Features

### Core Features
- ✅ **Multi-Platform Streaming** - Stream to Twitch, YouTube, and Kick simultaneously
- ✅ **One-Click Setup** - Easy configuration with intuitive GUI
- ✅ **Optimized Encoding** - Platform-specific bitrate optimization
- ✅ **Real-Time Monitoring** - Live stats and connection monitoring
- ✅ **Auto-Reconnect** - Automatic reconnection on stream failures
- ✅ **Secure Key Storage** - Encrypted storage of stream keys
- ✅ **Custom RTMP Support** - Add custom RTMP endpoints
- ✅ **Quality Presets** - Multiple encoding quality options

### Windows Desktop App Features
- 🖥️ **Standalone Operation** - Works independently of OBS
- 🎨 **Modern Dark UI** - Beautiful, streamer-friendly interface
- 💾 **Configuration Backup** - Save and load stream configurations
- 📊 **Built-in Statistics** - Monitor viewer counts and bitrates
- 🔧 **Advanced Settings** - Custom FFmpeg arguments support

### OBS Plugin Features
- 🔌 **Native OBS Integration** - Seamless integration with OBS Studio
- 📱 **Tabbed Interface** - Organized configuration, control, and monitoring
- 🎛️ **OBS Menu Integration** - Access from OBS Tools menu
- 📈 **Live Monitoring** - Real-time stream statistics within OBS
- ⚙️ **Advanced Configuration** - Quality presets and custom settings

## 📋 Requirements

### For Windows Desktop Application
- Windows 10/11 (64-bit)
- .NET 6.0 Runtime
- 4GB RAM minimum
- Stable internet connection (upload speed: 5+ Mbps recommended)

### For OBS Plugin
- OBS Studio 28.0 or later
- Windows 10/11, macOS 10.15+, or Linux (Ubuntu 20.04+)
- Qt6 development libraries
- CMake 3.16 or later (for building)
- 4GB RAM minimum
- Stable internet connection (upload speed: 5+ Mbps recommended)

### Additional Requirements (Both Solutions)
- **Nginx with RTMP module** (automatically handled in desktop app)
- **FFmpeg** (for video transcoding)
- **Stream keys** from your platforms (Twitch, YouTube, Kick)

## 🛠️ Installation

### Windows Desktop Application

1. **Download and Install .NET 6.0 Runtime**
   ```bash
   # Download from Microsoft's official website
   # https://dotnet.microsoft.com/download/dotnet/6.0
   ```

2. **Build the Application**
   ```bash
   cd StreamRelay
   dotnet build --configuration Release
   dotnet publish --configuration Release --self-contained true
   ```

3. **Install Dependencies**
   - Download nginx with RTMP module
   - Download FFmpeg
   - Place both in the application directory under `nginx/` and `ffmpeg/` folders

4. **Run the Application**
   ```bash
   cd bin/Release/net6.0-windows/publish
   ./StreamRelay.exe
   ```

### OBS Studio Plugin

1. **Install Build Dependencies**
   ```bash
   # Windows (using vcpkg)
   vcpkg install qt6 obs-studio
   
   # macOS (using Homebrew)
   brew install qt6 cmake ninja
   
   # Linux (Ubuntu/Debian)
   sudo apt install qtbase6-dev qtbase6-dev-tools cmake ninja-build
   sudo apt install obs-studio-dev
   ```

2. **Build the Plugin**
   ```bash
   cd obs-plugin
   mkdir build && cd build
   cmake .. -DCMAKE_BUILD_TYPE=Release
   cmake --build . --config Release
   ```

3. **Install the Plugin**
   ```bash
   # Windows
   cmake --install . --prefix "C:/Program Files/obs-studio"
   
   # macOS
   cmake --install . --prefix "/Applications/OBS.app/Contents"
   
   # Linux
   sudo cmake --install . --prefix "/usr"
   ```

4. **Restart OBS Studio**
   - The plugin will appear in the Tools menu as "StreamRelay - Multi-Platform Streaming"

## 🎯 Quick Start Guide

### Windows Desktop Application

1. **Launch StreamRelay**
   - Run `StreamRelay.exe`
   - The application will open with a dark, modern interface

2. **Configure Stream Keys**
   - Enter your Twitch stream key (get from Twitch Creator Dashboard)
   - Enter your YouTube stream key (get from YouTube Studio)
   - Enter your Kick stream key (get from Kick Creator Dashboard)
   - Click "💾 Save Keys"

3. **Start Multi-Streaming**
   - Click "🚀 Start Streaming"
   - Copy the RTMP URL: `rtmp://localhost:1935/live`
   - Use stream key: `live`

4. **Configure Your Streaming Software**
   - **OBS Studio**: Set Server to `rtmp://localhost:1935/live`, Stream Key to `live`
   - **Streamlabs**: Same settings as OBS
   - **XSplit**: Add Custom RTMP with the above settings

5. **Start Streaming**
   - Begin streaming in your software
   - StreamRelay will automatically relay to all configured platforms

### OBS Studio Plugin

1. **Open StreamRelay Plugin**
   - In OBS, go to Tools → "StreamRelay - Multi-Platform Streaming"
   - The plugin dialog will open with multiple tabs

2. **Configuration Tab**
   - Enable platforms you want to stream to
   - Enter stream keys for enabled platforms
   - Adjust local RTMP port if needed (default: 1935)
   - Click "💾 Save Configuration"

3. **Control Tab**
   - Click "🚀 Start Multi-Stream Relay"
   - Copy the RTMP URL to clipboard
   - The relay server is now running

4. **Configure OBS Streaming**
   - Go to OBS Settings → Stream
   - Set Service to "Custom"
   - Set Server to `rtmp://localhost:1935/live`
   - Set Stream Key to `live`
   - Click OK

5. **Start Streaming**
   - Click "Start Streaming" in OBS
   - Monitor the "Monitor" tab for real-time statistics

## ⚙️ Configuration

### Platform-Specific Settings

#### Twitch
- **Recommended Bitrate**: 3000-6000 kbps
- **Maximum Bitrate**: 6000 kbps
- **Keyframe Interval**: 2 seconds
- **Audio**: 160 kbps, 48 kHz

#### YouTube
- **Recommended Bitrate**: 4500-9000 kbps
- **Maximum Bitrate**: 51000 kbps (4K)
- **Keyframe Interval**: 2-4 seconds
- **Audio**: 128-320 kbps, 48 kHz

#### Kick
- **Recommended Bitrate**: 3000-8000 kbps
- **Maximum Bitrate**: 10000 kbps
- **Keyframe Interval**: 2 seconds
- **Audio**: 160 kbps, 48 kHz

### Quality Presets

- **Ultra Fast**: Lowest CPU usage, larger file size
- **Super Fast**: Very low CPU usage
- **Very Fast**: Low CPU usage (recommended for most users)
- **Fast**: Balanced CPU usage and quality
- **Medium**: Higher quality, more CPU usage
- **Slow**: High quality, high CPU usage
- **Very Slow**: Highest quality, highest CPU usage

### Advanced Settings

#### Custom FFmpeg Arguments
Add custom FFmpeg parameters for advanced users:
```
-tune zerolatency -preset veryfast -profile:v high
```

#### Network Settings
- **Auto-Reconnect**: Automatically reconnect on stream failure
- **Reconnect Attempts**: Number of retry attempts (default: 3)
- **Connection Timeout**: Timeout for platform connections (default: 30s)

## 📊 Monitoring and Statistics

### Desktop Application
- **Status Indicator**: Shows current streaming status
- **Uptime Counter**: Displays how long you've been streaming
- **Bitrate Monitor**: Shows current upload bitrate
- **Connection Status**: Individual platform connection status

### OBS Plugin
- **Monitor Tab**: Real-time statistics and logs
- **Viewer Count**: Combined viewer count across platforms
- **Bitrate Graph**: Visual bitrate monitoring
- **Log Output**: Detailed logging for troubleshooting

## 🔧 Troubleshooting

### Common Issues

#### "Port already in use" Error
**Solution**: Change the local RTMP port in settings
```
1. Open StreamRelay settings
2. Change port from 1935 to 1936 (or another available port)
3. Update your streaming software with the new port
4. Restart the relay
```

#### "Stream key invalid" Error
**Solution**: Verify your stream keys
```
1. Go to your platform's creator dashboard
2. Copy the stream key exactly (no extra spaces)
3. Paste into StreamRelay
4. Save configuration
```

#### "FFmpeg not found" Error
**Solution**: Install FFmpeg
```
# Windows
1. Download FFmpeg from https://ffmpeg.org/download.html
2. Extract to StreamRelay/ffmpeg/ directory
3. Restart StreamRelay

# macOS
brew install ffmpeg

# Linux
sudo apt install ffmpeg
```

#### "Connection failed" Error
**Solution**: Check network and firewall
```
1. Verify internet connection
2. Check firewall settings (allow StreamRelay)
3. Test platform connectivity
4. Try different quality preset
```

#### High CPU Usage
**Solution**: Optimize encoding settings
```
1. Use "Very Fast" or "Ultra Fast" preset
2. Lower bitrate settings
3. Reduce output resolution in OBS
4. Close unnecessary applications
```

### Log Files

#### Desktop Application
- `streamrelay.log` - Main application log
- `nginx/logs/error.log` - RTMP server errors
- `nginx/logs/access.log` - RTMP server access log

#### OBS Plugin
- OBS log file contains plugin messages
- `stream-relay.log` - Plugin-specific log
- `logs/` directory - Platform-specific logs

## 🔒 Security and Privacy

### Stream Key Protection
- Stream keys are stored encrypted on your local machine
- Keys are never transmitted except to their respective platforms
- Configuration files use secure storage mechanisms

### Network Security
- Local RTMP server only accepts connections from localhost
- No external access to your streaming setup
- All platform connections use secure RTMP over TLS where supported

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Report Bugs**: Use GitHub Issues to report problems
2. **Feature Requests**: Suggest new features via GitHub Issues
3. **Code Contributions**: Submit pull requests with improvements
4. **Documentation**: Help improve this documentation
5. **Testing**: Test on different platforms and configurations

### Development Setup

```bash
# Clone the repository
git clone https://github.com/streamrelay/streamrelay.git
cd streamrelay

# Desktop Application
cd desktop-app
dotnet restore
dotnet build

# OBS Plugin
cd obs-plugin
mkdir build && cd build
cmake ..
make
```

## 📄 License

StreamRelay is licensed under the GPL-2.0 License. See `LICENSE` file for details.

## 🆘 Support

### Getting Help
- **Documentation**: Check this README and the wiki
- **GitHub Issues**: Report bugs and request features
- **Community**: Join our Discord server for real-time help
- **Email**: support@streamrelay.com

### Before Asking for Help
1. Check this documentation
2. Search existing GitHub issues
3. Try the troubleshooting steps above
4. Gather log files and error messages

## 🎉 Acknowledgments

- **Nginx RTMP Module**: For providing the RTMP server foundation
- **FFmpeg**: For video transcoding capabilities
- **OBS Studio**: For the plugin API and streaming framework
- **Qt Framework**: For the cross-platform GUI capabilities
- **Community Contributors**: For testing, feedback, and improvements

---

**Happy Streaming! 🎮📺**

Made with ❤️ for the streaming community