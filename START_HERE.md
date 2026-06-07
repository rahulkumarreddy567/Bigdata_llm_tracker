# 🚀 START HERE - LLM Tracker Setup

Welcome! Your LLM Tracker project is **fully fixed and ready to run**. Follow these simple steps.

---

## ⚡ Quick Start (5 minutes)

### Step 1: Open PowerShell

```powershell
# Navigate to project folder
cd "d:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final"
```

### Step 2: Run Automatic Setup

```powershell
.\setup-secure.bat
```

**What this does:**
- ✓ Creates `.env` file with password template
- ✓ Starts all Docker services
- ✓ Initializes Airflow database
- ✓ Creates Kibana dashboard
- ⏱️ Takes ~5 minutes

### Step 3: Login to Airflow

```
URL: http://localhost:8080
Username: admin
Password: admin
```

**IMPORTANT:** Change your password immediately!
- Click **Admin** (top right)
- Select **Users**
- Find **admin** user, click **Edit**
- Change password
- Click **Save**

### Step 4: Enable & Run Pipeline

1. Go to **DAGs** section
2. Find **llm_cost_performance_tracker**
3. Click the toggle to turn DAG **ON** (blue switch)
4. Click on the DAG name
5. Click **Trigger DAG** button
6. Monitor execution in real-time

### Step 5: View Results

Once pipeline completes (~5-10 minutes):

```
URL: http://localhost:5601/app/dashboards
Dashboard: llm-dashboard-main
```

---

## 📚 Documentation

**New to Airflow?** Read these in order:

1. **SETUP_SUMMARY.txt** ← Read this for overview (2 min)
2. **GETTING_STARTED.md** ← Read for detailed guide (10 min)
3. **AIRFLOW_CREDENTIALS.md** ← Keep handy as reference

**Already familiar?**
- **AIRFLOW_SETUP_GUIDE.md** - Security best practices
- **FIXES_APPLIED.md** - Technical fixes summary

**Complete resource index:**
- **README_RESOURCES.md** - All files explained

---

## 🔓 Securing Your Setup

### Before Production

Edit `.env` file with strong passwords:

```powershell
notepad .env
```

Change these values:
```
POSTGRES_PASSWORD=your_secure_password_here
AIRFLOW_ADMIN_PASSWORD=your_secure_password_here
```

**Password requirements:**
- 12+ characters
- Mix of uppercase, lowercase, numbers, symbols
- Don't use common words

### Never Commit `.env` to Git!

```powershell
# Add to .gitignore
echo .env >> .gitignore
```

---

## ⚠️ Default Credentials (Development Only)

```
Airflow Web UI
  Username: admin
  Password: admin

PostgreSQL Database
  Username: airflow
  Password: airflow
```

**These are for testing only. Change before production!**

---

## 🛠️ Useful Commands

### View all services
```powershell
docker-compose ps
```

### View logs
```powershell
docker-compose logs -f
```

### Stop everything
```powershell
docker-compose down
```

### Reset admin password (if you forget it)
```powershell
docker exec llm_tracker-airflow-scheduler-1 airflow users update \
  --username admin --password admin
```

See **AIRFLOW_CREDENTIALS.md** for more commands.

---

## ❓ Troubleshooting

### Port 8080 already in use

```powershell
# Find what's using it
netstat -ano | findstr :8080

# Stop the process (replace PID)
taskkill /PID 1234 /F
```

### Services won't start

```powershell
# Check logs
docker-compose logs

# Clean up and restart
docker-compose down -v
docker-compose up -d postgres
# Wait 45 seconds
docker-compose up -d kibana airflow-webserver airflow-scheduler
docker-compose run --rm airflow-init
```

### Can't access Airflow

- Wait 1-2 minutes for startup
- Check: http://localhost:8080/health
- View logs: `docker-compose logs airflow-webserver`

### Forgot password

See **AIRFLOW_CREDENTIALS.md** → "Can't login to Airflow"

---

## 📊 What You Get

After setup completes:

```
✓ Airflow (DAG orchestration)      → http://localhost:8080
✓ Elasticsearch (data indexing)    → http://localhost:9200
✓ Kibana (dashboards)              → http://localhost:5601
✓ PostgreSQL (metadata database)   → localhost:5432
✓ DuckDB (local datalake)          → data/llm_tracker.duckdb
```

Daily pipeline:
```
1. Fetch pricing data from OpenRouter
2. Fetch quality rankings from LMSYS
3. Normalize data with DBT
4. Combine into value scores
5. Index in Elasticsearch
6. Display in Kibana dashboard
```

---

## 🎯 Next Steps

1. ✅ Run `.\setup-secure.bat`
2. ✅ Change admin password in Airflow UI
3. ✅ Enable the DAG in Airflow
4. ✅ Trigger pipeline manually
5. ✅ Monitor Kibana dashboard
6. ✅ Schedule daily runs (automatic)

---

## 📖 Full Documentation Index

| File | Purpose | Read Time |
|------|---------|-----------|
| **START_HERE.md** | This file - quick overview | 3 min |
| **SETUP_SUMMARY.txt** | 1-page cheat sheet | 2 min |
| **GETTING_STARTED.md** | Complete walkthrough | 10 min |
| **AIRFLOW_SETUP_GUIDE.md** | Security & advanced setup | 15 min |
| **AIRFLOW_CREDENTIALS.md** | Reference for all tasks | As needed |
| **README_RESOURCES.md** | Index of all resources | 5 min |
| **FIXES_APPLIED.md** | Technical fixes summary | 5 min |

---

## 💡 Pro Tips

- **Bookmark these URLs:**
  - Airflow: http://localhost:8080
  - Kibana: http://localhost:5601

- **Use Airflow UI for monitoring:**
  - View DAG runs
  - Check task logs
  - Monitor pipeline health

- **Use Kibana for analysis:**
  - View value rankings
  - Compare models
  - Analyze pricing trends

- **Schedule automated runs:**
  - Default: Daily at 08:00 UTC
  - Can be modified in DAG settings

---

## 🚨 Important Security Notes

1. **Change default passwords** before using in any shared/production environment
2. **Never commit `.env`** file to version control
3. **Use strong passwords** (12+ characters, mixed case, numbers, symbols)
4. **Restrict access** to http://localhost:8080
5. **Regular backups** of data and configurations

---

## 📞 Need Help?

### For setup issues:
→ See **SETUP_SUMMARY.txt** - TROUBLESHOOTING section

### For credential/user management:
→ See **AIRFLOW_CREDENTIALS.md** (entire document is reference)

### For security questions:
→ See **AIRFLOW_SETUP_GUIDE.md** - Security Best Practices

### For production deployment:
→ See **AIRFLOW_SETUP_GUIDE.md** - Production Recommendations

---

## ✨ You're All Set!

Everything is configured and ready. Just run:

```powershell
.\setup-secure.bat
```

Then open: **http://localhost:8080**

**Happy tracking!** 🎉

---

**Next:** Read `SETUP_SUMMARY.txt` for a detailed overview
