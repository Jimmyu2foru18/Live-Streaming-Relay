#!/bin/bash

# Real-time Stream Monitoring Script
# This script provides real-time monitoring of your streaming setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Function to get system stats
get_system_stats() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local mem_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo "CPU: ${cpu_usage}% | Memory: ${mem_usage}% | Disk: ${disk_usage}%"
}

# Function to get network stats
get_network_stats() {
    local interface=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -n "$interface" ]; then
        local rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes)
        local tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes)
        local rx_mb=$((rx_bytes / 1024 / 1024))
        local tx_mb=$((tx_bytes / 1024 / 1024))
        echo "Interface: $interface | RX: ${rx_mb}MB | TX: ${tx_mb}MB"
    else
        echo "Network interface not detected"
    fi
}

# Function to parse RTMP stats
parse_rtmp_stats() {
    local stats=$(curl -s http://localhost:8080/stat 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$stats" ]; then
        # Extract active streams
        local live_streams=$(echo "$stats" | grep -o '<name>[^<]*</name>' | sed 's/<name>//g; s/<\/name>//g' | grep -v '^$')
        local client_count=$(echo "$stats" | grep -o '<nclients>[^<]*</nclients>' | sed 's/<nclients>//g; s/<\/nclients>//g')
        
        if [ -n "$live_streams" ]; then
            print_color $GREEN "📡 Active Streams:"
            echo "$live_streams" | while read -r stream; do
                if [ -n "$stream" ]; then
                    print_color $CYAN "   └─ $stream"
                fi
            done
        else
            print_color $YELLOW "📡 No active streams"
        fi
        
        if [ -n "$client_count" ] && [ "$client_count" -gt 0 ]; then
            print_color $BLUE "👥 Connected clients: $client_count"
        fi
    else
        print_color $RED "❌ Cannot fetch RTMP statistics"
    fi
}

# Function to check service status
check_service_status() {
    if systemctl is-active --quiet nginx-rtmp; then
        print_color $GREEN "✅ nginx-rtmp service is running"
        
        # Check if processes are actually running
        local nginx_processes=$(pgrep -c nginx || echo "0")
        local ffmpeg_processes=$(pgrep -c ffmpeg || echo "0")
        
        print_color $BLUE "🔧 Nginx processes: $nginx_processes"
        print_color $BLUE "🎥 FFmpeg processes: $ffmpeg_processes"
        
        if [ "$ffmpeg_processes" -gt 0 ]; then
            print_color $GREEN "🚀 Streams are being processed"
        fi
    else
        print_color $RED "❌ nginx-rtmp service is not running"
        print_color $YELLOW "💡 Start with: sudo systemctl start nginx-rtmp"
    fi
}

# Function to show platform status
show_platform_status() {
    print_color $PURPLE "🎯 Platform Status:"
    
    # Check if keys are configured
    if [ -f "/usr/local/nginx/conf/nginx.conf" ]; then
        if ! grep -q "YOUR_TWITCH_KEY" /usr/local/nginx/conf/nginx.conf; then
            print_color $GREEN "   ✅ Twitch: Configured"
        else
            print_color $YELLOW "   ⚠️  Twitch: Not configured"
        fi
        
        if ! grep -q "YOUR_YOUTUBE_KEY" /usr/local/nginx/conf/nginx.conf; then
            print_color $GREEN "   ✅ YouTube: Configured"
        else
            print_color $YELLOW "   ⚠️  YouTube: Not configured"
        fi
        
        if ! grep -q "YOUR_KICK_KEY" /usr/local/nginx/conf/nginx.conf; then
            print_color $GREEN "   ✅ Kick: Configured"
        else
            print_color $YELLOW "   ⚠️  Kick: Not configured"
        fi
    else
        print_color $RED "   ❌ Configuration file not found"
    fi
}

# Function to show recent logs
show_recent_logs() {
    print_color $BLUE "📋 Recent Logs (last 5 lines):"
    if systemctl is-active --quiet nginx-rtmp; then
        journalctl -u nginx-rtmp -n 5 --no-pager -q | while read -r line; do
            echo "   $line"
        done
    else
        print_color $YELLOW "   Service not running"
    fi
}

# Main monitoring function
monitor_loop() {
    local refresh_interval=${1:-5}
    
    while true; do
        clear
        print_color $CYAN "═══════════════════════════════════════════════════════════════"
        print_color $CYAN "                    🎥 STREAMING MONITOR                        "
        print_color $CYAN "═══════════════════════════════════════════════════════════════"
        echo
        
        print_color $BLUE "⏰ $(get_timestamp)"
        echo
        
        print_color $YELLOW "💻 System Resources:"
        echo "   $(get_system_stats)"
        echo
        
        print_color $YELLOW "🌐 Network:"
        echo "   $(get_network_stats)"
        echo
        
        check_service_status
        echo
        
        show_platform_status
        echo
        
        parse_rtmp_stats
        echo
        
        show_recent_logs
        echo
        
        print_color $CYAN "═══════════════════════════════════════════════════════════════"
        print_color $BLUE "🔄 Refreshing in $refresh_interval seconds... (Ctrl+C to exit)"
        print_color $BLUE "📊 Web interface: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_IP'):8080"
        print_color $CYAN "═══════════════════════════════════════════════════════════════"
        
        sleep $refresh_interval
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --interval SECONDS    Refresh interval (default: 5)"
    echo "  -o, --once                Run once and exit"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Monitor with 5-second refresh"
    echo "  $0 -i 10                  # Monitor with 10-second refresh"
    echo "  $0 --once                 # Run once and show current status"
}

# Parse command line arguments
REFRESH_INTERVAL=5
RUN_ONCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            REFRESH_INTERVAL="$2"
            shift 2
            ;;
        -o|--once)
            RUN_ONCE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate refresh interval
if ! [[ "$REFRESH_INTERVAL" =~ ^[0-9]+$ ]] || [ "$REFRESH_INTERVAL" -lt 1 ]; then
    echo "Error: Refresh interval must be a positive integer"
    exit 1
fi

# Check if required tools are available
if ! command -v curl >/dev/null 2>&1; then
    print_color $RED "❌ curl is required but not installed"
    exit 1
fi

# Main execution
if [ "$RUN_ONCE" = true ]; then
    # Run once and exit
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    print_color $CYAN "                    🎥 STREAMING STATUS                         "
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    print_color $BLUE "⏰ $(get_timestamp)"
    echo
    
    print_color $YELLOW "💻 System Resources:"
    echo "   $(get_system_stats)"
    echo
    
    check_service_status
    echo
    
    show_platform_status
    echo
    
    parse_rtmp_stats
    echo
    
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
else
    # Continuous monitoring
    print_color $GREEN "🚀 Starting stream monitor..."
    print_color $BLUE "📊 Refresh interval: $REFRESH_INTERVAL seconds"
    print_color $YELLOW "💡 Press Ctrl+C to exit"
    echo
    sleep 2
    
    # Set up trap for clean exit
    trap 'echo; print_color $GREEN "👋 Monitor stopped. Happy streaming!"; exit 0' INT
    
    monitor_loop $REFRESH_INTERVAL
fi