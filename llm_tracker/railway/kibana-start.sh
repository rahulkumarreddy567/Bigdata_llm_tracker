#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ELASTICSEARCH_HOSTS:-}" ]]; then
  export ELASTICSEARCH_HOSTS="http://${ELASTICSEARCH_HOST:-elasticsearch.railway.internal}:${ELASTICSEARCH_PORT:-9200}"
fi

export SERVER_PORT="${PORT:-${SERVER_PORT:-5601}}"
export SERVER_HOST="${SERVER_HOST:-0.0.0.0}"
exec /usr/local/bin/kibana-docker
