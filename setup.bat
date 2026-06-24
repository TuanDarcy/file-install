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
set "DOWNLOADS=%USERPROFILE%\Downloads"
set "REPO_RAW=https://raw.githubusercontent.com/TuanDarcy/file-install/main"
set "CONFIG_SOURCE=%~dp0MachineMonitor_config.json"
set "FARMSYNC_KEY="

echo.
echo  ==========================================
echo    KAITUN SETUP - Intelligent Updater
echo  ==========================================
echo.

:: ===== Hỏi FarmSync key ngay từ đầu nếu chưa cài =====
if not exist "!DESKTOP!\FarmSync" (
    set /p "FARMSYNC_KEY=  [>] Enter FarmSync Key: "
    if "!FARMSYNC_KEY!"=="" (
        echo [!] No key entered - FarmSync will be skipped
    )
)
echo.

:: ===== [1] Check and Sync time with Cloudflare =====
echo [*] Checking time sync status...
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' -Name 'NtpServer' 2^>$null | Select-Object -ExpandProperty NtpServer" 2^>nul') do set "NTP_CHECK=%%a"

if "!NTP_CHECK!"=="time.cloudflare.com,0x1" (
    echo [+] Time already synced with Cloudflare
) else (
    echo [1/8] Syncing time with time.cloudflare.com...
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
    echo [2/8] Setting Virtual Memory to 350GB...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'AutomaticManagedPagefile' -Value 0 -Type DWord -Force; New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value @('C:\pagefile.sys 350000 350000') -PropertyType MultiString -Force | Out-Null"
    echo [+] Virtual RAM set to 350GB (restart required to apply)
)

:: ===== [3] Check and Install CuongBoots =====
echo.
echo [*] Checking CuongBoots status...
if exist "C:\Tool_Boots\SetUpAll_PlzRunAsAminThisFile.bat" (
    echo [+] CuongBoots already installed
) else (
    echo [3/8] Installing CuongBoots...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-MpPreference -DisableRealtimeMonitoring $true; Add-MpPreference -ExclusionPath 'C:\Tool_Boots'; Invoke-WebRequest -Uri 'https://apa.cdev.my/download/CuongBoots_V1.2.zip' -OutFile \"$env:TEMP\CuongBoots.zip\" -UseBasicParsing; Expand-Archive -Path \"$env:TEMP\CuongBoots.zip\" -DestinationPath 'C:\Tool_Boots' -Force; Start-Process -FilePath 'C:\Tool_Boots\SetUpAll_PlzRunAsAminThisFile.bat' -Verb RunAs; Start-Process 'C:\Tool_Boots'"
    echo [+] CuongBoots launched
)

:: Add AutoRunBoots to Startup
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "!STARTUP!\AutoRunBoots.lnk" (
    echo [+] AutoRunBoots already in Startup
) else (
    for /f "tokens=*" %%f in ('powershell -NoProfile -Command "Get-ChildItem -Path \"C:\Tool_Boots\" -Filter \"AutoRunBoots*\" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName" 2^>nul') do set "AUTORUNBOOTS_PATH=%%f"
    if not "!AUTORUNBOOTS_PATH!"=="" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut('!STARTUP!\AutoRunBoots.lnk'); $s.TargetPath='!AUTORUNBOOTS_PATH!'; $s.WorkingDirectory='C:\Tool_Boots'; $s.Description='AutoRunBoots'; $s.Save()"
        echo [+] AutoRunBoots added to Startup
    ) else (
        echo [*] AutoRunBoots not found in C:\Tool_Boots yet - skipping
    )
)

:: ===== [4] Check and Download Tools (volt.exe + OptimizerRoblox.exe) =====
echo.
echo [*] Checking tools status...

:: Check OptimizerRoblox version
set "UPDATE_OPTIMIZER=1"
set "LOCAL_VER=0"
set "REMOTE_VER=0"
set "OPTIMIZER_DIR=!DOWNLOADS!\OptimizerRoblox"
set "OPTIMIZER_EXE=!OPTIMIZER_DIR!\OptimizerRoblox.exe"
set "OPTIMIZER_VER_FILE=!OPTIMIZER_DIR!\optimizer_ver.txt"
set "OPTIMIZER_ZIP=!DOWNLOADS!\OptimizerRoblox_onedir.zip"
set "OPTIMIZER_DESKTOP_SHORTCUT=!DESKTOP!\OptimizerRoblox.lnk"
set "LEGACY_OPTIMIZER_DIR=!DESKTOP!\OptimizerRoblox"
set "LEGACY_OPTIMIZER_EXE=!DESKTOP!\OptimizerRoblox.exe"
set "ACTIVE_OPTIMIZER_DIR=!OPTIMIZER_DIR!"
set "ACTIVE_OPTIMIZER_EXE=!OPTIMIZER_EXE!"
set "ACTIVE_OPTIMIZER_VER_FILE=!OPTIMIZER_VER_FILE!"

