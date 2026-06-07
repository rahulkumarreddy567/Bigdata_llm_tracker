#!/bin/bash

sleep 10

# Create index with mapping
curl -X PUT http://localhost:9200/llm-models-2024 \
  -H 'Content-Type: application/json' \
  -d '{
    "mappings": {
      "properties": {
        "timestamp": {"type": "date"},
        "model_name": {"type": "keyword"},
        "provider": {"type": "keyword"},
        "cost": {"type": "float"},
        "performance_score": {"type": "float"},
        "request_count": {"type": "integer"}
      }
    }
  }'

echo ""
echo "Index created successfully"

# Add sample data
curl -X POST http://localhost:9200/llm-models-2024/_doc \
  -H 'Content-Type: application/json' \
  -d '{
    "timestamp": "2024-06-07T10:00:00Z",
    "model_name": "GPT-4",
    "provider": "OpenAI",
    "cost": 0.03,
    "performance_score": 95.5,
    "request_count": 1500
  }'

curl -X POST http://localhost:9200/llm-models-2024/_doc \
  -H 'Content-Type: application/json' \
  -d '{
    "timestamp": "2024-06-07T11:00:00Z",
    "model_name": "Claude-3",
    "provider": "Anthropic",
    "cost": 0.015,
    "performance_score": 92.3,
    "request_count": 1200
  }'

curl -X POST http://localhost:9200/llm-models-2024/_doc \
  -H 'Content-Type: application/json' \
  -d '{
    "timestamp": "2024-06-07T12:00:00Z",
    "model_name": "Llama-2",
    "provider": "Meta",
    "cost": 0.008,
    "performance_score": 88.1,
    "request_count": 2000
  }'

echo ""
echo "Sample data added successfully"

# List all indices
curl -s http://localhost:9200/_cat/indices?v

echo ""
echo "Data view setup complete!"
