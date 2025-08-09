# Project Validation Script - PowerShell Version
# Ensures all components are present and properly configured

param(
    [switch]$Detailed
)

# Validation results
$script:ERRORS = 0
$script:WARNINGS = 0
$script:PASSED = 0

# Function to print colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue" { Write-Host $Message -ForegroundColor Blue }
        "Magenta" { Write-Host $Message -ForegroundColor Magenta }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message -ForegroundColor White }
    }
}

# Function to print test result
function Write-TestResult {
    param(
        [string]$Status,
        [string]$Message,
        [string]$Details = ""
    )
    
    switch ($Status) {
        "PASS" {
            Write-ColorOutput "✅ PASS: $Message" "Green"
            $script:PASSED++
        }
        "WARN" {
            Write-ColorOutput "⚠️  WARN: $Message" "Yellow"
            if ($Details) {
                Write-ColorOutput "    $Details" "Yellow"
            }
            $script:WARNINGS++
        }
        "FAIL" {
            Write-ColorOutput "❌ FAIL: $Message" "Red"
            if ($Details) {
                Write-ColorOutput "    $Details" "Red"
            }
            $script:ERRORS++
        }
    }
}

# Function to print banner
function Show-Banner {
    Clear-Host
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                                                              ║" "Cyan"
    Write-ColorOutput "║        🔍 Multi-Platform Streaming Project Validator        ║" "Cyan"
    Write-ColorOutput "║                                                              ║" "Cyan"
    Write-ColorOutput "║            Comprehensive Project Completeness Check         ║" "Cyan"
    Write-ColorOutput "║                                                              ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

# Function to check file existence and basic validation
function Test-ProjectFile {
    param(
        [string]$FilePath,
        [string]$Description,
        [bool]$Required = $true,
        [int]$MinSize = 1
    )
    
    if (Test-Path $FilePath) {
        $size = (Get-Item $FilePath).Length
        if ($size -ge $MinSize) {
            Write-TestResult "PASS" "$Description exists and has content ($size bytes)"
        } else {
            Write-TestResult "WARN" "$Description exists but seems empty or too small ($size bytes)"
        }
        return $true
    } else {
        if ($Required) {
            Write-TestResult "FAIL" "$Description is missing" "Required file: $FilePath"
        } else {
            Write-TestResult "WARN" "$Description is missing" "Optional file: $FilePath"
        }
        return $false
    }
}

# Function to validate project structure
function Test-ProjectStructure {
    Write-ColorOutput "`n📁 Validating Project Structure" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    
    # Core files that must exist
    $coreFiles = @(
        "nginx.conf",
        "install.sh",
        "nginx-rtmp.service",
        "README.md"
    )
    
    $missingCore = 0
    foreach ($file in $coreFiles) {
        if (!(Test-Path $file)) {
            $missingCore++
        }
    }
    
    if ($missingCore -eq 0) {
        Write-TestResult "PASS" "All core files present"
    } else {
        Write-TestResult "FAIL" "$missingCore core files missing"
    }
    
    # Check for recommended files
    $recommendedFiles = @(
        "configure-keys.sh",
        "test-stream.sh",
        "monitor-streams.sh",
        "OBS-SETUP-GUIDE.md",
        "setup-wizard.sh",
        "setup-wizard.ps1"
    )
    
    $missingRecommended = 0
    foreach ($file in $recommendedFiles) {
        if (!(Test-Path $file)) {
            $missingRecommended++
        }
    }
    
    if ($missingRecommended -eq 0) {
        Write-TestResult "PASS" "All recommended files present"
    } else {
        Write-TestResult "WARN" "$missingRecommended recommended files missing"
    }
}

# Function to validate nginx configuration
function Test-NginxConfig {
    Write-ColorOutput "`n📋 Validating Nginx Configuration" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    
    if (Test-Path "nginx.conf") {
        $content = Get-Content "nginx.conf" -Raw
        
        # Check for required sections
        if ($content -match "rtmp \{") {
            Write-TestResult "PASS" "RTMP block found in nginx.conf"
        } else {
            Write-TestResult "FAIL" "RTMP block missing in nginx.conf"
        }
        
        if ($content -match "application live") {
            Write-TestResult "PASS" "Live application block found"
        } else {
            Write-TestResult "FAIL" "Live application block missing"
        }
        
        # Check for platform configurations
        $platforms = @("twitch", "youtube", "kick")
        foreach ($platform in $platforms) {
            if ($content -match "application $platform") {
                Write-TestResult "PASS" "$platform application block found"
            } else {
                Write-TestResult "WARN" "$platform application block missing"
            }
        }
        
        # Check for placeholder keys
        if ($content -match "YOUR_TWITCH_KEY|YOUR_YOUTUBE_KEY|YOUR_KICK_KEY") {
            Write-TestResult "WARN" "Placeholder stream keys found" "Run configure-keys.sh or setup-wizard to set real keys"
        } else {
            Write-TestResult "PASS" "Stream keys appear to be configured"
        }
        
        # Check for FFmpeg commands
        if ($content -match "exec ffmpeg") {
            Write-TestResult "PASS" "FFmpeg commands found in configuration"
        } else {
            Write-TestResult "FAIL" "FFmpeg commands missing from configuration"
        }
        
        # Check for HLS configuration
        if ($content -match "hls on") {
            Write-TestResult "PASS" "HLS streaming enabled"
        } else {
            Write-TestResult "WARN" "HLS streaming not enabled"
        }
        
        # Check for statistics endpoint
        if ($content -match "rtmp_stat") {
            Write-TestResult "PASS" "RTMP statistics endpoint configured"
        } else {
            Write-TestResult "WARN" "RTMP statistics endpoint not configured"
        }
        
    } else {
        Write-TestResult "FAIL" "nginx.conf file missing"
    }
}

# Function to validate scripts
function Test-Scripts {
    Write-ColorOutput "`n📜 Validating Helper Scripts" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    
    $scripts = @(
        @{File="configure-keys.sh"; Desc="Stream key configuration script"; Required=$true},
        @{File="test-stream.sh"; Desc="Stream testing script"; Required=$true},
        @{File="monitor-streams.sh"; Desc="Stream monitoring script"; Required=$true},
        @{File="quick-start.sh"; Desc="Quick start menu script"; Required=$true},
        @{File="setup-wizard.sh"; Desc="Interactive setup wizard (Linux)"; Required=$true},
        @{File="setup-wizard.ps1"; Desc="Interactive setup wizard (Windows)"; Required=$false},
        @{File="validate-project.sh"; Desc="Project validation script (Linux)"; Required=$false},
        @{File="validate-project.ps1"; Desc="Project validation script (Windows)"; Required=$true}
    )
    
    foreach ($script in $scripts) {
        Test-ProjectFile $script.File $script.Desc $script.Required 100
    }
}

# Function to validate documentation
function Test-Documentation {
    Write-ColorOutput "`n📚 Validating Documentation" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    
    $docs = @(
        @{File="README.md"; Desc="Main documentation"; Required=$true; MinSize=1000},
        @{File="OBS-SETUP-GUIDE.md"; Desc="OBS setup guide"; Required=$true; MinSize=500},
        @{File="project.md"; Desc="Project specification"; Required=$false; MinSize=500}
    )
    
    foreach ($doc in $docs) {
        if (Test-ProjectFile $doc.File $doc.Desc $doc.Required $doc.MinSize) {
            # Check for basic markdown structure
            $content = Get-Content $doc.File -Raw
            if ($content -match "^#") {
                Write-TestResult "PASS" "$($doc.File) has proper markdown headers"
            } else {
                Write-TestResult "WARN" "$($doc.File) may not have proper markdown structure"
            }
        }
    }
}

# Function to show validation summary
function Show-ValidationSummary {
    Write-ColorOutput "`n📊 Validation Summary" "Blue"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    $total = $script:PASSED + $script:WARNINGS + $script:ERRORS
    
    Write-ColorOutput "✅ Passed: $($script:PASSED)/$total tests" "Green"
    Write-ColorOutput "⚠️  Warnings: $($script:WARNINGS)/$total tests" "Yellow"
    Write-ColorOutput "❌ Errors: $($script:ERRORS)/$total tests" "Red"
    Write-Host ""
    
    if ($script:ERRORS -eq 0 -and $script:WARNINGS -eq 0) {
        Write-ColorOutput "🎉 Perfect! Your project is complete and ready for deployment!" "Green"
        Write-Host ""
        Write-ColorOutput "Next steps:" "Blue"
        Write-Host "1. Upload all files to your VPS"
        Write-Host "2. Run: chmod +x *.sh"
        Write-Host "3. Execute: ./setup-wizard.sh"
        Write-Host "4. Configure your stream keys"
        Write-Host "5. Test with OBS/Streamlabs OBS"
        
    } elseif ($script:ERRORS -eq 0) {
        Write-ColorOutput "⚠️  Good! Your project is mostly complete with minor warnings." "Yellow"
        Write-Host ""
        Write-ColorOutput "Recommendations:" "Blue"
        Write-Host "1. Review and address the warnings above"
        Write-Host "2. Test the setup thoroughly"
        Write-Host "3. Consider adding missing optional components"
        
    } else {
        Write-ColorOutput "❌ Issues found! Please address the errors before deployment." "Red"
        Write-Host ""
        Write-ColorOutput "Required actions:" "Blue"
        Write-Host "1. Fix all error conditions listed above"
        Write-Host "2. Re-run this validation script"
        Write-Host "3. Ensure all core files are present and properly configured"
    }
    
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    
    # Return appropriate exit code
    if ($script:ERRORS -gt 0) {
        return 1
    } else {
        return 0
    }
}

# Main validation function
function Main {
    Show-Banner
    
    Write-ColorOutput "🔍 Starting comprehensive project validation..." "Blue"
    Write-ColorOutput "This will check all components for completeness and correctness." "Yellow"
    Write-Host ""
    
    # Run all validation checks
    Test-ProjectStructure
    Test-NginxConfig
    Test-Scripts
    Test-Documentation
    
    # Show summary and exit with appropriate code
    $exitCode = Show-ValidationSummary
    
    if ($Detailed) {
        Write-Host ""
        Write-ColorOutput "📋 Detailed File Listing:" "Blue"
        Get-ChildItem | Format-Table Name, Length, LastWriteTime -AutoSize
    }
    
    exit $exitCode
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-ColorOutput "❌ PowerShell 5.0 or higher is required!" "Red"
    Write-ColorOutput "💡 Please upgrade your PowerShell version." "Yellow"
    exit 1
}

# Run main function
Main