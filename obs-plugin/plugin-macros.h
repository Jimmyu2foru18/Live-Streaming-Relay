#pragma once

#define PLUGIN_NAME "stream-relay-plugin"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_DESCRIPTION "StreamRelay - Multi-Platform Streaming Plugin for OBS Studio"
#define PLUGIN_AUTHOR "StreamRelay Team"
#define PLUGIN_URL "https://github.com/streamrelay/obs-plugin"

// Build configuration
#ifdef DEBUG_BUILD
#define PLUGIN_DEBUG 1
#else
#define PLUGIN_DEBUG 0
#endif

// Platform detection
#ifdef _WIN32
#define PLUGIN_PLATFORM_WINDOWS 1
#define PLUGIN_PLATFORM_MACOS 0
#define PLUGIN_PLATFORM_LINUX 0
#elif __APPLE__
#define PLUGIN_PLATFORM_WINDOWS 0
#define PLUGIN_PLATFORM_MACOS 1
#define PLUGIN_PLATFORM_LINUX 0
#else
#define PLUGIN_PLATFORM_WINDOWS 0
#define PLUGIN_PLATFORM_MACOS 0
#define PLUGIN_PLATFORM_LINUX 1
#endif

// Feature flags
#define PLUGIN_FEATURE_TWITCH 1
#define PLUGIN_FEATURE_YOUTUBE 1
#define PLUGIN_FEATURE_KICK 1
#define PLUGIN_FEATURE_CUSTOM_RTMP 1
#define PLUGIN_FEATURE_RECORDING 1
#define PLUGIN_FEATURE_STATS 1

// Default configuration
#define DEFAULT_RTMP_PORT 1935
#define DEFAULT_STREAM_KEY "live"
#define DEFAULT_BITRATE 6000
#define DEFAULT_PRESET "veryfast"
#define DEFAULT_RECONNECT_ATTEMPTS 3
#define DEFAULT_RECONNECT_DELAY 5000

// Logging macros
#if PLUGIN_DEBUG
#define PLUGIN_LOG_DEBUG(format, ...) blog(LOG_DEBUG, "[StreamRelay] " format, ##__VA_ARGS__)
#else
#define PLUGIN_LOG_DEBUG(format, ...)
#endif

#define PLUGIN_LOG_INFO(format, ...) blog(LOG_INFO, "[StreamRelay] " format, ##__VA_ARGS__)
#define PLUGIN_LOG_WARNING(format, ...) blog(LOG_WARNING, "[StreamRelay] " format, ##__VA_ARGS__)
#define PLUGIN_LOG_ERROR(format, ...) blog(LOG_ERROR, "[StreamRelay] " format, ##__VA_ARGS__)

// Version comparison macros
#define PLUGIN_VERSION_MAJOR 1
#define PLUGIN_VERSION_MINOR 0
#define PLUGIN_VERSION_PATCH 0

#define PLUGIN_MAKE_VERSION(major, minor, patch) \
    ((major) * 10000 + (minor) * 100 + (patch))

#define PLUGIN_VERSION_INT PLUGIN_MAKE_VERSION(PLUGIN_VERSION_MAJOR, PLUGIN_VERSION_MINOR, PLUGIN_VERSION_PATCH)

// Compatibility checks
#define OBS_MIN_VERSION_REQUIRED PLUGIN_MAKE_VERSION(28, 0, 0)
#define QT_MIN_VERSION_REQUIRED PLUGIN_MAKE_VERSION(6, 0, 0)

// Resource paths
#if PLUGIN_PLATFORM_WINDOWS
#define NGINX_EXECUTABLE "nginx.exe"
#define FFMPEG_EXECUTABLE "ffmpeg.exe"
#elif PLUGIN_PLATFORM_MACOS
#define NGINX_EXECUTABLE "nginx"
#define FFMPEG_EXECUTABLE "ffmpeg"
#else
#define NGINX_EXECUTABLE "nginx"
#define FFMPEG_EXECUTABLE "ffmpeg"
#endif

// Configuration file names
#define CONFIG_FILE_NAME "stream-relay.ini"
#define NGINX_CONFIG_FILE "nginx.conf"
#define LOG_FILE_NAME "stream-relay.log"

// Network configuration
#define MAX_RECONNECT_ATTEMPTS 10
#define CONNECTION_TIMEOUT_MS 30000
#define HEARTBEAT_INTERVAL_MS 5000
#define STATS_UPDATE_INTERVAL_MS 1000

