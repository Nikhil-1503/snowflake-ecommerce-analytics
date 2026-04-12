{{ config(
    materialized='incremental',
    unique_key='order_id || order_item_id',
    incremental_strategy='merge'
) }}

select *
from {{ ref('bronze_order_items') }}

{{ incremental_filter('insert_dt') }}