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

Cloud deployment notes are in [docs/CLOUD_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/CLOUD_DEPLOY.md).
AWS EC2 deployment notes are in [docs/AWS_EC2_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/AWS_EC2_DEPLOY.md).
Railway deployment notes are in [docs/RAILWAY_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/RAILWAY_DEPLOY.md).
Railway Docker image deployment notes are in [docs/RAILWAY_DOCKER_IMAGE_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/RAILWAY_DOCKER_IMAGE_DEPLOY.md).
Render deployment notes are in [docs/RENDER_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/RENDER_DEPLOY.md).
Oracle Cloud Always Free deployment notes are in [docs/ORACLE_FREE_TIER_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/ORACLE_FREE_TIER_DEPLOY.md).
