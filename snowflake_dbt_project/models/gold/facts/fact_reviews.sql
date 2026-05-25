{{ config(materialized='table') }}
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY review_creation_date DESC
           ) AS rn
    FROM {{ ref('silver_order_reviews') }}
)

SELECT
    review_id,
    order_id,
    review_score,
    review_creation_date,

    -- Derived KPIs
    CASE WHEN review_score >= 4 THEN 1 ELSE 0 END AS is_positive,
    CASE WHEN review_score <= 2 THEN 1 ELSE 0 END AS is_negative,

    -- Sentiment bucket
    CASE
        WHEN review_score = 5 THEN 'Excellent'
        WHEN review_score = 4 THEN 'Good'
        WHEN review_score = 3 THEN 'Average'
        WHEN review_score <= 2 THEN 'Poor'
    END AS sentiment_bucket

FROM ranked
WHERE rn = 1