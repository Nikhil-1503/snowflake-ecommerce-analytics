WITH base AS (
    SELECT
        geolocation_zip_code AS zip_code,
        UPPER(TRIM(geolocation_city)) AS city,
        UPPER(TRIM(geolocation_state)) AS state,
        latitude,
        longitude
    FROM {{ ref('silver_geolocation') }}
),

aggregated AS (
    SELECT
        zip_code,
        ANY_VALUE(city) AS city,
        ANY_VALUE(state) AS state,
        AVG(latitude) AS latitude,
        AVG(longitude) AS longitude
    FROM base
    GROUP BY zip_code
),

enriched AS (
    SELECT
        *,
        CASE
            WHEN state IN ('SP','RJ','MG','ES') THEN 'Southeast'
            WHEN state IN ('RS','SC','PR') THEN 'South'
            WHEN state IN ('BA','PE','CE','PB','RN','AL','SE','MA','PI') THEN 'Northeast'
            WHEN state IN ('DF','GO','MT','MS') THEN 'Central-West'
            WHEN state IN ('AM','PA','AC','RO','RR','AP','TO') THEN 'North'
            ELSE 'Unknown'
        END AS region,
        'Brazil' AS country
    FROM aggregated
),

final AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY zip_code) AS geolocation_id,
        *
    FROM enriched
)

SELECT * FROM final