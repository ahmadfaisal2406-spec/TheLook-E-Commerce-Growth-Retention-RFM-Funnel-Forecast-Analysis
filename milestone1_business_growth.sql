-- ============================================
-- MILESTONE 1: Business Growth Analysis
-- Dataset: bigquery-public-data.thelook_ecommerce
-- ============================================
-- KENAPA QUERY INI:
-- Untuk menjawab pertanyaan bisnis paling mendasar:
-- "Apakah bisnis kita tumbuh?" dan "Seberapa sehat pertumbuhannya?"
-- Kita tidak cukup hanya lihat total GMV — kita perlu tahu
-- apakah pertumbuhan datang dari lebih banyak pembeli (volume)
-- atau dari kenaikan harga (AOV). Dua hal yang implikasinya
-- sangat berbeda untuk strategi bisnis.
-- ============================================

-- CTE 1: valid_order_items
-- Kenapa: Hanya hitung transaksi yang benar-benar menghasilkan uang.
-- Order yang Cancelled atau Returned tidak masuk ke GMV
-- karena uangnya dikembalikan ke customer — misleading kalau ikut dihitung.
-- Filter bulan berjalan (< DATE_TRUNC CURRENT_DATE) untuk menghindari
-- incomplete period bias: bulan yang belum selesai akan terlihat
-- seperti penurunan drastis padahal hanya belum lengkap datanya.
WITH valid_order_items AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month,
    order_id,
    user_id,
    sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

-- CTE 2 & 3: date_bounds + month_spine
-- Kenapa: Tanpa ini, bulan yang tidak ada transaksinya akan
-- hilang dari hasil query. Grafik akan lompat dari Januari ke Maret
-- kalau Februari kosong — misleading secara visual.
-- month_spine adalah "kalender paksa" yang memastikan
-- semua bulan tetap muncul meski GMV-nya nol.
date_bounds AS (
  SELECT
    MIN(order_month) AS min_month,
    MAX(order_month) AS max_month
  FROM valid_order_items
),

month_spine AS (
  SELECT month AS order_month
  FROM date_bounds,
  UNNEST(GENERATE_DATE_ARRAY(min_month, max_month, INTERVAL 1 MONTH)) AS month
),

-- CTE 4: monthly_sales
-- Kenapa LEFT JOIN bukan INNER JOIN:
-- Karena month_spine adalah "master kalender" kita.
-- LEFT JOIN memastikan bulan tanpa transaksi tetap muncul
-- dengan nilai 0, bukan hilang dari hasil.
-- COALESCE mengubah NULL menjadi 0 untuk bulan kosong
-- supaya kalkulasi growth rate tidak error.
monthly_sales AS (
  SELECT
    m.order_month,
    COUNT(DISTINCT v.order_id)               AS total_unique_orders,
    ROUND(COALESCE(SUM(v.sale_price), 0), 2) AS total_gmv,
    COUNT(DISTINCT v.user_id)                AS total_unique_buyers
  FROM month_spine m
  LEFT JOIN valid_order_items v ON m.order_month = v.order_month
  GROUP BY m.order_month
),

-- CTE 5: monthly_growth
-- Kenapa LAG() bukan self-join:
-- LAG adalah window function yang mengambil nilai dari baris sebelumnya
-- tanpa perlu JOIN tabel ke dirinya sendiri.
-- Lebih efisien dan lebih mudah dibaca.
-- LAG(total_gmv) OVER (ORDER BY order_month) =
-- "ambil total_gmv dari bulan sebelumnya untuk setiap baris"
monthly_growth AS (
  SELECT
    order_month,
    total_unique_orders,
    total_gmv,
    total_unique_buyers,
    LAG(total_gmv)           OVER (ORDER BY order_month) AS previous_month_gmv,
    LAG(total_unique_orders) OVER (ORDER BY order_month) AS previous_month_orders,
    LAG(total_unique_buyers) OVER (ORDER BY order_month) AS previous_month_buyers
  FROM monthly_sales
)

-- FINAL SELECT
-- Kenapa SAFE_DIVIDE bukan operator / biasa:
-- Baris pertama selalu punya previous_month = NULL,
-- dan bulan kosong punya previous_month = 0.
-- Keduanya menyebabkan division by zero yang menghentikan query.
-- SAFE_DIVIDE mengembalikan NULL alih-alih error — lebih aman
-- untuk data produksi yang tidak bisa kita kontrol sepenuhnya.
SELECT
  order_month,

  -- Volume metrics
  total_unique_orders,
  previous_month_orders,
  ROUND(SAFE_DIVIDE(
    total_unique_orders - previous_month_orders,
    previous_month_orders) * 100, 2)        AS mom_order_growth_percentage,

  -- GMV metrics
  total_gmv,
  previous_month_gmv,
  ROUND(SAFE_DIVIDE(
    total_gmv - previous_month_gmv,
    previous_month_gmv) * 100, 2)           AS mom_gmv_growth_percentage,

  -- Buyer metrics
  total_unique_buyers,
  previous_month_buyers,
  ROUND(SAFE_DIVIDE(
    total_unique_buyers - previous_month_buyers,
    previous_month_buyers) * 100, 2)        AS mom_buyer_growth_percentage,

  -- Efficiency metrics
  -- AOV: apakah pertumbuhan datang dari harga naik atau volume naik?
  ROUND(SAFE_DIVIDE(total_gmv, total_unique_orders), 2) AS avg_order_value,
  -- GMV per buyer: seberapa besar kontribusi tiap pembeli?
  ROUND(SAFE_DIVIDE(total_gmv, total_unique_buyers), 2) AS gmv_per_buyer,
  -- Orders per buyer:
