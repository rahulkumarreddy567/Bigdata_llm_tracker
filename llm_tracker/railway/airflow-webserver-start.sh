#!/usr/bin/env bash
set -euo pipefail

source /opt/airflow/airflow-common.sh

airflow db migrate

if [[ -n "${AIRFLOW_ADMIN_USERNAME:-}" && -n "${AIRFLOW_ADMIN_PASSWORD:-}" ]]; then
  airflow users create \
    --username "${AIRFLOW_ADMIN_USERNAME}" \
    --firstname "${AIRFLOW_ADMIN_FIRSTNAME:-Admin}" \
    --lastname "${AIRFLOW_ADMIN_LASTNAME:-User}" \
    --role Admin \
    --email "${AIRFLOW_ADMIN_EMAIL:-admin@example.com}" \
    --password "${AIRFLOW_ADMIN_PASSWORD}" || true
fi

exec airflow webserver --port "${PORT:-8080}"
