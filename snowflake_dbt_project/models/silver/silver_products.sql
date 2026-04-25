{{ config(
    materialized='table'
) }}

select
    product_id,
    coalesce(upper(trim(product_category_name)), 'UNKNOWN') as product_category_name,
    product_weight_g as product_weight,
    product_length_cm as product_length,
    product_width_cm as product_width,
    product_height_cm as product_height,
    insert_dt
from {{ ref('bronze_products') }}