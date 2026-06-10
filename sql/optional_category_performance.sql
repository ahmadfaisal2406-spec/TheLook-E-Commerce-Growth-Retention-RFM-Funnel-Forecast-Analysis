-- ============================================================
-- OPTIONAL: Category Performance Analysis
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   Identify product categories with the highest GMV, buyers, orders, and AOV.
-- ============================================================

WITH valid_order_items AS (
  SELECT
    oi.order_id,
    oi.user_id,
    oi.product_id,
    oi.sale_price,
    DATE_TRUNC(DATE(oi.created_at), MONTH) AS order_month
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
    AND DATE(oi.created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
)

SELECT
  p.category,
  p.department,
  COUNT(DISTINCT v.order_id) AS total_orders,
  COUNT(DISTINCT v.user_id) AS unique_buyers,
  ROUND(SUM(v.sale_price), 2) AS total_gmv,
  ROUND(SAFE_DIVIDE(SUM(v.sale_price), COUNT(DISTINCT v.order_id)), 2) AS avg_order_value,
  ROUND(SAFE_DIVIDE(SUM(v.sale_price), COUNT(DISTINCT v.user_id)), 2) AS gmv_per_buyer
FROM valid_order_items v
LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` p
  ON v.product_id = p.id
GROUP BY p.category, p.department
ORDER BY total_gmv DESC;
