@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bootstrap\setup.ps1" %*
endlocal
