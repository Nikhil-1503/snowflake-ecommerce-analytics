{{ config(materialized='table') }}

WITH products AS (

    SELECT
        product_id,
        product_category_name,
        product_weight,
        product_length,
        product_height,
        product_width
    FROM {{ ref('silver_products') }}

),
category_translation AS (

    SELECT
        product_category_name,
        category_english
    FROM {{ ref('silver_category_translation') }}

),

base AS (

    SELECT
        p.product_id,
        UPPER(
            COALESCE(ct.category_english, p.product_category_name)
        ) AS raw_category,

        p.product_weight,
        p.product_length,
        p.product_height,
        p.product_width

    FROM products p
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name

),

cleaned AS (

    SELECT
        product_id,
        CASE
            WHEN raw_category IN ('COSTRUCTION_TOOLS_TOOLS', 'CONSTRUCTION_TOOLS_CONSTRUCTION') THEN 'CONSTRUCTION_TOOLS'
            WHEN raw_category = 'HOME_CONFORT' THEN 'HOME_COMFORT'
            WHEN raw_category = 'FASHIO_FEMALE_CLOTHING' THEN 'FASHION_FEMALE_CLOTHING'
            ELSE raw_category
        END AS clean_category,

        product_weight,
        product_length,
        product_height,
        product_width

    FROM base

),

categories AS (

    SELECT
        {# {{ dbt_utils.generate_surrogate_key(['product_id']) }} AS product_sk, #}
        product_id,

        clean_category,
        CASE

            -- Electronics & Tech
            WHEN clean_category IN (
                'COMPUTERS', 'COMPUTERS_ACCESSORIES', 'ELECTRONICS',
                'TABLETS_PRINTING_IMAGE', 'TELEPHONY', 'FIXED_TELEPHONY',
                'AUDIO', 'CONSOLES_GAMES'
            ) THEN 'TECH & ELECTRONICS'

            -- Home & Furniture
            WHEN clean_category IN (
                'FURNITURE_DECOR', 'FURNITURE_BEDROOM', 'FURNITURE_LIVING_ROOM',
                'OFFICE_FURNITURE', 'BED_BATH_TABLE', 'HOME_APPLIANCES',
                'HOME_APPLIANCES_2', 'HOUSEWARES', 'KITCHEN_DINING_LAUNDRY_GARDEN_FURNITURE',
                'HOME_COMFORT', 'HOME_COMFORT_2', 'MATTRESS_AND_UPHOLSTERY'
            ) THEN 'HOME & LIVING'

            -- Fashion
            WHEN clean_category LIKE 'FASHION%' OR clean_category LIKE 'WATCHES%' 
                OR clean_category LIKE 'LUGGAGE%' THEN 'FASHION & ACCESSORIES'

            -- Beauty & Health
            WHEN clean_category IN (
                'HEALTH_BEAUTY', 'PERFUMERY', 'DIAPERS_AND_HYGIENE'
            ) THEN 'HEALTH & BEAUTY'

            -- Sports & Outdoors
            WHEN clean_category IN (
                'SPORTS_LEISURE', 'GARDEN_TOOLS', 'COSTRUCTION_TOOLS_GARDEN'
            ) THEN 'SPORTS & OUTDOORS'

            -- Books & Media
            WHEN clean_category LIKE 'BOOKS%' OR clean_category IN (
                'CDS_DVDS_MUSICALS', 'MUSIC', 'DVDS_BLU_RAY'
            ) THEN 'MEDIA & BOOKS'

            -- Baby & Kids
            WHEN clean_category IN (
                'BABY', 'TOYS', 'FASHION_CHILDRENS_CLOTHES'
            ) THEN 'BABY & KIDS'

            -- Others
            ELSE 'OTHER'

        END AS category_group,

        product_weight,
        product_length,
        product_height,
        product_width,

        COALESCE(product_length,0) *
        COALESCE(product_height,0) *
        COALESCE(product_width,0) AS product_volume,

        CASE
            WHEN product_weight IS NULL THEN 'Unknown'
            WHEN product_weight < 500 THEN 'Light'
            WHEN product_weight < 2000 THEN 'Medium'
            ELSE 'Heavy'
        END AS weight_category,

        CASE
            WHEN (COALESCE(product_length,0) *
                  COALESCE(product_height,0) *
                  COALESCE(product_width,0)) < 1000 THEN 'Small'
            WHEN (COALESCE(product_length,0) *
                  COALESCE(product_height,0) *
                  COALESCE(product_width,0)) < 5000 THEN 'Medium'
            ELSE 'Large'
        END AS size_category

    FROM cleaned

),

final AS (
    SELECT
        product_id,
        INITCAP(lower(replace(clean_category, '_', ' '))) as clean_category,
        INITCAP(lower(replace(category_group, '_', ' '))) as category_group,
        product_weight,
        product_length,
        product_height,
        product_width,
        product_volume,
        weight_category,
        size_category
        from 
        categories
)

SELECT * FROM final