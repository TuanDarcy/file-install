@echo off
setlocal EnableDelayedExpansion
title KAITUN SETUP - Intelligent Updater

:: ===== Self-elevate to admin if needed =====
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "DESKTOP=%USERPROFILE%\Desktop"
set "TOOLS_DIR=%USERPROFILE%\Desktop\KaitunTools"
set "REPO_RAW=https://raw.githubusercontent.com/TuanDarcy/file-install/main"
set "FARMSYNC_KEY="

echo.
echo  ==========================================
echo    KAITUN SETUP - Intelligent Updater
echo  ==========================================
echo.

:: ===== [1] Check and Sync time with Cloudflare =====
echo [*] Checking time sync status...
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' -Name 'NtpServer' 2^>$null | Select-Object -ExpandProperty NtpServer" 2^>nul') do set "NTP_CHECK=%%a"

if "!NTP_CHECK!"=="time.cloudflare.com,0x1" (
    echo [+] Time already synced with Cloudflare
) else (
    echo [1/5] Syncing time with time.cloudflare.com...
    w32tm /config /manualpeerlist:"time.cloudflare.com" /syncfromflags:manual /reliable:YES /update >nul 2>&1
    net stop w32tm >nul 2>&1
    net start w32tm >nul 2>&1
    w32tm /resync /force >nul 2>&1
    echo [+] Time synced with Cloudflare
)

:: ===== [2] Check and Set Virtual RAM to 350GB =====
echo.
echo [*] Checking Virtual RAM status...
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' 2^>$null | Select-Object -ExpandProperty PagingFiles | Out-String).Trim()" 2^>nul') do set "PAGING_CHECK=%%a"

if "!PAGING_CHECK:350000=!"=="!PAGING_CHECK!" (
    echo [2/5] Setting Virtual Memory to 350GB...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value @('C:\pagefile.sys 350000 350000') -PropertyType MultiString -Force | Out-Null"
    echo [+] Virtual RAM set to 350GB (restart may be needed)
) else (
    echo [+] Virtual RAM already set to 350GB
)

:: ===== [3] Check and Install CuongBoots =====
echo.
echo [*] Checking CuongBoots status...
if exist "C:\Tool_Boots\SetUpAll_PlzRunAsAminThisFile.bat" (
    echo [+] CuongBoots already installed
) else (
    echo [3/5] Installing CuongBoots...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-MpPreference -DisableRealtimeMonitoring $true; Add-MpPreference -ExclusionPath 'C:\Tool_Boots'; Invoke-WebRequest -Uri 'https://apa.cdev.my/download/CuongBoots_V1.2.zip' -OutFile \"$env:TEMP\CuongBoots.zip\" -UseBasicParsing; Expand-Archive -Path \"$env:TEMP\CuongBoots.zip\" -DestinationPath 'C:\Tool_Boots' -Force; Start-Process -FilePath 'C:\Tool_Boots\SetUpAll_PlzRunAsAminThisFile.bat' -Verb RunAs; Start-Process 'C:\Tool_Boots'"
    echo [+] CuongBoots launched
)

:: ===== [4] Check and Download Tools (volt.exe + OptimizerRoblox.exe) =====
echo.
echo [*] Checking tools status...
if not exist "!TOOLS_DIR!" mkdir "!TOOLS_DIR!"

:: Check OptimizerRoblox version
set "UPDATE_OPTIMIZER=1"
if exist "!TOOLS_DIR!\OptimizerRoblox.exe" (
    for /f "tokens=*" %%v in ('powershell -NoProfile -Command "try{(Invoke-WebRequest '%REPO_RAW%/version.txt' -UseBasicParsing -TimeoutSec 5).Content.Trim()}catch{'0'}" 2^>nul') do set "REMOTE_VER=%%v"
    for /f "tokens=*" %%v in ('powershell -NoProfile -Command "(Get-Item '!TOOLS_DIR!\OptimizerRoblox.exe').VersionInfo.FileVersion" 2^>nul') do set "LOCAL_VER=%%v"
    
    if "!REMOTE_VER!"=="!LOCAL_VER!" (
        echo [+] OptimizerRoblox.exe already up to date ^(v!LOCAL_VER!^)
        set "UPDATE_OPTIMIZER=0"
    ) else (
        echo [*] New OptimizerRoblox version found ^(remote: v!REMOTE_VER!, local: v!LOCAL_VER!^)
    )
)

if "!UPDATE_OPTIMIZER!"=="1" (
    echo [4/5] Downloading OptimizerRoblox.exe...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/OptimizerRoblox.exe' -OutFile '!TOOLS_DIR!\OptimizerRoblox.exe' -UseBasicParsing"
    if exist "!TOOLS_DIR!\OptimizerRoblox.exe" (echo [+] OptimizerRoblox.exe saved) else (echo [-] OptimizerRoblox.exe FAILED)
)

:: Check volt.exe
if exist "!TOOLS_DIR!\volt.exe" (
    echo [+] volt.exe already downloaded
) else (
    echo [4/5] Downloading volt.exe...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/volt.exe' -OutFile '!TOOLS_DIR!\volt.exe' -UseBasicParsing"
    if exist "!TOOLS_DIR!\volt.exe" (echo [+] volt.exe saved) else (echo [-] volt.exe FAILED)
)

:: Open the tools folder on Desktop
if exist "!TOOLS_DIR!" start "" "!TOOLS_DIR!"

:: ===== [5] Check and Install FarmSync =====
echo.
echo [*] Checking FarmSync status...
if exist "%LOCALAPPDATA%\FarmSync" (
    echo [+] FarmSync already installed
) else (
    echo.
    set /p "FARMSYNC_KEY=  [>] Enter FarmSync Key: "
    if "!FARMSYNC_KEY!"=="" (
        echo [!] Key cannot be empty - skipping FarmSync
    ) else (
        echo [5/5] Installing FarmSync...
        set FARMSYNC_URL=https://downloads.farmsync.cloud/client_web.exe
        set FARMSYNC_CLIENT=client_web
        powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://files.farmsync.cloud/files/install.ps1' | iex"
        echo [+] FarmSync install complete
    )
)

echo.
echo  ==========================================
echo   Setup complete!
echo  ==========================================
echo.
pause
exit /b 0
