-- ============================================================
-- MILESTONE 4.3: RFM Customer Segmentation
-- Dataset: bigquery-public-data.thelook_ecommerce
-- ============================================================
-- KENAPA QUERY INI:
-- Tidak semua customer punya nilai bisnis yang sama.
-- Ada customer yang baru belanja, sering belanja, dan nilai belanjanya besar.
-- Ada juga customer yang sudah lama tidak aktif, jarang beli,
-- atau hanya pernah membeli satu kali.
--
-- RFM analysis membantu membagi customer berdasarkan tiga dimensi utama:
-- 1. Recency  : seberapa baru customer terakhir membeli.
-- 2. Frequency: seberapa sering customer membeli.
-- 3. Monetary : seberapa besar nilai belanja customer.
--
-- Analisis ini menjawab pertanyaan penting:
-- "Customer mana yang paling bernilai?"
-- "Customer mana yang loyal?"
-- "Customer mana yang mulai berisiko hilang?"
-- "Customer mana yang sudah dormant?"
--
-- Ini penting karena strategi marketing tidak boleh sama untuk semua customer.
-- Champions perlu dipertahankan.
-- Potential Loyalists perlu didorong agar makin sering belanja.
-- At Risk perlu campaign reactivation.
-- Dormant tidak boleh terlalu banyak menyerap budget.
--
-- Query ini membantu stakeholder membuat segmentasi customer
-- yang bisa langsung dipakai untuk CRM, loyalty program,
-- reactivation campaign, dan customer value prioritization.
-- ============================================================


-- CTE 1: valid_order_items
-- Kenapa mulai dari order_items:
-- RFM membutuhkan data transaksi valid di level item.
-- Monetary value dihitung dari SUM(sale_price), sehingga tabel order_items
-- lebih tepat daripada hanya memakai tabel orders.
--
-- Kenapa mengambil user_id:
-- user_id adalah unit utama segmentasi.
-- RFM selalu dihitung per customer, bukan per order atau per produk.
--
-- Kenapa mengambil order_id:
-- order_id dipakai untuk menghitung frequency.
-- Karena data berasal dari order_items, satu order bisa muncul beberapa kali
-- jika berisi lebih dari satu item.
-- COUNT(DISTINCT order_id) mencegah order yang sama dihitung berulang.
--
-- Kenapa mengambil DATE(created_at) sebagai order_date:
-- order_date dipakai untuk menghitung recency.
-- Recency membutuhkan tanggal transaksi terakhir setiap customer.
--
-- Kenapa mengambil sale_price:
-- sale_price dipakai sebagai monetary value.
-- Karena dataset tidak menyediakan margin, voucher cost, shipping fee,
-- platform subsidy, dan seller commission, maka monetary value di sini
-- dibaca sebagai total nilai penjualan item valid.
--
-- Kenapa filter Cancelled dan Returned:
-- Transaksi yang dibatalkan atau dikembalikan tidak boleh dihitung
-- sebagai perilaku pembelian valid.
-- Jika tetap dihitung, customer bisa terlihat lebih aktif atau lebih bernilai
-- daripada kondisi sebenarnya.
--
-- Kenapa menghapus bulan berjalan:
-- DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
-- digunakan agar data bulan berjalan tidak masuk analisis.
-- Bulan berjalan belum lengkap, sehingga bisa membuat customer terlihat
-- lebih pasif atau membuat monetary value bulan terakhir tampak rendah.
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


-- CTE 2: analysis_date
-- Kenapa membuat snapshot_date:
-- Recency harus dihitung dari satu titik waktu acuan.
-- Dalam dataset historis, lebih aman memakai tanggal transaksi terakhir
-- ditambah satu hari daripada memakai CURRENT_DATE().
--
-- Kenapa tidak langsung pakai CURRENT_DATE():
-- Dataset publik belum tentu memiliki data sampai tanggal hari ini.
-- Jika memakai CURRENT_DATE(), semua customer bisa terlihat sangat lama
-- tidak aktif, padahal masalahnya hanya karena data historis tidak sampai
-- hari ini.
--
-- Kenapa DATE_ADD(MAX(order_date), INTERVAL 1 DAY):
-- MAX(order_date) mengambil tanggal transaksi valid terakhir dalam dataset.
-- Ditambah satu hari agar recency minimum menjadi 1 hari,
-- bukan 0 hari.
--
-- Contoh:
-- Jika transaksi terakhir dataset terjadi pada 2026-05-31,
-- maka snapshot_date menjadi 2026-06-01.
analysis_date AS (
  SELECT
    DATE_ADD(MAX(order_date), INTERVAL 1 DAY) AS snapshot_date
  FROM valid_order_items
),


