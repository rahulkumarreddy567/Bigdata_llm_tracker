-- =============================================================
-- Model: llm_value_scores
-- Layer: combined
-- Description: JOIN OpenRouter pricing + LMSYS quality rankings.
--              Computes Value Score = quality / cost_per_1M_EUR.
--              This is the core business output of the pipeline.
-- =============================================================

WITH pricing AS (
    SELECT * FROM "llm_tracker"."main_formatted"."openrouter_formatted"
),

quality AS (
    SELECT * FROM "llm_tracker"."main_formatted"."lmsys_formatted"
),

-- ── Join Strategy ──────────────────────────────────────────────────────────────
-- OpenRouter model_id: "openai/gpt-4o"  → model_slug: "gpt-4o"
-- LMSYS model_key:     "gpt-4o"
-- Match on slug exact OR partial containment
joined AS (
    SELECT
        p.model_id,
        p.model_name                                AS openrouter_name,
        p.provider,
        p.model_slug,
        p.price_prompt_per_1m_usd,
        p.price_completion_per_1m_usd,
        p.avg_price_per_1m_usd,
        p.avg_price_per_1m_eur,
        p.context_length,
        p.modality,
        q.model_name                                AS lmsys_name,
        q.elo_score,
        q.mt_bench_score,
        q.mmlu_score,
        q.quality_score_normalized,
        q.license,
        q.knowledge_cutoff,
        p.ingestion_date,
        p.processed_at_utc

    FROM pricing p
    LEFT JOIN quality q
        ON p.model_slug = q.model_key
        OR p.model_slug LIKE '%' || q.model_key || '%'
        OR q.model_key  LIKE '%' || p.model_slug || '%'
),

-- ── Value Score Calculation ────────────────────────────────────────────────────
scored AS (
    SELECT
        model_id,
        openrouter_name                             AS model_name,
        provider,
        model_slug,
        lmsys_name,

        -- Pricing columns
        price_prompt_per_1m_usd,
        price_completion_per_1m_usd,
        avg_price_per_1m_usd,
        avg_price_per_1m_eur,
        context_length,
        modality,

        -- Quality columns
        elo_score,
        mt_bench_score,
        mmlu_score,
        quality_score_normalized,
        license,
        knowledge_cutoff,

        -- ── VALUE SCORE (core metric) ─────────────────────────────────────────
        -- Higher = better quality per euro spent
        CASE
            WHEN quality_score_normalized IS NOT NULL
             AND avg_price_per_1m_eur > 0
                THEN ROUND(quality_score_normalized / avg_price_per_1m_eur, 6)
            WHEN avg_price_per_1m_eur = 0
                THEN 999.999   -- free models get maximum value score
            ELSE NULL
        END                                         AS value_score,

        -- ── Price tier classification ─────────────────────────────────────────
        CASE
            WHEN avg_price_per_1m_usd = 0          THEN 'free'
            WHEN avg_price_per_1m_usd < 0.5        THEN 'budget'
            WHEN avg_price_per_1m_usd < 5.0        THEN 'mid'
            WHEN avg_price_per_1m_usd < 20.0       THEN 'premium'
            ELSE 'ultra'
        END                                         AS price_tier,

        -- ── Quality tier classification ───────────────────────────────────────
        CASE
            WHEN elo_score IS NULL                 THEN 'unranked'
            WHEN elo_score >= 1250                 THEN 'elite'
            WHEN elo_score >= 1150                 THEN 'high'
            WHEN elo_score >= 1050                 THEN 'medium'
            ELSE 'low'
        END                                         AS quality_tier,

        -- ── Has quality data flag ─────────────────────────────────────────────
        CASE WHEN elo_score IS NOT NULL THEN TRUE ELSE FALSE END
                                                    AS has_quality_data,

        ingestion_date,
        processed_at_utc

    FROM joined
),

-- ── Rank models by value score within each price tier ─────────────────────────
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY COALESCE(value_score, 0) DESC)           AS global_rank,
        RANK() OVER (
            PARTITION BY price_tier
            ORDER BY COALESCE(value_score, 0) DESC
        )                                                               AS rank_in_tier,
        CASE
            WHEN RANK() OVER (ORDER BY COALESCE(value_score, 0) DESC) <= 10
            THEN TRUE ELSE FALSE
        END                                                             AS is_top10_value

    FROM scored
)

SELECT * FROM ranked
ORDER BY global_rank ASC