:: Get remote version
for /f "tokens=*" %%v in ('powershell -NoProfile -Command "try{(Invoke-WebRequest '%REPO_RAW%/version.txt' -UseBasicParsing -TimeoutSec 5).Content.Trim()}catch{'0'}" 2^>nul') do set "REMOTE_VER=%%v"

if exist "!OPTIMIZER_EXE!" (
    :: Check sidecar version file
    if exist "!OPTIMIZER_VER_FILE!" (
        set /p LOCAL_VER=<"!OPTIMIZER_VER_FILE!"
        set "LOCAL_VER=!LOCAL_VER: =!"
    ) else (
        for /f "tokens=*" %%v in ('powershell -NoProfile -Command "(Get-Item '!OPTIMIZER_EXE!').VersionInfo.FileVersion" 2^>nul') do set "LOCAL_VER=%%v"
        if "!LOCAL_VER!"=="" set "LOCAL_VER=0"
    )

    if "!REMOTE_VER!"=="!LOCAL_VER!" (
        echo [+] OptimizerRoblox onedir up to date ^(v!LOCAL_VER!^)
        taskkill /f /im OptimizerRoblox.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '!OPTIMIZER_EXE!' -Verb RunAs"
        echo [+] OptimizerRoblox launched as Admin
        set "UPDATE_OPTIMIZER=0"
    ) else (
        echo [*] Updating OptimizerRoblox ^(v!LOCAL_VER! -^> v!REMOTE_VER!^)...
        taskkill /f /im OptimizerRoblox.exe >nul 2>&1
    )
)

if "!UPDATE_OPTIMIZER!"=="1" (
    echo [4/8] Downloading OptimizerRoblox onedir package...
    for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/OptimizerRoblox_onedir.zip' -OutFile '!OPTIMIZER_ZIP!' -UseBasicParsing; $stageRoot=Join-Path $env:TEMP ('OptimizerRoblox_stage_' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null; Expand-Archive -Path '!OPTIMIZER_ZIP!' -DestinationPath $stageRoot -Force; $stageDir=Join-Path $stageRoot 'OptimizerRoblox'; if(-not (Test-Path $stageDir)){ $child=Get-ChildItem -Path $stageRoot -Directory | Select-Object -First 1; if($child){$stageDir=$child.FullName} }; $target='!OPTIMIZER_DIR!'; $final=$target; $swapped=$false; try { if(Test-Path $target){ Remove-Item $target -Recurse -Force -ErrorAction Stop }; Move-Item -Path $stageDir -Destination $target -Force -ErrorAction Stop; $swapped=$true } catch { $verTarget=Join-Path '!DOWNLOADS!' ('OptimizerRoblox_v' + '!REMOTE_VER!'); if(Test-Path $verTarget){ Remove-Item $verTarget -Recurse -Force -ErrorAction SilentlyContinue }; New-Item -ItemType Directory -Path $verTarget -Force | Out-Null; Copy-Item -Path (Join-Path $stageDir '*') -Destination $verTarget -Recurse -Force; $final=$verTarget }; $verFile=Join-Path $final 'optimizer_ver.txt'; Set-Content -Path $verFile -Value '!REMOTE_VER!' -Encoding Ascii; Write-Output $final"`) do set "ACTIVE_OPTIMIZER_DIR=%%p"
    set "ACTIVE_OPTIMIZER_EXE=!ACTIVE_OPTIMIZER_DIR!\OptimizerRoblox.exe"
    set "ACTIVE_OPTIMIZER_VER_FILE=!ACTIVE_OPTIMIZER_DIR!\optimizer_ver.txt"
    if exist "!ACTIVE_OPTIMIZER_EXE!" (
        echo [+] OptimizerRoblox onedir v!REMOTE_VER! saved to !ACTIVE_OPTIMIZER_DIR!
    ) else (
        echo [-] OptimizerRoblox onedir FAILED
    )
)

