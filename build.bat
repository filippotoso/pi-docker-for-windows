@echo off
echo Costruzione dell'immagine Docker per pi-agent in corso...
echo.

docker build -t pi-agent .

if %errorlevel% neq 0 (
    echo.
    echo [ERRORE] Costruzione dell'immagine fallita!
    exit /b %errorlevel%
)

echo.
echo [OK] Immagine pi-agent costruita con successo.
echo Ora puoi avviare l'ambiente usando run-pi.bat
