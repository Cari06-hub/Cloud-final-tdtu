@echo off
chcp 65001 >nul
cd /d "%~dp0"
where py >nul 2>&1
if not errorlevel 1 (
  py -3 scripts\verify_local.py
) else (
  where python >nul 2>&1
  if not errorlevel 1 (
    python scripts\verify_local.py
  ) else (
    echo [ERROR] Chua cai Python 3. Cai Python 3 de kiem thu 20 muc.
    pause
    exit /b 1
  )
)
if errorlevel 1 (
  echo [ERROR] Con test FAIL. Xem docs\evidence\moi\*.txt.
) else (
  echo [OK] Tat ca bai test tren may nay PASS.
)
pause
