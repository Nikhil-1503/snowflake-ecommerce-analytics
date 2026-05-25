{{ config(materialized='table') }}

WITH base AS (

    SELECT
        customer_id,
        order_id,
        order_purchase_timestamp,
        total_payment_value

    FROM {{ ref('fact_orders') }}
    WHERE lower(order_status) = 'delivered'   -- completed orders
),

customer_metrics AS (

    SELECT
        customer_id,
        -- Recency
        DATEDIFF(
            day,
            MAX(order_purchase_timestamp),
            (SELECT MAX(order_purchase_timestamp) FROM {{ ref('fact_orders') }})
        ) AS recency_days,

        -- Frequency
        COUNT(DISTINCT order_id) AS frequency,

        -- Monetary
        SUM(total_payment_value) AS monetary

    FROM base
    GROUP BY 1
),

-- Create scores using NTILE (quintiles: 1–5)
rfm_scores AS (

    SELECT
        *,

        -- Recency: lower is better → reverse scoring
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,

        -- Frequency: higher is better
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,

        -- Monetary: higher is better
        NTILE(5) OVER (ORDER BY monetary DESC) AS m_score

    FROM customer_metrics
),

rfm_combined AS (

    SELECT
        *,

        -- Combine scores
        (0.5 * r_score + 0.3 * f_score + 0.2 * m_score) AS rfm_score

    FROM rfm_scores
),

segments AS (

    SELECT
        *,

        CASE
            WHEN r_score = 5 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Potential loyalist'
            WHEN r_score = 3 AND f_score = 3 THEN 'Need attention'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At risk'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
            ELSE 'Others'
        END AS customer_segment

    FROM rfm_combined
)

SELECT * FROM segments