@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    OBS Connection Test for Windows
echo ========================================
echo.
echo This script helps test your OBS connection to the streaming server
echo.

:: Check if FFmpeg is available
ffmpeg -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg not found in PATH
    echo.
    echo Please install FFmpeg:
    echo 1. Download from: https://ffmpeg.org/download.html
    echo 2. Extract to C:\ffmpeg
    echo 3. Add C:\ffmpeg\bin to your PATH environment variable
    echo.
    echo Or install via chocolatey: choco install ffmpeg
    echo.
    pause
    exit /b 1
)

echo [OK] FFmpeg is available
echo.

:: Get server IP from user
set /p SERVER_IP="Enter your VPS IP address: "
if "%SERVER_IP%"=="" (
    echo [ERROR] No IP address provided
    pause
    exit /b 1
)

echo.
echo Testing connection to: %SERVER_IP%
echo.

:: Test basic connectivity
echo [1/4] Testing basic connectivity...
ping -n 1 %SERVER_IP% >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Cannot reach server %SERVER_IP%
    echo Check your internet connection and server IP
    pause
    exit /b 1
)
echo [OK] Server is reachable

:: Test RTMP port (1935)
echo.
echo [2/4] Testing RTMP port (1935)...
telnet %SERVER_IP% 1935 2>nul
if %errorlevel% neq 0 (
    echo [WARNING] Cannot connect to RTMP port 1935
    echo This might be normal if the service isn't running
) else (
    echo [OK] RTMP port is accessible
)

:: Test web interface port (8080)
echo.
echo [3/4] Testing web interface port (8080)...
curl -s -o nul -w "%%{http_code}" http://%SERVER_IP%:8080 >temp_response.txt 2>nul
set /p HTTP_CODE=<temp_response.txt
del temp_response.txt >nul 2>&1

if "%HTTP_CODE%"=="200" (
    echo [OK] Web interface is accessible
    echo You can monitor streams at: http://%SERVER_IP%:8080
) else (
    echo [WARNING] Web interface not accessible (HTTP %HTTP_CODE%)
    echo The service might not be running on the server
)

:: Test RTMP stream
echo.
echo [4/4] Testing RTMP stream connection...
echo Sending a 5-second test stream...
echo.

:: Create a test stream
ffmpeg -f lavfi -i testsrc2=duration=5:size=640x480:rate=30 ^
       -f lavfi -i sine=frequency=1000:duration=5 ^
       -c:v libx264 -preset ultrafast -tune zerolatency ^
       -b:v 2000k -maxrate 2000k -bufsize 2000k ^
       -c:a aac -b:a 128k -ar 44100 ^
       -f flv rtmp://%SERVER_IP%/live/test_stream ^
       -y nul 2>test_output.txt

if %errorlevel% equ 0 (
    echo [OK] Test stream sent successfully!
    echo Your OBS should be able to connect to: rtmp://%SERVER_IP%/live
) else (
    echo [ERROR] Failed to send test stream
    echo Check the error details below:
    type test_output.txt
)

del test_output.txt >nul 2>&1

echo.
echo ========================================
echo           OBS Configuration
echo ========================================
echo.
echo Service: Custom
echo Server:  rtmp://%SERVER_IP%/live
echo Stream Key: your_stream_name (any name you want)
echo.
echo Recommended OBS Settings:
echo - Output Mode: Advanced
echo - Video Bitrate: 12000-15000 kbps
echo - Audio Bitrate: 160 kbps
echo - Encoder: x264 (or Hardware if available)
echo - Keyframe Interval: 2 seconds
echo.
echo ========================================
echo         Streamlabs OBS Configuration
echo ========================================
echo.
echo Stream Type: Custom Ingest
echo URL: rtmp://%SERVER_IP%/live
echo Stream Key: your_stream_name
echo Video Bitrate: 12000-15000 kbps
echo Audio Bitrate: 160 kbps
echo.
echo Monitor your streams at: http://%SERVER_IP%:8080
echo.
echo ========================================
echo              Test Complete
echo ========================================
echo.
echo If all tests passed, you're ready to stream!
echo If there were errors, check your server configuration.
echo.
pause