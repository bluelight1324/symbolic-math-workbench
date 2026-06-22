# PowerShell script to build Symbolic Math Workbench installer
# Usage: .\build-installer.ps1 -IsccPath "C:\path\to\ISCC.exe"

param(
    [string]$IsccPath = ""
)

Write-Host "Symbolic Math Workbench Installer Builder" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Search for ISCC if not provided
if (-not $IsccPath) {
    Write-Host "Searching for Inno Setup..." -ForegroundColor Yellow

    $searchPaths = @(
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        "C:\Program Files (x86)\Inno Setup 5\ISCC.exe",
        "C:\Program Files\Inno Setup 5\ISCC.exe"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $IsccPath = $path
            Write-Host "✓ Found: $IsccPath" -ForegroundColor Green
            break
        }
    }
}

if (-not $IsccPath -or -not (Test-Path $IsccPath)) {
    Write-Host ""
    Write-Host "ERROR: Inno Setup not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please provide the path to ISCC.exe:" -ForegroundColor Yellow
    Write-Host "  .\build-installer.ps1 -IsccPath 'C:\path\to\ISCC.exe'"
    Write-Host ""
    Write-Host "Or install Inno Setup from: https://jrsoftware.org/isdl.php"
    exit 1
}

# Check for required files
$requiredFiles = @(
    "mathdot.iss",
    "app\project.godot",
    "tools\godot\Godot_v4.6.3-stable_win64.exe",
    "tools\reduce\bin\rfcsl.exe"
)

Write-Host ""
Write-Host "Checking required files..." -ForegroundColor Yellow
$allPresent = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file NOT FOUND" -ForegroundColor Red
        $allPresent = $false
    }
}

if (-not $allPresent) {
    Write-Host ""
    Write-Host "ERROR: Missing required files" -ForegroundColor Red
    exit 1
}

# Create output directory
$outDir = "installers"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
    Write-Host ""
    Write-Host "Created output directory: $outDir" -ForegroundColor Green
}

# Build the installer
Write-Host ""
Write-Host "Building installer..." -ForegroundColor Cyan
Write-Host "Command: & '$IsccPath' mathdot.iss"
Write-Host ""

& $IsccPath "mathdot.iss"

$buildResult = $LASTEXITCODE

Write-Host ""
if ($buildResult -eq 0) {
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installer created:" -ForegroundColor Green
    Get-ChildItem "installers\*.exe" | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  ✓ $($_.Name) ($sizeMB MB)" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "You can now distribute the installer or test it by running:" -ForegroundColor Cyan
    Write-Host "  .\installers\mathdot-1.2.0-Setup.exe"
} else {
    Write-Host "FAILED!" -ForegroundColor Red
    Write-Host "Build exited with code: $buildResult" -ForegroundColor Red
    exit 1
}