:: Ensure OptimizerRoblox always runs as admin via compatibility flag
if exist "!ACTIVE_OPTIMIZER_EXE!" (
    set "OPT_RUNAS_SET=0"
    for /f "tokens=*" %%v in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$k='HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'; try{(Get-ItemProperty -Path $k -Name '!ACTIVE_OPTIMIZER_EXE!' -ErrorAction Stop).'!ACTIVE_OPTIMIZER_EXE!'}catch{''}" 2^>nul') do set "OPT_RUNAS_VAL=%%v"
    echo !OPT_RUNAS_VAL! | find /I "RUNASADMIN" >nul
    if errorlevel 1 (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$k='HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'; if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }; Set-ItemProperty -Path $k -Name '!ACTIVE_OPTIMIZER_EXE!' -Value '~ RUNASADMIN' -Force"
        echo [+] OptimizerRoblox Run as administrator set
    ) else (
        echo [+] OptimizerRoblox already set to Run as administrator
    )
)

if exist "!ACTIVE_OPTIMIZER_EXE!" (
    taskkill /f /im OptimizerRoblox.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '!ACTIVE_OPTIMIZER_EXE!' -Verb RunAs"
    echo [+] OptimizerRoblox launched as Admin
)

if exist "!LEGACY_OPTIMIZER_DIR!" (
    rmdir /s /q "!LEGACY_OPTIMIZER_DIR!" >nul 2>&1
)
if exist "!LEGACY_OPTIMIZER_EXE!" (
    del /f /q "!LEGACY_OPTIMIZER_EXE!" >nul 2>&1
)
if exist "!OPTIMIZER_ZIP!" (
    del /f /q "!OPTIMIZER_ZIP!" >nul 2>&1
)

:: Create Desktop shortcut for OptimizerRoblox
if exist "!ACTIVE_OPTIMIZER_EXE!" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut('!OPTIMIZER_DESKTOP_SHORTCUT!'); $s.TargetPath='!ACTIVE_OPTIMIZER_EXE!'; $s.WorkingDirectory='!ACTIVE_OPTIMIZER_DIR!'; $s.Description='Roblox Optimizer'; $s.Save()"
    echo [+] OptimizerRoblox desktop shortcut created
)

:: Add OptimizerRoblox to Startup (auto-start on boot)
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "!ACTIVE_OPTIMIZER_EXE!" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut('!STARTUP!\OptimizerRoblox.lnk'); $s.TargetPath='!ACTIVE_OPTIMIZER_EXE!'; $s.WorkingDirectory='!ACTIVE_OPTIMIZER_DIR!'; $s.Description='Roblox Optimizer'; $s.Save()"
    echo [+] OptimizerRoblox Startup shortcut updated
)

:: Check volt.exe (Desktop first, then Downloads)
if exist "!DESKTOP!\volt.exe" (
    echo [+] volt.exe already on Desktop
) else if exist "!USERPROFILE!\Downloads\volt.exe" (
    copy /Y "!USERPROFILE!\Downloads\volt.exe" "!DESKTOP!\volt.exe" >nul
    echo [+] volt.exe copied from Downloads to Desktop
) else (
    echo [4/8] Downloading volt.exe to Desktop...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/volt.exe' -OutFile '!DESKTOP!\volt.exe' -UseBasicParsing"
    if exist "!DESKTOP!\volt.exe" (echo [+] volt.exe saved to Desktop) else (echo [-] volt.exe FAILED)
)

:: ===== [5] Check and Download MachineMonitor =====
echo.
echo [*] Checking MachineMonitor status...
set "MONITOR_EXE=!DESKTOP!\MachineMonitor.exe"
set "MONITOR_CONFIG=!DESKTOP!\MachineMonitor_config.json"
set "MONITOR_VERSION_FILE=!DESKTOP!\machine_monitor_ver.txt"
set "MONITOR_REMOTE_VER=0"
set "MONITOR_LOCAL_VER=0"
set "UPDATE_MONITOR=1"

for /f "tokens=*" %%v in ('powershell -NoProfile -Command "try{(Invoke-WebRequest '%REPO_RAW%/machine_monitor_version.txt' -UseBasicParsing -TimeoutSec 5).Content.Trim()}catch{'0'}" 2^>nul') do set "MONITOR_REMOTE_VER=%%v"