-- CTE 3: customer_rfm
-- Kenapa menghitung RFM per user_id:
-- Segmentasi RFM harus dibuat pada level customer.
-- Setiap customer akan memiliki satu nilai recency, frequency, dan monetary.
--
-- Kenapa CROSS JOIN analysis_date:
-- analysis_date hanya menghasilkan satu baris snapshot_date.
-- CROSS JOIN membuat setiap customer bisa dibandingkan dengan tanggal acuan
-- yang sama.
--
-- Kenapa DATE_DIFF untuk recency_days:
-- Recency dihitung sebagai selisih hari antara snapshot_date
-- dan tanggal transaksi terakhir customer.
--
-- MAX(v.order_date) mengambil tanggal pembelian terakhir customer.
-- Semakin kecil recency_days, semakin baru customer tersebut belanja.
--
-- Contoh:
-- recency_days = 7 berarti customer terakhir belanja 7 hari sebelum snapshot.
-- recency_days = 300 berarti customer sudah lama tidak belanja.
--
-- Kenapa COUNT(DISTINCT order_id) untuk frequency_orders:
-- Frequency mengukur berapa kali customer melakukan order valid.
-- DISTINCT diperlukan karena satu order bisa memiliki beberapa item.
--
-- Kenapa SUM(sale_price) untuk monetary_value:
-- Monetary mengukur total nilai belanja customer.
-- Semakin besar monetary_value, semakin besar kontribusi customer
-- terhadap GMV.
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


-- CTE 4: rfm_score
-- Kenapa memberi skor 1 sampai 5:
-- Nilai asli recency, frequency, dan monetary punya skala yang berbeda.
-- Recency memakai hari, frequency memakai jumlah order,
-- dan monetary memakai nilai uang.
-- Skor 1 sampai 5 membuat ketiganya bisa dibandingkan secara relatif.
--
-- Kenapa memakai NTILE(5):
-- NTILE(5) membagi customer ke dalam lima kelompok relatif.
-- Skor 1 berarti kelompok terendah.
-- Skor 5 berarti kelompok tertinggi.
--
-- Kenapa recency memakai ORDER BY recency_days DESC:
-- Dalam recency, nilai yang lebih kecil lebih baik.
-- Customer yang baru belanja harus mendapatkan skor lebih tinggi.
--
-- Dengan ORDER BY recency_days DESC:
-- customer dengan recency paling besar masuk kelompok awal dan mendapat skor rendah,
-- sedangkan customer dengan recency paling kecil masuk kelompok akhir
-- dan mendapat skor tinggi.
--
-- Kenapa frequency memakai ORDER BY frequency_orders ASC:
-- Frequency yang lebih tinggi lebih baik.
-- Dengan urutan ASC, customer dengan order sedikit mendapat skor rendah,
-- sedangkan customer dengan order banyak mendapat skor tinggi.
--
-- Kenapa monetary memakai ORDER BY monetary_value ASC:
-- Monetary yang lebih tinggi lebih baik.
-- Dengan urutan ASC, customer dengan spending kecil mendapat skor rendah,
-- sedangkan customer dengan spending besar mendapat skor tinggi.
--
-- Catatan penting:
-- Skor NTILE bersifat relatif terhadap distribusi data.
-- Artinya, skor customer bisa berubah jika data customer bertambah
-- atau periode analisis berubah.
rfm_score AS (
  SELECT
    user_id,
    recency_days,
    frequency_orders,
    monetary_value,

    -- Lower recency is better.
    -- DESC gives older customers lower scores and recent customers higher scores.
    NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,

    -- Higher frequency and monetary value are better.
    NTILE(5) OVER (ORDER BY frequency_orders ASC) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value ASC) AS monetary_score
  FROM customer_rfm
),


