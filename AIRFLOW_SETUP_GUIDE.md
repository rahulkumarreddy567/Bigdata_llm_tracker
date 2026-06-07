# Secure Airflow Setup Guide

## Overview

This guide explains how to set up and secure Airflow for the LLM Tracker project. The project uses Docker Compose to run all services including Airflow, PostgreSQL, Elasticsearch, and Kibana.

## Current Setup

**Default Credentials (from docker-compose.yml):**
- **Airflow Admin**
  - Username: `admin`
  - Password: `admin`
- **PostgreSQL (Airflow metadata DB)**
  - Username: `airflow`
  - Password: `airflow`
  - Database: `airflow`

## Security Best Practices

### 1. Change Default Passwords (RECOMMENDED)

Before deploying to production, change all default credentials:

**Option A: Update docker-compose.yml**

Edit `docker-compose.yml` and change:

```yaml
# PostgreSQL section
postgres:
  environment:
    POSTGRES_USER: airflow
    POSTGRES_PASSWORD: change_this_to_secure_password  # Change this
    POSTGRES_DB: airflow

# Airflow init section - update the create user command
airflow-init:
  command: bash -c "airflow db migrate && airflow users create --username admin --firstname Rahul --lastname Duggempudi --role Admin --email rahul@isep.fr --password change_this_to_secure_password"
```

**Option B: Use Environment Variables (Recommended)**

Create a `.env` file in the project root:

```bash
# .env file (NEVER commit this to git!)
POSTGRES_PASSWORD=your_secure_postgres_password
AIRFLOW_ADMIN_PASSWORD=your_secure_airflow_password
AIRFLOW_FERNET_KEY=ZmDfcTF7_60GrrY167zsiPd67pEvs0aGOv2oasOM1Pg=
```

Then update `docker-compose.yml` to reference these variables:

```yaml
postgres:
  environment:
    POSTGRES_USER: airflow
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-airflow}
    POSTGRES_DB: airflow

airflow-init:
  command: bash -c "airflow db migrate && airflow users create --username admin --firstname Rahul --lastname Duggempudi --role Admin --email rahul@isep.fr --password ${AIRFLOW_ADMIN_PASSWORD:-admin}"
```

### 2. Generate a New Fernet Key (Optional but Recommended)

The Fernet key encrypts sensitive configuration in Airflow. Generate a new one:

```bash
# In Python
from cryptography.fernet import Fernet
key = Fernet.generate_key().decode()
print(key)

# Or using Docker
docker run --rm python:3.11 python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Update the `AIRFLOW__CORE__FERNET_KEY` in docker-compose.yml with your generated key.

### 3. Setup Authentication Backends

The docker-compose.yml already enables basic auth and session-based auth:

```yaml
AIRFLOW__API__AUTH_BACKENDS: 'airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session'
```

This allows:
- Web UI login with username/password
- API calls with basic authentication

### 4. Create Additional Users (Optional)

After the initial setup, add more users via the Airflow CLI:

```bash
# Inside the Airflow container
docker exec llm_tracker-airflow-scheduler-1 airflow users create \
  --username dbt_user \
  --firstname DBT \
  --lastname Admin \
  --role Admin \
  --email dbt@isep.fr \
  --password secure_password
```

## Deployment Steps

### Step 1: Prepare Environment

```powershell
cd "d:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker"

# (Optional) Create .env file with secure passwords
# See Option B above
```

### Step 2: Start Services

```powershell
# Method 1: Use the provided startup script
.\scripts\start.bat

# Method 2: Manual Docker Compose commands
docker-compose up -d postgres elasticsearch
# Wait 30-45 seconds for Elasticsearch to be healthy
Start-Sleep -Seconds 45
docker-compose up -d kibana airflow-webserver airflow-scheduler
docker-compose run --rm airflow-init
.\scripts\create_dashboard.ps1
```

### Step 3: Access Airflow

1. Open browser: `http://localhost:8080`
2. Login with default credentials:
   - Username: `admin`
   - Password: `admin`
3. Change your password immediately via the UI (Admin → Security → Change Password)

### Step 4: Configure the DAG

1. In Airflow UI, go to **DAGs**
2. Find `llm_cost_performance_tracker`
3. Toggle the DAG to **ON**
4. Click the DAG to view details

### Step 5: Run the Pipeline

**Option A: Manual Trigger (UI)**
1. Click the **Trigger DAG** button
2. View the DAG run in real-time
3. Check logs for any issues

**Option B: CLI Trigger**
```powershell
docker exec llm_tracker-airflow-scheduler-1 airflow dags trigger llm_cost_performance_tracker
```

**Option C: Scheduled Run**
The DAG is scheduled to run daily at 08:00 UTC. It will run automatically.

## Monitoring

### Airflow Web UI
- **DAG Runs**: View execution history and status
- **Task Logs**: Debug individual task failures
- **Admin Panel**: Manage users, connections, and variables

### Elasticsearch/Kibana
After the pipeline completes:
1. Navigate to `http://localhost:5601`
2. View the imported dashboard: `llm-dashboard-main`
3. Analyze the indexed LLM value scores

## Verification

Verify all services are running:

```powershell
# Check container status
docker compose ps

# Check Airflow is responsive
Invoke-WebRequest -Uri http://localhost:8080/health -UseBasicParsing

# Check Elasticsearch is healthy
Invoke-WebRequest -Uri http://localhost:9200/_cluster/health -UseBasicParsing

# Check Kibana is ready
Invoke-WebRequest -Uri http://localhost:5601/api/status -UseBasicParsing
```

## Troubleshooting

### Airflow won't start
```powershell
# Check logs
docker logs llm_tracker-airflow-webserver-1

# Try reinitializing
docker-compose down
docker-compose up -d postgres
Start-Sleep -Seconds 45
docker-compose run --rm airflow-init
docker-compose up -d kibana airflow-webserver airflow-scheduler
```

### Port already in use
```powershell
# Find process using port 8080
netstat -ano | findstr :8080

# Kill process by PID
taskkill /PID <PID> /F

# Or use different ports in docker-compose.yml
```

### Database migration errors
```powershell
# Reset Airflow database (WARNING: deletes all DAG history)
docker exec llm_tracker-postgres-1 dropdb -U airflow airflow
docker exec llm_tracker-postgres-1 createdb -U airflow airflow
docker-compose run --rm airflow-init
```

## Production Recommendations

1. **Rotate Credentials Regularly**
   - Change Airflow admin password every 90 days
   - Rotate database passwords

2. **Enable SSL/TLS**
   - Use reverse proxy (nginx/traefik) in front of Airflow
   - Enable HTTPS for web UI

3. **Network Security**
   - Don't expose ports to the internet
   - Use VPN or private networks
   - Implement IP whitelisting

4. **Audit and Logging**
   - Enable Airflow audit logs
   - Ship logs to centralized logging system
   - Monitor for suspicious activities

5. **Backup Strategy**
   - Backup PostgreSQL database regularly
   - Backup Elasticsearch snapshots
   - Store backups securely

6. **Access Control**
   - Use RBAC (Role-Based Access Control)
   - Create separate users for different roles
   - Audit user access logs

## Additional Resources

- [Airflow Security Documentation](https://airflow.apache.org/docs/apache-airflow/stable/security-and-api/security/)
- [Airflow Authentication](https://airflow.apache.org/docs/apache-airflow/stable/security-and-api/api/#authentication)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/sql-syntax.html)
- [Elasticsearch Security](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-overview.html)
