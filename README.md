# LLM Cost vs Performance Tracker

**A Production-Ready Big Data Analytics Platform for LLM Selection**

![Status](https://img.shields.io/badge/status-production-green)
![Python](https://img.shields.io/badge/python-3.11-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

## 🎯 What This Does

Automatically tracks 850+ LLM models, fetches real-time pricing and performance data daily, computes value scores, and visualizes insights in an interactive Kibana dashboard.

**Decision time**: From 15+ minutes of manual research → **30 seconds** with dashboards.

## 📊 Key Stats

- **850+ LLM models** tracked daily
- **2 data sources** (OpenRouter API + LMSYS rankings)
- **~30 seconds** pipeline execution
- **8 dashboard panels** with KPIs and trends
- **$0/month** cloud cost (Oracle Always Free)
- **24/7** automated updates at 08:00 UTC

## 🚀 Quick Start

### Local Development (30 seconds)

```bash
# Clone & navigate
git clone https://github.com/rahulkumarreddy567/Bigdata_llm_tracker.git
cd Bigdata_llm_tracker/llm_tracker

# Start services
docker-compose up -d

# Wait 10 seconds, then initialize dashboard
sleep 10 && python setup_kibana_dashboard.py

# Open dashboard
# http://localhost:5601
```

### Cloud Deployment (Oracle Free Tier)

```bash
# On your Oracle Cloud VM:
git clone https://github.com/rahulkumarreddy567/Bigdata_llm_tracker.git
cd Bigdata_llm_tracker/llm_tracker

chmod +x deploy/oracle-bootstrap.sh deploy/deploy-vm.sh
./deploy/oracle-bootstrap.sh
cp deploy/.env.cloud.example deploy/.env.cloud
nano deploy/.env.cloud  # Edit passwords
./deploy/deploy-vm.sh

# Access dashboard at http://<your-vm-ip>:5601
```

## 📚 Documentation

- **[README_COMPLETE.md](./README_COMPLETE.md)** - Full documentation (features, architecture, configuration, deployment, troubleshooting)
- **[docs/ORACLE_FREE_TIER_DEPLOY.md](./docs/ORACLE_FREE_TIER_DEPLOY.md)** - Detailed cloud deployment guide
- **[CHANGELOG.md](./CHANGELOG.md)** - Version history

## 🏗️ Architecture

```
Data Sources (OpenRouter + LMSYS)
         ↓
   Airflow DAG (Daily at 08:00 UTC)
    ├─ Fetch pricing (2s)
    ├─ Fetch rankings (2s)
    ├─ dbt transform (8s)
    ├─ Data validation (3s)
    ├─ Export to Parquet (5s)
    └─ Index to Elasticsearch (3s)
         ↓
   Elasticsearch (850 docs, searchable)
         ↓
   Kibana Dashboard (8 panels, real-time)
```

## 📊 Dashboard Panels

1. **Total Models** - 850+ tracked
2. **Ranked Models** - 120+ with quality data
3. **Avg Price** - Pricing statistics
4. **Top 10 Value LLMs** - Best quality/price ratio
5. **Models by Provider** - Provider distribution
6. **Price Tier Distribution** - Cheap/Budget/Mid/Premium breakdown
7. **Quality Tier Distribution** - Low/Medium/High/Elite breakdown
8. **Provider Value Comparison** - Provider rankings

## 🔧 Tech Stack

| Component | Technology |
|-----------|-----------|
| Orchestration | Apache Airflow 2.8.1 |
| Data Transform | dbt 1.7.2 |
| Analytics DB | DuckDB 1.1.0 |
| Search Engine | Elasticsearch 8.12.0 |
| Visualization | Kibana 8.12.0 |
| Storage | PostgreSQL 15 + Parquet |
| Containers | Docker + Docker Compose |
| Cloud | Oracle Cloud Always Free ($0) |

## 📋 Services & Ports

| Service | Port | URL |
|---------|------|-----|
| Airflow | 8080 | http://localhost:8080 |
| Kibana | 5601 | http://localhost:5601 |
| Elasticsearch | 9200 | http://localhost:9200 |
| PostgreSQL | 5432 | localhost:5432 |

## ✅ Pipeline Tasks

**Daily Execution (~30 seconds total)**

1. **ingest_openrouter** (2s) - Fetch 850+ models from OpenRouter API
2. **ingest_lmsys** (2s) - Fetch 120+ rankings from LMSYS
3. **dbt_format_and_combine** (8s) - Transform & join data
4. **dbt_test** (3s) - Validate data quality
5. **export_parquet_to_datalake** (5s) - Archive to Parquet
6. **index_to_elasticsearch** (3s) - Index for search

## 🔍 Query Examples

```bash
# Check indexed documents
curl http://localhost:9200/llm_value_scores/_count

# Search for model
curl -X POST http://localhost:9200/llm_value_scores/_search -H "Content-Type: application/json" -d '{
  "query": {"match": {"model_name": "gpt-4"}},
  "size": 10
}'

# Get top value models
curl -X POST http://localhost:9200/llm_value_scores/_search -H "Content-Type: application/json" -d '{
  "query": {"term": {"has_quality_data": true}},
  "sort": [{"value_score": {"order": "desc"}}],
  "size": 10
}'
```

## 🛠️ Customize

### Change Schedule

Edit `llm_tracker/dags/llm_pipeline_dag.py`:
```python
schedule_interval="0 */6 * * *",  # Every 6 hours instead of daily
```

### Modify Value Score

Edit `llm_tracker/dbt_project/models/combined/llm_value_scores.sql`:
```sql
-- Change formula (currently: quality / price)
value_score = quality_score_normalized / avg_price_per_1m_eur
```

## 📦 Project Structure

```
llm_tracker_final/
├── llm_tracker/
│   ├── dags/                    # Airflow DAG definitions
│   ├── ingestion/               # Data fetching scripts
│   ├── dbt_project/             # SQL transformations
│   ├── indexing/                # Elasticsearch indexing
│   ├── kibana/                  # Dashboard config
│   ├── deploy/                  # Cloud deployment scripts
│   ├── docker-compose.yml       # Local stack
│   └── requirements-airflow.txt # Dependencies
├── docs/                        # Detailed guides
├── README.md                    # This file
└── README_COMPLETE.md           # Full documentation
```

## 🐛 Troubleshooting

**Services won't start?**
```bash
docker-compose logs
docker-compose down -v && docker-compose up -d --build
```

**No data in dashboard?**
```bash
# Manually trigger pipeline
airflow dags trigger llm_cost_performance_tracker

# Check Elasticsearch
curl http://localhost:9200/llm_value_scores/_count
```

**Connection errors?**
```bash
# Check service health
curl http://localhost:9200/_cluster/health
docker stats
```

See [README_COMPLETE.md](./README_COMPLETE.md#troubleshooting) for detailed troubleshooting.

## 🌐 Live Demo

- **Dashboard**: http://141.253.111.107:5601/app/dashboards#/view/llm-dashboard-main
- **GitHub**: https://github.com/rahulkumarreddy567/Bigdata_llm_tracker
- **Blog Post**: https://medium.com/@duggempudirahul56/llm-tracker-building-an-end-to-end-llm-cost-vs-performance-analytics-platform-1aaa5ace25ea

## 📄 License

MIT - Free to use, modify, and distribute (see LICENSE file).

## 👤 Author

**Rahul Duggempudi**
- GitHub: [@rahulkumarreddy567](https://github.com/rahulkumarreddy567)
- Email: duggempudirahul56@gmail.com

## 🙏 Acknowledgments

- **OpenRouter** - LLM pricing data API
- **LMSYS** - Model ranking benchmarks
- **Apache Airflow** - Workflow orchestration
- **dbt Labs** - Data transformation
- **Elastic** - Search & visualization
- **Oracle Cloud** - Free infrastructure

---

**📖 For detailed documentation, API references, and advanced configuration, see [README_COMPLETE.md](./README_COMPLETE.md)**

**Ready? Run `docker-compose up -d` and access Kibana at `http://localhost:5601` 🚀**
