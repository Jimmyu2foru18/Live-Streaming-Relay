StreamRelay OBS Plugin - Data Directory
=======================================

This directory contains configuration templates and data files for the StreamRelay OBS Plugin.

Files in this directory:

1. nginx.conf.template
   - Template file for generating nginx RTMP server configuration
   - Contains placeholders that are replaced with actual values during runtime
   - Do not edit manually - changes will be overwritten

2. README.txt (this file)
   - Documentation for the data directory contents

Generated files (created during plugin operation):

- nginx.conf - Active nginx configuration file
- stream-relay.log - Plugin log file
- logs/ - Directory containing nginx and FFmpeg logs
- temp/ - Temporary files directory
- recordings/ - Local stream recordings (if enabled)

Configuration Variables:

The nginx.conf.template file uses the following variables that are replaced
at runtime by the plugin:

Basic Configuration:
- {{LOCAL_PORT}} - Local RTMP server port (default: 1935)
- {{QUALITY_PRESET}} - FFmpeg encoding preset for quality/speed balance
- {{GOP_SIZE}} - Keyframe interval for video encoding
- {{FRAMERATE}} - Output video framerate
- {{AUDIO_BITRATE}} - Audio encoding bitrate in kbps
- {{AUDIO_SAMPLERATE}} - Audio sample rate in Hz
- {{CUSTOM_FFMPEG_ARGS}} - Additional FFmpeg command line arguments

Platform Enablement:
- {{TWITCH_ENABLED}} - Enable/disable Twitch streaming
- {{YOUTUBE_ENABLED}} - Enable/disable YouTube streaming
- {{KICK_ENABLED}} - Enable/disable Kick streaming
- {{CUSTOM_RTMP_ENABLED}} - Enable/disable custom RTMP server
- {{HLS_ENABLED}} - Enable/disable HLS output
- {{RECORDING_ENABLED}} - Enable/disable local recording
- {{AUTH_ENABLED}} - Enable/disable stream authentication

Stream Keys and URLs:
- {{TWITCH_STREAM_KEY}} - Twitch stream key
- {{YOUTUBE_STREAM_KEY}} - YouTube stream key
- {{KICK_STREAM_KEY}} - Kick stream key
- {{CUSTOM_RTMP_URL}} - Custom RTMP server URL
- {{CUSTOM_RTMP_FULL_URL}} - Complete custom RTMP URL with key
- {{TWITCH_RTMP_URL}} - Twitch RTMP ingest endpoint
- {{YOUTUBE_RTMP_URL}} - YouTube RTMP ingest endpoint
- {{KICK_RTMP_URL}} - Kick RTMP ingest endpoint

Bitrate Configuration:
- {{TWITCH_BITRATE}} - Video bitrate for Twitch in kbps
- {{YOUTUBE_BITRATE}} - Video bitrate for YouTube in kbps
- {{KICK_BITRATE}} - Video bitrate for Kick in kbps
- {{CUSTOM_BITRATE}} - Video bitrate for custom RTMP in kbps
- {{TWITCH_BUFFER_SIZE}} - Buffer size for Twitch in kbps
- {{YOUTUBE_BUFFER_SIZE}} - Buffer size for YouTube in kbps
- {{KICK_BUFFER_SIZE}} - Buffer size for Kick in kbps
- {{CUSTOM_BUFFER_SIZE}} - Buffer size for custom RTMP in kbps

Platform-Specific Settings:

Twitch:
- Recommended bitrate: 3000-6000 kbps
- Maximum bitrate: 6000 kbps
- Keyframe interval: 2 seconds (GOP size = framerate * 2)
- Audio: 160 kbps, 48 kHz, stereo

YouTube:
- Recommended bitrate: 4500-9000 kbps
- Maximum bitrate: 51000 kbps (for 4K)
- Keyframe interval: 2-4 seconds
- Audio: 128-320 kbps, 48 kHz, stereo

Kick:
- Recommended bitrate: 3000-8000 kbps
- Maximum bitrate: 10000 kbps
- Keyframe interval: 2 seconds
- Audio: 160 kbps, 48 kHz, stereo

Troubleshooting:

If the plugin fails to start:
1. Check that nginx and FFmpeg are properly installed
2. Verify that the local RTMP port is not in use
3. Ensure stream keys are correctly configured
4. Check the logs directory for error messages

Common Issues:

1. "Port already in use" error:
   - Change the local RTMP port in plugin settings
   - Check for other RTMP servers running on the system

2. "FFmpeg not found" error:
   - Ensure FFmpeg is installed and in system PATH
   - Check that FFmpeg supports the required codecs

3. "Stream key invalid" error:
   - Verify stream keys are correctly copied from platform settings
   - Ensure there are no extra spaces or characters

4. "Connection failed" error:
   - Check internet connectivity
   - Verify platform RTMP endpoints are accessible
   - Check firewall settings

Log Files:

- stream-relay.log - Main plugin log
- logs/error.log - Nginx error log
- logs/access.log - Nginx access log
- logs/twitch_ffmpeg.log - Twitch FFmpeg output
- logs/youtube_ffmpeg.log - YouTube FFmpeg output
- logs/kick_ffmpeg.log - Kick FFmpeg output
- logs/custom_ffmpeg.log - Custom RTMP FFmpeg output

Support:

For support and documentation, visit:
- GitHub: https://github.com/streamrelay/obs-plugin
- Wiki: https://github.com/streamrelay/obs-plugin/wiki
- Issues: https://github.com/streamrelay/obs-plugin/issues

Version: 1.0.0
Last Updated: 2024
License: GPL-2.0