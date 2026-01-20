@echo off
setlocal

echo ========================================
echo ROALogin Build Script
echo ========================================
echo.

:: Check for AutoHotkey v2 compiler
set "AHK2EXE="

:: Try common AutoHotkey v2 installation paths
if exist "%ProgramFiles%\AutoHotkey\v2\Compiler\Ahk2Exe.exe" (
    set "AHK2EXE=%ProgramFiles%\AutoHotkey\v2\Compiler\Ahk2Exe.exe"
) else if exist "%ProgramFiles%\AutoHotkey\Compiler\Ahk2Exe.exe" (
    set "AHK2EXE=%ProgramFiles%\AutoHotkey\Compiler\Ahk2Exe.exe"
) else if exist "%LocalAppData%\Programs\AutoHotkey\v2\Compiler\Ahk2Exe.exe" (
    set "AHK2EXE=%LocalAppData%\Programs\AutoHotkey\v2\Compiler\Ahk2Exe.exe"
) else if exist "C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe" (
    set "AHK2EXE=C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe"
)

if "%AHK2EXE%"=="" (
    echo ERROR: Could not find Ahk2Exe compiler.
    echo.
    echo Please install AutoHotkey v2 from:
    echo   https://www.autohotkey.com/download/
    echo.
    pause
    exit /b 1
)

echo Found compiler: %AHK2EXE%
echo.

:: Create dist directory if it doesn't exist
if not exist "dist" mkdir dist

:: Compile main script
echo Compiling ROALogin.exe...
"%AHK2EXE%" /in "src\roa_login.ahk" /out "dist\ROALogin.exe" /silent

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Build successful!
    echo ========================================
    echo.
    echo Output: dist\ROALogin.exe
    echo.
    echo You can now distribute ROALogin.exe
    echo.
) else (
    echo.
    echo ========================================
    echo Build FAILED
    echo ========================================
    echo.
    echo Check for syntax errors in the AHK scripts.
    echo.
)

pause
