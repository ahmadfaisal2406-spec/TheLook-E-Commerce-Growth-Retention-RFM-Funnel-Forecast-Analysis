-- ============================================================
-- MILESTONE 4.2: New vs Returning Buyer GMV Contribution
-- Dataset: bigquery-public-data.thelook_ecommerce
-- ============================================================
-- KENAPA QUERY INI:
-- GMV yang naik belum tentu berasal dari bisnis yang sehat.
-- Bisa saja GMV naik karena perusahaan terus mendapatkan pembeli baru,
-- tetapi pembeli lama tidak pernah kembali.
--
-- Analisis New vs Returning Buyer menjawab pertanyaan penting:
-- "GMV bulanan lebih banyak berasal dari pembeli baru
-- atau dari pembeli lama yang kembali membeli?"
--
-- Ini penting karena pertumbuhan yang terlalu bergantung pada New Buyer
-- biasanya lebih mahal dan kurang efisien dalam jangka panjang.
-- Sebaliknya, kontribusi Returning Buyer yang meningkat menunjukkan
-- adanya repeat purchase dan potensi loyalitas pelanggan.
--
-- Query ini membantu stakeholder membedakan dua sumber pertumbuhan:
-- 1. Akuisisi pelanggan baru.
-- 2. Retensi dan pembelian ulang pelanggan lama.
--
-- Dengan analisis ini, bisnis bisa menilai apakah strategi pertumbuhan
-- masih acquisition-heavy atau sudah mulai ditopang oleh customer retention.
-- ============================================================


-- CTE 1: valid_order_items
-- Kenapa mulai dari order_items:
-- GMV dihitung dari level item karena satu order bisa berisi lebih dari satu produk.
-- Jika hanya memakai tabel orders, nilai GMV per item tidak bisa dihitung
-- secara detail.
--
-- Kenapa DATE_TRUNC ke MONTH:
-- Analisis ini dilakukan pada level bulanan.
-- DATE_TRUNC(DATE(created_at), MONTH) mengubah setiap tanggal transaksi
-- menjadi bulan transaksi.
--
-- Contoh:
-- 2025-03-10 menjadi 2025-03-01.
-- 2025-03-25 juga menjadi 2025-03-01.
-- Jadi semua transaksi pada bulan yang sama dapat dikelompokkan bersama.
--
-- Kenapa mengambil order_id:
-- order_id dipakai untuk menghitung total order unik.
-- Karena data berasal dari order_items, satu order bisa muncul beberapa kali.
-- COUNT(DISTINCT order_id) mencegah order yang sama dihitung berulang.
--
-- Kenapa mengambil user_id:
-- user_id dipakai untuk mengidentifikasi pembeli.
-- Kolom ini menjadi dasar untuk menentukan apakah pembeli termasuk
-- New Buyer atau Returning Buyer.
--
-- Kenapa mengambil sale_price:
-- sale_price digunakan sebagai proxy GMV.
-- Karena dataset tidak mencakup voucher, shipping fee, platform subsidy,
-- seller commission, dan contribution margin, maka GMV di sini dibaca
-- sebagai total nilai penjualan item valid.
--
-- Kenapa filter status Cancelled dan Returned:
-- Order yang dibatalkan atau dikembalikan tidak boleh dihitung
-- sebagai transaksi valid.
-- Jika tetap dihitung, GMV akan terlihat lebih tinggi daripada
-- performa bisnis yang sebenarnya.
--
-- Kenapa menghapus bulan berjalan:
-- DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
-- digunakan agar bulan berjalan tidak masuk ke analisis.
-- Bulan berjalan belum lengkap, sehingga bisa menciptakan penurunan palsu.
-- Misalnya, jika data baru sampai tanggal 6, GMV bulan tersebut pasti
-- terlihat rendah, padahal bulan belum selesai.
WITH valid_order_items AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month,
    order_id,
    user_id,
    sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),


-- CTE 2: first_purchase
-- Kenapa mencari MIN(order_month):
-- Setiap user hanya punya satu bulan pembelian pertama.
-- MIN(order_month) mengambil bulan pertama kali user melakukan transaksi valid.
--
-- Bulan pertama ini digunakan sebagai patokan untuk menentukan buyer type.
--
-- Jika order_month sama dengan first_purchase_month,
-- maka user diklasifikasikan sebagai New Buyer.
--
-- Jika order_month lebih besar daripada first_purchase_month,
-- maka user diklasifikasikan sebagai Returning Buyer.
--
-- Kenapa memakai valid_order_items:
-- Definisi pembelian pertama harus konsisten dengan transaksi valid.
-- Jadi order yang Cancelled dan Returned tidak boleh memengaruhi
-- status pembeli pertama.
first_purchase AS (
  SELECT
    user_id,
    MIN(order_month) AS first_purchase_month
  FROM valid_order_items
  GROUP BY user_id
),


