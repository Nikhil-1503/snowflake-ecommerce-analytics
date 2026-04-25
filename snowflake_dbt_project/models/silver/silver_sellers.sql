{{ config(
    materialized='table'
) }}

select
    seller_id,
    upper(trim(seller_city)) as seller_city,
    upper(trim(seller_state)) as seller_state,
    seller_zip_code_prefix as seller_zip_code,
    insert_dt
from {{ ref('bronze_sellers') }}