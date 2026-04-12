{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}

select *
from {{ ref('bronze_orders') }}

{{ incremental_filter('insert_dt') }}