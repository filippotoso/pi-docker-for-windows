@echo off
echo Building Docker image for pi-agent...
echo.

docker build -t pi-agent .

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to build the image!
    exit /b %errorlevel%
)

echo.
echo [OK] Image pi-agent built successfully.
echo You can now start the environment using run.bat
