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
set "VRAM_OK=0"
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' 2^>$null | Select-Object -ExpandProperty PagingFiles | Out-String).Trim()" 2^>nul') do set "PAGING_CHECK=%%a"
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'AutomaticManagedPagefile' 2^>$null | Select-Object -ExpandProperty AutomaticManagedPagefile)" 2^>nul') do set "AUTO_MANAGED=%%a"

if "!PAGING_CHECK:350000=!"=="!PAGING_CHECK!" goto :set_vram
if not "!AUTO_MANAGED!"=="0" goto :set_vram
set "VRAM_OK=1"

:set_vram
if "!VRAM_OK!"=="1" (
    echo [+] Virtual RAM already set to 350GB
) else (
    echo [2/5] Setting Virtual Memory to 350GB...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'AutomaticManagedPagefile' -Value 0 -Type DWord -Force; New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value @('C:\pagefile.sys 350000 350000') -PropertyType MultiString -Force | Out-Null"
    echo [+] Virtual RAM set to 350GB (restart required to apply)
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

:: Check OptimizerRoblox version
set "UPDATE_OPTIMIZER=1"
set "LOCAL_VER=0"
set "REMOTE_VER=0"

:: Get remote version
for /f "tokens=*" %%v in ('powershell -NoProfile -Command "try{(Invoke-WebRequest '%REPO_RAW%/version.txt' -UseBasicParsing -TimeoutSec 5).Content.Trim()}catch{'0'}" 2^>nul') do set "REMOTE_VER=%%v"

if exist "!DESKTOP!\OptimizerRoblox.exe" (
    :: Check sidecar version file
    if exist "!DESKTOP!\optimizer_ver.txt" (
        set /p LOCAL_VER=<"!DESKTOP!\optimizer_ver.txt"
        set "LOCAL_VER=!LOCAL_VER: =!"
    ) else (
        for /f "tokens=*" %%v in ('powershell -NoProfile -Command "(Get-Item '!DESKTOP!\OptimizerRoblox.exe').VersionInfo.FileVersion" 2^>nul') do set "LOCAL_VER=%%v"
        if "!LOCAL_VER!"=="" set "LOCAL_VER=0"
    )

    if "!REMOTE_VER!"=="!LOCAL_VER!" (
        echo [+] OptimizerRoblox.exe up to date ^(v!LOCAL_VER!^)
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '!DESKTOP!\OptimizerRoblox.exe' -Verb RunAs"
        echo [+] OptimizerRoblox launched as Admin
        set "UPDATE_OPTIMIZER=0"
    ) else (
        echo [*] Updating OptimizerRoblox ^(v!LOCAL_VER! -^> v!REMOTE_VER!^)...
        del /f "!DESKTOP!\OptimizerRoblox.exe" >nul 2>&1
    )
)

if "!UPDATE_OPTIMIZER!"=="1" (
    echo [4/5] Downloading OptimizerRoblox.exe to Desktop...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/OptimizerRoblox.exe' -OutFile '!DESKTOP!\OptimizerRoblox.exe' -UseBasicParsing"
    if exist "!DESKTOP!\OptimizerRoblox.exe" (
        echo !REMOTE_VER!>"!DESKTOP!\optimizer_ver.txt"
        echo [+] OptimizerRoblox.exe v!REMOTE_VER! saved to Desktop
        :: Chạy với quyền admin
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '!DESKTOP!\OptimizerRoblox.exe' -Verb RunAs"
        echo [+] OptimizerRoblox launched as Admin
    ) else (
        echo [-] OptimizerRoblox.exe FAILED
    )
)

:: Add OptimizerRoblox to Startup (auto-start on boot)
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "!DESKTOP!\OptimizerRoblox.exe" (
    if exist "!STARTUP!\OptimizerRoblox.lnk" (
        echo [+] OptimizerRoblox already in Startup
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut('!STARTUP!\OptimizerRoblox.lnk'); $s.TargetPath='!DESKTOP!\OptimizerRoblox.exe'; $s.WorkingDirectory='!DESKTOP!'; $s.Description='Roblox Optimizer'; $s.Save()"
        echo [+] OptimizerRoblox added to Startup
    )
)

:: Check volt.exe (Desktop first, then Downloads)
if exist "!DESKTOP!\volt.exe" (
    echo [+] volt.exe already on Desktop
) else if exist "!USERPROFILE!\Downloads\volt.exe" (
    copy /Y "!USERPROFILE!\Downloads\volt.exe" "!DESKTOP!\volt.exe" >nul
    echo [+] volt.exe copied from Downloads to Desktop
) else (
    echo [4/5] Downloading volt.exe to Desktop...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/volt.exe' -OutFile '!DESKTOP!\volt.exe' -UseBasicParsing"
    if exist "!DESKTOP!\volt.exe" (echo [+] volt.exe saved to Desktop) else (echo [-] volt.exe FAILED)
)

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
        :: Chạy FarmSync trong cửa sổ riêng - tránh nó thoát CMD main
        set "FS_TEMP=%TEMP%\farmsync_%RANDOM%.cmd"
        (
            echo @echo off
            echo title FarmSync Install
            echo set FARMSYNC_KEY=!FARMSYNC_KEY!
            echo set FARMSYNC_URL=https://downloads.farmsync.cloud/client_web.exe
            echo set FARMSYNC_CLIENT=client_web
            echo powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://files.farmsync.cloud/files/install.ps1' | iex"
        ) > "!FS_TEMP!"
        start "FarmSync Install" cmd /c "!FS_TEMP!"
        echo [+] FarmSync installing in separate window...
        :: Poll mỗi 3s - khi nào tìm thấy FarmSync_AutoStart thì bật và thoát loop
        echo [*] Waiting for FarmSync to finish installing...
        set "FS_AUTOSTART="
        set "FS_WAIT=0"
        :WAIT_FARMSYNC
        powershell -NoProfile -Command "Start-Sleep -Seconds 3" >nul 2>&1
        set /a FS_WAIT+=3
        for /f "tokens=*" %%f in ('powershell -NoProfile -Command "Get-ChildItem -Path $env:LOCALAPPDATA,$env:APPDATA -Filter 'FarmSync_AutoStart*' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName" 2^>nul') do set "FS_AUTOSTART=%%f"
        if "!FS_AUTOSTART!"=="" (
            if !FS_WAIT! LSS 300 (
                goto :WAIT_FARMSYNC
            ) else (
                echo [!] FarmSync install timeout after 5 min
            )
        )
        if not "!FS_AUTOSTART!"=="" (
            echo [+] FarmSync installed! Launching AutoStart...
            start "" "!FS_AUTOSTART!"
            echo [+] FarmSync_AutoStart launched
        )
    )
)

echo.
echo  ==========================================
echo   Setup complete!
echo  ==========================================
echo.
pause
exit /b 0
