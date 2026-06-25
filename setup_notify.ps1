param(
    [string]$DesktopPath,
    [string]$AutoStartPath
)

$configPath = Join-Path $DesktopPath 'MachineMonitor_config.json'
if (-not (Test-Path $configPath)) { Write-Output '[*] Skip webhook: MachineMonitor_config.json not found'; exit 0 }

$cfg = Get-Content -Path $configPath -Raw | ConvertFrom-Json
$webhook = ([string]$cfg.webhook_url).Trim()
if ([string]::IsNullOrWhiteSpace($webhook)) { Write-Output '[*] Skip webhook: webhook_url empty'; exit 0 }

$apiKey = ([string]$cfg.farmsync_api_key).Trim()
$devicesUrl = ([string]$cfg.farmsync_devices_url).Trim()
if ([string]::IsNullOrWhiteSpace($devicesUrl)) { $devicesUrl = 'https://api.farmsync.cloud/api/devices/' }
$apiHeader = ([string]$cfg.farmsync_api_key_header).Trim()
if ([string]::IsNullOrWhiteSpace($apiHeader)) { $apiHeader = 'Authorization' }
$idField = ([string]$cfg.farmsync_device_id_field).Trim()
if ([string]::IsNullOrWhiteSpace($idField)) { $idField = 'device_name' }
$noteField = ([string]$cfg.farmsync_note_field).Trim()
if ([string]::IsNullOrWhiteSpace($noteField)) { $noteField = 'device_note' }

function Get-DeviceInfo {
    $rx = [regex]'(?i)device\s*(\d+)'
    $p = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle.ToLower().Contains('farmsync') } | Select-Object -First 1
    if (-not $p) { return $null }
    $title = [string]$p.MainWindowTitle
    $m = $rx.Match($title)
    if (-not $m.Success) { return $null }
    return [pscustomobject]@{ Device = [int]$m.Groups[1].Value; Title = $title }
}

function Test-FarmSyncRunning {
    try {
        $p = Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessName -ieq 'client_web' -or
            ($_.MainWindowTitle -and $_.MainWindowTitle.ToLower().Contains('farmsync'))
        } | Select-Object -First 1
        return ($null -ne $p)
    } catch {
        return $false
    }
}

$deviceInfo = $null
$started = $false
for ($i = 0; $i -lt 60; $i++) {
    $deviceInfo = Get-DeviceInfo
    if ($deviceInfo) { break }
    if (-not $started -and -not [string]::IsNullOrWhiteSpace($AutoStartPath) -and (Test-Path $AutoStartPath) -and -not (Test-FarmSyncRunning)) {
        try {
            Start-Process -FilePath $AutoStartPath | Out-Null
            Write-Output '[*] FarmSync_AutoStart launched for device detection'
            $started = $true
        } catch {}
    }
    Start-Sleep -Seconds 2
}

$device = 'Unknown'
$title = 'N/A'
if ($deviceInfo) {
    $device = 'Device ' + $deviceInfo.Device
    $title = $deviceInfo.Title
}

$note = 'N/A'
if ($deviceInfo -and -not [string]::IsNullOrWhiteSpace($apiKey)) {
    try {
        $apiValue = $apiKey
        if ($apiHeader -ieq 'Authorization' -and -not $apiKey.ToLower().StartsWith('bearer ')) { $apiValue = 'Bearer ' + $apiKey }
        $headers = @{ 'Accept' = 'application/json' }
        $headers[$apiHeader] = $apiValue
        $payload = Invoke-RestMethod -Uri $devicesUrl -Headers $headers -Method Get -TimeoutSec 15
        $items = @()
        if ($payload -is [System.Collections.IEnumerable] -and -not ($payload -is [string])) { $items = @($payload) }
        elseif ($payload.data) { $items = @($payload.data) }
        elseif ($payload.devices) { $items = @($payload.devices) }

        foreach ($item in $items) {
            if ($null -eq $item) { continue }
            $raw = $item.$idField
            if ($null -eq $raw -and $item.device_name) { $raw = $item.device_name }
            $num = $null
            if ($raw -is [int]) { $num = [int]$raw }
            elseif ($raw) {
                $txt = [string]$raw
                $m = [regex]::Match($txt, '(?i)device\s*(\d+)')
                if ($m.Success) { $num = [int]$m.Groups[1].Value }
                else {
                    $m2 = [regex]::Match($txt, '(\d+)')
                    if ($m2.Success) { $num = [int]$m2.Groups[1].Value }
                }
            }
            if ($num -eq $deviceInfo.Device) {
                $candidate = $item.$noteField
                if ([string]::IsNullOrWhiteSpace([string]$candidate)) { $candidate = $item.device_note }
                if (-not [string]::IsNullOrWhiteSpace([string]$candidate)) { $note = [string]$candidate }
                break
            }
        }
    } catch {
        Write-Output ('[*] FarmSync note lookup failed: ' + $_.Exception.Message)
    }
}

$machine = $env:COMPUTERNAME
if ([string]::IsNullOrWhiteSpace($machine)) { $machine = [System.Net.Dns]::GetHostName() }

$desc = "Setup completed on $machine`nFarmSync Device: $device`nFarmSync Note: $note`nFarmSync Title: $title"
$embed = @{ title = 'KAITUN Setup Completed'; description = $desc; color = 3066993; timestamp = [DateTime]::UtcNow.ToString('o') }
$body = @{ username = 'KAITUN Setup'; embeds = @($embed) } | ConvertTo-Json -Depth 6
try {
    Invoke-RestMethod -Uri $webhook -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 15 | Out-Null
    Write-Output '[+] Setup completion webhook sent'
} catch {
    Write-Output ('[-] Setup webhook failed: ' + $_.Exception.Message)
}