// Stream configuration limits
#define MIN_BITRATE 500
#define MAX_BITRATE 50000
#define MIN_PORT 1024
#define MAX_PORT 65535
#define MAX_STREAM_KEY_LENGTH 256
#define MAX_CUSTOM_ARGS_LENGTH 1024

// UI configuration
#define DIALOG_MIN_WIDTH 600
#define DIALOG_MIN_HEIGHT 500
#define DIALOG_DEFAULT_WIDTH 800
#define DIALOG_DEFAULT_HEIGHT 600

// Color scheme (hex values)
#define COLOR_TWITCH "#9146ff"
#define COLOR_YOUTUBE "#ff0000"
#define COLOR_KICK "#53ff1a"
#define COLOR_SUCCESS "#107c10"
#define COLOR_ERROR "#d13438"
#define COLOR_WARNING "#ff8c00"
#define COLOR_INFO "#0078d4"

// Platform-specific RTMP endpoints
#define TWITCH_RTMP_URL "rtmp://live.twitch.tv/app/"
#define YOUTUBE_RTMP_URL "rtmp://a.rtmp.youtube.com/live2/"
#define KICK_RTMP_URL "rtmp://ingest.kick.com/live/"

// Error codes
#define PLUGIN_ERROR_NONE 0
#define PLUGIN_ERROR_INIT_FAILED 1
#define PLUGIN_ERROR_CONFIG_INVALID 2
#define PLUGIN_ERROR_NGINX_NOT_FOUND 3
#define PLUGIN_ERROR_FFMPEG_NOT_FOUND 4
#define PLUGIN_ERROR_NETWORK_ERROR 5
#define PLUGIN_ERROR_STREAM_KEY_INVALID 6
#define PLUGIN_ERROR_PERMISSION_DENIED 7
#define PLUGIN_ERROR_UNKNOWN 99

// Success messages
#define MSG_RELAY_STARTED "Multi-stream relay started successfully"
#define MSG_RELAY_STOPPED "Multi-stream relay stopped"
#define MSG_CONFIG_SAVED "Configuration saved successfully"
#define MSG_CONFIG_LOADED "Configuration loaded successfully"
#define MSG_CONNECTION_TEST_OK "Connection test passed"

// Error messages
#define MSG_ERROR_NO_PLATFORMS "Please enable at least one streaming platform"
#define MSG_ERROR_NO_STREAM_KEYS "Please enter stream keys for enabled platforms"
#define MSG_ERROR_NGINX_START_FAILED "Failed to start RTMP server"
#define MSG_ERROR_INVALID_PORT "Invalid port number"
#define MSG_ERROR_INVALID_BITRATE "Invalid bitrate value"
#define MSG_ERROR_CONFIG_LOAD_FAILED "Failed to load configuration"
#define MSG_ERROR_CONFIG_SAVE_FAILED "Failed to save configuration"

// Feature availability based on platform
#if PLUGIN_PLATFORM_WINDOWS
#define FEATURE_AUTO_UPDATER 1
#define FEATURE_SYSTEM_TRAY 1
#define FEATURE_WINDOWS_SERVICE 1
#else
#define FEATURE_AUTO_UPDATER 0
#define FEATURE_SYSTEM_TRAY 1
#define FEATURE_WINDOWS_SERVICE 0
#endif

// Compiler-specific attributes
#ifdef __GNUC__
#define PLUGIN_UNUSED __attribute__((unused))
#define PLUGIN_DEPRECATED __attribute__((deprecated))
#elif defined(_MSC_VER)
#define PLUGIN_UNUSED
#define PLUGIN_DEPRECATED __declspec(deprecated)
#else
#define PLUGIN_UNUSED
#define PLUGIN_DEPRECATED
#endif

// Memory management helpers
#define PLUGIN_SAFE_DELETE(ptr) do { delete (ptr); (ptr) = nullptr; } while(0)
#define PLUGIN_SAFE_DELETE_ARRAY(ptr) do { delete[] (ptr); (ptr) = nullptr; } while(0)

// String helpers
#define PLUGIN_STRINGIFY(x) #x
#define PLUGIN_TOSTRING(x) PLUGIN_STRINGIFY(x)

// Build timestamp
#define PLUGIN_BUILD_DATE __DATE__
#define PLUGIN_BUILD_TIME __TIME__
#define PLUGIN_BUILD_TIMESTAMP PLUGIN_BUILD_DATE " " PLUGIN_BUILD_TIME