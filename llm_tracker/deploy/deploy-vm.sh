#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$ROOT_DIR/deploy"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.cloud.yml"
ENV_FILE="$DEPLOY_DIR/.env.cloud"
CHECK_SCRIPT="$DEPLOY_DIR/check-cloud-stack.sh"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Copy $DEPLOY_DIR/.env.cloud.example to $ENV_FILE and fill in real values first."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --build postgres elasticsearch

echo "Waiting for Elasticsearch..."
until curl -fsS http://localhost:${ELASTICSEARCH_PORT:-9200}/_cluster/health >/dev/null 2>&1; do
  sleep 5
done

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm airflow-init
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d airflow-webserver airflow-scheduler kibana

echo "Waiting for Kibana..."
until curl -fsS http://localhost:${KIBANA_WEB_PORT:-5601}/api/status >/dev/null 2>&1; do
  sleep 5
done

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T airflow-webserver \
  env KIBANA_URL=http://kibana:5601 ELASTICSEARCH_URL=http://elasticsearch:9200 \
  python /opt/airflow/setup_kibana_dashboard.py

bash "$CHECK_SCRIPT"

echo
echo "Cloud stack is up."
echo "Airflow: http://localhost:${AIRFLOW_WEB_PORT:-8080}"
echo "Kibana:  http://localhost:${KIBANA_WEB_PORT:-5601}"
echo "Check:   bash $CHECK_SCRIPT"
echo "Run DAG: bash $DEPLOY_DIR/run-cloud-pipeline.sh"
