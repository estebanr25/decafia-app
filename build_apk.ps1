#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectDir = 'C:\Users\luise\Documents\decafia_app'
$LogFile    = Join-Path $ProjectDir 'build_apk_log.txt'
$BuildStart = Get-Date

# ---------------------------------------------------------------------------
# Start transcript
# ---------------------------------------------------------------------------
try { Stop-Transcript 2>$null } catch {}
Start-Transcript -Path $LogFile -Force | Out-Null

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

function Write-Step {
    param($n, $msg)
    Write-Host "`n[STEP $n] $msg" -ForegroundColor Cyan
}

function Write-Ok {
    param($msg)
    Write-Host "  OK  $msg" -ForegroundColor Green
}

function Write-Info {
    param($msg)
    Write-Host "  >>  $msg" -ForegroundColor White
}

function Write-Warn {
    param($msg)
    Write-Host "  !!  $msg" -ForegroundColor Yellow
}

function Write-Banner {
    param($msg)
    $sep = '=' * 70
    Write-Host "`n$sep" -ForegroundColor Magenta
    Write-Host "  $msg"  -ForegroundColor Magenta
    Write-Host "$sep`n"  -ForegroundColor Magenta
}

function Fail {
    param($msg)
    Write-Host "`n[FAILED] $msg" -ForegroundColor Red
    Write-Host "  See full log: $LogFile" -ForegroundColor Yellow
    try { Stop-Transcript 2>$null } catch {}
    exit 1
}

Write-Banner "DECAFIA APK Builder  -  $($BuildStart.ToString('yyyy-MM-dd HH:mm:ss'))"

# ---------------------------------------------------------------------------
# STEP 1 - Locate flutter.bat
# ---------------------------------------------------------------------------
Write-Step 1 'Locating flutter.bat'

$flutterBat = $null

$inPath = Get-Command 'flutter.bat' -ErrorAction SilentlyContinue
if (-not $inPath) {
    $inPath = Get-Command 'flutter' -ErrorAction SilentlyContinue
}
if ($inPath) {
    $flutterBat = $inPath.Source
    Write-Ok "Found on PATH: $flutterBat"
}

