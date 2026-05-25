{{ config(materialized='table') }}

WITH customer_orders AS (

    SELECT
        customer_id,
        order_id,
        order_purchase_timestamp,
        total_payment_value

    FROM {{ ref('fact_orders') }}
),

customer_agg AS (

    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_payment_value) AS total_spent,
        AVG(total_payment_value) AS avg_order_value,

        MIN(order_purchase_timestamp) AS first_order_date,
        MAX(order_purchase_timestamp) AS last_order_date

    FROM customer_orders
    GROUP BY 1
),

customer_retention AS (

    SELECT
        customer_id,

        CASE
            WHEN total_orders > 1 THEN 1
            ELSE 0
        END AS is_repeat_customer

    FROM customer_agg
)

SELECT
    ca.*,
    date(ca.first_order_date) as first_order_date_key,
    date(ca.last_order_date) as last_order_date_key,
    cr.is_repeat_customer,

    -- Customer Lifetime Value
    total_spent AS customer_lifetime_value,

    -- Recency (days since last order)
    DATEDIFF(day, last_order_date, CURRENT_DATE) AS recency_days

FROM customer_agg ca
JOIN customer_retention cr USING(customer_id)