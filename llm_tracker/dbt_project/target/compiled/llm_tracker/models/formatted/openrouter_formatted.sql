

-- =============================================================
-- Model: openrouter_formatted
-- Layer: formatted
-- Description: Normalize OpenRouter raw JSON into clean typed
--              columns. Prices converted to USD per 1M tokens
--              and EUR per 1M tokens.
-- =============================================================

WITH raw_file AS (
    SELECT
        json_extract_string(model, '$.id')                          AS model_id,
        json_extract_string(model, '$.name')                        AS model_name,
        json_extract_string(model, '$.pricing.prompt')              AS price_prompt_raw,
        json_extract_string(model, '$.pricing.completion')          AS price_completion_raw,
        TRY_CAST(json_extract(model, '$.context_length') AS INTEGER) AS context_length,
        json_extract_string(model, '$.description')                 AS description,
        json_extract_string(model, '$.architecture.modality')       AS modality,
        json_extract_string(model, '$.top_provider.is_moderated')   AS is_moderated
    FROM read_json_auto(
        '/opt/airflow/data/raw/openrouter/' ||
        '2026-06-07' ||
        '/models.json',
        format='auto'
    ) f
    CROSS JOIN UNNEST(f.models::JSON[]) AS t(model)
),

cleaned AS (
    SELECT
        TRIM(model_id)                                              AS model_id,
        TRIM(model_name)                                            AS model_name,

        -- Provider extracted from model_id prefix e.g. "openai/gpt-4o" → "openai"
        SPLIT_PART(TRIM(model_id), '/', 1)                         AS provider,

        -- Slug: last part of model_id for joining
        LOWER(SPLIT_PART(TRIM(model_id), '/', 2))                  AS model_slug,

        -- Price per token → price per 1M tokens (USD)
        ROUND(TRY_CAST(price_prompt_raw     AS DOUBLE) * 1e6, 6)   AS price_prompt_per_1m_usd,
        ROUND(TRY_CAST(price_completion_raw AS DOUBLE) * 1e6, 6)   AS price_completion_per_1m_usd,

        -- Average price per 1M tokens USD
        ROUND(
            (TRY_CAST(price_prompt_raw AS DOUBLE) +
             TRY_CAST(price_completion_raw AS DOUBLE)) / 2.0 * 1e6,
            6
        )                                                           AS avg_price_per_1m_usd,

        -- Convert to EUR (1 USD ≈ 0.92 EUR as of 2024)
        ROUND(
            (TRY_CAST(price_prompt_raw AS DOUBLE) +
             TRY_CAST(price_completion_raw AS DOUBLE)) / 2.0 * 1e6 * 0.92,
            6
        )                                                           AS avg_price_per_1m_eur,

        COALESCE(context_length, 0)                                 AS context_length,
        COALESCE(TRIM(modality), 'text->text')                     AS modality,

        -- Ingestion metadata
        '2026-06-07'                                            AS ingestion_date,
        CURRENT_TIMESTAMP                                           AS processed_at_utc

    FROM raw_file
    WHERE model_id IS NOT NULL
      AND price_prompt_raw IS NOT NULL
      AND price_completion_raw IS NOT NULL
      AND TRY_CAST(price_prompt_raw     AS DOUBLE) IS NOT NULL
      AND TRY_CAST(price_completion_raw AS DOUBLE) IS NOT NULL
      AND TRY_CAST(price_prompt_raw     AS DOUBLE) >= 0
      AND TRY_CAST(price_completion_raw AS DOUBLE) >= 0
)

SELECT * FROM cleaned