{{ config(
    materialized='table'
) }}

select
    upper(trim(product_category_name)) as product_category_name,
    upper(trim(product_category_name_english)) as category_english,
    insert_dt
from {{ ref('bronze_category_translation') }}