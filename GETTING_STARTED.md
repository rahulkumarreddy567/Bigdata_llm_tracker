# LLM Tracker Project - Complete Setup Guide

## Project Status

✅ **All critical errors fixed**
✅ **Security vulnerabilities patched**
✅ **Secure setup documentation created**
✅ **Ready to run**

## What Was Fixed

1. **Updated vulnerable packages** in requirements-airflow.txt
   - requests 2.32.4 (security fix for credential leak)
   - pyarrow 17.0.0 (security fix for unsafe deserialization)
   - duckdb 1.1.0 (security fix for filesystem vulnerability)

2. **Fixed resource leak** in fetch_lmsys.py
   - BytesIO now properly closed using context manager

3. **All Python files verified** to compile without errors

## Files Created for Secure Setup

### 📄 Documentation Files
- `AIRFLOW_SETUP_GUIDE.md` - Comprehensive security and setup guide
- `AIRFLOW_CREDENTIALS.md` - Quick reference for credentials and user management
- `FIXES_APPLIED.md` - Summary of all fixes applied
- `.env.example` - Template for environment variables

### 🔧 Configuration Files
- `docker-compose.secure.yml` - Docker Compose with environment variable support
- `setup-secure.bat` - Automated secure setup script

## Quick Start Guide

### Step 1: Navigate to Project Directory

```powershell
cd "d:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final"
```

### Step 2: Run Secure Setup

```powershell
.\setup-secure.bat
```

