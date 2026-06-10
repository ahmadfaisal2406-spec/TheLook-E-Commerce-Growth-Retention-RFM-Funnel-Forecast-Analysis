-- ============================================================
-- MILESTONE 3: Monthly GMV Extract for Forecasting
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   Export monthly GMV proxy into Python/Colab for forecasting.
-- ============================================================

SELECT
  DATE_TRUNC(DATE(created_at), MONTH) AS ds,
  ROUND(SUM(sale_price), 2) AS y
FROM `bigquery-public-data.thelook_ecommerce.order_items`
WHERE status NOT IN ('Cancelled', 'Returned')
  AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
GROUP BY ds
ORDER BY ds;
