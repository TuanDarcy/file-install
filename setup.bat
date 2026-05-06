@echo off
setlocal EnableDelayedExpansion
title KAITUN SETUP

set "SCRIPTDIR=%~dp0"
set "DESKTOP=%USERPROFILE%\Desktop"

:: =============================================
:: STEP 0 - Ask FarmSync Key
:: =============================================
echo.
echo  ==========================================
echo   KAITUN SETUP
echo  ==========================================
echo.
set /p "FARMSYNC_KEY=  Enter FarmSync Key: "

if "!FARMSYNC_KEY!"=="" (
    echo [!] Key cannot be empty. Exiting.
    pause
    exit /b 1
)

echo.
echo [*] Key accepted. Starting setup...
echo.

:: =============================================
:: STEP 1 - OptimizerRoblox: copy to Desktop + run + add to startup
:: =============================================
echo [1/3] Setting up OptimizerRoblox...

copy /Y "%SCRIPTDIR%OptimizerRoblox.exe" "%DESKTOP%\OptimizerRoblox.exe" >nul 2>&1

if not exist "%DESKTOP%\OptimizerRoblox.exe" (
    echo [-] OptimizerRoblox.exe not found in setup folder
    pause
    exit /b 1
)
echo [+] OptimizerRoblox copied to Desktop

:: Add to Windows Startup (runs on every login)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OptimizerRoblox" /t REG_SZ /d "\"%DESKTOP%\OptimizerRoblox.exe\"" /f >nul
echo [+] OptimizerRoblox added to Windows startup

:: Launch it now
start "" "%DESKTOP%\OptimizerRoblox.exe"
echo [+] OptimizerRoblox launched
timeout /t 2 /nobreak >nul

:: =============================================
:: STEP 2 - FarmSync install with user key
:: =============================================
echo.
echo [2/3] Installing FarmSync...

set "FARMSYNC_URL=https://downloads.farmsync.cloud/client_web.exe"
set "FARMSYNC_CLIENT=client_web"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$env:FARMSYNC_KEY='!FARMSYNC_KEY!'; $env:FARMSYNC_URL='%FARMSYNC_URL%'; $env:FARMSYNC_CLIENT='%FARMSYNC_CLIENT%'; irm 'https://files.farmsync.cloud/files/install.ps1' | iex"

echo [+] FarmSync install done

:: =============================================
:: STEP 3 - Install TNesc (silent, all permissions)
:: =============================================
echo.
echo [3/3] Installing TNesc...

if exist "%SCRIPTDIR%TNesc_Executor_Setup_0.0.1.22.exe" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%SCRIPTDIR%TNesc_Executor_Setup_0.0.1.22.exe' -ArgumentList '/S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' -Verb RunAs -Wait"
    echo [+] TNesc installed
) else (
    echo [-] TNesc installer not found, skipping
)

echo.
echo  ==========================================
echo   Setup complete!
echo  ==========================================
echo.
pause
