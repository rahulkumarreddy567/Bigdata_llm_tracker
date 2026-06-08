# Railway Deployment

This repository is now organized for a Railway multi-service deployment.

## Recommended Railway services

Create these services in one Railway project:

- `postgres`
- `elasticsearch`
- `kibana`
- `airflow-webserver`
- `airflow-scheduler`

## Repository paths

Use `llm_tracker` as the service root directory for all custom services.

Service config files:

- `/llm_tracker/railway/elasticsearch.railway.toml`
- `/llm_tracker/railway/kibana.railway.toml`
- `/llm_tracker/railway/airflow-webserver.railway.toml`
- `/llm_tracker/railway/airflow-scheduler.railway.toml`

## Dockerfiles

- `/llm_tracker/railway/Dockerfile.elasticsearch`
- `/llm_tracker/railway/Dockerfile.kibana`
- `/llm_tracker/railway/Dockerfile.airflow`

## Railway setup steps

1. Create a Railway project with five services.
2. For each custom service, set the root directory to `/llm_tracker`.
3. For each custom service, set the config-as-code path to the matching `*.railway.toml` file.
4. Add a Railway volume to `elasticsearch` mounted at `/usr/share/elasticsearch/data`.
5. Add a Railway volume to `airflow-scheduler` mounted at `/opt/airflow/data`.
6. Add a Railway volume to `airflow-webserver` mounted at `/opt/airflow/data` if you want shell access to the generated DuckDB/parquet data there too.

## Variables

Railway variables are available at build and runtime, and service-specific variables can be set in each service's Variables tab. Copy values from `llm_tracker/railway/.env.railway.example` as a starting point.

Required shared variables for Airflow:

- `AIRFLOW__CORE__FERNET_KEY`
- `AIRFLOW_ADMIN_USERNAME`
- `AIRFLOW_ADMIN_PASSWORD`
- `AIRFLOW_ADMIN_EMAIL`

Required database variables for Airflow:

- `DATABASE_URL`, or
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`

Recommended service names:

- `postgres`
- `elasticsearch`
- `kibana`
- `airflow-webserver`
- `airflow-scheduler`

With Railway private networking enabled, services can reach each other through internal DNS names like `kibana.railway.internal` and `elasticsearch.railway.internal`.

## Public exposure

Expose only:

- `airflow-webserver`
- `kibana`

Keep:

- `postgres`
- `elasticsearch`
- `airflow-scheduler`

private inside Railway.

## Dashboard bootstrap

After `elasticsearch`, `kibana`, and `airflow-webserver` are healthy, open a shell in the `airflow-webserver` service and run:

```bash
/opt/airflow/create-kibana-dashboard.sh
```

This creates the `llm-dashboard-main` dashboard against the internal Kibana and Elasticsearch services.

## Notes

- Railway builds from a Dockerfile automatically when one is present, and you can point each service at a custom Dockerfile path.
- Dockerfile-based services use the image `CMD` or `ENTRYPOINT` by default unless you override the start command.
- Volumes are attached per service, so persistent data should be mounted only where that service needs to read or write it.
