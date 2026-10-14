@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: config
set "ZIP_URL=https://github.com/lolokeia/sborka-mc"
set "FOLDER_NAME=MC_UPDATE"

echo только для внутреннего использования!
echo..

echo Скачивание обновления с гитхаба
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile 'update.zip'"

if not exist "update.zip" (
    echo Не удалось скачать файл..
    pause
    exit /b
)

echo Распаковка архива
powershell -Command "Expand-Archive -Path 'update.zip' -DestinationPath '.' -Force"
del update.zip

echo очистка устаревших папок и файлов
if exist "mods\" rmdir /s /q "mods"
if exist "kubejs\" rmdir /s /q "kubejs"
:: if exist "config\" rmdir /s /q "config"

echo Установка обновления
:: Переносим файлы из распакованной папки в корень игры
xcopy /e /y /q "%FOLDER_NAME%\*" ".\"
rmdir /s /q "%FOLDER_NAME%"


echo  Сборка обновлена! 

pause
