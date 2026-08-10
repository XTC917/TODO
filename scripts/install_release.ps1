# Builds a release APK and installs it on a connected Android device via ADB.
# Prerequisites:
#   1. USB debugging enabled on your phone
#   2. Phone connected by USB (or wireless ADB paired)
#   3. Flutter SDK and Android platform-tools (adb) on PATH
#
# Usage:
#   .\scripts\install_release.ps1
#   .\scripts\install_release.ps1 -SkipBuild    # install existing APK only
#   .\scripts\install_release.ps1 -DeviceId abc123   # when multiple devices

param(
    [switch]$SkipBuild,
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

function Require-Command($Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name not found. Add it to PATH and try again."
    }
}

Require-Command flutter
Require-Command adb

Write-Host "Checking connected devices..."
$deviceLines = @(adb devices | Select-String "device$")
if ($deviceLines.Count -eq 0) {
    throw @"
No Android device found.

1. Connect your phone with USB
2. Enable Developer options + USB debugging
3. Accept the debugging prompt on the phone
4. Run: adb devices
"@
}

if ($DeviceId -ne "") {
    $adbTarget = @("-s", $DeviceId)
    Write-Host "Using device: $DeviceId"
} elseif ($deviceLines.Count -gt 1) {
    Write-Host "Multiple devices detected:"
    adb devices -l
    throw "Pass -DeviceId <serial> to choose a device."
} else {
    $adbTarget = @()
    Write-Host "Using device: $($deviceLines[0].Line.Split()[0])"
}

if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "Building release APK..."
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build apk --release failed."
    }
}

$apkDir = Join-Path $ProjectRoot "build\app\outputs\flutter-apk"
$apk = Get-ChildItem $apkDir -Filter "JUJUSchedule-v*.apk" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if ($null -eq $apk) {
    $apk = Get-Item (Join-Path $apkDir "app-release.apk") -ErrorAction SilentlyContinue
}
if ($null -eq $apk) {
    throw "APK not found under: $apkDir"
}
$apk = $apk.FullName

Write-Host ""
Write-Host "Installing to phone..."
& adb @adbTarget install -r $apk
if ($LASTEXITCODE -ne 0) {
    throw "adb install failed."
}

Write-Host ""
Write-Host "Done. JUJU Schedule (release) is installed on your phone."
