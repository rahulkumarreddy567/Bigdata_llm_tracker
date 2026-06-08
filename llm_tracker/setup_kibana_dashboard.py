"""
Create and verify the Kibana dashboard for the LLM tracker project.

This script is the canonical dashboard bootstrapper for the repository.
It checks Elasticsearch/Kibana connectivity, ensures a fixed data view,
creates a populated dashboard, and removes legacy empty dashboards that
caused Kibana UI errors.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


ELASTICSEARCH_URL = os.getenv("ELASTICSEARCH_URL", "http://localhost:9200")
KIBANA_URL = os.getenv("KIBANA_URL", "http://localhost:5601")
INDEX_NAME = "llm_value_scores"
DATA_VIEW_ID = "llm-data-view"
DASHBOARD_ID = "llm-dashboard-main"
DASHBOARD_TITLE = "LLM Cost vs Performance Dashboard"


def request_json(
    method: str,
    url: str,
    payload: dict | None = None,
    headers: dict[str, str] | None = None,
) -> dict:
    body = None
    request_headers = {"Content-Type": "application/json"}
    if headers:
        request_headers.update(headers)
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")

    request = urllib.request.Request(
        url=url,
        data=body,
        method=method,
        headers=request_headers,
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        raw = response.read().decode("utf-8")
        return json.loads(raw) if raw else {}


def kibana_request(method: str, path: str, payload: dict | None = None) -> dict:
    return request_json(
        method,
        f"{KIBANA_URL}{path}",
        payload=payload,
        headers={"kbn-xsrf": "true"},
    )


def check_connections() -> tuple[int, str]:
    cluster = request_json("GET", f"{ELASTICSEARCH_URL}/_cluster/health")
    status = request_json("GET", f"{KIBANA_URL}/api/status")
    try:
        count = request_json("GET", f"{ELASTICSEARCH_URL}/{INDEX_NAME}/_count")
        document_count = count["count"]
    except urllib.error.HTTPError as exc:
        if exc.code != 404:
            raise
        document_count = 0

    overall = status["status"]["overall"]["level"]
    if overall != "available":
        raise RuntimeError(f"Kibana is not ready yet: {overall}")

    return document_count, cluster["status"]


def ensure_data_view() -> None:
    payload = {
        "attributes": {
            "title": INDEX_NAME,
            "name": INDEX_NAME,
            "timeFieldName": "ingestion_date",
            "fieldAttrs": "{}",
            "sourceFilters": "[]",
            "fields": "[]",
            "fieldFormatMap": "{}",
            "runtimeFieldMap": "{}",
            "allowHidden": False,
        }
    }
    kibana_request(
        "POST",
        f"/api/saved_objects/index-pattern/{DATA_VIEW_ID}?overwrite=true",
        payload,
    )


def lens_metric(title: str, agg_type: str, field_name: str, query: str) -> dict:
    column_id = "col-count" if agg_type == "count" else f"col-{agg_type}_{field_name}"
    if agg_type == "count":
        column = {
            "label": title,
            "dataType": "number",
            "isBucketed": False,
            "operationType": "count",
            "scale": "ratio",
            "sourceField": "___records___",
        }
    else:
        column = {
            "label": title,
            "dataType": "number",
            "isBucketed": False,
            "operationType": agg_type,
            "scale": "ratio",
            "sourceField": field_name,
        }

    return {
        "title": title,
        "description": "",
        "visualizationType": "lnsMetric",
        "references": [
            {
                "type": "index-pattern",
                "id": DATA_VIEW_ID,
                "name": "indexpattern-datasource-layer-layer1",
            }
        ],
        "state": {
            "query": {"query": query, "language": "kuery"},
            "filters": [],
            "visualization": {
                "layerId": "layer1",
                "layerType": "data",
                "metricAccessor": column_id,
            },
            "datasourceStates": {
                "formBased": {
                    "layers": {
                        "layer1": {
                            "columns": {column_id: column},
                            "columnOrder": [column_id],
                            "incompleteColumns": {},
                        }
                    }
                }
            },
        },
    }


def lens_bar(
    title: str,
    metric_agg: str,
    metric_field: str,
    bucket_field: str,
    bucket_size: int,
    query: str,
    horizontal: bool,
) -> dict:
    metric_id = "metric-count" if metric_agg == "count" else f"metric-{metric_field}"
    bucket_id = f"bucket-{bucket_field}"

    if metric_agg == "count":
        metric_column = {
            "label": "Count",
            "dataType": "number",
            "isBucketed": False,
            "operationType": "count",
            "scale": "ratio",
            "sourceField": "___records___",
        }
    else:
        metric_column = {
            "label": f"{metric_agg} of {metric_field}",
            "dataType": "number",
            "isBucketed": False,
            "operationType": metric_agg,
            "scale": "ratio",
            "sourceField": metric_field,
        }

    bucket_column = {
        "label": bucket_field,
        "dataType": "string",
        "isBucketed": True,
        "operationType": "terms",
        "scale": "ordinal",
        "sourceField": bucket_field,
        "params": {
            "size": bucket_size,
            "orderBy": {"type": "column", "columnId": metric_id},
            "orderDirection": "desc",
        },
    }

    series_type = "bar_horizontal" if horizontal else "bar"
    return {
        "title": title,
        "description": "",
        "visualizationType": "lnsXY",
        "references": [
            {
                "type": "index-pattern",
                "id": DATA_VIEW_ID,
                "name": "indexpattern-datasource-layer-layer1",
            }
        ],
        "state": {
            "query": {"query": query, "language": "kuery"},
            "filters": [],
            "visualization": {
                "preferredSeriesType": series_type,
                "layers": [
                    {
                        "layerId": "layer1",
                        "layerType": "data",
                        "seriesType": series_type,
                        "xAccessor": bucket_id,
                        "accessors": [metric_id],
                    }
                ],
                "legend": {"isVisible": False},
                "valueLabels": "show",
            },
            "datasourceStates": {
                "formBased": {
                    "layers": {
                        "layer1": {
                            "columns": {
                                metric_id: metric_column,
                                bucket_id: bucket_column,
                            },
                            "columnOrder": [bucket_id, metric_id],
                            "incompleteColumns": {},
                        }
                    }
                }
            },
        },
    }


def lens_pie(title: str, bucket_field: str, bucket_size: int, query: str, donut: bool) -> dict:
    metric_id = "metric-count"
    bucket_id = f"bucket-{bucket_field}"
    return {
        "title": title,
        "description": "",
        "visualizationType": "lnsPie",
        "references": [
            {
                "type": "index-pattern",
                "id": DATA_VIEW_ID,
                "name": "indexpattern-datasource-layer-layer1",
            }
        ],
        "state": {
            "query": {"query": query, "language": "kuery"},
            "filters": [],
            "visualization": {
                "shape": "donut" if donut else "pie",
                "layers": [
                    {
                        "layerId": "layer1",
                        "layerType": "data",
                        "primaryGroups": [bucket_id],
                        "metrics": [metric_id],
                        "numberDisplay": "percent",
                        "categoryDisplay": "default",
                        "legendDisplay": "default",
                    }
                ],
            },
            "datasourceStates": {
                "formBased": {
                    "layers": {
                        "layer1": {
                            "columns": {
                                metric_id: {
                                    "label": "Count",
                                    "dataType": "number",
                                    "isBucketed": False,
                                    "operationType": "count",
                                    "scale": "ratio",
                                    "sourceField": "___records___",
                                },
                                bucket_id: {
                                    "label": bucket_field,
                                    "dataType": "string",
                                    "isBucketed": True,
                                    "operationType": "terms",
                                    "scale": "ordinal",
                                    "sourceField": bucket_field,
                                    "params": {
                                        "size": bucket_size,
                                        "orderBy": {
                                            "type": "column",
                                            "columnId": metric_id,
                                        },
                                        "orderDirection": "desc",
                                    },
                                },
                            },
                            "columnOrder": [bucket_id, metric_id],
                            "incompleteColumns": {},
                        }
                    }
                }
            },
        },
    }


def panel(panel_id: str, x: int, y: int, w: int, h: int, attributes: dict) -> dict:
    return {
        "version": "8.12.0",
        "type": "lens",
        "gridData": {"x": x, "y": y, "w": w, "h": h, "i": panel_id},
        "panelIndex": panel_id,
        "embeddableConfig": {
            "attributes": attributes,
            "enhancements": {},
        },
    }


def build_dashboard_payload() -> dict:
    panels = [
        panel("p1", 0, 0, 16, 8, lens_metric("Total Models", "count", "", "")),
        panel("p2", 16, 0, 16, 8, lens_metric("Ranked Models", "count", "", "has_quality_data: true")),
        panel(
            "p3",
            32,
            0,
            16,
            8,
            lens_metric("Avg USD/1M tokens", "average", "avg_price_per_1m_usd", "avg_price_per_1m_usd > 0"),
        ),
        panel(
            "p4",
            0,
            8,
            24,
            16,
            lens_bar(
                "Top 10 Best Value LLMs",
                "max",
                "value_score",
                "model_name",
                10,
                "has_quality_data: true AND avg_price_per_1m_usd > 0",
                True,
            ),
        ),
        panel(
            "p5",
            24,
            8,
            24,
            16,
            lens_bar("Models by Provider (Top 15)", "count", "", "provider", 15, "", True),
        ),
        panel("p6", 0, 24, 24, 14, lens_pie("Price Tier Distribution", "price_tier", 5, "", True)),
        panel("p7", 24, 24, 24, 14, lens_pie("Quality Tier Distribution", "quality_tier", 5, "", True)),
        panel(
            "p8",
            0,
            38,
            48,
            16,
            lens_bar(
                "Top Providers by Avg Value Score",
                "average",
                "value_score",
                "provider",
                10,
                "has_quality_data: true AND avg_price_per_1m_usd > 0",
                False,
            ),
        ),
    ]

    return {
        "attributes": {
            "title": DASHBOARD_TITLE,
            "description": (
                "Daily tracker for LLM pricing, quality, and value score using "
                "OpenRouter pricing plus LMSYS rankings."
            ),
            "hits": 0,
            "timeRestore": True,
            "timeFrom": "now-5y",
            "timeTo": "now",
            "refreshInterval": {"pause": True, "value": 0},
            "panelsJSON": json.dumps(panels, separators=(",", ":")),
            "optionsJSON": json.dumps(
                {
                    "useMargins": True,
                    "syncColors": False,
                    "syncCursor": True,
                    "syncTooltips": False,
                    "hidePanelTitles": False,
                },
                separators=(",", ":"),
            ),
            "version": 1,
            "kibanaSavedObjectMeta": {
                "searchSourceJSON": json.dumps(
                    {"query": {"query": "", "language": "kuery"}, "filter": []},
                    separators=(",", ":"),
                )
            },
        },
        "references": [],
    }


def create_dashboard() -> None:
    kibana_request(
        "POST",
        f"/api/saved_objects/dashboard/{DASHBOARD_ID}?overwrite=true",
        build_dashboard_payload(),
    )


def cleanup_legacy_dashboards() -> list[str]:
    query = urllib.parse.quote("LLM Tracker Dashboard")
    result = kibana_request(
        "GET",
        f"/api/saved_objects/_find?type=dashboard&per_page=100&search_fields=title&search={query}",
    )

    removed: list[str] = []
    for saved_object in result.get("saved_objects", []):
        dashboard_id = saved_object["id"]
        if dashboard_id == DASHBOARD_ID:
            continue

        attributes = saved_object.get("attributes", {})
        panels_json = attributes.get("panelsJSON")
        has_panels = isinstance(panels_json, str) and panels_json.strip() not in {"", "[]"}
        if has_panels:
            continue

        kibana_request("DELETE", f"/api/saved_objects/dashboard/{dashboard_id}")
        removed.append(dashboard_id)

    return removed


def verify_dashboard() -> dict:
    dashboard = kibana_request("GET", f"/api/saved_objects/dashboard/{DASHBOARD_ID}")
    panels = json.loads(dashboard["attributes"]["panelsJSON"])
    if not panels:
        raise RuntimeError("Dashboard was created without panels.")
    return {
        "id": dashboard["id"],
        "title": dashboard["attributes"]["title"],
        "panel_count": len(panels),
    }


def main() -> int:
    try:
        document_count, cluster_status = check_connections()
        ensure_data_view()
        create_dashboard()
        removed = cleanup_legacy_dashboards()
        dashboard = verify_dashboard()
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", errors="replace")
        print(f"[ERROR] HTTP {exc.code}: {message}")
        return 1
    except Exception as exc:  # pragma: no cover
        print(f"[ERROR] {exc}")
        return 1

    print(f"[OK] Elasticsearch cluster status: {cluster_status}")
    print(f"[OK] Indexed documents in '{INDEX_NAME}': {document_count}")
    print(f"[OK] Data view ready: {DATA_VIEW_ID}")
    print(
        f"[OK] Dashboard ready: {dashboard['title']} "
        f"({dashboard['panel_count']} panels)"
    )
    if removed:
        print(f"[OK] Removed legacy empty dashboards: {', '.join(removed)}")
    print(f"Dashboard URL: {KIBANA_URL}/app/dashboards#/view/{dashboard['id']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
