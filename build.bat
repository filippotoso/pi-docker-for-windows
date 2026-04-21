@echo off
echo Building Docker image for pi-agent...
echo.

set TIMESTAMP=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

docker build --build-arg CACHEBUST=%TIMESTAMP% -t pi-agent .

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to build the image!
    exit /b %errorlevel%
)

echo.
echo [OK] Image pi-agent built successfully.
echo You can now start the environment using run.bat
