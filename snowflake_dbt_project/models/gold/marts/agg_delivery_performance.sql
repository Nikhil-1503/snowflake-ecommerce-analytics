{{ config(materialized='table') }}

SELECT
    oi.seller_id,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    AVG(fo.delivery_time_days) AS avg_delivery_time,

    SUM(fo.is_late_delivery) * 1.0 / COUNT(*) AS late_delivery_rate,
    -- Seller rating impact
    AVG(fo.avg_review_score) AS avg_seller_rating

FROM {{ ref('silver_order_items') }} oi
JOIN {{ ref('fact_orders') }} fo
    ON oi.order_id = fo.order_id

GROUP BY 1