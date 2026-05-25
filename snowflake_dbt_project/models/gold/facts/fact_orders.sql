{{ config(
    materialized='incremental',
    unique_key='order_id'
) }}

WITH order_base AS (

    SELECT
        o.order_id,
        c.customer_unique_id as customer_id,
        o.order_date,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        INITCAP(lower(o.order_status)) as order_status,
        SUM(oi.price) AS total_product_value,
        SUM(oi.freight_value) AS total_freight_value,
        COUNT(oi.order_item_id) AS total_items,
        SUM(oi.total_item_value) AS total_item_value

    FROM {{ ref('silver_orders') }} o
    JOIN {{ ref('silver_customers') }} c
    ON o.customer_id = c.customer_id
    JOIN {{ ref('silver_order_items') }} oi
    ON o.order_id = oi.order_id

    {% if is_incremental() %}
        WHERE o.order_purchase_timestamp > (SELECT MAX(order_purchase_timestamp) FROM {{ this }})
    {% endif %}

    GROUP BY 1,2,3,4,5,6,7
),

payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value
    FROM {{ ref('silver_order_payments') }}
    GROUP BY 1
),

reviews AS (
    SELECT
        order_id,
        ROUND(AVG(review_score),2) AS avg_review_score
    FROM {{ ref('silver_order_reviews') }}
    GROUP BY 1
)

SELECT
    ob.*,

    -- Revenue
    {# total_product_value + total_freight_value AS total_order_value, #}
    p.total_payment_value,

    -- Delivery KPIs
    DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS delivery_time_days,

    CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
        ELSE 0
    END AS is_late_delivery,

    -- Customer Satisfaction
    r.avg_review_score,

    CASE
        WHEN r.avg_review_score >= 4 THEN 'Positive'
        WHEN r.avg_review_score <= 2 THEN 'Negative'
        ELSE 'Neutral'
    END AS review_category

FROM order_base ob
LEFT JOIN payments p ON ob.order_id = p.order_id
LEFT JOIN reviews r ON ob.order_id = r.order_id