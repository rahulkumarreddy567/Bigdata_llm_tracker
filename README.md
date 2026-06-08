# LLM Tracker

This repository ingests LLM pricing and ranking data, transforms it with dbt, indexes the result into Elasticsearch, and creates a working Kibana dashboard automatically.

## Quick start

```bash
cd llm_tracker
docker-compose up -d
python setup_kibana_dashboard.py
```

The dashboard setup script now:

- verifies Kibana and Elasticsearch connectivity
- ensures the `llm_value_scores` data view exists
- creates the `llm-dashboard-main` dashboard with 8 Lens panels
- removes legacy empty dashboards that caused the `searchSourceJSON` error

Main services:

- Kibana: `http://localhost:5601`
- Elasticsearch: `http://localhost:9200`
- Airflow: `http://localhost:8080`

Use [llm_tracker/README.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/llm_tracker/README.md) for the full project guide.
