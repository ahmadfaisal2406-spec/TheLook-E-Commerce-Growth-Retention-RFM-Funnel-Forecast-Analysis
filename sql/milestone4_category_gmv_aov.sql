-- ============================================================
-- Milestone 4.1: Category-level GMV and AOV Analysis
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   Identify product categories with the highest GMV, buyers,
--   orders, AOV, GMV per buyer, GMV contribution, and ranking.
-- ============================================================

WITH valid_order_items AS (
  SELECT
    oi.order_id,
    oi.user_id,
    oi.product_id,
    oi.sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
    AND DATE(oi.created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

category_summary AS (
  SELECT
    COALESCE(p.category, 'Unknown') AS category,
    COALESCE(p.department, 'Unknown') AS department,
    COUNT(DISTINCT v.order_id) AS total_orders,
    COUNT(DISTINCT v.user_id) AS unique_buyers,
    ROUND(SUM(v.sale_price), 2) AS total_gmv,
    ROUND(SAFE_DIVIDE(SUM(v.sale_price), COUNT(DISTINCT v.order_id)), 2) AS avg_order_value,
    ROUND(SAFE_DIVIDE(SUM(v.sale_price), COUNT(DISTINCT v.user_id)), 2) AS gmv_per_buyer
  FROM valid_order_items v
  LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` p
    ON v.product_id = p.id
  GROUP BY 1, 2
)

SELECT
  category,
  department,
  total_orders,
  unique_buyers,
  total_gmv,
  avg_order_value,
  gmv_per_buyer,
  ROUND(SAFE_DIVIDE(total_gmv, SUM(total_gmv) OVER()) * 100, 2) AS gmv_contribution_pct,
  RANK() OVER (ORDER BY total_gmv DESC) AS gmv_rank,
  RANK() OVER (ORDER BY avg_order_value DESC) AS aov_rank,
  RANK() OVER (ORDER BY unique_buyers DESC) AS buyer_rank
FROM category_summary
ORDER BY total_gmv DESC;
