@echo off
setlocal EnableDelayedExpansion
title KAITUN SETUP - Intelligent Updater
set "SCRIPT_BUILD=2026-06-25-f3516aa"

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
echo    Build: !SCRIPT_BUILD!
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
echo [*] Setup build marker: !SCRIPT_BUILD!
echo [*] Optimizer update mode: EXE-FIRST ^(zip only as fallback^)

:: Check OptimizerRoblox version
set "UPDATE_OPTIMIZER=1"
set "LOCAL_VER=0"
set "REMOTE_VER=0"
set "OPTIMIZER_DIR=!DOWNLOADS!\OptimizerRoblox"
set "OPTIMIZER_EXE=!OPTIMIZER_DIR!\OptimizerRoblox.exe"
set "OPTIMIZER_VER_FILE=!OPTIMIZER_DIR!\optimizer_ver.txt"
set "OPTIMIZER_ZIP=!DOWNLOADS!\OptimizerRoblox_onedir.zip"
set "OPTIMIZER_EXE_URL=%REPO_RAW%/OptimizerRoblox.exe"
set "OPTIMIZER_EXE_TEMP=!DOWNLOADS!\OptimizerRoblox.exe.new"
set "OPTIMIZER_DESKTOP_SHORTCUT=!DESKTOP!\OptimizerRoblox.lnk"
set "LEGACY_OPTIMIZER_DIR=!DESKTOP!\OptimizerRoblox"
set "LEGACY_OPTIMIZER_EXE=!DESKTOP!\OptimizerRoblox.exe"
set "ACTIVE_OPTIMIZER_DIR=!OPTIMIZER_DIR!"
set "ACTIVE_OPTIMIZER_EXE=!OPTIMIZER_EXE!"
set "ACTIVE_OPTIMIZER_VER_FILE=!OPTIMIZER_VER_FILE!"
set "OPTIMIZER_SHORTCUT_TARGET="

if exist "!OPTIMIZER_DESKTOP_SHORTCUT!" (
    for /f "usebackq delims=" %%v in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('!OPTIMIZER_DESKTOP_SHORTCUT!'); if($s.TargetPath){$s.TargetPath}" 2^>nul`) do set "OPTIMIZER_SHORTCUT_TARGET=%%v"
    if exist "!OPTIMIZER_SHORTCUT_TARGET!" (
        for %%d in ("!OPTIMIZER_SHORTCUT_TARGET!") do set "ACTIVE_OPTIMIZER_DIR=%%~dpd"
        set "ACTIVE_OPTIMIZER_DIR=!ACTIVE_OPTIMIZER_DIR:~0,-1!"
        set "ACTIVE_OPTIMIZER_EXE=!OPTIMIZER_SHORTCUT_TARGET!"
        set "ACTIVE_OPTIMIZER_VER_FILE=!ACTIVE_OPTIMIZER_DIR!\optimizer_ver.txt"
    )
)

:: Get remote version
for /f "tokens=*" %%v in ('powershell -NoProfile -Command "try{(Invoke-WebRequest '%REPO_RAW%/version.txt' -UseBasicParsing -TimeoutSec 5).Content.Trim()}catch{'0'}" 2^>nul') do set "REMOTE_VER=%%v"
if "!REMOTE_VER!"=="0" (
    echo [!] Could not read remote Optimizer version - update check may be forced
) else (
    echo [*] Remote Optimizer version: !REMOTE_VER!
)

if exist "!OPTIMIZER_DIR!" (
    echo [*] Found folder: !OPTIMIZER_DIR!
) else (
    echo [*] Optimizer folder not found in Downloads yet
)