if exist "!MONITOR_EXE!" (
    if exist "!MONITOR_VERSION_FILE!" (
        set /p MONITOR_LOCAL_VER=<"!MONITOR_VERSION_FILE!"
        set "MONITOR_LOCAL_VER=!MONITOR_LOCAL_VER: =!"
    )
    if "!MONITOR_REMOTE_VER!"=="!MONITOR_LOCAL_VER!" (
        echo [+] MachineMonitor.exe up to date ^(v!MONITOR_LOCAL_VER!^)
        set "UPDATE_MONITOR=0"
    ) else (
        echo [*] Updating MachineMonitor ^(v!MONITOR_LOCAL_VER! -^> v!MONITOR_REMOTE_VER!^)...
        taskkill /f /im MachineMonitor.exe >nul 2>&1
        del /f "!MONITOR_EXE!" >nul 2>&1
    )
)

if "!UPDATE_MONITOR!"=="1" (
    echo [5/8] Downloading MachineMonitor.exe to Desktop...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/MachineMonitor.exe' -OutFile '!MONITOR_EXE!' -UseBasicParsing"
    if exist "!MONITOR_EXE!" (
        echo !MONITOR_REMOTE_VER!>"!MONITOR_VERSION_FILE!"
        echo [+] MachineMonitor.exe v!MONITOR_REMOTE_VER! saved to Desktop
    ) else (
        echo [-] MachineMonitor.exe FAILED
    )
)

if not exist "!MONITOR_CONFIG!" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/TuanDarcy/file-install/raw/main/MachineMonitor_config.json' -OutFile '!MONITOR_CONFIG!' -UseBasicParsing"
    if exist "!MONITOR_CONFIG!" (
        echo [+] MachineMonitor config created on Desktop
        echo [*] Edit MachineMonitor_config.json and fill webhook_url to receive Discord alerts
    ) else (
        echo [-] MachineMonitor config FAILED
    )
) else (
    echo [+] MachineMonitor config already exists - keeping user settings
)

if exist "!CONFIG_SOURCE!" if exist "!MONITOR_CONFIG!" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$src='!CONFIG_SOURCE!'; $dst='!MONITOR_CONFIG!'; try { $srcCfg = Get-Content -Path $src -Raw | ConvertFrom-Json; $dstCfg = Get-Content -Path $dst -Raw | ConvertFrom-Json; if ($srcCfg.webhook_url) { $dstCfg.webhook_url = $srcCfg.webhook_url }; $dstCfg | ConvertTo-Json -Depth 8 | Set-Content -Path $dst -Encoding UTF8; Write-Output '[+] MachineMonitor webhook_url synced from setup config' } catch { Write-Output ('[-] MachineMonitor webhook sync failed: ' + $_.Exception.Message) }"
)

if exist "!MONITOR_EXE!" (
    if exist "!STARTUP!\MachineMonitor.lnk" (
        echo [+] MachineMonitor already in Startup
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut('!STARTUP!\MachineMonitor.lnk'); $s.TargetPath='!MONITOR_EXE!'; $s.WorkingDirectory='!DESKTOP!'; $s.Description='Discord machine monitor'; $s.Save()"
        echo [+] MachineMonitor added to Startup
    )
    tasklist /fi "imagename eq MachineMonitor.exe" 2>nul | find "MachineMonitor.exe" >nul
    if errorlevel 1 (
        start "" "!MONITOR_EXE!"
        echo [+] MachineMonitor launched
    ) else (
        echo [+] MachineMonitor already running
    )
)

:: ===== [6] Check and Download 24122024 Folder =====
echo.
echo [*] Checking 24122024 folder status...
set "TOOLS_24122024_DIR=!DESKTOP!\24122024"
set "TOOLS_24122024_OK=1"
if not exist "!TOOLS_24122024_DIR!\dControl.exe" set "TOOLS_24122024_OK=0"
if not exist "!TOOLS_24122024_DIR!\dControl.ini" set "TOOLS_24122024_OK=0"
if not exist "!TOOLS_24122024_DIR!\Defender_Settings.vbs" set "TOOLS_24122024_OK=0"
if not exist "!TOOLS_24122024_DIR!\ReadMe.txt" set "TOOLS_24122024_OK=0"