-- CTE 5: rfm_segment
-- Kenapa menjumlahkan recency_score + frequency_score + monetary_score:
-- total_rfm_score memberikan skor ringkas untuk membaca kualitas customer
-- secara umum.
-- Skor minimum adalah 3 dan skor maksimum adalah 15.
--
-- Namun total score saja tidak cukup.
-- Dua customer bisa punya total score sama, tetapi profilnya berbeda.
--
-- Contoh:
-- Customer A: recency tinggi, frequency rendah, monetary sedang.
-- Customer B: recency rendah, frequency tinggi, monetary sedang.
-- Total score bisa mirip, tetapi strategi bisnisnya berbeda.
--
-- Karena itu, query tetap membuat segment berdasarkan kombinasi skor RFM,
-- bukan hanya total score.
--
-- Kenapa ada segment Champions:
-- Champions adalah customer terbaik.
-- Mereka baru belanja, sering belanja, dan nilai belanjanya tinggi.
-- Segment ini cocok untuk loyalty rewards, VIP campaign, dan early access.
--
-- Kenapa ada segment Loyal Customers:
-- Loyal Customers adalah customer yang masih aktif dan cukup sering membeli.
-- Mereka belum tentu memiliki monetary score tertinggi,
-- tetapi punya sinyal loyalitas yang baik.
--
-- Kenapa ada segment New / Promising:
-- Segment ini berisi customer yang baru belanja,
-- tetapi frekuensinya masih rendah.
-- Mereka perlu onboarding, second-purchase voucher, dan rekomendasi produk.
--
-- Kenapa ada segment Potential Loyalists:
-- Segment ini mulai menunjukkan pola pembelian berulang,
-- tetapi belum sekuat Loyal Customers atau Champions.
-- Mereka cocok untuk campaign yang mendorong repeat purchase.
--
-- Kenapa ada segment At Risk:
-- At Risk adalah customer yang dulu cukup sering membeli,
-- tetapi sudah lama tidak aktif.
-- Segment ini penting karena mereka punya riwayat pembelian,
-- sehingga lebih layak ditargetkan untuk reactivation campaign.
--
-- Kenapa ada segment Dormant:
-- Dormant adalah customer yang sudah lama tidak aktif
-- dan frekuensi belanjanya rendah.
-- Segment ini biasanya tidak menjadi prioritas utama untuk budget besar.
-- Gunakan campaign murah, seperti email automation atau low-cost reminder.
--
-- Kenapa ada segment Regular Customers:
-- Regular Customers adalah customer yang tidak masuk kategori ekstrem.
-- Mereka tetap bisa ditargetkan dengan campaign umum,
-- tetapi tidak seprioritas Champions, Potential Loyalists, atau At Risk.
rfm_segment AS (
  SELECT
    *,
    recency_score + frequency_score + monetary_score AS total_rfm_score,
    CASE
      WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4
        THEN 'Champions'
      WHEN recency_score >= 4 AND frequency_score >= 3
        THEN 'Loyal Customers'
      WHEN recency_score >= 4 AND frequency_score <= 2
        THEN 'New / Promising'
      WHEN recency_score BETWEEN 2 AND 3 AND frequency_score >= 3
        THEN 'Potential Loyalists'
      WHEN recency_score <= 2 AND frequency_score >= 3
        THEN 'At Risk'
      WHEN recency_score <= 2 AND frequency_score <= 2
        THEN 'Dormant'
      ELSE 'Regular Customers'
    END AS customer_segment
  FROM rfm_score
)


-- FINAL SELECT
-- Kenapa output dibuat agregat per customer_segment:
-- Dashboard eksekutif biasanya membutuhkan ringkasan segment,
-- bukan daftar user satu per satu.
-- Output ini langsung bisa dipakai untuk bar chart, ranking table,
-- treemap, atau comparison chart.
--
-- Kenapa menghitung total_customers:
-- total_customers menunjukkan ukuran setiap segment.
-- Ini membantu melihat segment mana yang paling besar secara populasi.
--
-- Kenapa menghitung avg_recency_days:
-- avg_recency_days menunjukkan rata-rata jarak hari sejak transaksi terakhir.
-- Semakin kecil nilainya, semakin aktif segment tersebut.
--
-- Kenapa menghitung avg_frequency_orders:
-- avg_frequency_orders menunjukkan rata-rata jumlah order per customer
-- dalam segment tersebut.
-- Ini membantu melihat seberapa kuat repeat purchase setiap segment.
--
-- Kenapa menghitung avg_monetary_value:
-- avg_monetary_value menunjukkan rata-rata nilai belanja per customer.
-- Ini penting untuk membaca kualitas customer dalam segment.
--
-- Kenapa menghitung total_monetary_value:
-- total_monetary_value menunjukkan total kontribusi GMV dari segment tersebut.
-- Ini metrik utama untuk menentukan prioritas bisnis.
--
-- Segment dengan jumlah customer besar belum tentu paling bernilai.
-- Sebaliknya, segment kecil bisa saja menghasilkan GMV besar.
--
-- Kenapa menghitung avg_total_rfm_score:
-- avg_total_rfm_score menunjukkan kualitas rata-rata segment
-- berdasarkan kombinasi recency, frequency, dan monetary.
--
-- Kenapa GROUP BY customer_segment:
-- Agregasi dilakukan pada level segment agar hasilnya bisa digunakan
-- untuk membaca performa setiap kelompok customer.
--
-- Kenapa ORDER BY total_monetary_value DESC:
-- Output diurutkan berdasarkan segment dengan kontribusi GMV terbesar.
-- Ini membantu stakeholder langsung melihat segment mana yang paling penting
-- secara revenue.
SELECT
  customer_segment,
  COUNT(DISTINCT user_id) AS total_customers,
  ROUND(AVG(recency_days), 2) AS avg_recency_days,
  ROUND(AVG(frequency_orders), 2) AS avg_frequency_orders,
  ROUND(AVG(monetary_value), 2) AS avg_monetary_value,
  ROUND(SUM(monetary_value), 2) AS total_monetary_value,
  ROUND(AVG(total_rfm_score), 2) AS avg_total_rfm_score
FROM rfm_segment
GROUP BY customer_segment
ORDER BY total_monetary_value DESC;
```
