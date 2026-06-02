# Find Inno Setup installation location

Write-Host "Searching for Inno Setup..." -ForegroundColor Cyan
Write-Host ""

# Common installation paths
$commonPaths = @(
    "C:\Program Files (x86)\Inno Setup 6",
    "C:\Program Files\Inno Setup 6",
    "C:\Program Files (x86)\Inno Setup 5",
    "C:\Program Files\Inno Setup 5",
    "$env:ProgramFiles\Inno Setup 6",
    "$env:ProgramFiles (x86)\Inno Setup 6"
)

$found = $false

foreach ($path in $commonPaths) {
    $isccPath = Join-Path $path "ISCC.exe"
    if (Test-Path $isccPath) {
        Write-Host "✓ Found Inno Setup at: $path" -ForegroundColor Green
        Write-Host "  ISCC.exe: $isccPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "To build the installer, run:" -ForegroundColor Cyan
        Write-Host "  .\build-installer.ps1 -IsccPath '$isccPath'" -ForegroundColor Yellow
        $found = $true
        break
    }
}

if (-not $found) {
    Write-Host "Inno Setup not found in common locations" -ForegroundColor Red
    Write-Host ""
    Write-Host "Checking user-provided paths..." -ForegroundColor Yellow

    # Try searching in Program Files variants
    $searchDirs = @(
        "C:\Program Files",
        "C:\Program Files (x86)",
        $env:ProgramFiles,
        "${env:ProgramFiles(x86)}"
    ) | Get-Unique

    Write-Host ""
    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            $found = Get-ChildItem -Path $dir -Filter "ISCC.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                Write-Host "✓ Found at: $($found.FullName)" -ForegroundColor Green
                Write-Host ""
                Write-Host "To build the installer, run:" -ForegroundColor Cyan
                Write-Host "  .\build-installer.ps1 -IsccPath '$($found.FullName)'" -ForegroundColor Yellow
                exit 0
            }
        }
    }

    Write-Host ""
    Write-Host "Inno Setup installation not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Download Inno Setup from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    Write-Host "  2. Install it" -ForegroundColor Yellow
    Write-Host "  3. Re-run this script" -ForegroundColor Yellow
}
