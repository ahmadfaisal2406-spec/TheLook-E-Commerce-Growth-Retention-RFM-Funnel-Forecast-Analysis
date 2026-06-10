-- ============================================================
-- OPTIONAL: New vs Returning Buyer GMV Contribution
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   Separate monthly GMV from new buyers and returning buyers.
-- ============================================================

WITH valid_order_items AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month,
    order_id,
    user_id,
    sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

first_purchase AS (
  SELECT
    user_id,
    MIN(order_month) AS first_purchase_month
  FROM valid_order_items
  GROUP BY user_id
),

buyer_type_gmv AS (
  SELECT
    v.order_month,
    CASE
      WHEN v.order_month = f.first_purchase_month THEN 'New Buyer'
      ELSE 'Returning Buyer'
    END AS buyer_type,
    COUNT(DISTINCT v.user_id) AS unique_buyers,
    COUNT(DISTINCT v.order_id) AS total_orders,
    ROUND(SUM(v.sale_price), 2) AS total_gmv
  FROM valid_order_items v
  JOIN first_purchase f
    ON v.user_id = f.user_id
  GROUP BY v.order_month, buyer_type
)

SELECT
  order_month,
  buyer_type,
  unique_buyers,
  total_orders,
  total_gmv,
  ROUND(SAFE_DIVIDE(total_gmv, total_orders), 2) AS avg_order_value,
  ROUND(SAFE_DIVIDE(total_gmv, unique_buyers), 2) AS gmv_per_buyer
FROM buyer_type_gmv
ORDER BY order_month, buyer_type;
