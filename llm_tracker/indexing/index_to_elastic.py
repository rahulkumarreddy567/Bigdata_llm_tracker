"""
indexing/index_to_elastic.py
Step 2.4 - Indexing Layer
Reads combined DuckDB table and bulk-indexes into Elasticsearch.
Index name: llm_value_scores
"""

import math
import os

import duckdb
from elasticsearch import Elasticsearch, helpers
from elasticsearch.exceptions import ApiError, TransportError


ES_HOST = os.getenv("ELASTICSEARCH_HOST", "http://elasticsearch:9200")
INDEX_NAME = "llm_value_scores"
DB_PATH = "/opt/airflow/data/llm_tracker.duckdb"

INDEX_MAPPING = {
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0,
    },
    "mappings": {
        "properties": {
            "model_id": {"type": "keyword"},
            "model_name": {"type": "keyword"},
            "provider": {"type": "keyword"},
            "model_slug": {"type": "keyword"},
            "lmsys_name": {"type": "keyword"},
            "price_prompt_per_1m_usd": {"type": "float"},
            "price_completion_per_1m_usd": {"type": "float"},
            "avg_price_per_1m_usd": {"type": "float"},
            "avg_price_per_1m_eur": {"type": "float"},
            "context_length": {"type": "integer"},
            "modality": {"type": "keyword"},
            "elo_score": {"type": "float"},
            "mt_bench_score": {"type": "float"},
            "mmlu_score": {"type": "float"},
            "quality_score_normalized": {"type": "float"},
            "value_score": {"type": "float"},
            "price_tier": {"type": "keyword"},
            "quality_tier": {"type": "keyword"},
            "has_quality_data": {"type": "boolean"},
            "global_rank": {"type": "integer"},
            "rank_in_tier": {"type": "integer"},
            "is_top10_value": {"type": "boolean"},
            "license": {"type": "keyword"},
            "knowledge_cutoff": {"type": "keyword"},
            "ingestion_date": {"type": "date", "format": "yyyy-MM-dd"},
            "processed_at_utc": {"type": "date"},
        }
    },
}


def connect_es() -> Elasticsearch:
    print(f"[Indexer] Connecting to Elasticsearch at {ES_HOST}...")
    es = Elasticsearch(ES_HOST, request_timeout=30)
    try:
        health = es.cluster.health()
    except (ApiError, TransportError) as exc:
        raise ConnectionError(f"Cannot reach Elasticsearch at {ES_HOST}") from exc

    print(f"[Indexer] Connected. Cluster status: {health.get('status', 'unknown')}")
    return es


def ensure_index(es: Elasticsearch) -> None:
    """Create index with mapping if it doesn't exist."""
    if es.indices.exists(index=INDEX_NAME):
        print(f"[Indexer] Index '{INDEX_NAME}' already exists.")
    else:
        es.indices.create(index=INDEX_NAME, body=INDEX_MAPPING)
        print(f"[Indexer] Created index '{INDEX_NAME}'.")


def read_duckdb(run_date: str | None = None) -> list[dict]:
    """Read combined table from DuckDB as list of dicts."""
    print(f"[Indexer] Reading from DuckDB: {DB_PATH}...")
    con = duckdb.connect(DB_PATH, read_only=True)
    if run_date:
        df = con.execute(
            """
            SELECT *
            FROM main_combined.llm_value_scores
            WHERE ingestion_date = ?
            """,
            [run_date],
        ).df()
    else:
        df = con.execute("SELECT * FROM main_combined.llm_value_scores").df()
    con.close()
    print(f"[Indexer] Loaded {len(df)} records.")
    return df.to_dict(orient="records")


def clean_doc(doc: dict) -> dict:
    """Sanitize document for ES: convert NaN/None, fix types."""
    cleaned = {}
    for key, value in doc.items():
        if value is None:
            cleaned[key] = None
        elif isinstance(value, float) and math.isnan(value):
            cleaned[key] = None
        elif hasattr(value, "item"):
            cleaned[key] = value.item()
        elif hasattr(value, "isoformat"):
            cleaned[key] = value.isoformat()
        else:
            cleaned[key] = value
    return cleaned


def build_actions(records: list[dict]):
    """Yield bulk index actions."""
    for doc in records:
        cleaned = clean_doc(doc)
        doc_id = f"{cleaned['model_id']}_{cleaned['ingestion_date']}"
        yield {
            "_index": INDEX_NAME,
            "_id": doc_id,
            "_source": cleaned,
        }


def run(run_date: str | None = None) -> None:
    es = connect_es()
    ensure_index(es)

    records = read_duckdb(run_date=run_date)
    if not records:
        print("[Indexer] No records to index. Exiting.")
        return

    success, errors = helpers.bulk(
        es,
        list(build_actions(records)),
        raise_on_error=False,
        stats_only=False,
    )

    print(f"[Indexer] Indexed {success} documents into '{INDEX_NAME}'.")
    if errors:
        print(f"[Indexer] {len(errors)} errors during indexing.")
        for err in errors[:5]:
            print(f"  -> {err}")

    print("[Indexer] Dashboard available at: http://localhost:5601")


if __name__ == "__main__":
    run()
