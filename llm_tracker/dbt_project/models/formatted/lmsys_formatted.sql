{% set run_date = env_var('LLM_TRACKER_RUN_DATE', modules.datetime.datetime.utcnow().strftime('%Y-%m-%d')) %}

-- =============================================================
-- Model: lmsys_formatted
-- Layer: formatted
-- Description: Normalize LMSYS Chatbot Arena rankings into
--              clean typed columns with composite quality score.
-- =============================================================

WITH raw_file AS (
    SELECT
        json_extract_string(row_data, '$.key')                      AS model_key,
        json_extract_string(row_data, '$.Model')                    AS model_name,
        json_extract_string(row_data, '$.Arena Elo rating')         AS elo_raw,
        json_extract_string(row_data, '$."MT-bench (score)"')       AS mt_bench_raw,
        json_extract_string(row_data, '$.MMLU')                     AS mmlu_raw,
        json_extract_string(row_data, '$.License')                  AS license,
        json_extract_string(row_data, '$."Knowledge cutoff date"')  AS knowledge_cutoff
    FROM read_json_auto(
        '/opt/airflow/data/raw/lmsys/' ||
        '{{ run_date }}' ||
        '/rankings.json',
        format='auto'
    ) f
    CROSS JOIN UNNEST(f.rankings::JSON[]) AS t(row_data)
),

normalized AS (
    SELECT
        LOWER(TRIM(model_key))                                          AS model_key,
        TRIM(model_name)                                                AS model_name,

        -- ELO score (numeric, higher = better)
        CASE
            WHEN elo_raw IS NULL OR elo_raw = '-' THEN NULL
            ELSE ROUND(TRY_CAST(elo_raw AS DOUBLE), 2)
        END                                                             AS elo_score,

        -- MT-Bench 0–10
        CASE
            WHEN mt_bench_raw IS NULL OR mt_bench_raw = '-' THEN NULL
            ELSE ROUND(TRY_CAST(mt_bench_raw AS DOUBLE), 2)
        END                                                             AS mt_bench_score,

        -- MMLU 0–100
        CASE
            WHEN mmlu_raw IS NULL OR mmlu_raw = '-' THEN NULL
            ELSE ROUND(TRY_CAST(mmlu_raw AS DOUBLE), 2)
        END                                                             AS mmlu_score,

        -- Composite quality score (0–1 normalized)
        -- Weights: ELO 50%, MT-Bench 30%, MMLU 20%
        ROUND(
            COALESCE(
                CASE WHEN elo_raw IS NOT NULL AND elo_raw != '-'
                     THEN LEAST(GREATEST((TRY_CAST(elo_raw AS DOUBLE) - 800.0) / 600.0, 0), 1)
                     ELSE 0.5 END, 0.5
            ) * 0.5
            +
            COALESCE(
                CASE WHEN mt_bench_raw IS NOT NULL AND mt_bench_raw != '-'
                     THEN TRY_CAST(mt_bench_raw AS DOUBLE) / 10.0
                     ELSE 0.5 END, 0.5
            ) * 0.3
            +
            COALESCE(
                CASE WHEN mmlu_raw IS NOT NULL AND mmlu_raw != '-'
                     THEN TRY_CAST(mmlu_raw AS DOUBLE) / 100.0
                     ELSE 0.5 END, 0.5
            ) * 0.2,
            4
        )                                                               AS quality_score_normalized,

        COALESCE(TRIM(license), 'unknown')                             AS license,
        knowledge_cutoff,

        -- Ingestion metadata
        '{{ run_date }}'                                                AS ingestion_date,
        CURRENT_TIMESTAMP                                               AS processed_at_utc

    FROM raw_file
    WHERE model_name IS NOT NULL
)

SELECT * FROM normalized