:: Fast-path: if Downloads\OptimizerRoblox already has correct version and required files, skip downloading.
if exist "!OPTIMIZER_DIR!\OptimizerRoblox.exe" (
    echo [*] Found OptimizerRoblox.exe in Downloads folder - checking required files...
    set "OPTIMIZER_REQUIRED_RESULT="
    for /f "usebackq delims=" %%r in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$d='!OPTIMIZER_DIR!'; $req=@('OptimizerRoblox.exe','_internal\libcrypto-3.dll','_internal\libssl-3.dll','_internal\libffi-8.dll','_internal\psutil\_psutil_windows.pyd'); $missing=@(); foreach($f in $req){ if(-not (Test-Path (Join-Path $d $f) -PathType Leaf)){ $missing += $f } }; if($missing.Count -eq 0){ 'OK' } else { 'MISSING: ' + ($missing -join ', ') }" 2^>nul`) do set "OPTIMIZER_REQUIRED_RESULT=%%r"
    if /I "!OPTIMIZER_REQUIRED_RESULT!"=="OK" (
        echo [*] Required files check: OK
        set "LOCAL_VER="
        if exist "!OPTIMIZER_VER_FILE!" (
            set /p LOCAL_VER=<"!OPTIMIZER_VER_FILE!"
            set "LOCAL_VER=!LOCAL_VER: =!"
            echo [*] Local version from optimizer_ver.txt: !LOCAL_VER!
        ) else (
            for /f "tokens=*" %%v in ('powershell -NoProfile -Command "(Get-Item '!OPTIMIZER_DIR!\OptimizerRoblox.exe').VersionInfo.FileVersion" 2^>nul') do set "LOCAL_VER=%%v"
            echo [*] Local version from exe metadata: !LOCAL_VER!
        )

        if "!LOCAL_VER!"=="!REMOTE_VER!" (
            set "ACTIVE_OPTIMIZER_DIR=!OPTIMIZER_DIR!"
            set "ACTIVE_OPTIMIZER_EXE=!OPTIMIZER_DIR!\OptimizerRoblox.exe"
            set "ACTIVE_OPTIMIZER_VER_FILE=!OPTIMIZER_VER_FILE!"
            set "UPDATE_OPTIMIZER=0"
            echo [+] OptimizerRoblox folder in Downloads is complete and up to date ^(v!REMOTE_VER!^) - skip download
        ) else (
            echo [*] Version mismatch in Downloads folder ^(local=!LOCAL_VER!, remote=!REMOTE_VER!^) - will update OptimizerRoblox.exe first
        )
    ) else (
        if not "!OPTIMIZER_REQUIRED_RESULT!"=="" echo [!] Existing OptimizerRoblox folder is incomplete: !OPTIMIZER_REQUIRED_RESULT!
        echo [*] Incomplete folder detected - will try OptimizerRoblox.exe repair first ^(zip fallback if needed^)
    )
)

if exist "!OPTIMIZER_DIR!" if not exist "!OPTIMIZER_DIR!\OptimizerRoblox.exe" (
    echo [*] Folder exists but missing OptimizerRoblox.exe - will download OptimizerRoblox.exe first
)

if not exist "!ACTIVE_OPTIMIZER_EXE!" (
    for /f "usebackq delims=" %%v in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$downloads='!DOWNLOADS!'; $rv='!REMOTE_VER!'; $cand=Get-ChildItem -Path $downloads -Directory -Filter 'OptimizerRoblox*' -ErrorAction SilentlyContinue ^| Sort-Object LastWriteTime -Descending; foreach($d in $cand){ $exe=Join-Path $d.FullName 'OptimizerRoblox.exe'; $vf=Join-Path $d.FullName 'optimizer_ver.txt'; if(Test-Path $exe -PathType Leaf){ if(Test-Path $vf -PathType Leaf){ $lv=(Get-Content -Path $vf -ErrorAction SilentlyContinue ^| Select-Object -First 1).Trim(); if($lv -eq $rv){ Write-Output $exe; break } } } }" 2^>nul`) do set "ACTIVE_OPTIMIZER_EXE=%%v"
    if exist "!ACTIVE_OPTIMIZER_EXE!" (
        for %%d in ("!ACTIVE_OPTIMIZER_EXE!") do set "ACTIVE_OPTIMIZER_DIR=%%~dpd"
        set "ACTIVE_OPTIMIZER_DIR=!ACTIVE_OPTIMIZER_DIR:~0,-1!"
        set "ACTIVE_OPTIMIZER_VER_FILE=!ACTIVE_OPTIMIZER_DIR!\optimizer_ver.txt"
    )
)

