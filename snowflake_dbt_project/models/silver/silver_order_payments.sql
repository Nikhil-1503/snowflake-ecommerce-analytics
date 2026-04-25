select
    order_id,
    payment_sequential,
    upper(payment_type) as payment_type,
    payment_value,
    insert_dt
from {{ ref('bronze_order_payments') }}