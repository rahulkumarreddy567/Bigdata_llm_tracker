#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$ROOT_DIR/deploy"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.cloud.yml"
ENV_FILE="$DEPLOY_DIR/.env.cloud"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

echo "== Docker services =="
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
echo

echo "== Host connectivity =="
curl -fsS "http://localhost:${AIRFLOW_WEB_PORT:-8080}/health" >/tmp/airflow-health.json
curl -fsS "http://localhost:${KIBANA_WEB_PORT:-5601}/api/status" >/tmp/kibana-status.json
curl -fsS "http://localhost:${ELASTICSEARCH_PORT:-9200}/_cluster/health" >/tmp/es-health.json
python - <<'PY'
import json
from pathlib import Path

airflow = json.loads(Path("/tmp/airflow-health.json").read_text())
kibana = json.loads(Path("/tmp/kibana-status.json").read_text())
es = json.loads(Path("/tmp/es-health.json").read_text())

print(f"Airflow webserver: {airflow.get('metadatabase', {}).get('status', 'unknown')}")
print(f"Kibana overall: {kibana.get('status', {}).get('overall', {}).get('level', 'unknown')}")
print(f"Elasticsearch cluster: {es.get('status', 'unknown')}")
PY
echo

echo "== Airflow container connectivity =="
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T airflow-webserver python - <<'PY'
import json
import urllib.request

checks = {
    "elasticsearch": "http://elasticsearch:9200/_cluster/health",
    "kibana": "http://kibana:5601/api/status",
}

for name, url in checks.items():
    with urllib.request.urlopen(url, timeout=20) as response:
        data = json.loads(response.read().decode("utf-8"))
    if name == "elasticsearch":
        detail = data.get("status", "unknown")
    else:
        detail = data.get("status", {}).get("overall", {}).get("level", "unknown")
    print(f"{name}: {detail}")
PY
echo

echo "== Index status =="
if curl -fsS "http://localhost:${ELASTICSEARCH_PORT:-9200}/llm_value_scores/_count" >/tmp/index-count.json; then
  python - <<'PY'
import json
from pathlib import Path
count = json.loads(Path("/tmp/index-count.json").read_text())
print(f"llm_value_scores count: {count.get('count', 0)}")
PY
else
  echo "llm_value_scores index not created yet."
fi
