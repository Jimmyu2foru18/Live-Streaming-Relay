#!/bin/bash

# Quick Start Script for Multi-Platform Streaming Relay
# This script provides an interactive setup experience

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

# Function to print banner
print_banner() {
    clear
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "║        🎥 Multi-Platform Streaming Relay Setup 🎥           ║"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "║          Stream once, broadcast everywhere!                  ║"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Function to check if running as root
check_user() {
    if [[ $EUID -eq 0 ]]; then
        print_color $RED "❌ This script should not be run as root!"
        print_color $YELLOW "💡 Please run as a regular user with sudo privileges."
        echo
        print_color $BLUE "To create a user:"
        echo "   adduser streamuser"
        echo "   usermod -aG sudo streamuser"
        echo "   su - streamuser"
        echo
        exit 1
    fi
}

# Function to check system requirements
check_requirements() {
    print_color $BLUE "🔍 Checking system requirements..."
    echo
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "22.04" ]]; then
            print_color $GREEN "✅ Ubuntu 22.04 LTS detected"
        else
            print_color $YELLOW "⚠️  OS: $PRETTY_NAME (Ubuntu 22.04 LTS recommended)"
        fi
    else
        print_color $YELLOW "⚠️  Cannot detect OS version"
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    print_color $BLUE "🔧 CPU Cores: $cpu_cores"
    if [ $cpu_cores -ge 4 ]; then
        print_color $GREEN "✅ Excellent CPU for streaming"
    elif [ $cpu_cores -ge 2 ]; then
        print_color $YELLOW "⚠️  Minimum CPU cores (consider upgrading)"
    else
        print_color $RED "❌ Insufficient CPU cores"
    fi
    
    # Check memory
    local mem_total=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    print_color $BLUE "🧠 Total Memory: ${mem_total}MB"
    if [ $mem_total -ge 8000 ]; then
        print_color $GREEN "✅ Excellent memory for streaming"
    elif [ $mem_total -ge 4000 ]; then
        print_color $GREEN "✅ Sufficient memory for streaming"
    elif [ $mem_total -ge 2000 ]; then
        print_color $YELLOW "⚠️  Minimum memory (monitor usage)"
    else
        print_color $RED "❌ Insufficient memory"
    fi
    
    # Check disk space
    local disk_free=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    print_color $BLUE "💾 Free Disk Space: ${disk_free}GB"
    if [ $disk_free -ge 20 ]; then
        print_color $GREEN "✅ Sufficient disk space"
    else
        print_color $YELLOW "⚠️  Low disk space"
    fi
    
    echo
}

# Function to show menu
show_menu() {
    print_color $CYAN "📋 What would you like to do?"
    echo
    echo "1. 🚀 Full Installation (Install everything from scratch)"
    echo "2. 🔑 Configure Stream Keys (Set up Twitch/YouTube/Kick keys)"
    echo "3. 🧪 Test Setup (Verify everything is working)"
    echo "4. 📊 Monitor Streams (Real-time monitoring)"
    echo "5. 🔧 Restart Service (Restart nginx-rtmp)"
    echo "6. 📖 View Documentation (Open setup guides)"
    echo "7. 🆘 Troubleshoot (Diagnose issues)"
    echo "8. ❌ Exit"
    echo
}

# Function to handle full installation
full_installation() {
    print_color $GREEN "🚀 Starting full installation..."
    echo
    
    if [ ! -f "install.sh" ]; then
        print_color $RED "❌ install.sh not found in current directory"
        print_color $BLUE "💡 Make sure you're in the correct directory with all setup files"
        return 1
    fi
    
    print_color $BLUE "📦 This will install:"
    echo "   - Nginx with RTMP module"
    echo "   - FFmpeg for stream processing"
    echo "   - Systemd service for auto-start"
    echo "   - Web monitoring interface"
    echo
    
    read -p "Continue with installation? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        chmod +x install.sh
        ./install.sh
        
        if [ $? -eq 0 ]; then
            print_color $GREEN "✅ Installation completed successfully!"
            print_color $BLUE "💡 Next step: Configure your stream keys (option 2)"
        else
            print_color $RED "❌ Installation failed. Check the error messages above."
        fi
    else
        print_color $YELLOW "Installation cancelled."
    fi
}

