@echo off
REM ============================================================
REM LLM Tracker - Secure Setup Script
REM ============================================================
REM This script sets up Airflow securely with custom credentials

setlocal enabledelayedexpansion

cd /d "%~dp0"

echo.
echo ============================================================
echo  LLM Tracker - Secure Airflow Setup
echo ============================================================
echo.

REM Step 1: Check Docker
echo [Step 1] Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not found. Please install Docker Desktop first.
    echo Download from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo DONE: Docker is installed
echo.

REM Step 2: Check if .env exists
echo [Step 2] Checking environment configuration...
if not exist ".env" (
    echo.
    echo WARNING: .env file not found!
    echo.
    echo A .env file with secure credentials is recommended.
    echo.
    echo Creating .env from template...
    copy ".env.example" ".env"
    echo.
    echo IMPORTANT: Please edit .env and change the default passwords:
    echo   - POSTGRES_PASSWORD
    echo   - AIRFLOW_ADMIN_PASSWORD
    echo.
    echo After editing .env, run this script again.
    echo.
    pause
    exit /b 0
)
echo DONE: .env file found
echo.

REM Step 3: Read credentials from .env
echo [Step 3] Loading environment variables...
for /f "delims==" %%a in ('findstr /v "^#" ".env" ^| findstr "="') do (
    for /f "tokens=1* delims==" %%b in ("%%a") do (
        set "%%b=%%c"
    )
)
echo DONE: Environment variables loaded
echo.

REM Step 4: Start services
echo [Step 4] Starting database services...
docker-compose up -d postgres elasticsearch
if errorlevel 1 (
    echo ERROR: Failed to start database services
    pause
    exit /b 1
)
echo DONE: PostgreSQL and Elasticsearch starting
echo.

REM Step 5: Wait for services
echo [Step 5] Waiting for services to become healthy...
echo Please wait 30-45 seconds...
timeout /t 45 /nobreak

REM Check Elasticsearch
echo Checking Elasticsearch health...
:es_check
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:9200/_cluster/health' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch { } exit 1"
if errorlevel 1 (
    timeout /t 5 /nobreak
    goto es_check
)
echo DONE: Elasticsearch is healthy
echo.

REM Step 6: Start application services
echo [Step 6] Starting application services...
docker-compose up -d kibana airflow-webserver airflow-scheduler
if errorlevel 1 (
    echo ERROR: Failed to start application services
    pause
    exit /b 1
)
echo DONE: Services starting
echo.

REM Step 7: Initialize Airflow
echo [Step 7] Initializing Airflow database...
docker-compose run --rm airflow-init
if errorlevel 1 (
    echo ERROR: Failed to initialize Airflow
    pause
    exit /b 1
)
echo DONE: Airflow initialized
echo.

REM Step 8: Wait for Kibana
echo [Step 8] Waiting for Kibana to become ready...
:kibana_check
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:5601/api/status' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch { } exit 1"
if errorlevel 1 (
    timeout /t 5 /nobreak
    goto kibana_check
)
echo DONE: Kibana is ready
echo.

REM Step 9: Create dashboard
echo [Step 9] Creating Kibana dashboard...
powershell -ExecutionPolicy Bypass -File ".\scripts\create_dashboard.ps1"
echo.

REM Summary
echo.
echo ============================================================
echo  SETUP COMPLETE!
echo ============================================================
echo.
echo CREDENTIALS:
echo   Username: admin
if defined AIRFLOW_ADMIN_PASSWORD (
    echo   Password: (as specified in .env)
) else (
    echo   Password: admin
)
echo.
echo ACCESS POINTS:
echo   Airflow UI:       http://localhost:8080
echo   Elasticsearch:    http://localhost:9200
echo   Kibana:           http://localhost:5601
echo.
echo NEXT STEPS:
echo.
echo 1. Open Airflow: http://localhost:8080
echo.
echo 2. Change your admin password immediately:
echo    - Click Admin menu (top right)
echo    - Select "Security" > "Change Password"
echo    - Enter new password
echo.
echo 3. Enable the DAG:
echo    - Go to DAGs section
echo    - Find "llm_cost_performance_tracker"
echo    - Toggle DAG to ON
echo.
echo 4. Trigger the pipeline:
echo    - Click on the DAG name
echo    - Click "Trigger DAG" button
echo    - Monitor execution in real-time
echo.
echo 5. View results in Kibana:
echo    - Once pipeline completes, open Kibana
echo    - Go to Dashboards
echo    - View "llm-dashboard-main"
echo.
echo USEFUL COMMANDS:
echo.
echo   docker-compose ps              # Show all containers
echo   docker-compose logs -f airflow-scheduler  # View scheduler logs
echo   docker exec llm_tracker-airflow-scheduler-1 airflow dags list  # List DAGs
echo.
echo SECURITY REMINDER:
echo   - NEVER commit .env to version control
echo   - Change default passwords regularly
echo   - Restrict access to http://localhost:8080
echo.
pause
