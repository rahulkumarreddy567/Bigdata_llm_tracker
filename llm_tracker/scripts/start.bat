@echo off
echo ============================================================
echo  LLM Cost vs Performance Tracker - Setup Script (Windows)
echo ============================================================
echo.

:: Ensure we are in the project root directory where docker-compose.yml resides
cd /d "%~dp0.."

echo [1/7] Checking Docker...
docker --version
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker not found. Please install Docker Desktop first.
    pause
    exit /b 1
)

echo.
echo [2/7] Phase 1: Starting database and search engine services (Postgres + Elasticsearch)...
docker-compose up -d postgres elasticsearch

echo.
echo [3/7] Waiting for Elasticsearch to become healthy (usually 30-45 seconds)...
powershell -Command "while ($true) { try { $r = Invoke-WebRequest -Uri 'http://localhost:9200' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { break } } catch {} Start-Sleep -Seconds 5 }"
echo Elasticsearch is healthy!

echo.
echo [4/7] Phase 2: Starting remaining services (Airflow + Kibana)...
docker-compose up -d kibana airflow-webserver airflow-scheduler

echo.
echo [5/7] Initializing Airflow database and admin user (pip install inside container may take 1-2 minutes)...
docker-compose run --rm airflow-init

echo.
echo [6/7] Waiting for Kibana to become healthy...
powershell -Command "while ($true) { try { $r = Invoke-WebRequest -Uri 'http://localhost:5601/api/status' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { break } } catch {} Start-Sleep -Seconds 5 }"
echo Kibana is healthy!

echo.
echo [7/7] Automatically creating Kibana dashboard with visualizations...
powershell -ExecutionPolicy Bypass -File "%~dp0create_dashboard.ps1"

echo.
echo ============================================================
echo  SETUP COMPLETE!
echo ============================================================
echo.
echo  Airflow UI:      http://localhost:8080  (admin / admin)
echo  Elasticsearch:   http://localhost:9200
echo  Kibana Dashboard: http://localhost:5601/app/dashboards#/view/llm-dashboard-main
echo.
echo  Next steps:
echo  1. Open Airflow (http://localhost:8080)
echo  2. Find DAG: llm_cost_performance_tracker
echo  3. Toggle the DAG ON and trigger it to run the pipeline
echo  4. Once finished, refresh the Kibana Dashboard to view results
echo.
pause
