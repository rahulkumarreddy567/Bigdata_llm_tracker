#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${KIBANA_URL:-}" && -n "${KIBANA_HOST:-}" ]]; then
  export KIBANA_URL="http://${KIBANA_HOST}:${KIBANA_PORT:-10000}"
fi

if [[ -z "${ELASTICSEARCH_URL:-}" && -n "${ELASTICSEARCH_HOST:-}" ]]; then
  export ELASTICSEARCH_URL="http://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT:-9200}"
fi

for _ in $(seq 1 60); do
  if curl -fsS "${KIBANA_URL}/api/status" >/dev/null 2>&1 && \
     curl -fsS "${ELASTICSEARCH_URL}/_cluster/health" >/dev/null 2>&1; then
    exec python /opt/airflow/setup_kibana_dashboard.py
  fi
  sleep 10
done

echo "Kibana or Elasticsearch did not become ready in time."
exit 1
