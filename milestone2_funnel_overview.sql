-- ============================================
-- MILESTONE 2: Conversion Funnel Overview
-- Dataset: bigquery-public-data.thelook_ecommerce
-- ============================================
-- KENAPA QUERY INI:
-- Tabel orders hanya mencatat transaksi yang sudah selesai.
-- Untuk tahu di mana user kabur SEBELUM beli,
-- kita perlu data clickstream dari tabel events —
-- setiap klik, setiap halaman yang dibuka, dicatat di sini.
-- Funnel analysis menjawab: dari sekian juta sesi,
-- di tahap mana terjadi kebocoran terbesar?
-- Ini yang tim Product pakai untuk prioritisasi perbaikan UI/UX.
-- ============================================

-- CTE 1: session_funnel
-- Kenapa unit analisisnya session, bukan user:
-- Satu user bisa punya banyak sesi dalam sehari.
-- Kalau pakai user sebagai unit, kita tidak bisa tahu
-- di sesi mana mereka kabur — semua sesinya digabung jadi satu.
-- Session lebih granular dan lebih mencerminkan
-- satu "percobaan belanja" yang spesifik.
--
-- Kenapa MAX() bukan COUNT() atau SUM():
-- Kita hanya butuh tahu apakah event terjadi dalam sesi ini (ya/tidak).
-- MAX(CASE WHEN event_type = 'product' THEN 1 ELSE 0 END)
-- menghasilkan 1 kalau event product pernah muncul di sesi ini,
-- 0 kalau tidak — terlepas dari berapa kali event itu muncul.
-- Ini mencegah satu sesi dihitung berkali-kali.
WITH session_funnel AS (
  SELECT
    session_id,
    MAX(CASE WHEN event_type = 'product'  THEN 1 ELSE 0 END) AS hit_product,
    MAX(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS hit_cart,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS hit_purchase
  FROM `bigquery-public-data.thelook_ecommerce.events`
  GROUP BY session_id
),

-- CTE 2: funnel_counts
-- Kenapa strict funnel (kondisi berantai) bukan loose funnel:
-- Strict funnel: sesi hanya masuk ke tahap N kalau
-- tahap 1 sampai N-1 juga sudah dilewati.
-- Loose funnel: sesi dihitung masuk ke tahap N kalau
-- event N pernah muncul, terlepas urutan.
--
-- Strict lebih bermakna untuk e-commerce karena kita ingin
-- tahu di mana user kabur dari ALUR NORMAL, bukan sekadar
-- event mana yang pernah terjadi.
--
-- Kenapa mulai dari product, bukan home:
-- Dari analisis awal, hanya 87K dari 681K sesi yang punya
-- event home. Mayoritas user masuk langsung ke halaman produk
-- (dari iklan, search, atau link langsung).
-- Memulai funnel dari home akan membuang 87% data traffic.
funnel_counts AS (
  SELECT
    COUNTIF(hit_product = 1)                                AS sessions_product,
    COUNTIF(hit_product = 1 AND hit_cart = 1)               AS sessions_cart,
    COUNTIF(hit_product = 1 AND hit_cart = 1
            AND hit_purchase = 1)                           AS sessions_purchase
  FROM session_funnel
),

funnel_long AS (
  SELECT 'Product Page' AS funnel_stage, 1 AS stage_order, sessions_product  AS session_count FROM funnel_counts UNION ALL
  SELECT 'Add to Cart',                  2,                sessions_cart                      FROM funnel_counts UNION ALL
  SELECT 'Purchase',                     3,                sessions_purchase                  FROM funnel_counts
)

-- FINAL SELECT
-- Kenapa tambah kolom pct_of_top dan drop_off_rate_pct:
-- pct_of_top: persentase dari titik masuk (product page = 100%).
-- Ini yang dipakai untuk bar chart funnel di Looker —
-- bar harus proporsional terhadap tahap pertama, bukan nilai absolut.
--
-- drop_off_rate_pct: kebalikan conversion rate.
-- Lebih mudah dikomunikasikan ke stakeholder non-teknis:
-- "58% user kabur di checkout" lebih impactful dari
-- "conversion rate checkout 42%".
--
-- Kenapa MAX(session_count) OVER() bukan hardcode angka:
-- Supaya query tetap benar kalau data berubah.
-- OVER() tanpa PARTITION membuat window mencakup semua baris —
-- jadi MAX selalu mengambil nilai terbesar dari seluruh tabel.
SELECT
  funnel_stage,
  stage_order,
  session_count,
  ROUND(SAFE_DIVIDE(session_count,
        MAX(session_count) OVER()) * 100, 2)                AS pct_of_top,
  ROUND((1 - SAFE_DIVIDE(session_count,
        LAG(session_count) OVER (ORDER BY stage_order))) * 100,
        2)                                                  AS drop_off_rate_pct
FROM funnel_long
ORDER BY stage_order;
