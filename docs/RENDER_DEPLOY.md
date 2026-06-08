# Render Deployment

This repo can deploy directly to Render from GitHub using the root `render.yaml` Blueprint.

## What gets created

- Render Postgres database
- private Elasticsearch service
- public Kibana web service
- public Airflow web service
- background Airflow scheduler

## Files

- `render.yaml`
- `llm_tracker/railway/Dockerfile.airflow`
- `llm_tracker/railway/Dockerfile.elasticsearch`
- `llm_tracker/railway/Dockerfile.kibana`
- `llm_tracker/railway/render-bootstrap-dashboard.sh`

## Deploy steps

1. Push this repo to GitHub.
2. In Render, choose **New +** -> **Blueprint**.
3. Connect the GitHub repo `rahulkumarreddy567/Bigdata_llm_tracker`.
4. Render will detect `render.yaml` at the repo root.
5. Review the resources and provide the prompted `AIRFLOW_ADMIN_EMAIL`.
6. Create the Blueprint.

## Notes

- The Airflow and Elasticsearch services use persistent disks.
- The Airflow web service runs an initial deploy hook that waits for Kibana and Elasticsearch, then creates the dashboard automatically.
- The scheduler stores pipeline output on its own disk at `/opt/airflow/data`.
- The web service and scheduler share the same Fernet key through a Render environment group defined in the Blueprint.
