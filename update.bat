@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

set "URL=https://github.com/lolokeia/sborka-mc/releases/download/latest/sborka.zip"
set "API=https://api.github.com/repos/lolokeia/sborka-mc/commits/main"
set "FOLDER_NAME=sborka-mc-main"
set "ZIP=update.zip"
set "SHAFILE=.last_commit"

echo.
echo Updating...
echo.

where curl.exe >nul 2>&1
if errorlevel 1 (
    echo [!] curl.exe not found. Windows 10 1803+ required.
    pause
    exit /b 1
)

echo Checking latest version on GitHub...
set "REMOTE_SHA="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri '%API%' -Headers @{'User-Agent'='updater'}).sha"`) do set "REMOTE_SHA=%%A"
set "REMOTE_SHA=!REMOTE_SHA: =!"

if "!REMOTE_SHA!"=="" (
    echo   Could not get SHA, downloading anyway.
) else (
    echo   Latest commit: !REMOTE_SHA!
)

if defined REMOTE_SHA if exist "%SHAFILE%" (
    set /p LOCAL_SHA=<"%SHAFILE%"
    if "!LOCAL_SHA!"=="!REMOTE_SHA!" (
        echo.
        echo   Already up to date. Nothing to do.
        pause
        exit /b 0
    )
)

if exist "%ZIP%" del /f /q "%ZIP%"

echo.
echo Downloading...
echo.

curl.exe -L --fail --retry 3 --retry-delay 2 --connect-timeout 30 ^
    -o "%ZIP%" ^
    "%URL%"

if errorlevel 1 (
    echo [!] Download failed.
    if exist "%ZIP%" del /f /q "%ZIP%"
    pause
    exit /b 1
)
if not exist "%ZIP%" (
    echo [!] File not created.
    pause
    exit /b 1
)

for %%F in ("%ZIP%") do echo Downloaded: %%~zF bytes

echo.
echo Unpacking...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '.' -Force } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [!] Unpack failed.
    del /f /q "%ZIP%"
    pause
    exit /b 1
)
del /f /q "%ZIP%"

if not exist "%FOLDER_NAME%\" (
    echo [!] Folder "%FOLDER_NAME%" not found.
    pause
    exit /b 1
)

echo Cleaning mods and kubejs...
if exist "mods\" rmdir /s /q "mods"
if exist "kubejs\" rmdir /s /q "kubejs"

if exist "%FOLDER_NAME%\update.bat" del /f /q "%FOLDER_NAME%\update.bat"
if exist "%FOLDER_NAME%\.last_commit" del /f /q "%FOLDER_NAME%\.last_commit"
if exist "%FOLDER_NAME%\update.log" del /f /q "%FOLDER_NAME%\update.log"

echo Installing...
xcopy /e /y /q /h "%FOLDER_NAME%\*" ".\"
rmdir /s /q "%FOLDER_NAME%"

if defined REMOTE_SHA > "%SHAFILE%" echo !REMOTE_SHA!

echo.
echo ============================================
echo   DONE. Sborka updated.
echo ============================================
pause