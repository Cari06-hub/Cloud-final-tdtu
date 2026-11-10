@echo off
cd /d "%~dp0"
echo Dung 11 container; GIU LAI volumes du lieu (khong down -v).
docker compose --env-file .env down
pause
