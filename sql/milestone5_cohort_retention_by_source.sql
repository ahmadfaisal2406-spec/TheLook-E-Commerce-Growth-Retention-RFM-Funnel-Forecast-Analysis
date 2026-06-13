-- ============================================================
-- Milestone 5.1: Cohort Retention by Acquisition Source
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   Measure customer retention by first purchase cohort and acquisition source.
-- ============================================================

WITH user_first_source AS (
  SELECT
    user_id,
    traffic_source AS acquisition_source
  FROM (
    SELECT
      user_id,
      traffic_source,
      created_at,
      ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY created_at ASC
      ) AS rn
    FROM `bigquery-public-data.thelook_ecommerce.events`
    WHERE user_id IS NOT NULL
  )
  WHERE rn = 1
),

user_cohort AS (
  SELECT
    o.user_id,
    DATE_TRUNC(MIN(DATE(o.created_at)), MONTH) AS cohort_month,
    COALESCE(s.acquisition_source, 'Unknown') AS acquisition_source
  FROM `bigquery-public-data.thelook_ecommerce.orders` o
  LEFT JOIN user_first_source s
    ON o.user_id = s.user_id
  WHERE o.status NOT IN ('Cancelled', 'Returned')
    AND DATE(o.created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
  GROUP BY o.user_id, acquisition_source
),

user_activities AS (
  SELECT
    user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS purchase_month
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
  GROUP BY user_id, purchase_month
),

cohort_retention AS (
  SELECT
    c.cohort_month,
    c.acquisition_source,
    DATE_DIFF(a.purchase_month, c.cohort_month, MONTH) AS month_number,
    COUNT(DISTINCT a.user_id) AS active_users
  FROM user_cohort c
  JOIN user_activities a
    ON c.user_id = a.user_id
  GROUP BY c.cohort_month, c.acquisition_source, month_number
),

cohort_size AS (
  SELECT
    cohort_month,
    acquisition_source,
    active_users AS cohort_size
  FROM cohort_retention
  WHERE month_number = 0
)

SELECT
  r.cohort_month,
  r.acquisition_source,
  r.month_number,
  r.active_users,
  s.cohort_size,
  ROUND(SAFE_DIVIDE(r.active_users, s.cohort_size) * 100, 2) AS retention_percentage
FROM cohort_retention r
JOIN cohort_size s
  ON r.cohort_month = s.cohort_month
 AND r.acquisition_source = s.acquisition_source
ORDER BY r.cohort_month ASC, r.acquisition_source ASC, r.month_number ASC;
