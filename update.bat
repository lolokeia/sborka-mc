@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: ============================================
::  ОБНОВЛЕНИЕ СБОРКИ
:: ============================================

set "URL=https://github.com/lolokeia/sborka-mc/releases/download/latest/sborka.zip"
set "API=https://api.github.com/repos/lolokeia/sborka-mc/commits/main"
set "FOLDER_NAME=sborka-mc-main"
set "ZIP=update.zip"
set "SHAFILE=.last_commit"

echo.
echo ============================================
echo   ОБНОВЛЕНИЕ СБОРКИ
echo ============================================
echo.

:: --- Проверка curl ---
where curl.exe >nul 2>&1
if errorlevel 1 (
    echo [!] curl.exe не найден. Нужна Windows 10 1803+.
    pause
    exit /b 1
)

:: --- Проверка последнего коммита ---
echo Проверяю последнюю версию на GitHub...
set "REMOTE_SHA="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri '%API%' -Headers @{'User-Agent'='updater'}).sha"`) do set "REMOTE_SHA=%%A"
set "REMOTE_SHA=!REMOTE_SHA: =!"

if "!REMOTE_SHA!"=="" (
    echo   Не удалось получить SHA, качаю всё равно.
) else (
    echo   Последний коммит: !REMOTE_SHA!
)

if defined REMOTE_SHA if exist "%SHAFILE%" (
    set /p LOCAL_SHA=<"%SHAFILE%"
    if "!LOCAL_SHA!"=="!REMOTE_SHA!" (
        echo.
        echo   У тебя уже последняя версия. Обновление не нужно.
        pause
        exit /b 0
    )
)

:: --- Чистка перед скачиванием ---
if exist "%ZIP%" del /f /q "%ZIP%"

:: --- Загрузка через curl ---
echo.
echo Качаю...
echo.

curl.exe -L --fail --retry 3 --retry-delay 2 --connect-timeout 30 ^
    -o "%ZIP%" ^
    "%URL%"

if errorlevel 1 (
    echo [!] Ошибка загрузки.
    if exist "%ZIP%" del /f /q "%ZIP%"
    pause
    exit /b 1
)
if not exist "%ZIP%" (
    echo [!] Файл не создан.
    pause
    exit /b 1
)

for %%F in ("%ZIP%") do echo Скачано: %%~zF байт

:: --- Распаковка ---
echo.
echo Распаковка...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '.' -Force } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [!] Не удалось распаковать.
    del /f /q "%ZIP%"
    pause
    exit /b 1
)
del /f /q "%ZIP%"

if not exist "%FOLDER_NAME%\" (
    echo [!] Не найдена папка "%FOLDER_NAME%".
    pause
    exit /b 1
)

:: --- Очистка старого ---
echo Чищу mods и kubejs...
if exist "mods\" rmdir /s /q "mods"
if exist "kubejs\" rmdir /s /q "kubejs"
:: if exist "config\" rmdir /s /q "config"

:: --- Исключаем служебные файлы из архива ---
if exist "%FOLDER_NAME%\update.bat" del /f /q "%FOLDER_NAME%\update.bat"
if exist "%FOLDER_NAME%\.last_commit" del /f /q "%FOLDER_NAME%\.last_commit"
if exist "%FOLDER_NAME%\update.log" del /f /q "%FOLDER_NAME%\update.log"

:: --- Установка ---
echo Устанавливаю...
xcopy /e /y /q /h "%FOLDER_NAME%\*" ".\"
rmdir /s /q "%FOLDER_NAME%"

:: --- Запоминаем коммит ---
if defined REMOTE_SHA > "%SHAFILE%" echo !REMOTE_SHA!

echo.
echo ============================================
echo   ГОТОВО. Сборка обновлена.
echo ============================================
pause