# Function to configure stream keys
configure_keys() {
    print_color $GREEN "🔑 Configuring stream keys..."
    echo
    
    if [ ! -f "configure-keys.sh" ]; then
        print_color $RED "❌ configure-keys.sh not found"
        return 1
    fi
    
    if [ ! -f "/usr/local/nginx/conf/nginx.conf" ]; then
        print_color $RED "❌ Nginx not installed. Run full installation first (option 1)"
        return 1
    fi
    
    print_color $BLUE "📝 You'll need stream keys from:"
    echo "   🟣 Twitch: https://dashboard.twitch.tv/settings/stream"
    echo "   🔴 YouTube: https://studio.youtube.com → Go Live → Stream"
    echo "   🟢 Kick: https://kick.com/dashboard/settings/stream"
    echo
    
    read -p "Do you have all your stream keys ready? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        chmod +x configure-keys.sh
        ./configure-keys.sh
        
        if [ $? -eq 0 ]; then
            print_color $GREEN "✅ Stream keys configured successfully!"
            print_color $BLUE "💡 Next step: Test your setup (option 3)"
        else
            print_color $RED "❌ Configuration failed"
        fi
    else
        print_color $YELLOW "Please get your stream keys first, then run this option again."
    fi
}

# Function to test setup
test_setup() {
    print_color $GREEN "🧪 Testing your setup..."
    echo
    
    if [ ! -f "test-stream.sh" ]; then
        print_color $RED "❌ test-stream.sh not found"
        return 1
    fi
    
    chmod +x test-stream.sh
    ./test-stream.sh
}

# Function to monitor streams
monitor_streams() {
    print_color $GREEN "📊 Starting stream monitor..."
    echo
    
    if [ ! -f "monitor-streams.sh" ]; then
        print_color $RED "❌ monitor-streams.sh not found"
        return 1
    fi
    
    print_color $BLUE "💡 Press Ctrl+C to exit monitoring"
    echo
    sleep 2
    
    chmod +x monitor-streams.sh
    ./monitor-streams.sh
}

# Function to restart service
restart_service() {
    print_color $GREEN "🔧 Restarting nginx-rtmp service..."
    echo
    
    if systemctl is-active --quiet nginx-rtmp; then
        print_color $BLUE "Stopping service..."
        sudo systemctl stop nginx-rtmp
        sleep 2
    fi
    
    print_color $BLUE "Starting service..."
    sudo systemctl start nginx-rtmp
    
    if systemctl is-active --quiet nginx-rtmp; then
        print_color $GREEN "✅ Service restarted successfully!"
        
        # Show status
        echo
        print_color $BLUE "📊 Service Status:"
        sudo systemctl status nginx-rtmp --no-pager -l
    else
        print_color $RED "❌ Failed to start service"
        print_color $BLUE "💡 Check logs with: sudo journalctl -u nginx-rtmp -f"
    fi
}

