@echo off
setlocal EnableDelayedExpansion
title KAITUN SETUP

:: =============================================
:: STEP 0 - Ask FarmSync Key
:: =============================================
echo ============================================
echo  KAITUN SETUP - Enter your FarmSync key
echo ============================================
echo.
set /p "FARMSYNC_KEY=Enter FarmSync Key: "

if "!FARMSYNC_KEY!"=="" (
    echo [!] Key cannot be empty. Exiting.
    pause
    exit /b 1
)

echo.
echo [*] Key received. Starting setup...
echo.

:: =============================================
:: STEP 1 - Download files from GitHub
:: =============================================
echo [1/4] Downloading files from GitHub...

set "REPO_RAW=https://github.com/TuanDarcy/file-install/raw/main"
set "DESKTOP=%USERPROFILE%\Desktop"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri '%REPO_RAW%/OptimizerRoblox.exe' -OutFile '%DESKTOP%\OptimizerRoblox.exe' -UseBasicParsing"

if not exist "%DESKTOP%\OptimizerRoblox.exe" (
    echo [-] Failed to download OptimizerRoblox.exe
    pause
    exit /b 1
)
echo [+] OptimizerRoblox.exe downloaded to Desktop

:: Download Tnesc installer
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri '%REPO_RAW%/TNesc_Executor_Setup_0.0.1.22.exe' -OutFile '%TEMP%\Tnesc_setup.exe' -UseBasicParsing"

:: =============================================
:: STEP 2 - Run OptimizerRoblox
:: =============================================
echo.
echo [2/4] Launching OptimizerRoblox...
start "" "%DESKTOP%\OptimizerRoblox.exe"
timeout /t 3 /nobreak >nul

:: =============================================
:: STEP 3 - Install Tnesc (silent, auto-accept)
:: =============================================
echo.
echo [3/4] Installing Tnesc...

if exist "%TEMP%\Tnesc_setup.exe" (
    :: /S = silent install, /VERYSILENT for NSIS/Inno Setup
    start /wait "" "%TEMP%\Tnesc_setup.exe" /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
    echo [+] Tnesc installed

    :: Copy shortcut to Desktop if installer didn't
    if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Tnesc\Tnesc.lnk" (
        copy /Y "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Tnesc\Tnesc.lnk" "%DESKTOP%\" >nul
    )
) else (
    echo [-] Tnesc_setup.exe not found in repo, skipping
)

:: =============================================
:: STEP 4 - FarmSync install with user key
:: =============================================
echo.
echo [4/4] Installing FarmSync with your key...

set "FARMSYNC_URL=https://downloads.farmsync.cloud/client_web.exe"
set "FARMSYNC_CLIENT=client_web"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$env:FARMSYNC_KEY='!FARMSYNC_KEY!'; $env:FARMSYNC_URL='%FARMSYNC_URL%'; $env:FARMSYNC_CLIENT='%FARMSYNC_CLIENT%'; irm 'https://files.farmsync.cloud/files/install.ps1' | iex"

echo.
echo ============================================
echo  Setup complete!
echo ============================================
pause
