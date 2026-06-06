-- ============================================
-- MILESTONE 2: Funnel Breakdown by Traffic Source
-- Dataset: bigquery-public-data.thelook_ecommerce
-- ============================================
-- KENAPA QUERY INI:
-- Angka funnel agregat (57.96% drop-off di checkout) sudah bagus,
-- tapi tidak cukup untuk rekomendasi bisnis yang actionable.
-- Yang perlu diketahui tim Marketing: dari channel mana
-- user yang paling sering sampai beli?
-- Ini membedakan channel yang bagus di volume (Email)
-- dengan channel yang bagus di kualitas (YouTube).
-- Insight ini langsung bisa dipakai untuk keputusan
-- realokasi budget iklan.
-- ============================================

-- CTE 1: session_first_source
-- Kenapa tidak pakai MAX(traffic_source):
-- MAX() pada kolom teks mengambil nilai terbesar secara alfabetis.
-- Kalau satu sesi punya dua event dengan traffic_source berbeda
-- (Email dan YouTube), MAX() akan ambil YouTube — bukan yang relevan.
--
-- Kenapa ambil traffic_source dari event PERTAMA:
-- Event pertama dalam sesi adalah yang membawa user masuk.
-- Itulah yang harus "dikreditkan" sebagai source sesi tersebut.
-- ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY created_at ASC)
-- mengurutkan event dalam tiap sesi dari yang paling awal.
-- WHERE rn = 1 mengambil hanya event pertama.
WITH session_first_source AS (
  SELECT session_id, traffic_source
  FROM (
    SELECT
      session_id,
      traffic_source,
      ROW_NUMBER() OVER (
        PARTITION BY session_id
        ORDER BY created_at ASC
      ) AS rn
    FROM `bigquery-public-data.thelook_ecommerce.events`
  )
  WHERE rn = 1
),

-- CTE 2: session_funnel
-- Kenapa JOIN ke session_first_source, bukan langsung GROUP BY traffic_source:
-- Kita perlu traffic_source dari event pertama (sudah diisolasi di CTE 1),
-- bukan traffic_source dari event manapun dalam sesi.
-- JOIN ini memastikan setiap sesi mendapat satu traffic_source
-- yang konsisten — yang pertama kali membawa user masuk.
session_funnel AS (
  SELECT
    e.session_id,
    s.traffic_source,
    MAX(CASE WHEN e.event_type = 'product'  THEN 1 ELSE 0 END) AS hit_product,
    MAX(CASE WHEN e.event_type = 'cart'     THEN 1 ELSE 0 END) AS hit_cart,
    MAX(CASE WHEN e.event_type = 'purchase' THEN 1 ELSE 0 END) AS hit_purchase
  FROM `bigquery-public-data.thelook_ecommerce.events` e
  JOIN session_first_source s ON e.session_id = s.session_id
  GROUP BY e.session_id, s.traffic_source
)

-- FINAL SELECT
-- Kenapa WHERE hit_product = 1:
-- Kita hanya analisis sesi yang sampai ke halaman produk.
-- Sesi yang tidak pernah lihat produk tidak relevan
-- untuk funnel analysis — mereka mungkin hanya buka halaman
-- utama lalu langsung tutup.
--
-- Kenapa dua metrik conversion yang berbeda:
-- Pct_Product_to_Cart: seberapa bagus channel ini
-- membawa user dari lihat produk ke intent beli.
-- Pct_Cart_to_Purchase: seberapa bagus channel ini
-- menghasilkan user yang benar-benar commit beli.
-- Dua metrik ini bisa bergerak berlawanan —
-- channel dengan Cart rate tinggi belum tentu
-- punya Purchase rate tinggi.
SELECT
  traffic_source                                                   AS Traffic_Source,
  COUNT(*)                                                         AS Sessions,
  COUNTIF(hit_cart = 1)                                            AS Added_to_Cart,
  COUNTIF(hit_cart = 1 AND hit_purchase = 1)                       AS Purchased,
  ROUND(SAFE_DIVIDE(
    COUNTIF(hit_cart = 1),
    COUNT(*)) * 100, 2)                                            AS Pct_Product_to_Cart,
  ROUND(SAFE_DIVIDE(
    COUNTIF(hit_cart = 1 AND hit_purchase = 1),
    COUNTIF(hit_cart = 1)) * 100, 2)                               AS Pct_Cart_to_Purchase
FROM session_funnel
WHERE hit_product = 1
GROUP BY traffic_source
ORDER BY Sessions DESC;
