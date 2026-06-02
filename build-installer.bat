@echo off
REM Build script for Symbolic Math Workbench installer
REM Requires Inno Setup 6.x to be installed

setlocal enabledelayedexpansion

REM Check if Inno Setup is installed
if not exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    echo.
    echo ERROR: Inno Setup 6 not found at C:\Program Files (x86)\Inno Setup 6
    echo Please install Inno Setup from: https://jrsoftware.org/isdl.php
    echo.
    pause
    exit /b 1
)

REM Create output directory
if not exist "installers" mkdir installers

REM Build the installer
echo Building Symbolic Math Workbench installer...
echo.

"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" symbolic-math-workbench.iss

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
