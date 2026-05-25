{{ config(materialized='table') }}

WITH date_spine AS (

    SELECT 
        DATEADD(day, seq4(), '2015-01-01') AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))  -- ~13 years

),

final AS (

    SELECT
        DATE(date_day) AS date_day,

        -- Basic
        EXTRACT(YEAR FROM date_day) AS year,
        EXTRACT(MONTH FROM date_day) AS month,
        EXTRACT(DAY FROM date_day) AS day,

        -- Names
        TO_CHAR(date_day, 'MMMM') AS month_name,
        TO_CHAR(date_day, 'DY') AS day_name,
        TO_CHAR(date_day, 'Mon YYYY') AS year_month,
        TO_CHAR(date_day, 'YYYYMM') AS year_month_sort,

        -- Week
        EXTRACT(WEEK FROM date_day) AS week_of_year,
        EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,

        -- Quarter
        EXTRACT(QUARTER FROM date_day) AS quarter,

        -- Flags
        CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend,

        -- Year-Month formats
        TO_CHAR(date_day, 'YYYY-MM') AS year_month_num,
        TO_CHAR(date_day, 'YYYYMM') AS year_month_key,

        -- Start/End markers
        DATE_TRUNC('MONTH', date_day) AS month_start_date,
        LAST_DAY(date_day) AS month_end_date

    FROM date_spine

)

SELECT * FROM final