#!/usr/bin/env bash
set -euo pipefail

export KIBANA_URL="${KIBANA_URL:-http://kibana.railway.internal:5601}"
export ELASTICSEARCH_URL="${ELASTICSEARCH_URL:-http://elasticsearch.railway.internal:9200}"

python /opt/airflow/setup_kibana_dashboard.py
