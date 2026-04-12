{% set city = '%sao%' %}

select * from {{ ref('bronze_customers') }}
where customer_city like '{{city}}'
