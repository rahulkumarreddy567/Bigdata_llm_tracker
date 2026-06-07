#!/bin/bash

set -e

echo "================================"
echo "LLM Tracker - Setup Script"
echo "================================"
echo ""

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✓ Docker and Docker Compose found"
echo ""

# Navigate to project directory
cd "$(dirname "$0")/llm_tracker"

# Create .env if it doesn't exist
if [ ! -f ../.env ]; then
    echo "📝 Creating .env file from template..."
    cp ../.env.example ../.env
    echo "✓ .env created. Please review and update if needed."
    echo ""
fi

# Start services
echo "🚀 Starting services..."
docker-compose down -v 2>/dev/null || true
docker-compose build --no-cache
docker-compose up -d

# Wait for PostgreSQL
echo "⏳ Waiting for PostgreSQL to be healthy..."
until docker-compose exec -T postgres pg_isready -U airflow >/dev/null 2>&1; do
    sleep 2
done
echo "✓ PostgreSQL is ready"
echo ""

# Initialize Airflow database
echo "🗄️  Initializing Airflow database..."
docker-compose exec -T airflow-webserver airflow db init
docker-compose run --rm airflow-init 2>/dev/null || true
echo "✓ Airflow database initialized"
echo ""

# Wait for Elasticsearch
echo "⏳ Waiting for Elasticsearch..."
until docker-compose exec -T elasticsearch curl -s http://localhost:9200 >/dev/null 2>&1; do
    sleep 5
done
echo "✓ Elasticsearch is ready"
echo ""

# Create Elasticsearch index
echo "📊 Creating Elasticsearch index..."
docker-compose exec -T elasticsearch curl -X PUT http://localhost:9200/llm-value-scores \
  -H 'Content-Type: application/json' \
  -d '{
    "mappings": {
      "properties": {
        "ingestion_date": {"type": "date"},
        "model_id": {"type": "keyword"},
        "model_name": {"type": "keyword"},
        "provider": {"type": "keyword"},
        "performance_score": {"type": "float"},
        "avg_price_per_1m": {"type": "float"},
        "value_score": {"type": "float"}
      }
    }
  }' 2>/dev/null
echo "✓ Elasticsearch index created"
echo ""

# Final status
echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo ""
echo "📡 Services are running:"
echo "   - Airflow UI:     http://localhost:8080  (admin / admin)"
echo "   - Kibana:         http://localhost:5601"
echo "   - Elasticsearch:  http://localhost:9200"
echo ""
echo "📚 Next steps:"
echo "   1. Review configuration in ../.env"
echo "   2. Change default passwords (see AIRFLOW_CREDENTIALS.md)"
echo "   3. Create Kibana data views (see README.md)"
echo "   4. Trigger first DAG run in Airflow UI"
echo ""
echo "📖 Documentation: https://github.com/yourusername/llm-tracker/README.md"
echo ""