# Function to view documentation
view_documentation() {
    print_color $GREEN "📖 Available Documentation:"
    echo
    
    echo "1. 📋 Main README (README.md)"
    echo "2. 🎥 OBS Setup Guide (OBS-SETUP-GUIDE.md)"
    echo "3. 🔧 Configuration Files"
    echo "4. 🌐 Open Web Interface"
    echo "5. ⬅️  Back to main menu"
    echo
    
    read -p "Select documentation to view (1-5): " doc_choice
    
    case $doc_choice in
        1)
            if [ -f "README.md" ]; then
                less README.md
            else
                print_color $RED "❌ README.md not found"
            fi
            ;;
        2)
            if [ -f "OBS-SETUP-GUIDE.md" ]; then
                less OBS-SETUP-GUIDE.md
            else
                print_color $RED "❌ OBS-SETUP-GUIDE.md not found"
            fi
            ;;
        3)
            print_color $BLUE "📁 Configuration Files:"
            echo "   - nginx.conf (Main configuration)"
            echo "   - nginx-rtmp.service (Systemd service)"
            echo
            if [ -f "/usr/local/nginx/conf/nginx.conf" ]; then
                print_color $GREEN "✅ Active config: /usr/local/nginx/conf/nginx.conf"
                read -p "View active configuration? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    less /usr/local/nginx/conf/nginx.conf
                fi
            else
                print_color $YELLOW "⚠️  No active configuration found"
            fi
            ;;
        4)
            local public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
            print_color $BLUE "🌐 Web Interface URLs:"
            echo "   📊 Statistics: http://$public_ip:8080/stat"
            echo "   🏠 Dashboard: http://$public_ip:8080"
            echo
            print_color $YELLOW "💡 Open these URLs in your web browser"
            ;;
        5)
            return
            ;;
        *)
            print_color $RED "❌ Invalid selection"
            ;;
    esac
}

