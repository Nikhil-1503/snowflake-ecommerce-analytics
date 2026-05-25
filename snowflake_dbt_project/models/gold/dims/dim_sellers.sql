{{ config(
    materialized='table'
) }}

with sellers as (

    select distinct

        seller_id,

        INITCAP(lower(replace(seller_city, '_', ' '))) as seller_city,

        upper(trim(seller_state)) as seller_state,

        seller_zip_code_prefix as seller_zip_code,

        current_timestamp as insert_dt

    from {{ ref('bronze_sellers') }}

),

final as (

    select

        seller_id,

        -- Business-friendly seller label
        'S-' ||
        lpad(
            row_number() over (
                order by seller_id
            ),
            5,
            '0'
        ) as seller_label,

        seller_city,

        seller_state,

        -- Useful for visuals
        seller_city || ', ' || seller_state
            as seller_city_state,

        seller_zip_code,

        insert_dt

    from sellers

)

select *
from final