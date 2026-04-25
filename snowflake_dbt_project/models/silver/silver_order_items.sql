{{ config(
    materialized='incremental',
    unique_key='order_id || order_item_id',
    incremental_strategy='merge',
    merge_update_columns=[
        'product_id',
        'seller_id',
        'price',
        'freight_value',
        'total_item_value',
        'update_dt'
    ]
) }}

{# select 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date as shipping_limit_ts,
    date(shipping_limit_date) as shipping_limit_date,
    price,
    freight_value,
    (price + freight_value) as total_item_value,
    insert_dt
from {{ ref('bronze_order_items') }}

{{ incremental_filter('insert_dt') }} #}

with source as (

    select *
    from {{ ref('bronze_order_items') }}
    {{ incremental_filter('insert_dt') }}

),

final as (

    select
        s.order_id,
        s.order_item_id,
        s.product_id,
        s.seller_id,
        s.shipping_limit_date as shipping_limit_ts,
        date(s.shipping_limit_date) as shipping_limit_date,
        s.price,
        s.freight_value,
        s.price + s.freight_value as total_item_value,

        -- insert_dt logic
        {% if is_incremental() %}
            coalesce(t.insert_dt, s.insert_dt) as insert_dt,
        {% else %}
            s.insert_dt as insert_dt,
        {% endif %}

        -- update_dt logic
        {% if is_incremental() %}
            case 
                when t.order_id is null then s.insert_dt
                else current_timestamp
            end as update_dt
        {% else %}
            s.insert_dt as update_dt
        {% endif %}

    from source s

    {% if is_incremental() %}
    left join {{ this }} t
        on s.order_id = t.order_id
        and s.order_item_id = t.order_item_id
    {% endif %}
)

select * from final