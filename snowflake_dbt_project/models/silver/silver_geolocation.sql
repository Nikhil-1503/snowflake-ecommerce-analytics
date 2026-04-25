{{ config(
    materialized='table'
) }}

select distinct
    upper(trim(geolocation_city)) as geolocation_city,
    upper(trim(geolocation_state)) as geolocation_state,
    geolocation_zip_code_prefix as geolocation_zip_code,
    geolocation_lat as latitude,
    geolocation_lng as longitude,
    insert_dt
from {{ ref('bronze_geolocation') }}