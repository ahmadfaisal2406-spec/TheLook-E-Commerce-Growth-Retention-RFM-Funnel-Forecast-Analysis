-- ============================================================
-- OPTIONAL: RFM Customer Segmentation
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   Segment customers based on recency, frequency, and monetary value.
-- ============================================================

WITH valid_order_items AS (
  SELECT
    user_id,
    order_id,
    DATE(created_at) AS order_date,
    sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

analysis_date AS (
  SELECT DATE_ADD(MAX(order_date), INTERVAL 1 DAY) AS snapshot_date
  FROM valid_order_items
),

customer_rfm AS (
  SELECT
    v.user_id,
    DATE_DIFF(a.snapshot_date, MAX(v.order_date), DAY) AS recency_days,
    COUNT(DISTINCT v.order_id) AS frequency_orders,
    ROUND(SUM(v.sale_price), 2) AS monetary_value
  FROM valid_order_items v
  CROSS JOIN analysis_date a
  GROUP BY v.user_id, a.snapshot_date
),

rfm_score AS (
  SELECT
    user_id,
    recency_days,
    frequency_orders,
    monetary_value,

    -- Lower recency is better, so ordering is ASC.
    NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,

    -- Higher frequency and monetary value are better.
    NTILE(5) OVER (ORDER BY frequency_orders ASC) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value ASC) AS monetary_score
  FROM customer_rfm
),

rfm_segment AS (
  SELECT
    *,
    recency_score + frequency_score + monetary_score AS total_rfm_score,
    CASE
      WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
      WHEN recency_score >= 4 AND frequency_score >= 3 THEN 'Loyal Customers'
      WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New / Promising'
      WHEN recency_score BETWEEN 2 AND 3 AND frequency_score >= 3 THEN 'Potential Loyalists'
      WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
      WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Dormant'
      ELSE 'Regular Customers'
    END AS customer_segment
  FROM rfm_score
)

SELECT
  customer_segment,
  COUNT(DISTINCT user_id) AS total_customers,
  ROUND(AVG(recency_days), 2) AS avg_recency_days,
  ROUND(AVG(frequency_orders), 2) AS avg_frequency_orders,
  ROUND(AVG(monetary_value), 2) AS avg_monetary_value,
  ROUND(SUM(monetary_value), 2) AS total_monetary_value
FROM rfm_segment
GROUP BY customer_segment
ORDER BY total_monetary_value DESC;
