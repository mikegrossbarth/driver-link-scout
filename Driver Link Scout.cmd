@echo off
setlocal
set "APP_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%APP_DIR%DriverLinkScout.ps1"
if errorlevel 1 (
  echo.
  echo Driver Link Scout could not start.
  echo Try right-clicking this file and choosing "Run as administrator".
  echo.
  pause
)