This script will:
1. Check Docker installation
2. Create `.env` file from template (if it doesn't exist)
3. Prompt you to set secure passwords
4. Start PostgreSQL and Elasticsearch
5. Wait for services to be healthy
6. Start Kibana, Airflow Webserver, and Scheduler
7. Initialize Airflow database and admin user
8. Create Kibana dashboard

### Step 3: Access Airflow

Once setup completes:
1. Open browser: **http://localhost:8080**
2. Login with credentials from `.env` file
3. Change your password immediately (Admin → Users → Edit admin → Change Password)

### Step 4: Enable and Run DAG

1. Go to **DAGs** section
2. Find **llm_cost_performance_tracker**
3. Toggle DAG to **ON** (blue switch)
4. Click on DAG name to view details
5. Click **Trigger DAG** button to start pipeline
6. Monitor execution in real-time

### Step 5: View Results

After pipeline completes (typically 5-10 minutes):
1. Open Kibana: **http://localhost:5601**
2. Go to **Dashboards**
3. Open **llm-dashboard-main**
4. View LLM value scores and rankings

## Default Credentials

**For Development/Testing Only:**
- Username: `admin`
- Password: `admin` (unless changed in `.env`)

**IMPORTANT:** For any environment beyond local testing:
1. Edit `.env` before running setup-secure.bat
2. Change all default passwords
3. Never commit `.env` to version control
4. Use secure password: 12+ characters with mixed case, numbers, symbols

## Directory Structure

```
llm_tracker_final/
├── llm_tracker/
│   ├── dags/                      # Airflow DAG definitions
│   │   └── llm_pipeline_dag.py
│   ├── ingestion/                 # Data ingestion scripts
│   │   ├── fetch_lmsys.py
│   │   └── fetch_openrouter.py
│   ├── indexing/                  # Elasticsearch indexing
│   │   └── index_to_elastic.py
│   ├── dbt_project/               # DBT transformation models
│   ├── data/                      # Local datalake
│   ├── docker-compose.yml         # Original compose file
│   ├── requirements-airflow.txt   # Python dependencies (UPDATED)
│   └── README.md
│
├── docker-compose.secure.yml      # ✨ NEW: Secure compose file
├── setup-secure.bat               # ✨ NEW: Automated setup script
├── .env.example                   # ✨ NEW: Credentials template
├── AIRFLOW_SETUP_GUIDE.md         # ✨ NEW: Comprehensive guide
├── AIRFLOW_CREDENTIALS.md         # ✨ NEW: Quick reference
└── FIXES_APPLIED.md               # ✨ NEW: Summary of fixes
```

## Pipeline Overview

The project implements a complete data pipeline:

```
┌─────────────────────────────────────────────────────────────┐
│                  INGESTION LAYER                            │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │  OpenRouter API  │  │  LMSYS Leaderboard               │
│  │   (Pricing)      │  │   (Quality Scores)               │
│  └────────┬─────────┘  └────────┬─────────┘                │
│           │                     │                           │
└───────────┼─────────────────────┼───────────────────────────┘
            │                     │
            ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   RAW LAYER (JSON)                          │
│  data/raw/openrouter/YYYY-MM-DD/models.json                │
│  data/raw/lmsys/YYYY-MM-DD/rankings.json                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│            DBT FORMATTING MODELS (SQL)                      │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ openrouter_fmt   │  │ lmsys_formatted  │                │
│  │   (normalize)    │  │   (normalize)    │                │
│  └────────┬─────────┘  └────────┬─────────┘                │
│           └─────────────┬───────┘                           │
│                         │                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   FORMATTED LAYER                           │
│  data/formatted/openrouter/YYYY-MM-DD/data.parquet         │
│  data/formatted/lmsys/YYYY-MM-DD/data.parquet              │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│          DBT COMBINATION MODEL (SQL)                        │
│  ┌──────────────────────────────────────┐                  │
│  │     llm_value_scores                 │                  │
│  │  ├─ Join on model names              │                  │
│  │  ├─ Normalize pricing (USD/EUR)      │                  │
│  │  ├─ Normalize quality scores         │                  │
│  │  ├─ Compute value_score              │                  │
│  │  ├─ Rank models by value            │                  │
│  │  └─ Create tiers and flags           │                  │
│  └──────────────┬───────────────────────┘                  │
│                 │                                          │
└─────────────────┼──────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                   COMBINED LAYER                            │
│  data/combined/YYYY-MM-DD/llm_value_scores.parquet         │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│            ELASTICSEARCH INDEXING                           │
│  Index: llm_value_scores                                   │
│  ├─ model_id, model_name, provider                         │
│  ├─ pricing fields (USD/EUR per 1M tokens)                 │
│  ├─ quality scores (elo, mt_bench, mmlu)                   │
│  ├─ value_score (quality per euro)                         │
│  ├─ rankings and tiers                                     │
│  └─ ingestion_date (partition key)                         │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                 KIBANA DASHBOARD                            │
│  http://localhost:5601/app/dashboards                      │
│  ├─ Value rankings                                         │
│  ├─ Price vs Quality scatter plot                          │
│  ├─ Provider breakdown                                     │
│  ├─ Historical trends                                      │
│  └─ Top 10 value models                                    │
└─────────────────────────────────────────────────────────────┘
```

## Airflow DAG Tasks

The `llm_cost_performance_tracker` DAG runs daily at 08:00 UTC and includes:

1. **ingest_openrouter** - Fetch pricing data from OpenRouter API
2. **ingest_lmsys** - Fetch quality scores from LMSYS Chatbot Arena
3. **dbt_format_and_combine** - Run DBT models to normalize and join data
4. **dbt_test** - Run DBT tests for data quality validation
5. **export_parquet_to_datalake** - Export results to Parquet files
6. **index_to_elasticsearch** - Index results in Elasticsearch

## Key Features

- ✅ Two real-world data sources (pricing + quality)
- ✅ Daily automated pipeline orchestration
- ✅ SQL-based data transformation with DBT
- ✅ Full-stack data lake with raw/formatted/combined layers
- ✅ Data validation with DBT tests
- ✅ Search indexing with Elasticsearch
- ✅ Real-time dashboarding with Kibana
- ✅ Docker-based one-command deployment
- ✅ Secure credential management
- ✅ Comprehensive error handling

## Troubleshooting

### Port Already in Use
```powershell
netstat -ano | findstr :8080  # Find process
taskkill /PID <PID> /F        # Kill process
```

### Services Won't Start
```powershell
docker-compose logs           # View logs
docker-compose down -v        # Reset (deletes data!)
docker-compose up -d postgres # Restart
```

### Forgot Password
```powershell
docker exec llm_tracker-airflow-scheduler-1 airflow users update \
  --username admin \
  --password new_password
```

### Can't Connect to Elasticsearch
```powershell
docker-compose logs elasticsearch
docker-compose restart elasticsearch
```

## Security Best Practices

1. **Always use strong passwords** (12+ chars, mixed case, numbers, symbols)
2. **Change defaults before production** - Edit `.env` file
3. **Don't commit `.env` to git** - Add to `.gitignore`
4. **Use environment variables** for all sensitive data
5. **Enable HTTPS** with reverse proxy for production
6. **Regular backups** of PostgreSQL and Elasticsearch data
7. **Monitor logs** for suspicious activity
8. **Rotate credentials** regularly

## Next Steps

1. ✅ Run `setup-secure.bat`
2. ✅ Change admin password in Airflow UI
3. ✅ Enable the DAG in Airflow
4. ✅ Trigger manual run to test
5. ✅ Monitor Kibana dashboard for results
6. ✅ Schedule automated daily runs

## Support & Documentation

- **Airflow Docs**: https://airflow.apache.org/docs/
- **DBT Docs**: https://docs.getdbt.com/
- **Elasticsearch Docs**: https://www.elastic.co/guide/
- **Kibana Docs**: https://www.elastic.co/guide/en/kibana/

## Summary

Your LLM Tracker project is now **fully configured, secured, and ready to run**. Use the automated setup script to get started in seconds!

```powershell
cd "d:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final"
.\setup-secure.bat
```

Happy data tracking! 🚀