if (-not $flutterBat) {
    Write-Info 'Not on PATH - searching candidate directories...'

    $searchRoots = @(
        'C:\flutter',
        'C:\src\flutter',
        (Join-Path $env:USERPROFILE 'flutter'),
        (Join-Path $env:USERPROFILE 'Downloads'),
        (Join-Path $env:LOCALAPPDATA 'flutter')
    )

    $allMatches = @()
    foreach ($root in $searchRoots) {
        if (Test-Path $root) {
            Write-Info "  Searching: $root"
            $hits = Get-ChildItem -Path $root -Filter 'flutter.bat' `
                        -Recurse -ErrorAction SilentlyContinue
            if ($hits) {
                $allMatches += $hits
            }
        }
    }

    if ($allMatches.Count -eq 0) {
        Write-Warn 'No flutter.bat found in any candidate location.'
        Write-Host ''
        Write-Host '  To install Flutter:' -ForegroundColor Yellow
        Write-Host '    1. Visit https://docs.flutter.dev/get-started/install/windows' -ForegroundColor Yellow
        Write-Host '    2. Download the stable SDK zip and extract to C:\flutter' -ForegroundColor Yellow
        Write-Host '    3. Add C:\flutter\bin to your PATH environment variable' -ForegroundColor Yellow
        Write-Host '    4. Reopen PowerShell and rerun this script.' -ForegroundColor Yellow
        Write-Host ''
        Fail 'Flutter SDK not found.'
    }

    Write-Info 'Matches found:'
    foreach ($m in $allMatches) {
        Write-Info "  $($m.FullName)"
    }

    $preferred = $allMatches |
        Where-Object { $_.FullName -match '\\bin\\flutter\.bat$' } |
        Select-Object -First 1

    if ($preferred) {
        $flutterBat = $preferred.FullName
    } else {
        $flutterBat = $allMatches[0].FullName
    }
    Write-Ok "Using: $flutterBat"
}

Write-Info 'Verifying flutter.bat executes...'
$flutterVersion = & $flutterBat --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Fail "flutter.bat at '$flutterBat' exited with code $LASTEXITCODE."
}
$versionLine = $flutterVersion | Select-String 'Flutter' | Select-Object -First 1
if ($versionLine) {
    Write-Ok $versionLine.Line
}

# ---------------------------------------------------------------------------
# STEP 2 - Locate a valid JDK and set JAVA_HOME
# ---------------------------------------------------------------------------
Write-Step 2 'Locating a valid JDK'

$javaHome = $null

# Preferred: Android Studio bundled JBR
$asJbr = 'C:\Program Files\Android\Android Studio\jbr'
if (Test-Path (Join-Path $asJbr 'bin\java.exe')) {
    $javaHome = $asJbr
    Write-Ok "Found Android Studio JBR: $javaHome"
}

# Fallback: scan Program Files / LocalAppData for any java.exe
if (-not $javaHome) {
    Write-Info 'Android Studio JBR not found - scanning for other JDK installations...'

    $jdkSearchRoots = @()
    if ($env:ProgramFiles -and (Test-Path $env:ProgramFiles)) {
        $jdkSearchRoots += $env:ProgramFiles
    }
    if (${env:ProgramFiles(x86)} -and (Test-Path ${env:ProgramFiles(x86)})) {
        $jdkSearchRoots += ${env:ProgramFiles(x86)}
    }
    if ($env:LOCALAPPDATA -and (Test-Path $env:LOCALAPPDATA)) {
        $jdkSearchRoots += $env:LOCALAPPDATA
    }

    $javaExes = @()
    foreach ($root in $jdkSearchRoots) {
        $hits = Get-ChildItem -Path $root -Filter 'java.exe' `
                    -Recurse -ErrorAction SilentlyContinue
        if ($hits) {
            $javaExes += $hits
        }
    }

    $candidates = @()
    foreach ($j in $javaExes) {
        $binDir = Split-Path $j.FullName -Parent
        $jdkDir = Split-Path $binDir -Parent
        if ($jdkDir -and (Test-Path (Join-Path $jdkDir 'bin\java.exe'))) {
            if ($candidates -notcontains $jdkDir) {
                $candidates += $jdkDir
            }
        }
    }

    if ($candidates.Count -gt 0) {
        Write-Info 'JDK candidates found:'
        foreach ($c in $candidates) {
            Write-Info "  $c"
        }
        $javaHome = $candidates[0]
        Write-Ok "Using: $javaHome"
    }
}

# Last resort: honour existing JAVA_HOME
if (-not $javaHome) {
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
        $javaHome = $env:JAVA_HOME
        Write-Info "Using pre-existing JAVA_HOME: $javaHome"
    } else {
        Write-Warn 'No JDK found automatically.'
        Write-Host ''
        Write-Host '  A JDK is required to build an Android APK.' -ForegroundColor Yellow
        Write-Host '  Recommended: install Android Studio (includes a bundled JDK):' -ForegroundColor Yellow
        Write-Host '    https://developer.android.com/studio' -ForegroundColor Yellow
        Write-Host '  Or a standalone JDK 17 or 21:' -ForegroundColor Yellow
        Write-Host '    https://adoptium.net/' -ForegroundColor Yellow
        Write-Host ''
        Fail 'No valid JDK found.'
    }
}

$env:JAVA_HOME = $javaHome
Write-Info "JAVA_HOME set to: $env:JAVA_HOME"

Write-Info 'Confirming java -version:'
$javaVer = & "$env:JAVA_HOME\bin\java.exe" -version 2>&1
foreach ($line in $javaVer) {
    Write-Info "  $line"
}
if ($LASTEXITCODE -ne 0) {
    Fail "java.exe at '$env:JAVA_HOME\bin\java.exe' exited with code $LASTEXITCODE."
}

