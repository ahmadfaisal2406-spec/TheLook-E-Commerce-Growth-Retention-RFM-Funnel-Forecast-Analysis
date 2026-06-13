-- ============================================================
-- Milestone 5.3: Product Category Performance and Repeat Purchase Behavior
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   Analyze category performance and identify categories with strong repeat purchase behavior.
-- ============================================================

WITH valid_order_items AS (
  SELECT
    oi.user_id,
    oi.order_id,
    oi.product_id,
    DATE(oi.created_at) AS order_date,
    oi.sale_price,
    COALESCE(p.category, 'Unknown') AS category,
    COALESCE(p.department, 'Unknown') AS department
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` p
    ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
    AND DATE(oi.created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

category_user_behavior AS (
  SELECT
    category,
    department,
    user_id,
    COUNT(DISTINCT order_id) AS user_category_orders,
    ROUND(SUM(sale_price), 2) AS user_category_gmv,
    MIN(order_date) AS first_category_purchase_date,
    MAX(order_date) AS last_category_purchase_date
  FROM valid_order_items
  GROUP BY category, department, user_id
),

category_performance AS (
  SELECT
    category,
    department,
    COUNT(DISTINCT user_id) AS total_buyers,
    COUNT(DISTINCT CASE WHEN user_category_orders >= 2 THEN user_id END) AS repeat_buyers,
    SUM(user_category_orders) AS total_orders,
    ROUND(SUM(user_category_gmv), 2) AS total_gmv,
    ROUND(AVG(user_category_orders), 2) AS avg_orders_per_buyer,
    ROUND(AVG(user_category_gmv), 2) AS avg_gmv_per_buyer
  FROM category_user_behavior
  GROUP BY category, department
),

final_category_metrics AS (
  SELECT
    category,
    department,
    total_buyers,
    repeat_buyers,
    total_orders,
    total_gmv,
    avg_orders_per_buyer,
    avg_gmv_per_buyer,
    ROUND(SAFE_DIVIDE(total_gmv, total_orders), 2) AS avg_order_value,
    ROUND(SAFE_DIVIDE(repeat_buyers, total_buyers) * 100, 2) AS repeat_buyer_rate_pct
  FROM category_performance
)

SELECT
  category,
  department,
  total_buyers,
  repeat_buyers,
  total_orders,
  total_gmv,
  avg_orders_per_buyer,
  avg_gmv_per_buyer,
  avg_order_value,
  repeat_buyer_rate_pct,
  RANK() OVER (ORDER BY total_gmv DESC) AS gmv_rank,
  RANK() OVER (ORDER BY repeat_buyer_rate_pct DESC) AS repeat_rate_rank
FROM final_category_metrics
ORDER BY total_gmv DESC;
