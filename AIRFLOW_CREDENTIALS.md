# Airflow Credentials & Security Quick Reference

## Default Access Points

| Service | URL | Default User | Default Password |
|---------|-----|--------------|------------------|
| Airflow Web UI | http://localhost:8080 | admin | admin |
| Elasticsearch | http://localhost:9200 | - | - |
| Kibana | http://localhost:5601 | - | - |
| PostgreSQL | localhost:5432 | airflow | airflow |

**⚠️ IMPORTANT:** Change all default passwords before running in any environment other than local development!

## Quick Setup

### Option 1: Automatic (Recommended)
```powershell
cd "d:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final"
.\setup-secure.bat
```

This will:
- Create `.env` file from template
- Prompt you to set secure passwords
- Start all services
- Initialize Airflow
- Create Kibana dashboard

### Option 2: Manual

```powershell
# 1. Create .env from template
copy .env.example .env

# 2. Edit .env and set secure passwords (use Notepad)
notepad .env

# 3. Start services
docker-compose up -d postgres elasticsearch
Start-Sleep -Seconds 45
docker-compose up -d kibana airflow-webserver airflow-scheduler

# 4. Initialize Airflow
docker-compose run --rm airflow-init

# 5. Create dashboard
.\scripts\create_dashboard.ps1

# 6. Access Airflow
Start-Process "http://localhost:8080"
```

## Changing Passwords

### Change Airflow Admin Password (Web UI)

1. Login to http://localhost:8080
2. Click **Admin** (top right) → **Users**
3. Find **admin** user
4. Click **Edit**
5. Change password
6. Click **Save**

### Change Airflow Admin Password (CLI)

```powershell
docker exec llm_tracker-airflow-scheduler-1 airflow users update \
  --username admin \
  --password new_secure_password
```

### Change PostgreSQL Password

⚠️ This requires recreating containers!

```powershell
# 1. Stop all services
docker-compose down

# 2. Remove PostgreSQL volume
docker volume rm llm_tracker_postgres-db

# 3. Update .env with new password
notepad .env

# 4. Restart
docker-compose up -d postgres elasticsearch
Start-Sleep -Seconds 45
docker-compose up -d kibana airflow-webserver airflow-scheduler
docker-compose run --rm airflow-init
```

## User Management

### Create New User

```powershell
docker exec llm_tracker-airflow-scheduler-1 airflow users create \
  --username newuser \
  --firstname FirstName \
  --lastname LastName \
  --role Viewer \
  --email user@example.com \
  --password temporary_password
```

**User Roles:**
- `Admin`: Full access, can modify DAGs
- `Op`: Can trigger DAGs, view logs
- `Viewer`: Read-only access
- `User`: Basic access

### List All Users

```powershell
docker exec llm_tracker-airflow-scheduler-1 airflow users list
```

### Delete User

```powershell
docker exec llm_tracker-airflow-scheduler-1 airflow users delete --username username
```

## Security Checklist

- [ ] Changed PostgreSQL password in .env
- [ ] Changed Airflow admin password in Web UI
- [ ] Added `.env` to `.gitignore`
- [ ] Generated new Fernet key (optional)
- [ ] Disabled config exposure: `AIRFLOW__WEBSERVER__EXPOSE_CONFIG=false`
- [ ] Created audit users for different teams
- [ ] Documented password storage location
- [ ] Tested password recovery procedure

## Service Management

### View All Running Containers

```powershell
docker-compose ps
```

### View Logs

```powershell
# Airflow webserver logs
docker-compose logs -f airflow-webserver

# Airflow scheduler logs
docker-compose logs -f airflow-scheduler

# PostgreSQL logs
docker-compose logs -f postgres

# All logs
docker-compose logs -f
```

### Stop All Services

```powershell
docker-compose down
```

### Restart Services

```powershell
docker-compose restart
```

### Remove Everything (⚠️ Deletes all data!)

```powershell
docker-compose down -v
```

## Troubleshooting

### Airflow won't start

```powershell
# Check logs
docker-compose logs airflow-webserver

# Reinitialize database
docker-compose down
docker volume rm llm_tracker_postgres-db
docker-compose up -d postgres
Start-Sleep -Seconds 45
docker-compose up -d airflow-webserver airflow-scheduler
docker-compose run --rm airflow-init
```

### Can't login to Airflow

```powershell
# Reset admin password
docker exec llm_tracker-airflow-scheduler-1 airflow users update \
  --username admin \
  --password admin
```

### Port already in use

```powershell
# Find process using port 8080
netstat -ano | findstr :8080

# Kill process (replace PID)
taskkill /PID 1234 /F

# Or use different port in docker-compose.yml
# Change "8080:8080" to "8081:8080"
```

### PostgreSQL won't connect

```powershell
# Check PostgreSQL is running
docker-compose logs postgres

# Verify credentials in .env
type .env | findstr POSTGRES

# Recreate container
docker-compose down
docker volume rm llm_tracker_postgres-db
docker-compose up -d postgres
```

## Environment Variables Reference

**File: `.env`**

```bash
# Required
POSTGRES_USER=airflow
POSTGRES_PASSWORD=secure_password
AIRFLOW_ADMIN_PASSWORD=secure_password

# Optional (have defaults)
AIRFLOW__CORE__FERNET_KEY=
POSTGRES_DB=airflow
AIRFLOW_ADMIN_USERNAME=admin
ELASTICSEARCH_HOST=http://elasticsearch:9200
```

## Production Recommendations

1. **Use strong passwords**: Mix uppercase, lowercase, numbers, symbols (12+ chars)
2. **Enable SSL/TLS**: Use reverse proxy (nginx) with HTTPS
3. **Restrict access**: Firewall rules, VPN, IP whitelisting
4. **Regular backups**: PostgreSQL database and Elasticsearch snapshots
5. **Audit logging**: Enable and monitor audit logs
6. **Secrets management**: Use AWS Secrets Manager, HashiCorp Vault
7. **Multi-factor authentication**: Implement if possible
8. **Update regularly**: Keep Docker images and Python packages current

## Useful Docker Commands

```powershell
# Execute command in container
docker exec <container_name> <command>

# Access PostgreSQL
docker exec llm_tracker-postgres-1 psql -U airflow airflow

# Access Airflow CLI
docker exec llm_tracker-airflow-scheduler-1 airflow <command>

# Build image
docker-compose build

# Pull latest images
docker-compose pull
```

## Additional Resources

- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Airflow Security](https://airflow.apache.org/docs/apache-airflow/stable/security-and-api/security/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
