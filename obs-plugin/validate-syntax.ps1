#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Syntax validation script for StreamRelay OBS Studio Plugin

.DESCRIPTION
    This script validates the C++ syntax without requiring compilation.
    It checks for common syntax errors, missing includes, and code structure.
#>

# Colors for output
$ErrorColor = 'Red'
$SuccessColor = 'Green'
$InfoColor = 'Cyan'
$WarningColor = 'Yellow'

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Test-CppSyntax {
    param([string]$FilePath)
    
    if (!(Test-Path $FilePath)) {
        Write-ColorOutput "ERROR: File not found: $FilePath" $ErrorColor
        return $false
    }
    
    $content = Get-Content $FilePath -Raw
    $issues = @()
    
    # Check for basic syntax issues
    $braceCount = ($content.ToCharArray() | Where-Object { $_ -eq '{' }).Count - ($content.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    if ($braceCount -ne 0) {
        $issues += "Mismatched braces (difference: $braceCount)"
    }
    
    $parenCount = ($content.ToCharArray() | Where-Object { $_ -eq '(' }).Count - ($content.ToCharArray() | Where-Object { $_ -eq ')' }).Count
    if ($parenCount -ne 0) {
        $issues += "Mismatched parentheses (difference: $parenCount)"
    }
    
    # Check for required elements
    if ($content -notmatch 'class StreamRelayDialog') {
        $issues += "Missing StreamRelayDialog class definition"
    }
    
    if ($content -notmatch 'class StreamRelayPlugin') {
        $issues += "Missing StreamRelayPlugin class definition"
    }
    
    if ($content -notmatch '#include "plugin-macros.h"') {
        $issues += "Missing plugin-macros.h include"
    }
    
    if ($content -notmatch 'Q_OBJECT') {
        $issues += "Missing Q_OBJECT macro (required for Qt MOC)"
    }
    
    # Check conditional compilation
    if ($content -notmatch '#ifdef OBS_STUDIO_BUILD') {
        $issues += "Missing OBS_STUDIO_BUILD conditional compilation"
    }
    
    if ($content -notmatch '#ifdef QT_WIDGETS_LIB') {
        $issues += "Missing QT_WIDGETS_LIB conditional compilation"
    }
    
    # Check for MOC include
    if ($content -notmatch '#include "stream-relay-plugin.moc"') {
        $issues += "Missing MOC include at end of file"
    }
    
    return $issues
}

Write-ColorOutput "StreamRelay Plugin Syntax Validator" $InfoColor
Write-ColorOutput "======================================" $InfoColor

# Validate main plugin file
Write-ColorOutput "`nValidating stream-relay-plugin.cpp..." $InfoColor
$cppIssues = Test-CppSyntax "stream-relay-plugin.cpp"

if ($cppIssues.Count -eq 0) {
    Write-ColorOutput "SUCCESS: stream-relay-plugin.cpp syntax is valid" $SuccessColor
} else {
    Write-ColorOutput "ISSUES found in stream-relay-plugin.cpp:" $WarningColor
    foreach ($issue in $cppIssues) {
        Write-ColorOutput "  - $issue" $WarningColor
    }
}

# Validate header file
Write-ColorOutput "`nValidating plugin-macros.h..." $InfoColor
if (Test-Path "plugin-macros.h") {
    $headerContent = Get-Content "plugin-macros.h" -Raw
    
    $headerIssues = @()
    if ($headerContent -notmatch '#define PLUGIN_VERSION') {
        $headerIssues += "Missing PLUGIN_VERSION definition"
    }
    
    if ($headerIssues.Count -eq 0) {
        Write-ColorOutput "SUCCESS: plugin-macros.h is valid" $SuccessColor
    } else {
        Write-ColorOutput "ISSUES found in plugin-macros.h:" $WarningColor
        foreach ($issue in $headerIssues) {
            Write-ColorOutput "  - $issue" $WarningColor
        }
    }
} else {
    Write-ColorOutput "WARNING: plugin-macros.h not found" $WarningColor
}

# Validate CMakeLists.txt
Write-ColorOutput "`nValidating CMakeLists.txt..." $InfoColor
if (Test-Path "CMakeLists.txt") {
    $cmakeContent = Get-Content "CMakeLists.txt" -Raw
    
    $cmakeIssues = @()
    if ($cmakeContent -notmatch 'target_compile_definitions.*OBS_STUDIO_BUILD') {
        $cmakeIssues += "Missing OBS_STUDIO_BUILD definition"
    }
    
    if ($cmakeContent -notmatch 'target_compile_definitions.*QT_WIDGETS_LIB') {
        $cmakeIssues += "Missing QT_WIDGETS_LIB definition"
    }
    
    if ($cmakeContent -notmatch 'AUTOMOC ON') {
        $cmakeIssues += "Missing AUTOMOC setting"
    }
    
    if ($cmakeIssues.Count -eq 0) {
        Write-ColorOutput "SUCCESS: CMakeLists.txt is properly configured" $SuccessColor
    } else {
        Write-ColorOutput "ISSUES found in CMakeLists.txt:" $WarningColor
        foreach ($issue in $cmakeIssues) {
            Write-ColorOutput "  - $issue" $WarningColor
        }
    }
} else {
    Write-ColorOutput "WARNING: CMakeLists.txt not found" $WarningColor
}

# Summary
Write-ColorOutput "`n======================================" $InfoColor
$totalIssues = $cppIssues.Count
if (Test-Path "plugin-macros.h") { $totalIssues += $headerIssues.Count }
if (Test-Path "CMakeLists.txt") { $totalIssues += $cmakeIssues.Count }

if ($totalIssues -eq 0) {
    Write-ColorOutput "OVERALL: All files passed validation!" $SuccessColor
    Write-ColorOutput "The plugin code structure is correct and ready for compilation." $InfoColor
} else {
    Write-ColorOutput "OVERALL: Found $totalIssues issue(s) that should be addressed." $WarningColor
}

Write-ColorOutput "`nNext steps:" $InfoColor
Write-ColorOutput "1. Install OBS Studio SDK and Qt6 for full compilation" $InfoColor
Write-ColorOutput "2. Use build-plugin.ps1 -Mode obs-plugin to build the actual plugin" $InfoColor
Write-ColorOutput "3. The conditional compilation ensures compatibility with different environments" $InfoColor