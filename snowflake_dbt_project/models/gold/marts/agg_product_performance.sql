{{ config(materialized='table') }}

WITH product_sales AS (

    SELECT
        oi.product_id,
        oi.order_id,
        oi.price,
        oi.freight_value,
        fo.avg_review_score

    FROM {{ ref('silver_order_items') }} oi
    JOIN {{ ref('fact_orders') }} fo
        ON oi.order_id = fo.order_id
)

SELECT
    product_id,

    COUNT(DISTINCT order_id) AS total_orders,
    SUM(price) AS total_revenue,
    AVG(price) AS avg_price,

    -- Rating KPI
    AVG(avg_review_score) AS avg_product_rating,

    -- Ranking
    RANK() OVER (ORDER BY SUM(price) DESC) AS revenue_rank

FROM product_sales
GROUP BY 1