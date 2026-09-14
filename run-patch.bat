@echo off
REM ---------------------------------------------------------------------------
REM Claude Desktop Persian RTL -- Secure Hardened v1.3.2 launcher
REM ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

echo.
echo  Claude Desktop Persian RTL -- Secure Hardened v1.3.2
echo  Folder: %~dp0
echo.

if not exist "%~dp0patch.ps1" (
    echo  [!] patch.ps1 was not found next to this file.
    echo      Extract the complete ZIP first and run this launcher from the extracted folder.
    echo.
    pause
    exit /b 1
)

echo  Tip: before first install, menu ^> Security ^& Maintenance ^> Verify package hashes.
echo.
echo  Starting patcher...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1"
set RC=%errorlevel%

echo.
echo  ---------------------------------------------------------------
echo   Patcher exit code: %RC%
echo.
echo   Log, when present:
echo     %ProgramData%\ClaudeRtlPatch\patch.log
echo  ---------------------------------------------------------------
echo.
pause
endlocal
