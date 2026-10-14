@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

set "URL=https://github.com/lolokeia/sborka-mc/releases/download/latest/sborka.zip"
set "API=https://api.github.com/repos/lolokeia/sborka-mc/commits/master"
set "FOLDER_NAME=sborka-mc-main"
set "ZIP=update.zip"
set "SHAFILE=.last_commit"

echo.

echo   ОБНОВЛЕНИЕ СБОРКИ

echo.

:: --- Проверка aria2c ---
if not exist "aria2c.exe" (
    where aria2c.exe >nul 2>&1
    if errorlevel 1 (
        echo [!] aria2c.exe не найден рядом со скриптом.
        echo     Скачай с https://github.com/aria2/aria2/releases
        pause
        exit /b 1
    )
)

:: --- Узнаём последний коммит ---
echo Проверяю последнюю версию на GitHub...
set "REMOTE_SHA="
for /f "tokens=2 delims=:," %%A in ('curl.exe -s "%API%" ^| findstr /r /c:"\"sha\""') do (
    if not defined REMOTE_SHA set "REMOTE_SHA=%%A"
)
set "REMOTE_SHA=!REMOTE_SHA: =!"
set "REMOTE_SHA=!REMOTE_SHA:"=!"

if "!REMOTE_SHA!"=="" (
    echo   Не удалось получить SHA, продолжаю без проверки.
    echo   GitHub API мог лимитировать. Качаем всё равно.
) else (
    echo   Последний коммит: !REMOTE_SHA!
)

:: --- Сравниваем с локальным ---
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

:: --- Загрузка через aria2c (16 потоков) ---
echo.
echo Качаю (16 потоков)...
echo.

aria2c.exe -x16 -s16 -k1M ^
    --file-allocation=none ^
    --console-log-level=warn ^
    --summary-interval=3 ^
    -o "%ZIP%" ^
    "%URL%"

if errorlevel 1 (
    echo.
    echo [!] Ошибка загрузки.
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