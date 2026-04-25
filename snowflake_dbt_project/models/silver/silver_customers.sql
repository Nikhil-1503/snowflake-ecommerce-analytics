{{ config(
    materialized='view'
) }}

select
    customer_id,
    customer_unique_id,
    upper(trim(customer_city)) as customer_city,
    upper(trim(customer_state)) as customer_state,
    dbt_valid_from
from {{ ref('customers_snapshot') }}
where dbt_valid_to is null