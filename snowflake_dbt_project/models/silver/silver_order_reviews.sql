select
    review_id,
    order_id,
    coalesce(review_score, 0) as review_score,
    coalesce(review_comment_title, 'No title') as review_title,
    coalesce(review_comment_message, 'No Comment') as review_comment,
    date(review_creation_date) as review_creation_date,
    review_answer_timestamp,
    insert_dt
from {{ ref('bronze_order_reviews') }}