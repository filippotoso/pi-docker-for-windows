@echo off
setlocal EnableExtensions

if defined PI_DOTPI (set "PI_MOUNT=%PI_DOTPI%") else (set "PI_MOUNT=%cd%\.pi")

if defined CURSOR_API_KEY_FILE (set "SECRET_SRC=%CURSOR_API_KEY_FILE%") else (set "SECRET_SRC=%USERPROFILE%\.cursor-api-key")

if not exist "%SECRET_SRC%" (
    echo [ERROR] API key file not found: "%SECRET_SRC%"
    echo Set CURSOR_API_KEY_FILE to your key file path, or create the default file.
    exit /b 1
)

if exist "%SECRET_SRC%\" (
    echo [ERROR] Expected a file, not a directory: "%SECRET_SRC%"
    exit /b 1
)

for %%I in ("%SECRET_SRC%") do if %%~zI equ 0 (
    echo [ERROR] API key file is empty: "%SECRET_SRC%"
    exit /b 1
)

set "EXTRA_ENV="
if defined PI_AUTH_PROVIDER set "EXTRA_ENV=-e PI_AUTH_PROVIDER=%PI_AUTH_PROVIDER%"

start cmd /c "docker run -it --rm --security-opt=no-new-privileges --cap-drop=ALL %EXTRA_ENV% -v ""%cd%:/workspace"" -v ""%PI_MOUNT%:/home/sandbox/.pi"" -v ""%SECRET_SRC%:/run/secrets/cursor_api_key:ro"" pi-agent"
