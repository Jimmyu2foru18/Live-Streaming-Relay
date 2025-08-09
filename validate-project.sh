#!/bin/bash

# Project Validation Script
# Ensures all components are present and properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Validation results
ERRORS=0
WARNINGS=0
PASSED=0

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print test result
print_result() {
    local status=$1
    local message=$2
    local details=$3
    
    case $status in
        "PASS")
            print_color $GREEN "✅ PASS: $message"
            ((PASSED++))
            ;;
        "WARN")
            print_color $YELLOW "⚠️  WARN: $message"
            if [ -n "$details" ]; then
                print_color $YELLOW "    $details"
            fi
            ((WARNINGS++))
            ;;
        "FAIL")
            print_color $RED "❌ FAIL: $message"
            if [ -n "$details" ]; then
                print_color $RED "    $details"
            fi
            ((ERRORS++))
            ;;
    esac
}

# Function to print banner
print_banner() {
    clear
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "║        🔍 Multi-Platform Streaming Project Validator        ║"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "║            Comprehensive Project Completeness Check         ║"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Function to check file existence and basic validation
check_file() {
    local file=$1
    local description=$2
    local required=$3
    local min_size=${4:-1}
    
    if [ -f "$file" ]; then
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        if [ "$size" -ge "$min_size" ]; then
            print_result "PASS" "$description exists and has content ($size bytes)"
        else
            print_result "WARN" "$description exists but seems empty or too small ($size bytes)"
        fi
    else
        if [ "$required" = "true" ]; then
            print_result "FAIL" "$description is missing" "Required file: $file"
        else
            print_result "WARN" "$description is missing" "Optional file: $file"
        fi
    fi
}

# Function to validate nginx configuration
validate_nginx_config() {
    print_color $BLUE "\n📋 Validating Nginx Configuration"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    if [ -f "nginx.conf" ]; then
        # Check for required sections
        if grep -q "rtmp {" nginx.conf; then
            print_result "PASS" "RTMP block found in nginx.conf"
        else
            print_result "FAIL" "RTMP block missing in nginx.conf"
        fi
        
        if grep -q "application live" nginx.conf; then
            print_result "PASS" "Live application block found"
        else
            print_result "FAIL" "Live application block missing"
        fi
        
        # Check for platform configurations
        local platforms=("twitch" "youtube" "kick")
        for platform in "${platforms[@]}"; do
            if grep -q "application $platform" nginx.conf; then
                print_result "PASS" "$platform application block found"
            else
                print_result "WARN" "$platform application block missing"
            fi
        done
        
        # Check for placeholder keys
        if grep -q "YOUR_TWITCH_KEY\|YOUR_YOUTUBE_KEY\|YOUR_KICK_KEY" nginx.conf; then
            print_result "WARN" "Placeholder stream keys found" "Run configure-keys.sh or setup-wizard to set real keys"
        else
            print_result "PASS" "Stream keys appear to be configured"
        fi
        
        # Check for FFmpeg commands
        if grep -q "exec ffmpeg" nginx.conf; then
            print_result "PASS" "FFmpeg commands found in configuration"
        else
            print_result "FAIL" "FFmpeg commands missing from configuration"
        fi
        
        # Check for HLS configuration
        if grep -q "hls on" nginx.conf; then
            print_result "PASS" "HLS streaming enabled"
        else
            print_result "WARN" "HLS streaming not enabled"
        fi
        
        # Check for statistics endpoint
        if grep -q "rtmp_stat" nginx.conf; then
            print_result "PASS" "RTMP statistics endpoint configured"
        else
            print_result "WARN" "RTMP statistics endpoint not configured"
        fi
        
    else
        print_result "FAIL" "nginx.conf file missing"
    fi
}

# Function to validate installation script
validate_install_script() {
    print_color $BLUE "\n🚀 Validating Installation Script"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    if [ -f "install.sh" ]; then
        # Check if executable
        if [ -x "install.sh" ]; then
            print_result "PASS" "install.sh is executable"
        else
            print_result "WARN" "install.sh is not executable" "Run: chmod +x install.sh"
        fi
        
        # Check for key components
        if grep -q "apt update" install.sh; then
            print_result "PASS" "System update commands found"
        else
            print_result "WARN" "System update commands not found"
        fi
        
        if grep -q "nginx.*rtmp" install.sh; then
            print_result "PASS" "Nginx RTMP module installation found"
        else
            print_result "FAIL" "Nginx RTMP module installation missing"
        fi
        
        if grep -q "ffmpeg" install.sh; then
            print_result "PASS" "FFmpeg installation found"
        else
            print_result "FAIL" "FFmpeg installation missing"
        fi
        
        if grep -q "systemctl" install.sh; then
            print_result "PASS" "Systemd service setup found"
        else
            print_result "WARN" "Systemd service setup not found"
        fi
        
    else
        print_result "FAIL" "install.sh script missing"
    fi
}

# Function to validate service file
validate_service_file() {
    print_color $BLUE "\n⚙️  Validating Service Configuration"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    if [ -f "nginx-rtmp.service" ]; then
        # Check for required sections
        if grep -q "\[Unit\]" nginx-rtmp.service; then
            print_result "PASS" "Service Unit section found"
        else
            print_result "FAIL" "Service Unit section missing"
        fi
        
        if grep -q "\[Service\]" nginx-rtmp.service; then
            print_result "PASS" "Service section found"
        else
            print_result "FAIL" "Service section missing"
        fi
        
        if grep -q "\[Install\]" nginx-rtmp.service; then
            print_result "PASS" "Install section found"
        else
            print_result "FAIL" "Install section missing"
        fi
        
        # Check for key configurations
        if grep -q "ExecStart" nginx-rtmp.service; then
            print_result "PASS" "ExecStart directive found"
        else
            print_result "FAIL" "ExecStart directive missing"
        fi
        
        if grep -q "Restart=" nginx-rtmp.service; then
            print_result "PASS" "Restart policy configured"
        else
            print_result "WARN" "Restart policy not configured"
        fi
        
    else
        print_result "FAIL" "nginx-rtmp.service file missing"
    fi
}

# Function to validate scripts
validate_scripts() {
    print_color $BLUE "\n📜 Validating Helper Scripts"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    local scripts=(
        "configure-keys.sh:Stream key configuration script:true"
        "test-stream.sh:Stream testing script:true"
        "monitor-streams.sh:Stream monitoring script:true"
        "quick-start.sh:Quick start menu script:true"
        "setup-wizard.sh:Interactive setup wizard:true"
        "setup-wizard.ps1:PowerShell setup wizard:false"
    )
    
    for script_info in "${scripts[@]}"; do
        IFS=':' read -r script desc required <<< "$script_info"
        check_file "$script" "$desc" "$required" 100
        
        if [ -f "$script" ] && [[ "$script" == *.sh ]]; then
            if [ -x "$script" ]; then
                print_result "PASS" "$script is executable"
            else
                print_result "WARN" "$script is not executable" "Run: chmod +x $script"
            fi
        fi
    done
}

# Function to validate documentation
validate_documentation() {
    print_color $BLUE "\n📚 Validating Documentation"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    local docs=(
        "README.md:Main documentation:true:1000"
        "OBS-SETUP-GUIDE.md:OBS setup guide:true:500"
        "project.md:Project specification:false:500"
    )
    
    for doc_info in "${docs[@]}"; do
        IFS=':' read -r doc desc required min_size <<< "$doc_info"
        check_file "$doc" "$desc" "$required" "$min_size"
        
        if [ -f "$doc" ]; then
            # Check for basic markdown structure
            if grep -q "^#" "$doc"; then
                print_result "PASS" "$doc has proper markdown headers"
            else
                print_result "WARN" "$doc may not have proper markdown structure"
            fi
        fi
    done
}

# Function to validate test files
validate_test_files() {
    print_color $BLUE "\n🧪 Validating Test Files"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    local test_files=(
        "test-obs-connection.bat:Windows OBS connection test:false"
        "validate-project.sh:Project validation script:true"
    )
    
    for test_info in "${test_files[@]}"; do
        IFS=':' read -r test desc required <<< "$test_info"
        check_file "$test" "$desc" "$required" 50
    done
}

# Function to check for common issues
check_common_issues() {
    print_color $BLUE "\n🔍 Checking for Common Issues"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    # Check for Windows line endings in shell scripts
    for script in *.sh; do
        if [ -f "$script" ]; then
            if file "$script" | grep -q "CRLF"; then
                print_result "WARN" "$script has Windows line endings" "May cause issues on Linux. Run: dos2unix $script"
            else
                print_result "PASS" "$script has Unix line endings"
            fi
        fi
    done
    
    # Check for sensitive information
    for file in *.conf *.sh *.md; do
        if [ -f "$file" ]; then
            if grep -q "password\|secret\|token" "$file" | grep -v "YOUR_" | grep -v "#" | head -1; then
                print_result "WARN" "$file may contain sensitive information" "Review and ensure no real credentials are exposed"
            fi
        fi
    done
    
    # Check for TODO or FIXME comments
    local todo_count=0
    for file in *.sh *.conf *.md; do
        if [ -f "$file" ]; then
            local count=$(grep -c "TODO\|FIXME\|XXX" "$file" 2>/dev/null || echo "0")
            todo_count=$((todo_count + count))
        fi
    done
    
    if [ $todo_count -gt 0 ]; then
        print_result "WARN" "Found $todo_count TODO/FIXME comments" "Review and address pending items"
    else
        print_result "PASS" "No TODO/FIXME comments found"
    fi
}

# Function to validate project structure
validate_project_structure() {
    print_color $BLUE "\n📁 Validating Project Structure"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    # Core files that must exist
    local core_files=(
        "nginx.conf"
        "install.sh"
        "nginx-rtmp.service"
        "README.md"
    )
    
    local missing_core=0
    for file in "${core_files[@]}"; do
        if [ ! -f "$file" ]; then
            ((missing_core++))
        fi
    done
    
    if [ $missing_core -eq 0 ]; then
        print_result "PASS" "All core files present"
    else
        print_result "FAIL" "$missing_core core files missing"
    fi
    
    # Check for recommended files
    local recommended_files=(
        "configure-keys.sh"
        "test-stream.sh"
        "monitor-streams.sh"
        "OBS-SETUP-GUIDE.md"
    )
    
    local missing_recommended=0
    for file in "${recommended_files[@]}"; do
        if [ ! -f "$file" ]; then
            ((missing_recommended++))
        fi
    done
    
    if [ $missing_recommended -eq 0 ]; then
        print_result "PASS" "All recommended files present"
    else
        print_result "WARN" "$missing_recommended recommended files missing"
    fi
}

# Function to show validation summary
show_validation_summary() {
    print_color $BLUE "\n📊 Validation Summary"
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    echo
    
    local total=$((PASSED + WARNINGS + ERRORS))
    
    print_color $GREEN "✅ Passed: $PASSED/$total tests"
    print_color $YELLOW "⚠️  Warnings: $WARNINGS/$total tests"
    print_color $RED "❌ Errors: $ERRORS/$total tests"
    echo
    
    if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        print_color $GREEN "🎉 Perfect! Your project is complete and ready for deployment!"
        echo
        print_color $BLUE "Next steps:"
        echo "1. Upload all files to your VPS"
        echo "2. Run: chmod +x *.sh"
        echo "3. Execute: ./setup-wizard.sh"
        echo "4. Configure your stream keys"
        echo "5. Test with OBS/Streamlabs OBS"
        
    elif [ $ERRORS -eq 0 ]; then
        print_color $YELLOW "⚠️  Good! Your project is mostly complete with minor warnings."
        echo
        print_color $BLUE "Recommendations:"
        echo "1. Review and address the warnings above"
        echo "2. Test the setup thoroughly"
        echo "3. Consider adding missing optional components"
        
    else
        print_color $RED "❌ Issues found! Please address the errors before deployment."
        echo
        print_color $BLUE "Required actions:"
        echo "1. Fix all error conditions listed above"
        echo "2. Re-run this validation script"
        echo "3. Ensure all core files are present and properly configured"
    fi
    
    echo
    print_color $CYAN "═══════════════════════════════════════════════════════════════"
    
    # Return appropriate exit code
    if [ $ERRORS -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Main validation function
main() {
    print_banner
    
    print_color $BLUE "🔍 Starting comprehensive project validation..."
    print_color $YELLOW "This will check all components for completeness and correctness."
    echo
    
    # Run all validation checks
    validate_project_structure
    validate_nginx_config
    validate_install_script
    validate_service_file
    validate_scripts
    validate_documentation
    validate_test_files
    check_common_issues
    
    # Show summary and exit with appropriate code
    show_validation_summary
}

# Run main function
main "$@"