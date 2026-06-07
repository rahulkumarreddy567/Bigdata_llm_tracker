# LLM API Cost vs Performance Tracker

This project is an end-to-end Big Data pipeline built for the ISEP Big Data project. It ingests two internet data sources, transforms them through a DBT-based datalake workflow, combines them into a value-scoring dataset, and exposes the result in Elasticsearch and Kibana.

## Theme

The project studies the tradeoff between LLM quality and API cost:

- OpenRouter provides public pricing metadata for many LLM APIs.
- LMSYS Chatbot Arena provides model quality signals through leaderboard rankings.
- The final output ranks models by a computed `value_score`, which represents quality per euro spent.

## Architecture

This implementation follows the DBT option from the project brief:

1. Ingestion jobs fetch data from REST and public web APIs.
2. DBT formatting models normalize the raw data.
3. A DBT combination model joins both sources and computes KPIs.
4. The final output is indexed in Elasticsearch and visualized in Kibana.

Main services:

- Airflow for orchestration
- DuckDB for SQL-based transformation storage
- DBT for formatting and combination
- Elasticsearch for indexing
- Kibana for dashboarding
- Docker Compose for one-command startup

## Data Sources

### 1. OpenRouter

- Endpoint: `https://openrouter.ai/api/v1/models`
- Refresh style: daily
- Content: model metadata, prompt price, completion price, context length, modality

### 2. LMSYS Chatbot Arena

- Endpoint source: Hugging Face Space metadata and leaderboard snapshot files
- Refresh style: daily
- Content: Arena Elo rating and related quality indicators

## Datalake Layout

The local datalake is stored in [`data/`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\data) with date-partitioned layers:

```text
data/
  raw/
    openrouter/YYYY-MM-DD/models.json
    lmsys/YYYY-MM-DD/rankings.json
  formatted/
    openrouter/YYYY-MM-DD/data.parquet
    lmsys/YYYY-MM-DD/data.parquet
  combined/
    YYYY-MM-DD/llm_value_scores.parquet
  llm_tracker.duckdb
```

Each DAG run now uses the Airflow logical run date (`ds`) so raw, formatted, combined, and indexed outputs stay aligned to the same partition.

## Pipeline

The Airflow DAG is [`dags/llm_pipeline_dag.py`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\dags\llm_pipeline_dag.py).

Tasks:

1. `ingest_openrouter`
2. `ingest_lmsys`
3. `dbt_format_and_combine`
4. `dbt_test`
5. `export_parquet_to_datalake`
6. `index_to_elasticsearch`

## Output Value

The combined model is [`dbt_project/models/combined/llm_value_scores.sql`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\dbt_project\models\combined\llm_value_scores.sql).

It produces:

- normalized pricing in USD and EUR per 1M tokens
- normalized quality score
- value score
- price tiers
- quality tiers
- global and in-tier ranking
- top-10 value flag

This gives a concrete business-style output rather than a default movie recommendation example.

## Run The Project

Prerequisites:

- Docker Desktop running
- Internet access for API fetching and container image pulls

Start the stack:

```powershell
cd "D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker"
docker compose up -d postgres elasticsearch
docker compose up -d kibana airflow-webserver airflow-scheduler
docker compose run --rm airflow-init
powershell -ExecutionPolicy Bypass -File .\scripts\create_dashboard.ps1
```

Or use:

```powershell
.\scripts\start.bat
```

Useful URLs:

- Airflow: [http://localhost:8080](http://localhost:8080)
- Elasticsearch: [http://localhost:9200](http://localhost:9200)
- Kibana dashboard: [http://localhost:5601/app/dashboards#/view/llm-dashboard-main](http://localhost:5601/app/dashboards#/view/llm-dashboard-main)

Default Airflow credentials:

- Username: `admin`
- Password: `admin`

## Trigger The Pipeline

You can trigger the DAG from the Airflow UI or from the scheduler container:

```powershell
docker exec llm_tracker-airflow-scheduler-1 airflow dags trigger llm_cost_performance_tracker
```

## Verification

Example checks:

```powershell
docker compose ps
Invoke-WebRequest -Uri http://localhost:8080/health -UseBasicParsing
Invoke-WebRequest -Uri http://localhost:9200/llm_value_scores/_count -UseBasicParsing
Invoke-WebRequest -Uri http://localhost:5601/api/status -UseBasicParsing
```

## Submission Checklist

Project brief coverage:

- Done: at least 2 internet data sources
- Done: one Airflow DAG for the whole pipeline
- Done: raw ingestion into a local datalake
- Done: formatting and normalization with DBT
- Done: combination of both sources into a useful final dataset
- Done: indexing in Elasticsearch
- Done: Kibana dashboard exposure
- Done: one-command runnable stack through Docker Compose and startup scripts
- Done: PDF report already present as [`llm_tracker_report.pdf`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\llm_tracker_report.pdf)
- Pending manual deliverable: project demo video
- Pending manual packaging step: final zip export for submission

## Files To Highlight In Your Submission

- [`dags/llm_pipeline_dag.py`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\dags\llm_pipeline_dag.py)
- [`ingestion/fetch_openrouter.py`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\ingestion\fetch_openrouter.py)
- [`ingestion/fetch_lmsys.py`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\ingestion\fetch_lmsys.py)
- [`dbt_project/models/formatted/openrouter_formatted.sql`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\dbt_project\models\formatted\openrouter_formatted.sql)
- [`dbt_project/models/formatted/lmsys_formatted.sql`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\dbt_project\models\formatted\lmsys_formatted.sql)
- [`dbt_project/models/combined/llm_value_scores.sql`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\dbt_project\models\combined\llm_value_scores.sql)
- [`indexing/index_to_elastic.py`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\indexing\index_to_elastic.py)
- [`docker-compose.yml`](D:\chrome programs duggempudirahul56@gmail.com\llm_tracker_final\llm_tracker\docker-compose.yml)
