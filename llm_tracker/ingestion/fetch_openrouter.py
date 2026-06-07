"""
ingestion/fetch_openrouter.py
Step 2.1 - Ingestion Layer
Fetches all LLM model pricing data from OpenRouter public API.
Stores raw JSON in: data/raw/openrouter/YYYY-MM-DD/models.json
No API key required for model listing.
"""

import json
import os
from datetime import datetime, timezone

import requests

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ── API ────────────────────────────────────────────────────────────────────────
OPENROUTER_URL = "https://openrouter.ai/api/v1/models"


def fetch_models() -> list:
    """Fetch all LLM models and pricing from OpenRouter API."""
    print(f"[OpenRouter] Fetching models from {OPENROUTER_URL} ...")

    headers = {
        "Content-Type": "application/json",
        "User-Agent": "LLM-Tracker/1.0 (ISEP Big Data Project)",
    }

    response = requests.get(OPENROUTER_URL, headers=headers, timeout=30)
    response.raise_for_status()

    data = response.json()
    models = data.get("data", [])

    print(f"[OpenRouter] ✓ Retrieved {len(models)} models.")
    return models


def resolve_output_file(run_date: str | None = None) -> str:
    date_part = run_date or datetime.now(timezone.utc).strftime("%Y-%m-%d")
    raw_dir = os.path.join(BASE_DIR, "data", "raw", "openrouter", date_part)
    return os.path.join(raw_dir, "models.json")


def save_raw(models: list, run_date: str | None = None) -> str:
    """Save raw API response to datalake raw layer as JSON."""
    output_file = resolve_output_file(run_date)
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    payload = {
        "source": "openrouter",
        "url": OPENROUTER_URL,
        "fetched_at_utc": datetime.now(timezone.utc).isoformat(),
        "record_count": len(models),
        "models": models,
    }

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)

    print(f"[OpenRouter] ✓ Saved {len(models)} records → {output_file}")
    return output_file


def run(run_date: str | None = None) -> str:
    """Main entry point called by Airflow."""
    models = fetch_models()
    path = save_raw(models, run_date=run_date)
    return path


if __name__ == "__main__":
    run()