if "!TOOLS_24122024_OK!"=="1" (
    echo [+] 24122024 folder already on Desktop
) else (
    echo [6/8] Downloading 24122024 folder to Desktop...
    if not exist "!TOOLS_24122024_DIR!" mkdir "!TOOLS_24122024_DIR!"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$dest='!TOOLS_24122024_DIR!'; Invoke-WebRequest '%REPO_RAW%/24122024/dControl.exe' -OutFile (Join-Path $dest 'dControl.exe') -UseBasicParsing; Invoke-WebRequest '%REPO_RAW%/24122024/dControl.ini' -OutFile (Join-Path $dest 'dControl.ini') -UseBasicParsing; Invoke-WebRequest '%REPO_RAW%/24122024/Defender_Settings.vbs' -OutFile (Join-Path $dest 'Defender_Settings.vbs') -UseBasicParsing; Invoke-WebRequest '%REPO_RAW%/24122024/ReadMe.txt' -OutFile (Join-Path $dest 'ReadMe.txt') -UseBasicParsing"
    set "TOOLS_24122024_OK=1"
    if not exist "!TOOLS_24122024_DIR!\dControl.exe" set "TOOLS_24122024_OK=0"
    if not exist "!TOOLS_24122024_DIR!\dControl.ini" set "TOOLS_24122024_OK=0"
    if not exist "!TOOLS_24122024_DIR!\Defender_Settings.vbs" set "TOOLS_24122024_OK=0"
    if not exist "!TOOLS_24122024_DIR!\ReadMe.txt" set "TOOLS_24122024_OK=0"
    if "!TOOLS_24122024_OK!"=="1" (
        echo [+] 24122024 folder saved to Desktop
    ) else (
        echo [-] 24122024 folder download FAILED
    )
)

:: ===== [7] Check and Install FarmSync =====
echo.
echo [*] Checking FarmSync status...
if exist "!DESKTOP!\FarmSync" (
    echo [+] FarmSync already installed
) else (
    if "!FARMSYNC_KEY!"=="" (
        echo [!] No key - skipping FarmSync
    ) else (
        echo [7/8] Installing FarmSync...
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
        for /f "tokens=*" %%f in ('powershell -NoProfile -Command "Get-ChildItem -Path \"!DESKTOP!\" -Filter FarmSync_AutoStart* -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName" 2^>nul') do set "FS_AUTOSTART=%%f"
        if "!FS_AUTOSTART!"=="" (
            if !FS_WAIT! LSS 300 (
                goto :WAIT_FARMSYNC
            ) else (
                echo [!] FarmSync install timeout after 5 min
            )
        )
        if not "!FS_AUTOSTART!"=="" (
            echo [+] FarmSync installed! Checking if already running...
            tasklist /fi "imagename eq client_web.exe" 2>nul | find "client_web.exe" >nul
            if not errorlevel 1 (
                echo [+] FarmSync client already running - skipping AutoStart
            ) else (
                start "" "!FS_AUTOSTART!"
                echo [+] FarmSync_AutoStart launched
            )
        )
    )
)

:: ===== [8] Notify setup complete to Discord via FarmSync Device/Note =====
echo.
echo [*] Sending setup completion webhook...
set "FS_AUTOSTART_NOTIFY="
for /f "tokens=*" %%f in ('powershell -NoProfile -Command "Get-ChildItem -Path \"!DESKTOP!\" -Filter \"FarmSync_AutoStart*\" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName" 2^>nul') do set "FS_AUTOSTART_NOTIFY=%%f"
if exist "%~dp0setup_notify.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_notify.ps1" -DesktopPath "!DESKTOP!" -AutoStartPath "!FS_AUTOSTART_NOTIFY!"
) else (
    echo [-] setup_notify.ps1 not found - skipping webhook
)

echo.
echo  ==========================================
echo   Setup complete!
echo  ==========================================
echo.
set "EXIT_WAIT_CMD=%TEMP%\kaitun_exit_wait_%RANDOM%.cmd"
(
    echo @echo off
    echo title KAITUN Setup Complete
    echo echo.
    echo echo  ==========================================
    echo echo   Setup complete!
    echo echo  ==========================================
    echo echo.
    echo powershell -NoProfile -Command "Read-Host 'Press Enter to exit' ^| Out-Null"
) > "!EXIT_WAIT_CMD!"
start /wait "KAITUN Setup Complete" cmd /c "!EXIT_WAIT_CMD!"
del /f /q "!EXIT_WAIT_CMD!" >nul 2>&1
exit /b 0
