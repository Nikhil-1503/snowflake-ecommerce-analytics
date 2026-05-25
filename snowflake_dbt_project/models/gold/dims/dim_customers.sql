{{ config(materialized='table') }}

WITH base AS (
    SELECT
        c.customer_unique_id,

        ANY_VALUE(UPPER(TRIM(c.customer_city))) AS customer_city,
        ANY_VALUE(UPPER(TRIM(c.customer_state))) AS customer_state,
        ANY_VALUE(c.customer_zip_code_prefix) AS customer_zip_code_prefix

    FROM {{ ref('silver_customers') }} c
    GROUP BY 1
),
geo AS (

    SELECT
        geolocation_zip_code AS zip_code,

        ANY_VALUE(UPPER(TRIM(geolocation_city))) AS geo_city,
        ANY_VALUE(UPPER(TRIM(geolocation_state))) AS geo_state

    FROM {{ ref('silver_geolocation') }}
    GROUP BY 1
),

customer_enriched AS (

    SELECT
        b.customer_unique_id,
        REPLACE(
            REPLACE(
                COALESCE(g.geo_city, b.customer_city),
            'Ã', 'A'), 
        'ã', 'a') 
        AS customer_city,
        COALESCE(g.geo_state, b.customer_state) AS customer_state,
        b.customer_zip_code_prefix

    FROM base b
    LEFT JOIN geo g
        ON b.customer_zip_code_prefix = g.zip_code
),

customer_metrics AS (

    SELECT
        customer_id,  -- = customer_unique_id

        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_payment_value) AS total_spent,
        MIN(order_purchase_timestamp) AS first_order_date,
        MAX(order_purchase_timestamp) AS last_order_date

    FROM {{ ref('fact_orders') }}
    GROUP BY 1
),

rfm AS (

    SELECT
        customer_id,  -- = customer_unique_id
        customer_segment
    FROM {{ ref('agg_customer_rfm') }}
)

SELECT
    ce.customer_unique_id,
    INITCAP(lower(replace(ce.customer_city, '_', ' '))) as customer_city,
    ce.customer_state,
    INITCAP(lower(replace(ce.customer_city, '_', ' '))) || ',' || ce.customer_state as customer_city_state,
    ce.customer_zip_code_prefix,
        CASE
            WHEN ce.customer_state IN ('SP','RJ','MG','ES') THEN 'Southeast'
            WHEN ce.customer_state IN ('RS','SC','PR') THEN 'South'
            WHEN ce.customer_state IN ('BA','PE','CE','PB','RN','AL','SE','MA','PI') THEN 'Northeast'
            WHEN ce.customer_state IN ('DF','GO','MT','MS') THEN 'Central-West'
            WHEN ce.customer_state IN ('AM','PA','AC','RO','RR','AP','TO') THEN 'North'
            ELSE 'Unknown'
        END AS customer_region,

    -- Metrics
    cm.total_orders,
    cm.total_spent,
    cm.first_order_date,
    cm.last_order_date,

    -- Segmentation
    COALESCE(
        INITCAP(LOWER(REPLACE(r.customer_segment, '_', ' '))),
        'Unknown'
    ) AS customer_segment

FROM customer_enriched ce

LEFT JOIN customer_metrics cm
    ON ce.customer_unique_id = cm.customer_id

LEFT JOIN rfm r
    ON ce.customer_unique_id = r.customer_id