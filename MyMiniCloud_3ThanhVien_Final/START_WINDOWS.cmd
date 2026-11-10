@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0START_WINDOWS.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] Co loi khi khoi dong. Xem thong bao phia tren.
  pause
  exit /b 1
)
echo.
echo [OK] MyMiniCloud da hoan tat quy trinh khoi dong.
pause
