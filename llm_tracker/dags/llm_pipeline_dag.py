"""
dags/llm_pipeline_dag.py
LLM Cost vs Performance Tracker - Main Airflow DAG
Schedule: Daily at 08:00 UTC
Pipeline: Ingest -> DBT format -> DBT combine -> Export Parquet -> Index ES
"""

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator


DBT_RUN_ENV = {
    "LLM_TRACKER_RUN_DATE": "{{ ds }}",
    "DBT_LOG_PATH": "/opt/airflow/data/dbt/logs",
    "DBT_TARGET_PATH": "/opt/airflow/data/dbt/target",
    "DBT_PACKAGES_INSTALL_PATH": "/opt/airflow/data/dbt/packages",
}


default_args = {
    "owner": "rahul",
    "depends_on_past": False,
    "email_on_failure": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=3),
}


with DAG(
    dag_id="llm_cost_performance_tracker",
    description="Daily fetch of LLM pricing and rankings to compute value scores",
    default_args=default_args,
    schedule_interval="0 8 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["big-data", "llm", "datalake", "isep"],
) as dag:
    def task_ingest_openrouter_fn(ds=None, **_context):
        import sys

        sys.path.insert(0, "/opt/airflow")
        from ingestion.fetch_openrouter import run

        path = run(run_date=ds)
        print(f"OpenRouter ingestion complete: {path}")


    def task_ingest_lmsys_fn(ds=None, **_context):
        import sys

        sys.path.insert(0, "/opt/airflow")
        from ingestion.fetch_lmsys import run

        path = run(run_date=ds)
        print(f"LMSYS ingestion complete: {path}")


    def task_export_parquet_fn(ds=None, **_context):
        import os

        import duckdb

        con = duckdb.connect("/opt/airflow/data/llm_tracker.duckdb")
        exports = {
            "main_formatted.openrouter_formatted": f"/opt/airflow/data/formatted/openrouter/{ds}/data.parquet",
            "main_formatted.lmsys_formatted": f"/opt/airflow/data/formatted/lmsys/{ds}/data.parquet",
            "main_combined.llm_value_scores": f"/opt/airflow/data/combined/{ds}/llm_value_scores.parquet",
        }

        for table, path in exports.items():
            os.makedirs(os.path.dirname(path), exist_ok=True)
            con.execute(
                f"""
                COPY (
                    SELECT *
                    FROM {table}
                    WHERE ingestion_date = ?
                ) TO '{path}' (FORMAT PARQUET)
                """,
                [ds],
            )
            print(f"Exported {table} -> {path}")

        con.close()


    def task_index_es_fn(ds=None, **_context):
        import sys

        sys.path.insert(0, "/opt/airflow")
        from indexing.index_to_elastic import run

        run(run_date=ds)


    t1_ingest_openrouter = PythonOperator(
        task_id="ingest_openrouter",
        python_callable=task_ingest_openrouter_fn,
        doc_md="Fetches LLM pricing from OpenRouter into the raw layer partition for the DAG run date.",
    )

    t2_ingest_lmsys = PythonOperator(
        task_id="ingest_lmsys",
        python_callable=task_ingest_lmsys_fn,
        doc_md="Fetches LMSYS rankings into the raw layer partition for the DAG run date.",
    )

    t3_dbt_run = BashOperator(
        task_id="dbt_format_and_combine",
        bash_command=(
            "mkdir -p /opt/airflow/data/dbt/logs "
            "/opt/airflow/data/dbt/target "
            "/opt/airflow/data/dbt/packages && "
            "cd /opt/airflow/dbt_project && "
            "/home/airflow/.local/bin/dbt run "
            "--profiles-dir /opt/airflow/dbt_project "
            "--project-dir /opt/airflow/dbt_project "
            "--select formatted.openrouter_formatted "
            "formatted.lmsys_formatted "
            "combined.llm_value_scores"
        ),
        env=DBT_RUN_ENV,
        append_env=True,
        doc_md="Runs DBT models to normalize both sources and compute the final value score table.",
    )

    t4_dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=(
            "mkdir -p /opt/airflow/data/dbt/logs "
            "/opt/airflow/data/dbt/target "
            "/opt/airflow/data/dbt/packages && "
            "cd /opt/airflow/dbt_project && "
            "/home/airflow/.local/bin/dbt test "
            "--profiles-dir /opt/airflow/dbt_project "
            "--project-dir /opt/airflow/dbt_project"
        ),
        env=DBT_RUN_ENV,
        append_env=True,
        doc_md="Runs DBT tests for the current partition.",
    )

    t5_export_parquet = PythonOperator(
        task_id="export_parquet_to_datalake",
        python_callable=task_export_parquet_fn,
        doc_md="Exports formatted and combined tables to Parquet in date-partitioned folders.",
    )

    t6_index_es = PythonOperator(
        task_id="index_to_elasticsearch",
        python_callable=task_index_es_fn,
        doc_md="Indexes the combined output for the current partition into Elasticsearch.",
    )

    [t1_ingest_openrouter, t2_ingest_lmsys] >> t3_dbt_run >> t4_dbt_test >> t5_export_parquet >> t6_index_es
