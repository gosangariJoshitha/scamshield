param(
    [string]$DeviceId,
    [int]$Port = 8000,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
$adb = if ($adbCommand) {
    $adbCommand.Source
} else {
    Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
}

if (-not (Test-Path $adb)) {
    throw 'Android Debug Bridge was not found. Install Android platform-tools or add adb to PATH.'
}

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    throw 'Flutter was not found on PATH. Add the Flutter SDK bin directory to PATH and retry.'
}

$deviceLines = & $adb devices
$devices = @(
    $deviceLines |
        Select-Object -Skip 1 |
        Where-Object { $_ -match '^(\S+)\s+device$' } |
        ForEach-Object {
            [regex]::Match($_, '^(\S+)\s+device$').Groups[1].Value
        }
)

if ($DeviceId) {
    if ($devices -notcontains $DeviceId) {
        throw "Android device '$DeviceId' is not connected and authorized."
    }
} elseif ($devices.Count -eq 1) {
    $DeviceId = $devices[0]
} elseif ($devices.Count -eq 0) {
    throw 'No authorized Android phone is connected. Connect and authorize the phone, then retry.'
} else {
    throw 'More than one Android device is connected. Specify one with -DeviceId.'
}

$healthUri = "http://127.0.0.1:$Port/api/health"
try {
    $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 5
} catch {
    throw "ScamShield API is not responding at $healthUri. Start the backend, then retry."
}

if ($health.status -ne 'ok') {
    throw "ScamShield API health check returned an unexpected response at $healthUri."
}

& $adb -s $DeviceId reverse "tcp:$Port" "tcp:$Port"
if ($LASTEXITCODE -ne 0) {
    throw "Could not configure USB port forwarding for Android device '$DeviceId'."
}

$reverseMappings = & $adb -s $DeviceId reverse --list
if (-not ($reverseMappings | Select-String -SimpleMatch "tcp:$Port tcp:$Port")) {
    throw "USB port forwarding for port $Port could not be verified."
}

Write-Host "API health check passed: $healthUri"
Write-Host "USB forwarding is active for Android device $DeviceId on port $Port."

if ($CheckOnly) {
    return
}

Push-Location $PSScriptRoot
try {
    & $flutterCommand.Source run `
        --device-id $DeviceId `
        "--dart-define=API_BASE_URL=http://127.0.0.1:$Port/api"
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
