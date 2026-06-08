# LLM Cost vs Performance Tracker

This project ingests LLM pricing and ranking data, transforms it with dbt, indexes the final `llm_value_scores` dataset into Elasticsearch, and publishes a Kibana dashboard automatically.

## Quick start

```bash
docker-compose up -d
python setup_kibana_dashboard.py
```

Services:

- Kibana: `http://localhost:5601`
- Elasticsearch: `http://localhost:9200`
- Airflow: `http://localhost:8080`
- PostgreSQL: `localhost:5432`

## What the dashboard script does

`setup_kibana_dashboard.py` is the supported setup path for Kibana. It:

- checks Elasticsearch and Kibana connectivity
- verifies the `llm_value_scores` index is reachable
- creates or updates the fixed data view `llm-data-view`
- creates or updates the fixed dashboard `llm-dashboard-main`
- removes legacy empty dashboards that triggered the `searchSourceJSON` UI error

Dashboard URL:

```text
http://localhost:5601/app/dashboards#/view/llm-dashboard-main
```

## Dashboard panels

The generated dashboard includes 8 working Lens panels:

- Total Models
- Ranked Models
- Avg USD/1M tokens
- Top 10 Best Value LLMs
- Models by Provider (Top 15)
- Price Tier Distribution
- Quality Tier Distribution
- Top Providers by Avg Value Score

## Pipeline summary

1. `ingestion/fetch_openrouter.py` fetches pricing data.
2. `ingestion/fetch_lmsys.py` fetches ranking data.
3. dbt models normalize and combine both sources.
4. `indexing/index_to_elastic.py` indexes the final output into Elasticsearch.
5. `setup_kibana_dashboard.py` builds the Kibana data view and dashboard.

## Useful commands

```bash
docker-compose logs kibana
docker-compose logs elasticsearch
curl http://localhost:9200/_cluster/health
curl http://localhost:9200/llm_value_scores/_count
python setup_kibana_dashboard.py
```

## Cloud deployment

For VM-based cloud deployment, use:

- `Dockerfile.cloud`
- `deploy/docker-compose.cloud.yml`
- `deploy/.env.cloud.example`
- `deploy/deploy-vm.sh`

The deployment guide is available at [docs/CLOUD_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/CLOUD_DEPLOY.md).

For AWS-specific setup, use [docs/AWS_EC2_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/AWS_EC2_DEPLOY.md) and `deploy/ec2-user-data.sh`.

For Railway, use the service configs and start scripts under `railway/`, and follow [docs/RAILWAY_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/RAILWAY_DEPLOY.md).

If you prefer Railway services to pull prebuilt images instead of building from source, use [docs/RAILWAY_DOCKER_IMAGE_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/RAILWAY_DOCKER_IMAGE_DEPLOY.md).

For direct GitHub-to-Render deployment, use the root [render.yaml](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/render.yaml) and [docs/RENDER_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/RENDER_DEPLOY.md).

For a free VM-based deployment, use [docs/ORACLE_FREE_TIER_DEPLOY.md](/D:/chrome%20programs%20duggempudirahul56@gmail.com/llm_tracker_final/docs/ORACLE_FREE_TIER_DEPLOY.md) and `deploy/oracle-bootstrap.sh`.

## Important fields

The dashboard uses the fields already present in the Elasticsearch mapping:

- `model_name`
- `provider`
- `avg_price_per_1m_usd`
- `value_score`
- `price_tier`
- `quality_tier`
- `has_quality_data`
- `ingestion_date`
