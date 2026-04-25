{# {{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge',
    merge_update_columns=[
        'customer_id',
        'order_status',
        'order_ts',
        'order_date',
        'order_delivered_carrier_date',
        'order_delivered_customer_date',
        'is_delivered',
        'is_shipped',
        'delivery_date_missing_flag',
        'delivery_days',
        'shipping_days',
        'update_dt'
    ]
) }}

with source as (

    select *
    from {{ ref('bronze_orders') }}
    {{ incremental_filter('insert_dt') }}

),

final as (

    select
        s.order_id,
        s.customer_id,
        s.order_status,

        cast(s.order_purchase_timestamp as timestamp) as order_ts,
        date(s.order_purchase_timestamp) as order_date,

        s.order_delivered_carrier_date,
        s.order_delivered_customer_date,

        -- Business flags (robust)
        case 
            when s.order_status = 'delivered' 
                 or s.order_delivered_customer_date is not null 
            then 1 else 0 
        end as is_delivered,

        case 
            when s.order_delivered_carrier_date is not null 
            then 1 else 0 
        end as is_shipped,

        -- Data quality flag
        case 
            when s.order_status = 'delivered' 
                 and s.order_delivered_customer_date is null 
            then 1 else 0 
        end as delivery_date_missing_flag,

        -- Derived metrics
        case 
            when s.order_delivered_customer_date is not null 
            then datediff(day, s.order_purchase_timestamp, s.order_delivered_customer_date)
        end as delivery_days,

        case 
            when s.order_delivered_carrier_date is not null 
            then datediff(day, s.order_purchase_timestamp, s.order_delivered_carrier_date)
        end as shipping_days,

        -- Preserve insert_dt
        coalesce(t.insert_dt, s.insert_dt) as insert_dt,

        -- Update timestamp logic
        case 
            when t.order_id is null then s.insert_dt
            else current_timestamp
        end as update_dt

    from source s
    left join {{ this }} t
        on s.order_id = t.order_id

)

select * from final #}

{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge',
    merge_update_columns=[
        'customer_id',
        'order_status',
        'order_ts',
        'order_date',
        'order_delivered_carrier_date',
        'order_delivered_customer_date',
        'is_delivered',
        'is_shipped',
        'delivery_date_missing_flag',
        'delivery_days',
        'shipping_days',
        'update_dt'
    ]
) }}

with source as (

    select *
    from {{ ref('bronze_orders') }}
    {{ incremental_filter('insert_dt') }}

),

final as (

    select
        s.order_id,
        s.customer_id,
        s.order_status,

        cast(s.order_purchase_timestamp as timestamp) as order_ts,
        date(s.order_purchase_timestamp) as order_date,

        s.order_delivered_carrier_date,
        s.order_delivered_customer_date,

        -- business flags
        case 
            when s.order_status = 'delivered' 
                 or s.order_delivered_customer_date is not null 
            then 1 else 0 
        end as is_delivered,

        case 
            when s.order_delivered_carrier_date is not null 
            then 1 else 0 
        end as is_shipped,

        -- data quality
        case 
            when s.order_status = 'delivered' 
                 and s.order_delivered_customer_date is null 
            then 1 else 0 
        end as delivery_date_missing_flag,

        -- metrics
        case 
            when s.order_delivered_customer_date is not null 
            then datediff(day, s.order_purchase_timestamp, s.order_delivered_customer_date)
        end as delivery_days,

        case 
            when s.order_delivered_carrier_date is not null 
            then datediff(day, s.order_purchase_timestamp, s.order_delivered_carrier_date)
        end as shipping_days,

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
    {% endif %}

)

select * from final