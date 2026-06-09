# LLM Cost vs Performance Tracker

**A Production-Ready Big Data Analytics Platform for LLM Selection**

![Status](https://img.shields.io/badge/status-production-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Python](https://img.shields.io/badge/python-3.11-blue)
![Version](https://img.shields.io/badge/version-1.0.0-blue)

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Features](#features)
- [Architecture](#architecture)
- [Data Pipeline](#data-pipeline)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Cloud Deployment](#cloud-deployment)
- [Dashboard](#dashboard)
- [Technologies](#technologies)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## Overview

**LLM Cost vs Performance Tracker** is an end-to-end Big Data analytics solution that integrates LLM pricing and performance data, computes value-based metrics, and provides interactive dashboards for intelligent model selection.

### Problem Statement

Choosing an LLM for production requires balancing:
- **Pricing** (varies across providers: OpenAI, Anthropic, Meta, Google, etc.)
- **Performance** (measured via different benchmarks: Elo, MT-Bench, MMLU)
- **Availability** (API access, self-hosting, support)

Without unified analysis, this comparison takes **15+ minutes** of manual research across multiple platforms.

### Solution

A **fully automated pipeline** that:
1. ✅ Ingests pricing from OpenRouter API (850+ models)
2. ✅ Ingests rankings from LMSYS API (120+ models)
3. ✅ Transforms & normalizes data with dbt
4. ✅ Computes value scores: `Quality / Price`
5. ✅ Indexes into Elasticsearch (850+ searchable documents)
6. ✅ Visualizes insights in Kibana dashboard (8 panels)
7. ✅ Runs **automatically every day** via Airflow
8. ✅ **Reduces decision time to 30 seconds**

### Key Metrics

| Metric | Value |
|--------|-------|
| **Models Tracked** | 850+ |
| **Data Sources** | 2 (OpenRouter + LMSYS) |
| **Dashboard Panels** | 8 (KPIs, trends, distributions) |
| **Pipeline Frequency** | Daily (08:00 UTC) |
| **Execution Time** | ~30 seconds |
| **Data Freshness** | < 24 hours |
| **Uptime** | 24/7/365 |
| **Cloud Cost** | $0/month (Oracle Always Free) |

---

## Quick Start

### Local Development (Docker)

```bash
# Clone repository
git clone https://github.com/rahulkumarreddy567/Bigdata_llm_tracker.git
cd Bigdata_llm_tracker/llm_tracker

# Start all services
docker-compose up -d

# Initialize Kibana dashboard (wait 10 seconds for Elasticsearch to be ready)
python setup_kibana_dashboard.py

# Access services
# - Kibana:       http://localhost:5601
# - Elasticsearch: http://localhost:9200
# - Airflow:      http://localhost:8080
```

### Cloud Deployment (Oracle Free Tier)

```bash
# On your Oracle Cloud VM:
git clone https://github.com/rahulkumarreddy567/Bigdata_llm_tracker.git
cd Bigdata_llm_tracker/llm_tracker

# Make scripts executable
chmod +x deploy/oracle-bootstrap.sh deploy/deploy-vm.sh

# Bootstrap VM (installs Docker)
./deploy/oracle-bootstrap.sh

# Configure environment
cp deploy/.env.cloud.example deploy/.env.cloud
nano deploy/.env.cloud  # Edit with your passwords

# Deploy
./deploy/deploy-vm.sh

# Access dashboard at: http://<your-vm-public-ip>:5601
```

### Verify Installation

```bash
# Check service health
curl http://localhost:9200/_cluster/health

# Check indexed documents
curl http://localhost:9200/llm_value_scores/_count

# View Airflow DAG
curl http://localhost:8080/api/v1/dags/llm_cost_performance_tracker/dagRuns

# View logs
docker-compose logs -f airflow-scheduler
```

---

## Features

### 🎯 Core Capabilities

✅ **Multi-Source Integration**
- OpenRouter API for real-time LLM pricing (850+ models)
- LMSYS Chatbot Arena for benchmark rankings (120+ models)
- Intelligent fuzzy matching for data alignment

✅ **Automated ETL Pipeline**
- Daily execution via Apache Airflow (08:00 UTC)
- Fault-tolerant with automatic retries
- Data quality validation via dbt tests

✅ **Advanced Transformations**
- dbt SQL models for reproducible transforms
- 3-layer data architecture (raw → formatted → combined)
- Value score computation: `quality_normalized / (price + constant)`

✅ **Fast Search & Analytics**
- Elasticsearch indexing (850+ documents)
- Sub-second query response times
- Full-text search support

✅ **Interactive Dashboards**
- Kibana Lens visualizations (8 panels)
- KPI metrics (total models, ranked models, avg pricing)
- Value-based rankings
- Provider & tier distributions
- Real-time data updates

✅ **Production Deployment**
- Docker containerization
- Oracle Cloud Always Free ($0/month)
- 24/7 unattended operation
- Comprehensive monitoring

### 📊 Insights Generated

1. **Value Score Ranking** - Which models offer best quality-to-price ratio?
2. **Provider Strategy Analysis** - How do vendors position themselves?
3. **Price Tier Distribution** - What % of models are cheap, budget, premium?
4. **Quality Tier Breakdown** - What % have elite, high, medium, low quality?
5. **Market Concentration** - Which providers dominate?
6. **Cost-Quality Trade-offs** - What quality do I get for $0.01 per 1M tokens?

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   DATA SOURCES                              │
├─────────────────────────────────────────────────────────────┤
│ OpenRouter API (Pricing)    │    LMSYS API (Rankings)      │
│ 850+ models, daily fetch    │    120+ models, weekly cache  │
└────────────────┬────────────┴────────────────┬──────────────┘
                 │                             │
      ┌──────────▼─────────────────────────────▼──────────────┐
      │    AIRFLOW ORCHESTRATION (llm_cost_performance_tracker) │
      │              Runs daily at 08:00 UTC                   │
      └──────────────────┬─────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
    ┌───▼────────┐             ┌─────────▼────────┐
    │ INGESTION  │             │ INGESTION        │
    │ (fetch)    │             │ (fetch)          │
    │ ~2 sec     │             │ ~2 sec           │
    └───┬────────┘             └────────┬─────────┘
        │                               │
    data/raw/openrouter/       data/raw/lmsys/
    YYYY-MM-DD/models.json     YYYY-MM-DD/rankings.json
        │                               │
        └────────────────┬──────────────┘
                         │
        ┌────────────────▼──────────────┐
        │      DBT TRANSFORMATION       │
        │ (openrouter_formatted,        │
        │  lmsys_formatted)             │
        │ ~8 sec                        │
        └────────────────┬──────────────┘
                         │
        ┌────────────────▼──────────────┐
        │      DBT VALIDATION           │
        │      (dbt test)               │
        │ ~3 sec                        │
        └────────────────┬──────────────┘
                         │
        ┌────────────────▼──────────────┐
        │    DBT COMBINATION            │
        │ (llm_value_scores)            │
        │ - Join pricing + quality      │
        │ - Compute value_score         │
        │ - Assign tiers & ranks        │
        └────────────────┬──────────────┘
                         │
    ┌────────────────────┴─────────────────────┐
    │                                          │
    ▼                                          ▼
PARQUET EXPORT                        ELASTICSEARCH INDEX
data/formatted/                       llm_value_scores (850 docs)
data/combined/                        26 fields, searchable
    │                                          │
    │                                          ▼
    │                                    ┌──────────────┐
    │                                    │ KIBANA DASH  │
    │                                    │ (8 panels)   │
    │                                    └──────────────┘
    │                                          │
    │                                    http://localhost:5601
    │
    └──────────────► Archive & Audit Trail
```

### Data Layers

**Layer 1: Raw (Immutable)**
- Location: `data/raw/openrouter/YYYY-MM-DD/` and `data/raw/lmsys/YYYY-MM-DD/`
- Format: JSON (full API responses)
- Purpose: Audit trail, replay capability
- Retention: Permanent

**Layer 2: Formatted (Normalized)**
- Location: `data/formatted/openrouter/YYYY-MM-DD/` and `data/formatted/lmsys/YYYY-MM-DD/`
- Format: Parquet (columnar, compressed)
- Purpose: Single source of truth per source
- Transformations: Type casting, null handling, date normalization to UTC

**Layer 3: Combined (Analytical)**
- Location: `data/combined/YYYY-MM-DD/llm_value_scores.parquet`
- Format: Parquet
- Purpose: Business intelligence queries
- Computations: Join, value score, tier classification, ranking

---

## Data Pipeline

### Daily Execution Flow

Triggered every day at **08:00 UTC** by Airflow scheduler.

#### Task 1 & 2: Ingestion (Parallel)

**Task: `ingest_openrouter`** (~2 seconds)
```python
# Fetches 850+ models from OpenRouter API
# Saves to: data/raw/openrouter/YYYY-MM-DD/models.json
# Contains: model_id, name, provider, pricing, context_length, modality, license
```

**Task: `ingest_lmsys`** (~2 seconds)
```python
# Fetches ranking data from LMSYS
# Saves to: data/raw/lmsys/YYYY-MM-DD/rankings.json
# Contains: model_name, elo_score, mt_bench_score, mmlu_score
```

#### Task 3: DBT Format & Combine (~8 seconds)

Runs 3 SQL models:

1. **`openrouter_formatted`** - Normalizes pricing data
   - Converts to UTC
   - Casts to correct types
   - Outputs Parquet

2. **`lmsys_formatted`** - Normalizes ranking data
   - Extracts benchmark scores
   - Normalizes to 0-100 scale
   - Outputs Parquet

3. **`llm_value_scores`** - Joins & computes value
   - LEFT JOIN on model name fuzzy match
   - Computes: `value_score = quality_normalized / (avg_price + 0.001)`
   - Assigns price tiers: free, budget, mid, premium, ultra
   - Assigns quality tiers: unranked, low, medium, high, elite
   - Calculates rankings: global_rank, rank_in_tier, is_top10_value

#### Task 4: Data Quality Tests (~3 seconds)

dbt tests validate:
- No nulls in critical fields
- Prices are positive numbers
- Value scores between 0-999
- No duplicate model IDs
- Referential integrity

**If tests fail**: DAG stops, team is alerted.

#### Task 5: Export to Parquet (~5 seconds)

Exports final dataset to date-partitioned Parquet files:
- `data/formatted/openrouter/YYYY-MM-DD/data.parquet`
- `data/formatted/lmsys/YYYY-MM-DD/data.parquet`
- `data/combined/YYYY-MM-DD/llm_value_scores.parquet`

Purpose: Long-term archive, data lake storage, audit trail.

#### Task 6: Index to Elasticsearch (~3 seconds)

Bulk indexes all 850 documents:
- Read from DuckDB
- Clean & sanitize (handle NaN, type conversion)
- Bulk insert into `llm_value_scores` index
- Enables sub-millisecond dashboard queries

**Total Pipeline Time**: ~28-30 seconds

---

## Project Structure

```
llm_tracker_final/
│
├── 📁 .github/
│   └── workflows/             # GitHub Actions CI/CD
│
├── 📁 docs/
│   ├── ORACLE_FREE_TIER_DEPLOY.md  # Cloud deployment guide
│   ├── CLOUD_DEPLOY.md
│   └── README.md
│
├── 📁 llm_tracker/            # Main application
│   │
│   ├── 📁 dags/               # Airflow DAGs
│   │   └── llm_pipeline_dag.py
│   │       └─ Main orchestration (6 tasks, daily at 08:00 UTC)
│   │
│   ├── 📁 data/               # Data lake (created at runtime)
│   │   ├── raw/               # Layer 1: Raw ingestion
│   │   ├── formatted/         # Layer 2: Normalized data
│   │   ├── combined/          # Layer 3: Final output
│   │   └── llm_tracker.duckdb # Analytics DB
│   │
│   ├── 📁 ingestion/          # Data fetching
│   │   ├── fetch_openrouter.py
│   │   │   └─ Fetches 850+ models from OpenRouter API
│   │   └── fetch_lmsys.py
│   │       └─ Fetches rankings from LMSYS API
│   │
│   ├── 📁 dbt_project/        # SQL transformations
│   │   ├── 📁 models/
│   │   │   ├── 📁 formatted/
│   │   │   │   ├── openrouter_formatted.sql
│   │   │   │   └── lmsys_formatted.sql
│   │   │   └── 📁 combined/
│   │   │       └── llm_value_scores.sql ⭐ Core business logic
│   │   ├── dbt_project.yml
│   │   └── profiles.yml
│   │
│   ├── 📁 indexing/           # Search indexing
│   │   └── index_to_elastic.py
│   │       └─ Bulk indexes to Elasticsearch
│   │
│   ├── 📁 kibana/             # Dashboard config
│   │   └── dashboard_export.json
│   │
│   ├── 📁 deploy/             # Cloud deployment
│   │   ├── oracle-bootstrap.sh     # VM setup
│   │   ├── deploy-vm.sh            # Stack launch
│   │   ├── docker-compose.cloud.yml
│   │   ├── .env.cloud.example
│   │   └── check-cloud-stack.sh
│   │
│   ├── 📁 scripts/            # Utility scripts
│   │   ├── start.bat
│   │   └── stop.bat
│   │
│   ├── docker-compose.yml     # Local stack definition
│   ├── Dockerfile.cloud       # Production image
│   ├── setup_kibana_dashboard.py  # Dashboard auto-setup
│   └── requirements-airflow.txt   # Python dependencies
│
├── 📄 README.md               # Quick start (this file)
├── 📄 CHANGELOG.md            # Version history
├── 📄 CONTRIBUTING.md         # Contribution guidelines
├── 📄 LICENSE                 # MIT License
└── 📄 .gitignore
```

---

## Installation

### Prerequisites

- **Docker & Docker Compose** (for local development)
  - [Install Docker](https://docs.docker.com/get-docker/)
  - [Install Docker Compose](https://docs.docker.com/compose/install/)

- **Python 3.11+** (for development)
  ```bash
  python --version  # Should be 3.11 or higher
  ```

- **Oracle Cloud Account** (for cloud deployment, free tier available)
  - Sign up at: https://www.oracle.com/cloud/free/

### Local Setup

#### Step 1: Clone Repository

```bash
git clone https://github.com/rahulkumarreddy567/Bigdata_llm_tracker.git
cd Bigdata_llm_tracker/llm_tracker
```

#### Step 2: Start Services

```bash
# Start all Docker containers (background mode)
docker-compose up -d

# Wait 10 seconds for Elasticsearch to initialize
sleep 10

# Verify services are running
docker-compose ps
```

Expected output:
```
NAME              STATUS      PORTS
postgres          Up          5432/tcp
elasticsearch     Up          9200/tcp
kibana            Up          5601/tcp
airflow-webserver Up          8080/tcp
airflow-scheduler Up
```

#### Step 3: Initialize Dashboard

```bash
# Create Kibana dashboard and data view
python setup_kibana_dashboard.py
```

Expected output:
```
[OK] Elasticsearch cluster status: green
[OK] Indexed documents in 'llm_value_scores': 0
[OK] Data view ready: llm-data-view
[OK] Dashboard ready: LLM Cost vs Performance Dashboard (8 panels)
Dashboard URL: http://localhost:5601/app/dashboards#/view/llm-dashboard-main
```

#### Step 4: Access Services

```bash
# Dashboard (visualizations)
http://localhost:5601

# Airflow (scheduling)
http://localhost:8080
# Default: admin / admin

# Elasticsearch (search engine)
http://localhost:9200

# PostgreSQL (metadata)
localhost:5432
```

#### Step 5: Trigger First Pipeline Run

```bash
# Option A: Wait for scheduled trigger (08:00 UTC daily)

# Option B: Trigger manually via Airflow UI
# 1. Go to http://localhost:8080/dags/llm_cost_performance_tracker
# 2. Click "Trigger DAG"
# 3. Watch progress

# Option C: Trigger via CLI
docker-compose exec airflow-webserver airflow dags trigger \
  llm_cost_performance_tracker \
  --exec-date 2024-01-15
```

#### Step 6: Verify Data Flow

```bash
# Check Elasticsearch has data
curl http://localhost:9200/llm_value_scores/_count
# Should show: {"count": 850, "status": 200}

# View DuckDB tables
docker-compose exec airflow-webserver duckdb /opt/airflow/data/llm_tracker.duckdb
# In DuckDB shell:
# .tables
# SELECT COUNT(*) FROM main_combined.llm_value_scores;

# Check Airflow logs
docker-compose logs -f airflow-scheduler
```

### Stopping Services

```bash
# Stop all containers (keep data)
docker-compose down

# Stop and remove all data
docker-compose down -v
```

---

## Usage

### Run the Pipeline

#### Option 1: Automatic (Recommended)

The DAG runs automatically every day at **08:00 UTC**.

Monitor progress:
```bash
# View DAG runs
curl http://localhost:8080/api/v1/dags/llm_cost_performance_tracker/dagRuns

# Stream logs
docker-compose logs -f airflow-scheduler
```

#### Option 2: Manual Trigger

Via Airflow UI:
1. Navigate to: `http://localhost:8080`
2. Go to: **DAGs** → **llm_cost_performance_tracker**
3. Click: **Trigger DAG**
4. Select execution date (YYYY-MM-DD)
5. Click: **Trigger**

Via CLI:
```bash
# Trigger for today
airflow dags trigger llm_cost_performance_tracker

# Trigger for specific date
airflow dags trigger llm_cost_performance_tracker \
  --exec-date 2024-01-15
```

### Query the Dashboard

**Kibana Dashboard URL**: `http://localhost:5601/app/dashboards#/view/llm-dashboard-main`

**Dashboard Panels**:

1. **Total Models** - Count of all 850+ indexed models
2. **Ranked Models** - Count with quality data (120+)
3. **Avg USD/1M tokens** - Price range statistics
4. **Top 10 Best Value LLMs** - Ranked by value score
5. **Models by Provider** - Top 15 providers by count
6. **Price Tier Distribution** - Cheap/Budget/Mid/Premium breakdown
7. **Quality Tier Distribution** - Low/Medium/High/Elite breakdown
8. **Top Providers by Avg Value** - Provider comparison

### Query via Elasticsearch API

```bash
# Get total count
curl http://localhost:9200/llm_value_scores/_count

# Search for specific model
curl -X POST http://localhost:9200/llm_value_scores/_search -H "Content-Type: application/json" -d '
{
  "query": {"match": {"model_name": "gpt-4"}},
  "size": 10
}
'

# Get top value models
curl -X POST http://localhost:9200/llm_value_scores/_search -H "Content-Type: application/json" -d '
{
  "query": {"bool": {"must": [{"term": {"has_quality_data": true}}]}},
  "sort": [{"value_score": {"order": "desc"}}],
  "size": 10
}
'

# Get models by provider
curl -X POST http://localhost:9200/llm_value_scores/_search -H "Content-Type: application/json" -d '
{
  "query": {"term": {"provider": "openai"}},
  "size": 50
}
'
```

### View Raw Data

```bash
# List ingested files
ls -la data/raw/openrouter/*/
ls -la data/raw/lmsys/*/

# View formatted data
ls -la data/formatted/*/

# View combined output
ls -la data/combined/*/

# Query with DuckDB
duckdb data/llm_tracker.duckdb
# .tables
# SELECT * FROM main_combined.llm_value_scores LIMIT 10;
# SELECT COUNT(*) FROM main_combined.llm_value_scores;
```

---

## Configuration

### Environment Variables

Create `.env` file in project root:

```bash
# Elasticsearch
ELASTICSEARCH_HOST=http://elasticsearch:9200
ELASTICSEARCH_PORT=9200

# Kibana
KIBANA_URL=http://localhost:5601
KIBANA_WEB_PORT=5601

# Airflow
AIRFLOW__CORE__FERNET_KEY=your-fernet-key-here
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql://airflow:airflow@postgres:5432/airflow

# PostgreSQL
POSTGRES_USER=airflow
POSTGRES_PASSWORD=airflow
POSTGRES_DB=airflow
```

### Customize Pipeline Schedule

Edit `llm_tracker/dags/llm_pipeline_dag.py`:

```python
# Change schedule (default: daily at 08:00 UTC)
schedule_interval="0 8 * * *",  # Cron format

# Examples:
# "0 8 * * *"        # Daily at 08:00 UTC
# "0 */6 * * *"      # Every 6 hours
# "0 0 * * 0"        # Weekly on Monday at 00:00
# "0 0 1 * *"        # Monthly on 1st at 00:00
```

### Modify Value Score Calculation

Edit `llm_tracker/dbt_project/models/combined/llm_value_scores.sql`:

```sql
-- Change the formula (currently: quality / price)
-- Line ~110:
value_score = quality_score_normalized / avg_price_per_1m_eur

-- Examples:
-- (quality * 0.8) + (1 / price)  -- Weighted formula
-- quality / POWER(price, 1.5)    -- Penalize expensive models
-- CASE WHEN price < 0.01 THEN quality * 1.5 ELSE quality / price END
```

### Add New Data Source

1. Create ingestion script: `ingestion/fetch_mynewsource.py`
2. Create dbt model: `dbt_project/models/formatted/mynewsource_formatted.sql`
3. Update `llm_value_scores.sql` to JOIN with new source
4. Add task to `dags/llm_pipeline_dag.py`
5. Run pipeline

---

## Cloud Deployment

### Oracle Cloud Always Free

**Why Oracle?**
- ✅ Truly free (no credit card, no time limit)
- ✅ Generous specs (4 vCPU, 24GB RAM, 200GB storage)
- ✅ Always free tier
- ✅ No surprise bills

**Cost**: $0/month

### Deployment Steps

#### Step 1: Create VM on Oracle Cloud

1. Log in to [Oracle Cloud Console](https://cloud.oracle.com)
2. Go to **Compute** → **Instances**
3. Click **Create Instance**
4. Select:
   - Image: **Ubuntu 22.04** (Minimal)
   - Shape: **Ampere (ARM)** (always free)
   - vCPU: 4
   - RAM: 24GB
   - Storage: 200GB
5. Create SSH key pair (download private key)
6. Click **Create**
7. Wait 3-5 minutes for instance to start
8. Note the **public IP address**

#### Step 2: Configure Network

1. Go to **Networking** → **Security Lists** (or Network Security Groups)
2. Add ingress rules:
   ```
   Port 22 (SSH) from your IP
   Port 8080 (Airflow) from anywhere
   Port 5601 (Kibana) from anywhere
   ```

#### Step 3: SSH into VM

```bash
ssh -i your-private-key.key ubuntu@<PUBLIC_IP>
```

#### Step 4: Deploy Stack

```bash
# Clone repository
git clone https://github.com/rahulkumarreddy567/Bigdata_llm_tracker.git
cd Bigdata_llm_tracker/llm_tracker

# Make scripts executable
chmod +x deploy/oracle-bootstrap.sh deploy/deploy-vm.sh

# Bootstrap (installs Docker) - takes 5-10 minutes
./deploy/oracle-bootstrap.sh

# Create environment file
cp deploy/.env.cloud.example deploy/.env.cloud

# Edit with your passwords
nano deploy/.env.cloud

# Deploy stack - takes 2-3 minutes
./deploy/deploy-vm.sh
```

#### Step 5: Access Dashboard

```
Airflow:  http://<PUBLIC_IP>:8080
Kibana:   http://<PUBLIC_IP>:5601
```

#### Step 6: Monitor

```bash
# Check services
docker-compose ps

# View logs
docker-compose logs -f

# Check health
curl http://localhost:9200/_cluster/health
```

---

## Dashboard

### 8 Kibana Panels

#### Panel 1: Total Models
- **Type**: KPI Card
- **Metric**: COUNT(*)
- **Description**: Total LLM models in system
- **Value**: 850+

#### Panel 2: Ranked Models
- **Type**: KPI Card
- **Metric**: COUNT(*) WHERE has_quality_data = true
- **Description**: Models with quality benchmark data
- **Value**: 120+

#### Panel 3: Avg USD/1M Tokens
- **Type**: KPI Card
- **Metric**: AVERAGE(avg_price_per_1m_usd)
- **Description**: Average pricing across all models
- **Value**: $0.01-0.50

#### Panel 4: Top 10 Best Value LLMs
- **Type**: Horizontal Bar Chart
- **Metric**: MAX(value_score) per model
- **Dimension**: model_name
- **Filter**: has_quality_data = true AND avg_price_per_1m_usd > 0
- **Sort**: value_score DESC, limit 10
- **Insight**: Which models give best quality-to-price ratio?

#### Panel 5: Models by Provider (Top 15)
- **Type**: Horizontal Bar Chart
- **Metric**: COUNT(*)
- **Dimension**: provider
- **Sort**: COUNT DESC, limit 15
- **Insight**: Which providers have most models?

#### Panel 6: Price Tier Distribution
- **Type**: Donut Chart
- **Metric**: COUNT(*)
- **Dimension**: price_tier
- **Categories**: free, budget, mid, premium, ultra
- **Insight**: How many models in each price tier?

#### Panel 7: Quality Tier Distribution
- **Type**: Pie Chart
- **Metric**: COUNT(*)
- **Dimension**: quality_tier
- **Categories**: unranked, low, medium, high, elite
- **Insight**: How many models in each quality tier?

#### Panel 8: Top Providers by Avg Value Score
- **Type**: Vertical Bar Chart
- **Metric**: AVERAGE(value_score) per provider
- **Dimension**: provider
- **Filter**: has_quality_data = true AND avg_price_per_1m_usd > 0
- **Sort**: AVERAGE(value_score) DESC, limit 10
- **Insight**: Which providers offer best average value?

---

## Technologies

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Orchestration** | Apache Airflow | 2.8.1 | Workflow scheduling & monitoring |
| **Database (Metadata)** | PostgreSQL | 15 | Airflow metadata storage |
| **Database (Analytics)** | DuckDB | 1.1.0 | SQL analytics on Parquet files |
| **Transformation** | dbt | 1.7.2 | SQL-based data modeling |
| **Search Engine** | Elasticsearch | 8.12.0 | Indexing and full-text search |
| **Visualization** | Kibana | 8.12.0 | Interactive dashboards |
| **Data Format** | Parquet | - | Columnar storage for data lake |
| **Container Runtime** | Docker | Latest | Containerization |
| **Orchestration Tool** | Docker Compose | Latest | Multi-container management |
| **Programming Language** | Python | 3.11 | ETL scripting |
| **Query Language** | SQL | - | Data transformations |
| **Cloud Provider** | Oracle Cloud | Always Free | VM hosting |
| **OS (Cloud)** | Ubuntu | 22.04 | Linux distribution |

### Key Dependencies

**Python Libraries** (`requirements-airflow.txt`):
- `requests>=2.33.0` - HTTP client for API calls
- `pandas>=2.1.4` - Data manipulation
- `pyarrow>=18.0.0` - Parquet file support
- `elasticsearch>=8.12.0` - Elasticsearch client
- `dbt-duckdb>=1.7.2` - dbt DuckDB adapter
- `duckdb>=1.1.0` - DuckDB Python client
- `numpy>=1.26.3` - Numerical computing

---

## Contributing

### Code Standards

- **Python**: PEP 8, type hints, docstrings
- **SQL**: Descriptive names, comments, proper formatting
- **Git**: Meaningful commit messages, feature branches
- **Testing**: Unit tests for new features

### How to Contribute

1. **Fork** the repository
2. **Create** feature branch: `git checkout -b feature/my-feature`
3. **Commit** changes: `git commit -am 'Add feature'`
4. **Push** to branch: `git push origin feature/my-feature`
5. **Create** pull request with description

### Development Setup

```bash
# Install dev dependencies
pip install -r requirements-airflow.txt
pip install pytest pytest-cov black flake8

# Format code
black llm_tracker/

# Lint code
flake8 llm_tracker/

# Run tests
pytest tests/
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker-compose logs

# Check resource usage
docker stats

# Rebuild images
docker-compose down
docker-compose up -d --build
```

### No Data in Dashboard

```bash
# Check if pipeline ran
curl http://localhost:8080/api/v1/dags/llm_cost_performance_tracker/dagRuns

# Check Elasticsearch
curl http://localhost:9200/llm_value_scores/_count

# Check DuckDB
duckdb data/llm_tracker.duckdb
# SELECT COUNT(*) FROM main_combined.llm_value_scores;

# Manually trigger pipeline
airflow dags trigger llm_cost_performance_tracker
```

### Elasticsearch Connection Failed

```bash
# Check Elasticsearch health
curl http://localhost:9200/_cluster/health

# Check port availability
netstat -tlnp | grep 9200

# Restart Elasticsearch
docker-compose restart elasticsearch
```

### High Memory Usage

```bash
# Check container memory
docker stats

# Reduce Elasticsearch heap size (edit docker-compose.yml)
# Change: ES_JAVA_OPTS=-Xms512m -Xmx512m

# Reduce DuckDB cache
# Edit dbt_project/profiles.yml: threads: 2
```

---

## Support

### Documentation

- **Quick Start**: This file
- **Cloud Deployment**: `docs/ORACLE_FREE_TIER_DEPLOY.md`
- **Architecture**: `docs/README.md`
- **Changelog**: `CHANGELOG.md`

### Community

- **GitHub Issues**: https://github.com/rahulkumarreddy567/Bigdata_llm_tracker/issues
- **GitHub Discussions**: https://github.com/rahulkumarreddy567/Bigdata_llm_tracker/discussions
- **Blog Post**: https://medium.com/@duggempudirahul56/llm-tracker-building-an-end-to-end-llm-cost-vs-performance-analytics-platform-1aaa5ace25ea

### Contact

- **Project Lead**: Rahul Duggempudi
- **Email**: [Your Email]
- **GitHub**: @rahulkumarreddy567

---

## License

This project is licensed under the **MIT License** - see `LICENSE` file for details.

### Key Points:
- ✅ Free to use, modify, distribute
- ✅ Must include license notice
- ✅ No warranty provided

---

## Acknowledgments

- **OpenRouter** for LLM pricing data API
- **LMSYS** for model ranking benchmarks
- **Apache Airflow** for workflow orchestration
- **dbt Labs** for data transformation framework
- **Elastic** for search and visualization platform
- **Oracle Cloud** for free infrastructure

---

## Citation

If you use this project in your research or publication, please cite:

```bibtex
@software{llm_tracker_2024,
  author = {Duggempudi, Rahul and Devarakonda, Suresh},
  title = {LLM Cost vs Performance Tracker: An End-to-End Big Data Analytics Platform},
  year = {2024},
  url = {https://github.com/rahulkumarreddy567/Bigdata_llm_tracker},
  note = {GitHub Repository}
}
```

---

## Project Status

| Component | Status | Last Updated |
|-----------|--------|--------------|
| Core Pipeline | ✅ Production | 2024-01-15 |
| Dashboard | ✅ Production | 2024-01-15 |
| Cloud Deployment | ✅ Production | 2024-01-15 |
| Documentation | ✅ Complete | 2024-01-15 |
| v1.1 (Streaming) | 🔄 Planned | Q2 2024 |
| v1.2 (Web UI) | 🔄 Planned | Q3 2024 |

---

**Last Updated**: 2024-01-15  
**Version**: 1.0.0  
**Status**: Production Ready  
**License**: MIT

---

# Quick Links

📊 **Live Dashboard**: http://141.253.111.107:5601/app/dashboards#/view/llm-dashboard-main

📂 **GitHub**: https://github.com/rahulkumarreddy567/Bigdata_llm_tracker

📝 **Blog**: https://medium.com/@duggempudirahul56/llm-tracker-building-an-end-to-end-llm-cost-vs-performance-analytics-platform-1aaa5ace25ea

📊 **OpenRouter API**: https://openrouter.ai/api/v1/models

📊 **LMSYS Rankings**: https://huggingface.co/api/spaces/lmsys/chatbot-arena-leaderboard

---

**Ready to get started? Run `docker-compose up -d` and access Kibana at `http://localhost:5601`!** 🚀
