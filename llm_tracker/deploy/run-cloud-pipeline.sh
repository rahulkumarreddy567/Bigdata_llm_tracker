#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$ROOT_DIR/deploy"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.cloud.yml"
ENV_FILE="$DEPLOY_DIR/.env.cloud"
DAG_ID="llm_cost_performance_tracker"
WAIT_SECONDS="${WAIT_SECONDS:-600}"
POLL_SECONDS="${POLL_SECONDS:-10}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

RUN_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="manual_cli__${RUN_STAMP}"

echo "Triggering DAG '${DAG_ID}'..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T airflow-webserver \
  airflow dags trigger "$DAG_ID" --run-id "$RUN_ID"

echo "Waiting for DAG run to finish..."
deadline=$(( $(date +%s) + WAIT_SECONDS ))

while true; do
  state="$(docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T airflow-webserver \
    python - <<PY
import json
import subprocess

run_id = "${RUN_ID}"
result = subprocess.run(
    ["airflow", "dags", "list-runs", "-d", "${DAG_ID}", "-o", "json"],
    capture_output=True,
    text=True,
    check=True,
)

payload = json.loads(result.stdout or "[]")
for item in payload:
    if item.get("run_id") == run_id:
        print(item.get("state", ""))
        break
PY
    | tr -d '\r' | tail -n 1 | xargs)"

  if [[ "$state" == "success" ]]; then
    echo "DAG run succeeded."
    break
  fi

  if [[ "$state" == "failed" ]]; then
    echo "DAG run failed."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=200 airflow-scheduler
    exit 1
  fi

  if (( $(date +%s) >= deadline )); then
    echo "Timed out waiting for DAG run. Last state: ${state:-unknown}"
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=200 airflow-scheduler
    exit 1
  fi

  echo "Current DAG state: ${state:-unknown}. Waiting ${POLL_SECONDS}s..."
  sleep "$POLL_SECONDS"
done

echo "Checking Elasticsearch index..."
curl -fsS "http://localhost:${ELASTICSEARCH_PORT:-9200}/llm_value_scores/_count"
echo

echo "Refreshing Kibana dashboard..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T airflow-webserver \
  env KIBANA_URL=http://kibana:5601 ELASTICSEARCH_URL=http://elasticsearch:9200 \
  python /opt/airflow/setup_kibana_dashboard.py
