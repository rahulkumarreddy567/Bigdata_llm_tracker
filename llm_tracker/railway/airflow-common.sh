#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${DATABASE_URL:-}" ]]; then
  export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="${DATABASE_URL/postgres:\/\//postgresql+psycopg2://}"
elif [[ -n "${PGHOST:-}" && -n "${PGUSER:-}" && -n "${PGPASSWORD:-}" && -n "${PGDATABASE:-}" ]]; then
  export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="postgresql+psycopg2://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT:-5432}/${PGDATABASE}"
elif [[ -n "${POSTGRES_HOST:-}" && -n "${POSTGRES_USER:-}" && -n "${POSTGRES_PASSWORD:-}" && -n "${POSTGRES_DB:-}" ]]; then
  export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT:-5432}/${POSTGRES_DB}"
fi

export AIRFLOW__CORE__EXECUTOR="${AIRFLOW__CORE__EXECUTOR:-LocalExecutor}"
export AIRFLOW__CORE__LOAD_EXAMPLES="${AIRFLOW__CORE__LOAD_EXAMPLES:-false}"
export AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION="${AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION:-false}"
export AIRFLOW__WEBSERVER__EXPOSE_CONFIG="${AIRFLOW__WEBSERVER__EXPOSE_CONFIG:-false}"
export AIRFLOW__API__AUTH_BACKENDS="${AIRFLOW__API__AUTH_BACKENDS:-airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session}"

if [[ -z "${AIRFLOW__CORE__FERNET_KEY:-}" ]]; then
  echo "AIRFLOW__CORE__FERNET_KEY is required."
  exit 1
fi

mkdir -p /opt/airflow/data /opt/airflow/logs /opt/airflow/plugins