if exist "!ACTIVE_OPTIMIZER_EXE!" (
    :: Check sidecar version file
    if exist "!ACTIVE_OPTIMIZER_VER_FILE!" (
        set /p LOCAL_VER=<"!ACTIVE_OPTIMIZER_VER_FILE!"
        set "LOCAL_VER=!LOCAL_VER: =!"
    ) else (
        for /f "tokens=*" %%v in ('powershell -NoProfile -Command "(Get-Item '!ACTIVE_OPTIMIZER_EXE!').VersionInfo.FileVersion" 2^>nul') do set "LOCAL_VER=%%v"
        if "!LOCAL_VER!"=="" set "LOCAL_VER=0"
    )

    if "!REMOTE_VER!"=="!LOCAL_VER!" (
        echo [+] OptimizerRoblox onedir up to date ^(v!LOCAL_VER!^)
        taskkill /f /im OptimizerRoblox.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '!ACTIVE_OPTIMIZER_EXE!' -Verb RunAs"
        echo [+] OptimizerRoblox launched as Admin
        set "UPDATE_OPTIMIZER=0"
    ) else (
        echo [*] Updating OptimizerRoblox ^(v!LOCAL_VER! -^> v!REMOTE_VER!^)...
        taskkill /f /im OptimizerRoblox.exe >nul 2>&1
    )
)

if "!UPDATE_OPTIMIZER!"=="1" if exist "!OPTIMIZER_DIR!" (
    echo [*] Trying exe-only update/repair in existing Optimizer folder...
    set "OPTIMIZER_EXE_UPDATE_RESULT="
    for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $url='!OPTIMIZER_EXE_URL!'; $tmp='!OPTIMIZER_EXE_TEMP!'; $targetDir='!OPTIMIZER_DIR!'; $targetExe=Join-Path $targetDir 'OptimizerRoblox.exe'; if(-not (Test-Path $targetDir)){ throw 'Target folder not found' }; if(Test-Path $tmp){ Remove-Item $tmp -Force -ErrorAction SilentlyContinue }; Invoke-WebRequest $url -OutFile $tmp -UseBasicParsing; if(-not (Test-Path $tmp -PathType Leaf)){ throw 'EXE download failed: temp file missing' }; if((Get-Item $tmp).Length -lt 102400){ throw 'EXE download failed: file too small' }; $killCmd={ taskkill /f /im OptimizerRoblox.exe *> $null; taskkill /f /im RobloxPlayerBeta.exe *> $null; Start-Sleep -Milliseconds 1200 }; try { Move-Item -Path $tmp -Destination $targetExe -Force -ErrorAction Stop } catch { & $killCmd; Move-Item -Path $tmp -Destination $targetExe -Force -ErrorAction Stop }; Set-Content -Path '!OPTIMIZER_VER_FILE!' -Value '!REMOTE_VER!' -Encoding Ascii; Write-Output ('OK::' + $targetDir) } catch { Write-Output ('ERR::' + $_.Exception.Message) }"`) do set "OPTIMIZER_EXE_UPDATE_RESULT=%%p"
    if /I "!OPTIMIZER_EXE_UPDATE_RESULT:~0,4!"=="OK::" (
        set "ACTIVE_OPTIMIZER_DIR=!OPTIMIZER_EXE_UPDATE_RESULT:~4!"
        set "ACTIVE_OPTIMIZER_EXE=!ACTIVE_OPTIMIZER_DIR!\OptimizerRoblox.exe"
        set "ACTIVE_OPTIMIZER_VER_FILE=!ACTIVE_OPTIMIZER_DIR!\optimizer_ver.txt"
        set "OPTIMIZER_REQUIRED_RESULT="
        for /f "usebackq delims=" %%r in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$d='!ACTIVE_OPTIMIZER_DIR!'; $req=@('OptimizerRoblox.exe','_internal\libcrypto-3.dll','_internal\libssl-3.dll','_internal\libffi-8.dll','_internal\psutil\_psutil_windows.pyd'); $missing=@(); foreach($f in $req){ if(-not (Test-Path (Join-Path $d $f) -PathType Leaf)){ $missing += $f } }; if($missing.Count -eq 0){ 'OK' } else { 'MISSING: ' + ($missing -join ', ') }" 2^>nul`) do set "OPTIMIZER_REQUIRED_RESULT=%%r"
        if /I "!OPTIMIZER_REQUIRED_RESULT!"=="OK" (
            set "UPDATE_OPTIMIZER=0"
            echo [+] OptimizerRoblox.exe updated in existing folder ^(v!REMOTE_VER!^) - zip download skipped
        ) else (
            if not "!OPTIMIZER_REQUIRED_RESULT!"=="" echo [!] Exe-only update done but folder still incomplete: !OPTIMIZER_REQUIRED_RESULT!
            echo [*] Falling back to full onedir package to repair missing dependencies
        )
    ) else (
        if /I "!OPTIMIZER_EXE_UPDATE_RESULT:~0,5!"=="ERR::" (
            echo [!] Exe-only update failed: !OPTIMIZER_EXE_UPDATE_RESULT:~5!
        ) else (
            echo [!] Exe-only update failed: Unknown error
        )
        echo [*] Falling back to full onedir package
    )
)

