@echo off
start cmd /c "docker run -it --rm -v ""%cd%:/workspace"" -v ""%cd%/.pi:/root/.pi"" pi-agent"
