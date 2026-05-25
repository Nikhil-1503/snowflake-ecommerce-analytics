{{ config(materialized='table') }}

SELECT
    DATE(order_purchase_timestamp) AS order_date,

    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_payment_value) AS total_revenue,
    AVG(total_payment_value) AS avg_order_value,

    COUNT(DISTINCT customer_id) AS total_customers,

    -- Running revenue 
    SUM(SUM(total_payment_value)) OVER (
        ORDER BY DATE(order_purchase_timestamp)
    ) AS cumulative_revenue

FROM {{ ref('fact_orders') }}

GROUP BY 1
ORDER BY order_purchase_timestamp