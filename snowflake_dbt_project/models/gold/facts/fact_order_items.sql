{{ config(
    materialized='table'
) }}

with order_items as (

    select *
    from {{ ref('silver_order_items') }}

),

order_payments as (

    select
        order_id,
        listagg(distinct payment_type, ', ')
        within group (order by payment_type) as payment_type
    from {{ ref('silver_order_payments') }}
    group by order_id

),

final as (

    select

        -- Degenerate Dimensions
        oi.order_id,
        oi.order_item_id,

        -- Foreign Keys
        oi.product_id,
        oi.seller_id,

        -- Payment
        coalesce(initcap(lower(replace(op.payment_type, '_', ' '))), 'Not Defined') as payment_type,

        -- Measures
        oi.price,
        oi.freight_value,
        oi.total_item_value,

        -- Dates
        oi.shipping_limit_ts,
        oi.shipping_limit_date,

        -- Audit Columns
        oi.insert_dt,
        oi.update_dt

    from order_items oi
    left join order_payments op
        on oi.order_id = op.order_id

)

select *
from final