if "!UPDATE_OPTIMIZER!"=="1" (
    echo [4/8] Downloading OptimizerRoblox onedir package ^(fallback mode^)...
    set "OPTIMIZER_DL_RESULT="
    for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $zip='!OPTIMIZER_ZIP!'; $zipUrl='!REPO_RAW!/OptimizerRoblox_onedir.zip'; if(Test-Path $zip){ Remove-Item $zip -Force -ErrorAction SilentlyContinue }; $downloadOk=$false; for($i=1; $i -le 2 -and -not $downloadOk; $i++){ try { Invoke-WebRequest $zipUrl -OutFile $zip -UseBasicParsing; $stageRoot=Join-Path $env:TEMP ('OptimizerRoblox_stage_' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null; Expand-Archive -Path $zip -DestinationPath $stageRoot -Force; $downloadOk=$true } catch { if(Test-Path $zip){ Remove-Item $zip -Force -ErrorAction SilentlyContinue }; if($i -eq 2){ throw } } }; $stageDir=Join-Path $stageRoot 'OptimizerRoblox'; if(-not (Test-Path $stageDir)){ $child=Get-ChildItem -Path $stageRoot -Directory | Select-Object -First 1; if($child){$stageDir=$child.FullName} }; if(-not (Test-Path (Join-Path $stageDir 'OptimizerRoblox.exe') -PathType Leaf)){ throw 'Optimizer package missing OptimizerRoblox.exe after extract' }; $target='!OPTIMIZER_DIR!'; $final=$target; $killCmd={ taskkill /f /im OptimizerRoblox.exe *> $null; taskkill /f /im RobloxPlayerBeta.exe *> $null; Start-Sleep -Milliseconds 1200 }; try { if(Test-Path $target){ Remove-Item $target -Recurse -Force -ErrorAction Stop }; Move-Item -Path $stageDir -Destination $target -Force -ErrorAction Stop } catch { & $killCmd; try { if(Test-Path $target){ Remove-Item $target -Recurse -Force -ErrorAction Stop }; Move-Item -Path $stageDir -Destination $target -Force -ErrorAction Stop } catch { $verTarget=Join-Path '!DOWNLOADS!' ('OptimizerRoblox_v' + '!REMOTE_VER!'); if(Test-Path $verTarget){ Remove-Item $verTarget -Recurse -Force -ErrorAction SilentlyContinue }; New-Item -ItemType Directory -Path $verTarget -Force | Out-Null; Copy-Item -Path (Join-Path $stageDir '*') -Destination $verTarget -Recurse -Force; $final=$verTarget } }; $verFile=Join-Path $final 'optimizer_ver.txt'; Set-Content -Path $verFile -Value '!REMOTE_VER!' -Encoding Ascii; Write-Output ('OK::' + $final) } catch { Write-Output ('ERR::' + $_.Exception.Message) }"`) do set "OPTIMIZER_DL_RESULT=%%p"
    if /I "!OPTIMIZER_DL_RESULT:~0,4!"=="OK::" (
        set "ACTIVE_OPTIMIZER_DIR=!OPTIMIZER_DL_RESULT:~4!"
        set "ACTIVE_OPTIMIZER_EXE=!ACTIVE_OPTIMIZER_DIR!\OptimizerRoblox.exe"
        set "ACTIVE_OPTIMIZER_VER_FILE=!ACTIVE_OPTIMIZER_DIR!\optimizer_ver.txt"
        if exist "!ACTIVE_OPTIMIZER_EXE!" (
            echo [+] OptimizerRoblox onedir v!REMOTE_VER! saved to !ACTIVE_OPTIMIZER_DIR!
        ) else (
            echo [-] OptimizerRoblox onedir FAILED ^(missing exe after install^)
        )
    ) else (
        if /I "!OPTIMIZER_DL_RESULT:~0,5!"=="ERR::" (
            echo [-] OptimizerRoblox onedir FAILED: !OPTIMIZER_DL_RESULT:~5!
        ) else (
            echo [-] OptimizerRoblox onedir FAILED: Unknown download/extract error
        )
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
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$startup='!STARTUP!'; Get-ChildItem -Path $startup -Filter '*.lnk' -ErrorAction SilentlyContinue | ForEach-Object { try { $s=(New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName); $tp=($s.TargetPath + '').ToLower(); if($_.Name -ieq 'OptimizerRoblox.lnk' -or $tp -like '*optimizerroblox*'){ Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue } } catch {} }"
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
set "NOTIFY_SCRIPT=%~dp0setup_notify.ps1"
for /f "tokens=*" %%f in ('powershell -NoProfile -Command "Get-ChildItem -Path \"!DESKTOP!\" -Filter \"FarmSync_AutoStart*\" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName" 2^>nul') do set "FS_AUTOSTART_NOTIFY=%%f"
if exist "!DESKTOP!\setup_notify.ps1" set "NOTIFY_SCRIPT=!DESKTOP!\setup_notify.ps1"
if not exist "!NOTIFY_SCRIPT!" (
    set "NOTIFY_FETCH_RESULT="
    for /f "tokens=*" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest '%REPO_RAW%/setup_notify.ps1' -OutFile '!DESKTOP!\setup_notify.ps1' -UseBasicParsing -TimeoutSec 10; 'OK' } catch { 'ERR: ' + $_.Exception.Message }" 2^>nul') do set "NOTIFY_FETCH_RESULT=%%r"
    if /I "!NOTIFY_FETCH_RESULT!"=="OK" (
        echo [+] setup_notify.ps1 downloaded to Desktop
    ) else (
        if not "!NOTIFY_FETCH_RESULT!"=="" echo [!] setup_notify.ps1 download failed: !NOTIFY_FETCH_RESULT!
    )
    if exist "!DESKTOP!\setup_notify.ps1" set "NOTIFY_SCRIPT=!DESKTOP!\setup_notify.ps1"
)
if exist "!NOTIFY_SCRIPT!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!NOTIFY_SCRIPT!" -DesktopPath "!DESKTOP!" -AutoStartPath "!FS_AUTOSTART_NOTIFY!"
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
