# Incremental JUJU Schedule website publish for Tencent CloudBase static hosting.
# Uploads only the new APK and js/config.js. Does not replace the whole website.
#
# Usage (from repo root or this folder):
#   .\website\deploy.ps1 -Version 2.6.5
#   .\deploy.ps1 -Version 2.6.5
#
# Prerequisites:
#   1. flutter build apk --release  (creates build/app/outputs/flutter-apk/app-release.apk)
#   2. CloudBase CLI: npm i -g @cloudbase/cli
#   3. tcb login

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$EnvId = "juju-d7g3aezw61b68afe8",

    [string]$SiteOrigin = "https://juju-d7g3aezw61b68afe8-1358899741.tcloudbaseapp.com"
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    Fail "Missing -Version. Example: .\deploy.ps1 -Version 2.6.5"
}

$Version = $Version.Trim()
if ($Version.StartsWith("v") -or $Version.StartsWith("V")) {
    $Version = $Version.Substring(1)
}
if ($Version -notmatch '^\d+(\.\d+)*$') {
    Fail "Invalid version '$Version'. Use a number like 2.6.5"
}

if ([string]::IsNullOrWhiteSpace($EnvId)) {
    Fail "CloudBase EnvId is empty. Expected: juju-d7g3aezw61b68afe8"
}

$WebsiteRoot = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $WebsiteRoot
$SourceApk = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"
$DownloadsDir = Join-Path $WebsiteRoot "downloads"
$ApkName = "JUJUSchedule-v$Version.apk"
$LocalApk = Join-Path $DownloadsDir $ApkName
$ConfigPath = Join-Path $WebsiteRoot "js\config.js"
$CloudApkPath = "downloads/$ApkName"
$CloudConfigPath = "js/config.js"
$DownloadUrl = "$SiteOrigin/$CloudApkPath"

if (-not (Test-Path -LiteralPath $SourceApk)) {
    Fail @"
Release APK not found:
  $SourceApk

Run this first in the project root:
  flutter build apk --release
"@
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Fail "Config file not found: $ConfigPath"
}

function Resolve-Tcb {
    $names = @("tcb.cmd", "tcb", "cloudbase.cmd", "cloudbase")
    foreach ($name in $names) {
        $found = Get-Command $name -ErrorAction SilentlyContinue
        if ($found) {
            return $found.Source
        }
    }

    $npmPrefix = $null
    try {
        $npmPrefix = (npm prefix -g 2>$null)
    } catch {
        $npmPrefix = $null
    }
    if ($npmPrefix) {
        foreach ($name in @("tcb.cmd", "tcb.ps1", "cloudbase.cmd", "cloudbase.ps1")) {
            $candidate = Join-Path $npmPrefix $name
            if (Test-Path -LiteralPath $candidate) {
                return $candidate
            }
        }
    }

    $npx = Get-Command npx.cmd -ErrorAction SilentlyContinue
    if (-not $npx) {
        $npx = Get-Command npx -ErrorAction SilentlyContinue
    }
    if ($npx) {
        return "npx"
    }

    return $null
}

$Tcb = Resolve-Tcb
if (-not $Tcb) {
    Fail @"
CloudBase CLI not found (tcb / cloudbase).
No remote files were changed.

Install and log in:
  npm i -g @cloudbase/cli
  tcb login

Then run:
  .\deploy.ps1 -Version $Version
"@
}

function Invoke-Tcb {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CliArgs,
        [Parameter(Mandatory = $true)]
        [string]$OnFail
    )
    Write-Host ("  > tcb " + ($CliArgs -join " "))

    # Start-Process keeps tcb stderr (progress spinners) out of PowerShell's
    # error stream. 2>&1 + ErrorAction Stop would treat "Loading data..." as failure.
    if ($Tcb -eq "npx") {
        $file = "npx.cmd"
        $allArgs = @("--yes", "@cloudbase/cli") + $CliArgs
    } else {
        $file = $Tcb
        $allArgs = $CliArgs
    }
    $argLine = ($allArgs | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }) -join " "

    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $proc = Start-Process -FilePath $file -ArgumentList $argLine -Wait -NoNewWindow -PassThru
    } finally {
        $ErrorActionPreference = $prev
    }
    if (-not $proc -or $proc.ExitCode -ne 0) {
        Fail $OnFail
    }
}

Write-Host "Checking CloudBase CLI login and environment $EnvId ..."
Invoke-Tcb -CliArgs @("hosting", "list", "-e", $EnvId) -OnFail @"
CloudBase CLI check failed. No remote files were changed.

If you are not logged in:
  tcb login

If the environment ID is wrong, expected:
  juju-d7g3aezw61b68afe8
"@

Write-Host "CloudBase environment is ready."
Write-Host "Version : $Version"
Write-Host "APK     : $SourceApk"
Write-Host "Upload  : $CloudApkPath"
Write-Host "Config  : $CloudConfigPath"
Write-Host "URL     : $DownloadUrl"
Write-Host ""

New-Item -ItemType Directory -Force -Path $DownloadsDir | Out-Null
Copy-Item -LiteralPath $SourceApk -Destination $LocalApk -Force
Write-Host "Copied APK -> $LocalApk"

$config = [System.IO.File]::ReadAllText($ConfigPath)
# (?m) so ^ matches each line. Replace count 1 keeps changelog version strings.
$versionPattern = [regex]'(?m)^(\s*version:\s*")[^"]*(")'
$betaPattern = [regex]'(?m)^(\s*beta:\s*")[^"]*(")'
if (-not $versionPattern.IsMatch($config)) {
    Fail "version field not found in config.js. Stopped. No remote files were changed."
}
if (-not $betaPattern.IsMatch($config)) {
    Fail "downloads.beta field not found in config.js. Stopped. No remote files were changed."
}

$config = $versionPattern.Replace($config, ('${1}' + $Version + '${2}'), 1)
$config = $betaPattern.Replace($config, ('${1}' + $DownloadUrl + '${2}'), 1)
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($ConfigPath, $config, $utf8)
Write-Host "Updated $ConfigPath"
Write-Host "  version = $Version"
Write-Host "  downloads.beta = $DownloadUrl"
Write-Host ""

$apkFail = @"
APK upload failed. Stopped.
config.js was NOT uploaded, so the live download URL is unchanged.
Local files already updated:
  $LocalApk
  $ConfigPath
Fix the error and run the script again.
"@

Write-Host "Uploading APK (existing versions will be kept)..."
Invoke-Tcb -CliArgs @("hosting", "deploy", $LocalApk, $CloudApkPath, "-e", $EnvId) -OnFail $apkFail

$configFail = @"
config.js upload failed. Stopped.
The APK may already be at:
  $DownloadUrl
but live config.js is still the old version.
Fix the error and run the script again. Old APKs are not deleted.
"@

Write-Host "Uploading js/config.js ..."
Invoke-Tcb -CliArgs @("hosting", "deploy", $ConfigPath, $CloudConfigPath, "-e", $EnvId) -OnFail $configFail

Write-Host ""
Write-Host "Publish succeeded." -ForegroundColor Green
Write-Host "Download: $DownloadUrl"
Write-Host "Site:     $SiteOrigin/"
Write-Host "Old APK files on CloudBase were not deleted."
