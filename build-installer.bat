@echo off
REM Build script for Symbolic Math Workbench installer
REM Requires Inno Setup 6.x to be installed

setlocal enabledelayedexpansion

REM Check if Inno Setup is installed (try multiple locations)
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    goto build_with_6x86
)
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    goto build_with_6
)
if exist "C:\Program Files (x86)\Inno Setup 5\ISCC.exe" (
    goto build_with_5x86
)
if exist "C:\Program Files\Inno Setup 5\ISCC.exe" (
    goto build_with_5
)

echo.
echo ERROR: Inno Setup not found in standard locations
echo Checked:
echo   C:\Program Files (x86)\Inno Setup 6\ISCC.exe
echo   C:\Program Files\Inno Setup 6\ISCC.exe
echo   C:\Program Files (x86)\Inno Setup 5\ISCC.exe
echo   C:\Program Files\Inno Setup 5\ISCC.exe
echo.
echo Please install Inno Setup from: https://jrsoftware.org/isdl.php
echo.
pause
exit /b 1

:build_with_6x86
REM Create output directory
if not exist "installers" mkdir installers
echo Building Symbolic Math Workbench installer...
echo Using: C:\Program Files (x86)\Inno Setup 6\ISCC.exe
echo.
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" symbolic-math-workbench.iss
goto check_result

:build_with_6
REM Create output directory
if not exist "installers" mkdir installers
echo Building Symbolic Math Workbench installer...
echo Using: C:\Program Files\Inno Setup 6\ISCC.exe
echo.
"C:\Program Files\Inno Setup 6\ISCC.exe" symbolic-math-workbench.iss
goto check_result

:build_with_5x86
REM Create output directory
if not exist "installers" mkdir installers
echo Building Symbolic Math Workbench installer...
echo Using: C:\Program Files (x86)\Inno Setup 5\ISCC.exe
echo.
"C:\Program Files (x86)\Inno Setup 5\ISCC.exe" symbolic-math-workbench.iss
goto check_result

:build_with_5
REM Create output directory
if not exist "installers" mkdir installers
echo Building Symbolic Math Workbench installer...
echo Using: C:\Program Files\Inno Setup 5\ISCC.exe
echo.
"C:\Program Files\Inno Setup 5\ISCC.exe" symbolic-math-workbench.iss

:check_result

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: Installer created in .\installers\
    echo.
    dir installers\*.exe
    pause
) else (
    echo.
    echo ERROR: Installer build failed
    pause
    exit /b 1
)
