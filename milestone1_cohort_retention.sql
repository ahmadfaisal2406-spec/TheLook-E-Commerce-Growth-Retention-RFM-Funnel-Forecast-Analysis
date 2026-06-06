-- ============================================
-- MILESTONE 1: Cohort Retention Analysis
-- Dataset: bigquery-public-data.thelook_ecommerce
-- ============================================
-- KENAPA QUERY INI:
-- GMV yang naik bisa menipu. Bisnis bisa terlihat tumbuh
-- padahal sebenarnya "bocor" — terus-terusan cari customer baru
-- karena customer lama kabur semua.
-- Cohort analysis menjawab pertanyaan yang lebih jujur:
-- "Dari customer yang masuk bulan ini, berapa yang masih beli
-- 1 bulan, 3 bulan, 6 bulan ke depan?"
-- Ini metrik yang paling diperhatikan investor dan C-level
-- karena biaya akuisisi customer baru 5-7x lebih mahal
-- dari mempertahankan yang lama.
-- ============================================

-- CTE 1: user_cohort
-- Kenapa MIN(created_at):
-- Setiap user hanya punya SATU cohort bulan seumur hidupnya —
-- yaitu bulan pertama kali mereka bertransaksi.
-- MIN(created_at) per user_id mengambil transaksi pertama itu.
-- DATE_TRUNC ke MONTH supaya semua user yang beli
-- di bulan yang sama masuk ke cohort yang sama.
-- Kenapa tidak pakai tabel users langsung:
-- Tidak semua user di tabel users pernah beli.
-- Cohort analysis hanya relevan untuk user yang pernah transaksi.
WITH user_cohort AS (
  SELECT
    user_id,
    DATE_TRUNC(MIN(DATE(created_at)), MONTH) AS cohort_month
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY user_id
),

-- CTE 2: user_activities
-- Kenapa GROUP BY user_id + purchase_month:
-- Kita hanya perlu tahu apakah user aktif di bulan tersebut,
-- bukan berapa kali mereka beli. Satu user yang beli 5x
-- di bulan yang sama tetap dihitung sebagai 1 user aktif.
-- Ini mencegah double-counting yang akan menggelembungkan angka retensi.
user_activities AS (
  SELECT
    user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS purchase_month
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY user_id, purchase_month
),

-- CTE 3: cohort_retention
-- Kenapa DATE_DIFF:
-- DATE_DIFF menghitung jarak bulan antara cohort_month dan purchase_month.
-- month_number = 0 berarti bulan pertama user beli (bulan masuk cohort)
-- month_number = 1 berarti bulan berikutnya, dst.
-- Ini yang membentuk "koordinat" untuk setiap sel di heatmap retensi.
cohort_retention AS (
  SELECT
    c.cohort_month,
    DATE_DIFF(a.purchase_month, c.cohort_month, MONTH) AS month_number,
    COUNT(DISTINCT a.user_id) AS active_users
  FROM user_cohort c
  JOIN user_activities a ON c.user_id = a.user_id
  GROUP BY c.cohort_month, month_number
),

-- CTE 4: cohort_size
-- Kenapa WHERE month_number = 0:
-- month_number = 0 adalah bulan pertama — semua user pasti aktif
-- di bulan mereka pertama beli. Jadi ini adalah ukuran cohort awal.
-- Kenapa ini penting: penyebut (denominator) untuk menghitung
-- persentase retensi harus TETAP di angka cohort awal,
-- bukan berubah tiap bulan. Kalau penyebutnya berubah,
-- angka retensi antar cohort tidak bisa dibandingkan.
cohort_size AS (
  SELECT
    cohort_month,
    active_users AS cohort_size
  FROM cohort_retention
  WHERE month_number = 0
),

-- CTE 5: retention_rate
-- Kenapa SAFE_DIVIDE:
-- Menghindari error division by zero kalau ada cohort_size = 0
-- (meski seharusnya tidak ada, tapi defensive programming
-- adalah kebiasaan baik untuk data produksi).
retention_rate AS (
  SELECT
    r.cohort_month,
    r.month_number,
    SAFE_DIVIDE(r.active_users, s.cohort_size) * 100 AS retention_percentage
  FROM cohort_retention r
  JOIN cohort_size s ON r.cohort_month = s.cohort_month
)

-- FINAL SELECT — Format Long
-- Kenapa format long bukan pivot (wide):
-- Looker Studio membutuhkan format flat/long untuk membaca data.
-- Format wide (kolom Month_0, Month_1, ... Month_24) harus ditulis
-- manual dan tidak fleksibel kalau jumlah bulannya berubah.
-- Format long ini juga langsung bisa dipakai di Python
-- dengan pandas.pivot_table() untuk membuat heatmap.
-- Filter cohort_month >= 2021:
-- Cohort sebelum 2021 terlalu kecil (< 20 user) sehingga
-- satu user yang balik beli sudah mengubah retensi 5-10%.
-- Ini tidak mencerminkan pola bisnis yang real.
SELECT
  cohort_month,
  month_number,
  ROUND(retention_percentage, 2) AS retention_percentage
FROM retention_rate
WHERE cohort_month >= '2021-01-01'
ORDER BY cohort_month ASC, month_number ASC;
