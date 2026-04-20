@echo off
docker run -it --rm -v "%cd%/src:/workspace" ^ -v "%cd%/.pi:/root/.pi" pi-agent