# ---------------------------------------------------------------------------
# STEP 3 - cd to project and run flutter doctor
# ---------------------------------------------------------------------------
Write-Step 3 'Running flutter doctor -v'

if (-not (Test-Path $ProjectDir)) {
    Fail "Project directory not found: $ProjectDir"
}
Set-Location $ProjectDir
Write-Info "Working directory: $(Get-Location)"

Write-Info 'Running flutter doctor -v (may take a moment)...'
& $flutterBat doctor -v 2>&1 | ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) {
    Write-Warn "flutter doctor exited with code $LASTEXITCODE - build will still be attempted."
}

# ---------------------------------------------------------------------------
# STEP 4 - Build the release APK
# ---------------------------------------------------------------------------
Write-Step 4 'Building release APK'

Write-Info 'Running: flutter build apk --release'
Write-Info '(First build typically takes 3-10 minutes - subsequent builds are faster)'
Write-Host ''

& $flutterBat build apk --release 2>&1 | ForEach-Object { Write-Host "  $_" }
$buildExitCode = $LASTEXITCODE

if ($buildExitCode -ne 0) {
    Fail "flutter build apk --release failed with exit code $buildExitCode. Review the output above."
}

# ---------------------------------------------------------------------------
# STEP 5 - Verify and report the produced APK
# ---------------------------------------------------------------------------
Write-Step 5 'Verifying produced APK'

$apkDefault = Join-Path $ProjectDir 'build\app\outputs\flutter-apk\app-release.apk'
$apkPath    = $null

if (Test-Path $apkDefault) {
    $apkPath = $apkDefault
} else {
    $buildRoot = Join-Path $ProjectDir 'build'
    $found = Get-ChildItem -Path $buildRoot -Filter 'app-release.apk' `
                 -Recurse -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($found) {
        $apkPath = $found.FullName
        Write-Warn "APK not at default path - found at: $apkPath"
    } else {
        Fail 'Build reported success but app-release.apk was not found in the build tree.'
    }
}

$apkItem     = Get-Item $apkPath
$apkSizeMB   = [math]::Round($apkItem.Length / 1MB, 2)
$apkModified = $apkItem.LastWriteTime
$ageSeconds  = ($BuildStart - $apkModified).TotalSeconds

if ($ageSeconds -gt 60) {
    Write-Warn "APK timestamp ($($apkModified.ToString('HH:mm:ss'))) predates this build run - may be stale."
} else {
    Write-Ok "APK timestamp is current: $($apkModified.ToString('yyyy-MM-dd HH:mm:ss'))"
}

$BuildEnd = Get-Date
$elapsed  = $BuildEnd - $BuildStart
$elMin    = [math]::Floor($elapsed.TotalMinutes)
$elSec    = [math]::Floor($elapsed.TotalSeconds) % 60

Write-Banner 'BUILD SUCCESSFUL'
Write-Host "  APK path  : $apkPath"                                         -ForegroundColor Green
Write-Host "  Size      : $apkSizeMB MB"                                    -ForegroundColor Green
Write-Host "  Timestamp : $($apkModified.ToString('yyyy-MM-dd HH:mm:ss'))"  -ForegroundColor Green
Write-Host "  Elapsed   : ${elMin}m ${elSec}s"                              -ForegroundColor Green
Write-Host "  Log file  : $LogFile"                                          -ForegroundColor Green
Write-Host ''
Write-Host '  To install on a connected device:'  -ForegroundColor Cyan
Write-Host "    adb install `"$apkPath`""          -ForegroundColor Cyan
Write-Host ''

# ---------------------------------------------------------------------------
# STEP 6 - Close transcript
# ---------------------------------------------------------------------------
try { Stop-Transcript 2>$null } catch {}
Write-Host "Full transcript saved to: $LogFile" -ForegroundColor DarkGray
