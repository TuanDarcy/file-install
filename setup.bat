@echo off
setlocal EnableDelayedExpansion
title KAITUN SETUP

set "DESKTOP=%USERPROFILE%\Desktop"
set "SETUP_DIR=%DESKTOP%\AutoSetupTFA"
set "FARMSYNC_DIR=%DESKTOP%\FarmSync"
set "KEY_FILE=%FARMSYNC_DIR%\key.txt"
set "LOCAL_VER_FILE=%SETUP_DIR%\ver.txt"
set "OPTIMIZER_EXE=%DESKTOP%\OptimizerRoblox.exe"
set "REPO_RAW=https://github.com/TuanDarcy/file-install/raw/main"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "FARMSYNC_URL=https://downloads.farmsync.cloud/client_web.exe"
set "FARMSYNC_CLIENT=client_web"

:: =============================================
:: STEP 1 - Check version FIRST (runs every boot)
:: =============================================
echo [*] Checking for updates...

set "REMOTE_VER=0"
for /f "delims=" %%v in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "try{(Invoke-WebRequest '%REPO_RAW%/version.txt' -UseBasicParsing).Content.Trim()}catch{'0'}" 2^>nul') do set "REMOTE_VER=%%v"

set "LOCAL_VER=0"
if exist "%LOCAL_VER_FILE%" (
    set /p LOCAL_VER=<"%LOCAL_VER_FILE%"
    set "LOCAL_VER=!LOCAL_VER: =!"
)

echo [*] Local v!LOCAL_VER! / Remote v!REMOTE_VER!

:: =============================================
:: Decide: first install OR auto-update
:: =============================================
if exist "%KEY_FILE%" (
    :: Already installed - check if update needed
    if !REMOTE_VER! LEQ !LOCAL_VER! (
        :: Up to date - silent exit
        exit /b 0
    )
    :: New version found - auto update with saved key
    set /p FARMSYNC_KEY=<"%KEY_FILE%"
    echo [*] New version v!REMOTE_VER! found. Auto-updating...
    goto :AUTO_UPDATE
)

:: =============================================
:: FIRST INSTALL - ask key
:: =============================================
echo.
echo  ==========================================
echo   KAITUN SETUP - First Install
echo  ==========================================
echo.
set /p "FARMSYNC_KEY=  Enter FarmSync Key: "

if "!FARMSYNC_KEY!"=="" (
    echo [!] Key cannot be empty.
    pause
    exit /b 1
)
echo.

:: --- 1. OptimizerRoblox ---
echo [1/4] Downloading OptimizerRoblox...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest '%REPO_RAW%/OptimizerRoblox.exe' -OutFile '%OPTIMIZER_EXE%' -UseBasicParsing"

if not exist "%OPTIMIZER_EXE%" (
    echo [-] Failed to download OptimizerRoblox.exe
    pause & exit /b 1
)
echo [+] Downloaded OptimizerRoblox

:: Create .lnk shortcut in Startup folder (shows in Task Manager Startup tab)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ws=New-Object -ComObject WScript.Shell;$s=$ws.CreateShortcut('%STARTUP%\OptimizerRoblox.lnk');$s.TargetPath='%OPTIMIZER_EXE%';$s.WorkingDirectory='%DESKTOP%';$s.Description='Roblox Optimizer';$s.Save()"
echo [+] OptimizerRoblox shortcut added to Startup folder

start "" "%OPTIMIZER_EXE%"
echo [+] OptimizerRoblox launched

:: --- 2. TNesc ---
echo.
echo [2/4] Downloading and installing TNesc...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest '%REPO_RAW%/TNesc_Executor_Setup_0.0.1.22.exe' -OutFile '%TEMP%\TNesc_setup.exe' -UseBasicParsing"

