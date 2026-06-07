#!/bin/bash

set -e

echo "================================"
echo "LLM Tracker - Verification Script"
echo "================================"
echo ""

cd "$(dirname "$0")/llm_tracker"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0
fail_count=0

# Helper functions
run_test() {
    local test_name=$1
    local command=$2
    
    test_count=$((test_count + 1))
    echo -n "[$test_count] $test_name... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        pass_count=$((pass_count + 1))
    else
        echo -e "${RED}✗${NC}"
        fail_count=$((fail_count + 1))
    fi
}

echo "🔍 Running verification tests..."
echo ""

# 1. Docker Compose Tests
echo "=== Docker Services ==="
run_test "Airflow Webserver running" "docker-compose ps airflow-webserver | grep -q 'Up'"
run_test "Airflow Scheduler running" "docker-compose ps airflow-scheduler | grep -q 'Up'"
run_test "PostgreSQL running" "docker-compose ps postgres | grep -q 'healthy'"
run_test "Elasticsearch running" "docker-compose ps elasticsearch | grep -q 'healthy'"
run_test "Kibana running" "docker-compose ps kibana | grep -q 'healthy'"
echo ""

# 2. Database Tests
echo "=== Database Connectivity ==="
run_test "PostgreSQL connection" "docker-compose exec -T postgres pg_isready -U airflow"
run_test "DuckDB file exists" "[ -f data/llm_tracker.duckdb ]"
echo ""

# 3. Python Code Tests
echo "=== Python Code ==="
run_test "DAG syntax" "docker-compose exec -T airflow-webserver python -m py_compile dags/llm_pipeline_dag.py"
run_test "Ingestion scripts" "docker-compose exec -T airflow-webserver python -m py_compile ingestion/fetch_openrouter.py ingestion/fetch_lmsys.py"
run_test "Indexing script" "docker-compose exec -T airflow-webserver python -m py_compile indexing/index_to_elastic.py"
echo ""

# 4. API Tests
echo "=== API Endpoints ==="
run_test "Airflow health" "curl -s http://localhost:8080/health | grep -q 'OK'"
run_test "Elasticsearch status" "curl -s http://localhost:9200/_cluster/health | grep -q '\"status\"'"
run_test "Kibana status" "curl -s http://localhost:5601/api/status | grep -q '\"state\"'"
echo ""

# 5. Configuration Tests
echo "=== Configuration ==="
run_test "docker-compose.yml exists" "[ -f docker-compose.yml ]"
run_test "Dockerfile exists" "[ -f Dockerfile.airflow ]"
run_test "requirements file exists" "[ -f requirements-airflow.txt ]"
run_test "dbt_project.yml exists" "[ -f dbt_project/dbt_project.yml ]"
echo ""

# 6. DAG Tests
echo "=== Airflow DAGs ==="
run_test "DAG list command" "docker-compose exec -T airflow-webserver airflow dags list | grep -q 'llm_cost_performance_tracker'"
run_test "DAG validate" "docker-compose exec -T airflow-webserver airflow dags validate"
echo ""

# 7. DBT Tests
echo "=== DBT Configuration ==="
run_test "DBT debug" "docker-compose exec -T airflow-webserver bash -c 'cd dbt_project && /home/airflow/.local/bin/dbt debug'"
echo ""

# 8. File Structure Tests
echo "=== Project Structure ==="
run_test "dags directory exists" "[ -d dags ]"
run_test "ingestion directory exists" "[ -d ingestion ]"
run_test "indexing directory exists" "[ -d indexing ]"
run_test "dbt_project directory exists" "[ -d dbt_project ]"
run_test "data directory exists" "[ -d data ]"
echo ""

# Summary
echo "================================"
echo "Test Results"
echo "================================"
echo "Total Tests:  $test_count"
echo -e "Passed:       ${GREEN}$pass_count${NC}"
echo -e "Failed:       ${RED}$fail_count${NC}"
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "📊 Next steps:"
    echo "   1. Create Kibana data views:"
    echo "      - Go to http://localhost:5601/app/management/kibana/dataViews"
    echo "      - Create data view with pattern: llm-value-scores*"
    echo "      - Set time field to: ingestion_date"
    echo ""
    echo "   2. Trigger first DAG run:"
    echo "      - Go to http://localhost:8080"
    echo "      - Select DAG: llm_cost_performance_tracker"
    echo "      - Click Trigger DAG"
    echo ""
    echo "   3. Monitor execution:"
    echo "      - Watch task execution in Airflow UI"
    echo "      - Check logs for any errors"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo ""
    echo "💡 Troubleshooting:"
    echo "   - Check Docker containers: docker-compose ps"
    echo "   - View service logs: docker-compose logs [service]"
    echo "   - Restart services: docker-compose restart"
    echo "   - Re-run setup: ./setup.sh"
    exit 1
fi
