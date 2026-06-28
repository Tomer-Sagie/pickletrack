@echo off
setlocal
:: _build.bat — Helper: runs flutter build web and writes .build_timestamp.
:: Called by watch_web.bat (both chokidar and polling paths).

cd /d "%~dp0\.."

echo [build] Rebuilding at %time:~0,8%...
flutter build web 2>&1 | findstr /V /R /C:"^Compiling" /C:"^Building" /C:"^Font" /C:"^Asset" /C:"^$"
if %ERRORLEVEL% == 0 (
    powershell -NoProfile -Command "[int](Get-Date -UFormat %%s)" > build\web\.build_timestamp
    echo [done]  Build OK - %time:~0,8%
) else (
    echo [FAIL]  Build failed - see errors above
)
echo ---
endlocal
