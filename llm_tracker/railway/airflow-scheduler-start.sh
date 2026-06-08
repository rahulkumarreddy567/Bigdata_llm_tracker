#!/usr/bin/env bash
set -euo pipefail

source /opt/airflow/airflow-common.sh

airflow db migrate
exec airflow scheduler