if exist "%TEMP%\TNesc_setup.exe" (
    :: Chạy installer bình thường - người dùng tự bấm Next/Accept/Finish
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process '%TEMP%\TNesc_setup.exe' -Verb RunAs"
    echo [*] TNesc installer launched - waiting for installation...

    :: Đợi tối đa 3 phút cho đến khi TNescApp.exe xuất hiện trong AppData\Local\Cuckuu
    set "TNESC_EXE="
    set "TNESC_WAITED=0"
    :WAIT_TNESC
    if exist "%LOCALAPPDATA%\Cuckuu\TNescApp.exe" set "TNESC_EXE=%LOCALAPPDATA%\Cuckuu\TNescApp.exe"
    if "!TNESC_EXE!"=="" (
        if !TNESC_WAITED! LSS 180 (
            timeout /t 3 /nobreak >nul
            set /a TNESC_WAITED+=3
            goto :WAIT_TNESC
        )
    )

    if not "!TNESC_EXE!"=="" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "$ws=New-Object -ComObject WScript.Shell;$s=$ws.CreateShortcut('%STARTUP%\TNesc.lnk');$s.TargetPath='%LOCALAPPDATA%\Cuckuu\TNescApp.exe';$s.WorkingDirectory='%LOCALAPPDATA%\Cuckuu';$s.Description='TNesc Executor';$s.Save()"
        echo [+] TNesc shortcut added to Startup folder
    ) else (
        echo [-] TNesc not detected after 3 minutes, skipping
    )
) else (
    echo [-] TNesc download failed, skipping
)

:: --- 3. Add this setup.bat to startup for auto-update checks ---
echo.
echo [3/4] Configuring auto-update on startup...

:: Save key to FarmSync folder now (before FarmSync runs)
if not exist "%FARMSYNC_DIR%" mkdir "%FARMSYNC_DIR%" >nul 2>&1
if not exist "%KEY_FILE%" (
    echo !FARMSYNC_KEY!>"%KEY_FILE%"
    echo [+] Key saved to FarmSync folder
)

:: Ensure AutoSetupTFA folder exists
if not exist "%SETUP_DIR%" mkdir "%SETUP_DIR%" >nul 2>&1

:: Copy this bat to AutoSetupTFA folder
copy /Y "%~f0" "%SETUP_DIR%\setup.bat" >nul
echo [+] Setup script saved to AutoSetupTFA folder

:: Create silent VBS launcher for startup
(
    echo Set ws = CreateObject^("WScript.Shell"^)
    echo ws.Run Chr^(34^) ^& "%SETUP_DIR%\setup.bat" ^& Chr^(34^), 0, False
) > "%SETUP_DIR%\kaitun_update.vbs"

copy /Y "%SETUP_DIR%\kaitun_update.vbs" "%STARTUP%\KaitunUpdate.vbs" >nul
echo [+] Auto-update check added to startup ^(runs silently on every boot^)

:: Save current version
echo !REMOTE_VER!>"%LOCAL_VER_FILE%"

:: --- 4. FarmSync (last - runs inline, same window) ---
echo.
echo [4/4] Installing FarmSync...
set FARMSYNC_URL=%FARMSYNC_URL%
set FARMSYNC_CLIENT=%FARMSYNC_CLIENT%
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://files.farmsync.cloud/files/install.ps1' | iex"

echo.
echo  ==========================================
echo   Setup complete!
echo  ==========================================
echo.
pause
exit /b 0

:: =============================================
:AUTO_UPDATE
:: New version - download new OptimizerRoblox.exe silently
:: =============================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest '%REPO_RAW%/OptimizerRoblox.exe' -OutFile '%TEMP%\Optimizer_new.exe' -UseBasicParsing"

if exist "%TEMP%\Optimizer_new.exe" (
    taskkill /f /im OptimizerRoblox.exe >nul 2>&1
    timeout /t 1 /nobreak >nul
    copy /Y "%TEMP%\Optimizer_new.exe" "%OPTIMIZER_EXE%" >nul
    del /f "%TEMP%\Optimizer_new.exe" >nul
    echo !REMOTE_VER!>"%LOCAL_VER_FILE%"
    echo [+] Updated to v!REMOTE_VER!
    start "" "%OPTIMIZER_EXE%"
)
exit /b 0
