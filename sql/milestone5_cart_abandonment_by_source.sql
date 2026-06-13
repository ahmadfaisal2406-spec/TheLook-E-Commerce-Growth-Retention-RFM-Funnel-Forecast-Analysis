-- ============================================================
-- Milestone 5.2: Cart Abandonment Segmentation by Traffic Source
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   Identify traffic sources with the highest cart abandonment rate
--   using ordered product -> cart -> purchase funnel logic.
-- ============================================================

WITH session_first_source AS (
  SELECT
    session_id,
    traffic_source
  FROM (
    SELECT
      session_id,
      traffic_source,
      created_at,
      ROW_NUMBER() OVER (
        PARTITION BY session_id
        ORDER BY created_at ASC
      ) AS rn
    FROM `bigquery-public-data.thelook_ecommerce.events`
    WHERE session_id IS NOT NULL
      AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
  )
  WHERE rn = 1
),

session_product AS (
  SELECT
    session_id,
    MIN(created_at) AS first_product_at
  FROM `bigquery-public-data.thelook_ecommerce.events`
  WHERE event_type = 'product'
    AND session_id IS NOT NULL
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
  GROUP BY session_id
),

session_cart AS (
  SELECT
    p.session_id,
    MIN(e.created_at) AS first_cart_at
  FROM session_product p
  JOIN `bigquery-public-data.thelook_ecommerce.events` e
    ON p.session_id = e.session_id
   AND e.event_type = 'cart'
   AND e.created_at >= p.first_product_at
   AND DATE(e.created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
  GROUP BY p.session_id
),

session_purchase AS (
  SELECT
    c.session_id,
    MIN(e.created_at) AS first_purchase_at
  FROM session_cart c
  JOIN `bigquery-public-data.thelook_ecommerce.events` e
    ON c.session_id = e.session_id
   AND e.event_type = 'purchase'
   AND e.created_at >= c.first_cart_at
   AND DATE(e.created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
  GROUP BY c.session_id
),

session_funnel AS (
  SELECT
    p.session_id,
    COALESCE(s.traffic_source, 'Unknown') AS traffic_source,
    1 AS hit_product,
    CASE WHEN c.first_cart_at IS NOT NULL THEN 1 ELSE 0 END AS hit_cart,
    CASE WHEN pr.first_purchase_at IS NOT NULL THEN 1 ELSE 0 END AS hit_purchase
  FROM session_product p
  LEFT JOIN session_first_source s
    ON p.session_id = s.session_id
  LEFT JOIN session_cart c
    ON p.session_id = c.session_id
  LEFT JOIN session_purchase pr
    ON p.session_id = pr.session_id
),

traffic_source_funnel AS (
  SELECT
    traffic_source,
    COUNTIF(hit_product = 1) AS product_sessions,
    COUNTIF(hit_product = 1 AND hit_cart = 1) AS cart_sessions,
    COUNTIF(hit_product = 1 AND hit_cart = 1 AND hit_purchase = 1) AS purchase_sessions,
    COUNTIF(hit_product = 1 AND hit_cart = 0) AS product_view_abandonment_sessions,
    COUNTIF(hit_product = 1 AND hit_cart = 1 AND hit_purchase = 0) AS cart_abandonment_sessions
  FROM session_funnel
  GROUP BY traffic_source
)

SELECT
  traffic_source,
  product_sessions,
  cart_sessions,
  purchase_sessions,
  product_view_abandonment_sessions,
  cart_abandonment_sessions,

  ROUND(SAFE_DIVIDE(cart_sessions, product_sessions) * 100, 2) AS product_to_cart_rate_pct,
  ROUND(SAFE_DIVIDE(purchase_sessions, cart_sessions) * 100, 2) AS cart_to_purchase_rate_pct,
  ROUND(SAFE_DIVIDE(purchase_sessions, product_sessions) * 100, 2) AS product_to_purchase_rate_pct,

  ROUND(SAFE_DIVIDE(product_view_abandonment_sessions, product_sessions) * 100, 2) AS product_view_abandonment_rate_pct,
  ROUND(SAFE_DIVIDE(cart_abandonment_sessions, cart_sessions) * 100, 2) AS cart_abandonment_rate_pct
FROM traffic_source_funnel
WHERE product_sessions > 0
ORDER BY cart_abandonment_rate_pct DESC;