-- CTE 3: buyer_type_gmv
-- Kenapa JOIN dengan first_purchase:
-- Setiap transaksi bulanan perlu dibandingkan dengan bulan pembelian pertama user.
-- Dari perbandingan ini, kita bisa menentukan apakah transaksi pada bulan tersebut
-- berasal dari New Buyer atau Returning Buyer.
--
-- Kenapa CASE WHEN v.order_month = f.first_purchase_month:
-- Jika bulan transaksi sama dengan bulan pembelian pertama,
-- maka user dianggap New Buyer pada bulan tersebut.
--
-- Kenapa ELSE Returning Buyer:
-- Jika user sudah pernah membeli sebelum bulan transaksi,
-- maka user masuk kategori Returning Buyer.
--
-- Catatan penting:
-- Definisi ini adalah monthly buyer classification.
-- Artinya, jika user pertama kali membeli pada 5 Januari,
-- lalu membeli lagi pada 20 Januari, transaksi kedua masih masuk New Buyer
-- karena masih berada dalam bulan pembelian pertama.
--
-- Jika ingin klasifikasi order-level, logikanya harus diubah dengan timestamp
-- transaksi pertama, bukan hanya bulan pertama.
--
-- Kenapa menghitung unique_buyers:
-- unique_buyers menunjukkan jumlah pembeli unik pada setiap bulan
-- dan buyer type.
-- Ini membantu melihat apakah pertumbuhan didorong oleh banyak pembeli baru
-- atau oleh pembeli lama yang kembali.
--
-- Kenapa menghitung total_orders:
-- total_orders menunjukkan jumlah order unik dari masing-masing buyer type.
-- Ini berguna untuk membaca volume transaksi.
--
-- Kenapa menghitung total_gmv:
-- total_gmv menunjukkan kontribusi nilai penjualan dari New Buyer
-- dan Returning Buyer pada setiap bulan.
-- Ini adalah metrik utama dalam analisis kontribusi GMV.
buyer_type_gmv AS (
  SELECT
    v.order_month,
    CASE
      WHEN v.order_month = f.first_purchase_month THEN 'New Buyer'
      ELSE 'Returning Buyer'
    END AS buyer_type,
    COUNT(DISTINCT v.user_id) AS unique_buyers,
    COUNT(DISTINCT v.order_id) AS total_orders,
    ROUND(SUM(v.sale_price), 2) AS total_gmv
  FROM valid_order_items v
  JOIN first_purchase f
    ON v.user_id = f.user_id
  GROUP BY v.order_month, buyer_type
)


-- FINAL SELECT
-- Kenapa menampilkan order_month:
-- order_month menjadi dimensi waktu utama.
-- Dashboard dapat menampilkan tren kontribusi New Buyer dan Returning Buyer
-- dari bulan ke bulan.
--
-- Kenapa menampilkan buyer_type:
-- buyer_type membagi performa bulanan menjadi dua kelompok:
-- New Buyer dan Returning Buyer.
--
-- Kenapa menampilkan unique_buyers:
-- Metrik ini menunjukkan jumlah pembeli unik per buyer type.
-- Jika New Buyer terus tinggi, bisnis kuat dalam akuisisi.
-- Jika Returning Buyer meningkat, bisnis mulai menunjukkan repeat purchase.
--
-- Kenapa menampilkan total_orders:
-- total_orders menunjukkan volume transaksi.
-- Ini membantu membedakan apakah GMV naik karena lebih banyak order
-- atau karena nilai order lebih besar.
--
-- Kenapa menampilkan total_gmv:
-- total_gmv menunjukkan kontribusi penjualan dari masing-masing buyer type.
-- Ini adalah metrik utama untuk melihat sumber pertumbuhan bisnis.
--
-- Kenapa menghitung avg_order_value:
-- AOV = total_gmv / total_orders.
-- Metrik ini menunjukkan rata-rata nilai transaksi per order.
--
-- Jika AOV Returning Buyer lebih tinggi,
-- pembeli lama cenderung membeli dengan nilai order lebih besar.
--
-- Jika AOV New Buyer lebih tinggi,
-- kemungkinan campaign akuisisi menarik pembeli dengan basket size besar
-- atau produk pertama yang dibeli bernilai tinggi.
--
-- Kenapa menghitung gmv_per_buyer:
-- GMV per Buyer = total_gmv / unique_buyers.
-- Metrik ini menunjukkan rata-rata kontribusi GMV per pembeli.
--
-- Ini penting karena jumlah buyer yang besar belum tentu berarti
-- kualitas buyer tinggi.
--
-- Contoh:
-- New Buyer bisa lebih banyak secara jumlah,
-- tetapi Returning Buyer bisa memiliki GMV per buyer lebih tinggi.
--
-- Kenapa menghitung monthly_gmv_contribution_pct:
-- Metrik ini menunjukkan persentase kontribusi GMV setiap buyer type
-- terhadap total GMV pada bulan yang sama.
--
-- Contoh:
-- Jika Returning Buyer contribution = 60%,
-- artinya 60% GMV bulan tersebut berasal dari pembeli lama.
--
-- Kenapa memakai SUM(total_gmv) OVER (PARTITION BY order_month):
-- Window function ini menghitung total GMV bulanan dari semua buyer type.
-- Karena memakai PARTITION BY order_month, persentase kontribusi dihitung
-- dalam konteks bulan yang sama, bukan terhadap seluruh periode.
--
-- Kenapa memakai SAFE_DIVIDE:
-- SAFE_DIVIDE mencegah error division by zero.
-- Ini penting untuk menjaga query tetap aman jika suatu bulan tidak punya
-- order atau GMV.
--
-- Kenapa ORDER BY order_month ASC, buyer_type:
-- Output disusun kronologis agar mudah dibaca sebagai tren waktu.
-- buyer_type ditambahkan agar New Buyer dan Returning Buyer tersusun rapi
-- dalam setiap bulan.
SELECT
  order_month,
  buyer_type,
  unique_buyers,
  total_orders,
  total_gmv,
  ROUND(SAFE_DIVIDE(total_gmv, total_orders), 2) AS avg_order_value,
  ROUND(SAFE_DIVIDE(total_gmv, unique_buyers), 2) AS gmv_per_buyer,
  ROUND(
    SAFE_DIVIDE(
      total_gmv,
      SUM(total_gmv) OVER (PARTITION BY order_month)
    ) * 100,
    2
  ) AS monthly_gmv_contribution_pct
FROM buyer_type_gmv
ORDER BY order_month ASC, buyer_type;
```
