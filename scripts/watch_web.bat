@echo off
setlocal EnableDelayedExpansion

:: watch_web.bat — Auto-rebuild Flutter web on lib/ changes (Windows native)
::
:: Usage:  scripts\watch_web.bat
::
:: What it does:
::   1. Runs an initial flutter build web
::   2. Watches lib\**\*.dart and web\phone_preview.html for changes
::   3. Rebuilds and writes build\web\.build_timestamp on every change
::   4. The phone_preview.html page polls that file every 2s and
::      auto-refreshes the iframe when it changes.
::
:: Preferred watcher: chokidar-cli (cross-platform, instant)
::   Install: npm install --save-dev chokidar-cli
:: Fallback: polling loop (checks every 2s)

cd /d "%~dp0\.."

set BUILD_DIR=build\web
set TS_FILE=%BUILD_DIR%\.build_timestamp

echo ^>^> PickleTrack web watcher
echo   Watching: lib\  +  web\phone_preview.html
echo   Output:   %BUILD_DIR%\
echo.

:: ── Initial build ──
echo [build] Initial build...
call "%~dp0_build.bat"
if %ERRORLEVEL% == 0 (
    echo [done]  Initial build complete - %time:~0,8%
) else (
    echo [FAIL]  Initial build failed
    exit /b 1
)
echo.

:: ── Watch method 1: chokidar-cli (preferred, cross-platform, instant) ──
call npx chokidar --version >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using chokidar-cli (instant, cross-platform) for file watching.
    echo Press Ctrl+C to stop.
    echo.
    npx chokidar "lib/**/*.dart" "web/phone_preview.html" --initial --command "call \"%~dp0_build.bat\""
    goto :end
)

:: ── Watch method 2: polling fallback ──
echo No instant watcher found - using polling fallback (checks every 2s).
echo Install chokidar-cli for instant rebuilds: npm install --save-dev chokidar-cli
echo Press Ctrl+C to stop.
echo.

set LAST_MTIME=
:poll_loop
for /f "delims=" %%t in ('powershell -NoProfile -Command "$files = Get-ChildItem -Path 'lib\**\*.dart','web\phone_preview.html' -Recurse -ErrorAction SilentlyContinue; if ($files) { ($files ^| Sort-Object LastWriteTime -Descending ^| Select-Object -First 1).LastWriteTime.ToString('yyyyMMddHHmmssfff') } else { '0' }"') do set CURRENT_MTIME=%%t

if not "!LAST_MTIME!"=="" if not "!LAST_MTIME!"=="!CURRENT_MTIME!" (
    call "%~dp0_build.bat"
)
set LAST_MTIME=!CURRENT_MTIME!
timeout /t 2 /nobreak >nul
goto poll_loop

:end
endlocal
