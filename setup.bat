@echo off
echo ===================================================
echo          StreamRelay Windows Setup
echo ===================================================
echo.
echo This batch file will help you set up StreamRelay on Windows.
echo.
echo IMPORTANT: The install.sh and setup-wizard.sh files are for Linux/Ubuntu.
echo For Windows, please follow these steps:
echo.
echo 1. Install .NET 6.0 SDK:
echo    - Visit: https://dotnet.microsoft.com/download/dotnet/6.0
echo    - Download and install the SDK (not just runtime)
echo.
echo 2. After installing .NET SDK, restart this command prompt
echo.
echo 3. Run the Windows setup script:
echo    PowerShell -ExecutionPolicy Bypass -File setup-windows.ps1
echo.
echo 4. Or build the desktop app directly:
echo    PowerShell -ExecutionPolicy Bypass -File build-desktop-app.ps1 -IncludeDependencies
echo.
echo ===================================================
echo.
pause
echo.
echo Opening .NET download page...
start https://dotnet.microsoft.com/download/dotnet/6.0
echo.
echo After installing .NET SDK, run:
echo PowerShell -ExecutionPolicy Bypass -File setup-windows.ps1
echo.
pause