@echo off
cd /d "%~dp0.."
echo Stopping all services...
docker-compose down
echo Done. All containers stopped.
pause