# Function to troubleshoot
troubleshoot() {
    print_color $GREEN "🆘 Troubleshooting Assistant"
    echo
    
    print_color $BLUE "🔍 Common Issues:"
    echo
    echo "1. 🚫 Service won't start"
    echo "2. 📡 Cannot connect from OBS"
    echo "3. 🎥 Streams not reaching platforms"
    echo "4. 💻 High CPU/Memory usage"
    echo "5. 🌐 Web interface not accessible"
    echo "6. 📋 View all logs"
    echo "7. ⬅️  Back to main menu"
    echo
    
    read -p "Select issue to diagnose (1-7): " issue_choice
    
    case $issue_choice in
        1)
            print_color $BLUE "🔧 Diagnosing service issues..."
            echo
            
            # Check if nginx binary exists
            if [ -f "/usr/local/nginx/sbin/nginx" ]; then
                print_color $GREEN "✅ Nginx binary found"
                
                # Test configuration
                if sudo /usr/local/nginx/sbin/nginx -t; then
                    print_color $GREEN "✅ Configuration is valid"
                else
                    print_color $RED "❌ Configuration has errors"
                    print_color $BLUE "💡 Run: ./configure-keys.sh to fix configuration"
                fi
            else
                print_color $RED "❌ Nginx not installed"
                print_color $BLUE "💡 Run full installation (option 1)"
            fi
            
            # Check service status
            print_color $BLUE "📊 Service Status:"
            sudo systemctl status nginx-rtmp --no-pager || true
            ;;
        2)
            print_color $BLUE "📡 Diagnosing OBS connection issues..."
            echo
            
            # Check if port 1935 is listening
            if netstat -tuln | grep -q ":1935 "; then
                print_color $GREEN "✅ RTMP port (1935) is listening"
            else
                print_color $RED "❌ RTMP port (1935) not listening"
                print_color $BLUE "💡 Service may not be running"
            fi
            
            # Show firewall status
            print_color $BLUE "🔥 Firewall Status:"
            sudo ufw status || print_color $YELLOW "UFW not installed/configured"
            
            # Test with ffmpeg if available
            if command -v ffmpeg >/dev/null 2>&1; then
                print_color $BLUE "🧪 Testing RTMP connection..."
                timeout 5 ffmpeg -f lavfi -i testsrc2=duration=3:size=320x240:rate=30 \
                    -f lavfi -i sine=frequency=1000:duration=3 \
                    -c:v libx264 -preset ultrafast -b:v 1000k \
                    -c:a aac -b:a 128k \
                    -f flv rtmp://localhost/live/test -y /dev/null 2>/dev/null && \
                    print_color $GREEN "✅ Local RTMP connection successful" || \
                    print_color $RED "❌ Local RTMP connection failed"
            fi
            ;;
        3)
            print_color $BLUE "🎥 Diagnosing platform streaming issues..."
            echo
            
            # Check if keys are configured
            if [ -f "/usr/local/nginx/conf/nginx.conf" ]; then
                if grep -q "YOUR_TWITCH_KEY" /usr/local/nginx/conf/nginx.conf; then
                    print_color $RED "❌ Twitch key not configured"
                else
                    print_color $GREEN "✅ Twitch key configured"
                fi
                
                if grep -q "YOUR_YOUTUBE_KEY" /usr/local/nginx/conf/nginx.conf; then
                    print_color $RED "❌ YouTube key not configured"
                else
                    print_color $GREEN "✅ YouTube key configured"
                fi
                
                if grep -q "YOUR_KICK_KEY" /usr/local/nginx/conf/nginx.conf; then
                    print_color $RED "❌ Kick key not configured"
                else
                    print_color $GREEN "✅ Kick key configured"
                fi
            else
                print_color $RED "❌ Configuration file not found"
            fi
            
            # Check FFmpeg processes
            local ffmpeg_count=$(pgrep -c ffmpeg || echo "0")
            print_color $BLUE "🎬 Active FFmpeg processes: $ffmpeg_count"
            ;;
        4)
            print_color $BLUE "💻 Checking system resources..."
            echo
            
            # Show top processes
            print_color $BLUE "🔝 Top CPU processes:"
            ps aux --sort=-%cpu | head -6
            echo
            
            # Show memory usage
            print_color $BLUE "🧠 Memory usage:"
            free -h
            echo
            
            # Show disk usage
            print_color $BLUE "💾 Disk usage:"
            df -h /
            echo
            
            print_color $YELLOW "💡 Tips to reduce resource usage:"
            echo "   - Lower bitrates in configuration"
            echo "   - Use hardware encoding if available"
            echo "   - Close unnecessary services"
            ;;
        5)
            print_color $BLUE "🌐 Diagnosing web interface issues..."
            echo
            
            # Check if port 8080 is listening
            if netstat -tuln | grep -q ":8080 "; then
                print_color $GREEN "✅ Web interface port (8080) is listening"
                
                local public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_IP")
                print_color $BLUE "🌍 Access at: http://$public_ip:8080"
            else
                print_color $RED "❌ Web interface port (8080) not listening"
            fi
            
            # Test local access
            if curl -s http://localhost:8080 >/dev/null; then
                print_color $GREEN "✅ Local web access working"
            else
                print_color $RED "❌ Local web access failed"
            fi
            ;;
        6)
            print_color $BLUE "📋 Recent logs (last 20 lines):"
            echo
            sudo journalctl -u nginx-rtmp -n 20 --no-pager || \
                print_color $YELLOW "No logs available or service not installed"
            echo
            print_color $BLUE "💡 For real-time logs: sudo journalctl -u nginx-rtmp -f"
            ;;
        7)
            return
            ;;
        *)
            print_color $RED "❌ Invalid selection"
            ;;
    esac
}

# Main function
main() {
    print_banner
    check_user
    check_requirements
    
    while true; do
        show_menu
        read -p "Enter your choice (1-8): " choice
        echo
        
        case $choice in
            1)
                full_installation
                ;;
            2)
                configure_keys
                ;;
            3)
                test_setup
                ;;
            4)
                monitor_streams
                ;;
            5)
                restart_service
                ;;
            6)
                view_documentation
                ;;
            7)
                troubleshoot
                ;;
            8)
                print_color $GREEN "👋 Thanks for using Multi-Platform Streaming Relay!"
                print_color $BLUE "🎥 Happy streaming!"
                exit 0
                ;;
            *)
                print_color $RED "❌ Invalid choice. Please select 1-8."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
        print_banner
    done
}

# Run main function
main "$@"