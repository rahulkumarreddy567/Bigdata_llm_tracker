#!/usr/bin/env bash
set -euo pipefail

export ELASTICSEARCH_HOSTS="${ELASTICSEARCH_HOSTS:-http://elasticsearch.railway.internal:9200}"
exec /usr/local/bin/kibana-docker
