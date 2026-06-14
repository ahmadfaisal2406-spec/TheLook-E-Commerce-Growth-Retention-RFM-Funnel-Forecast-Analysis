
-- ============================================================
-- MILESTONE 4.1: Category-level GMV and AOV Analysis
-- Dataset: bigquery-public-data.thelook_ecommerce
-- ============================================================
-- KENAPA QUERY INI:
-- GMV total yang naik belum cukup untuk menjelaskan bisnis.
-- Kita perlu tahu kategori produk mana yang benar-benar mendorong
-- revenue, order, dan jumlah buyer.
--
-- Analisis kategori menjawab pertanyaan penting:
-- "Kategori mana yang paling besar kontribusinya terhadap GMV?"
-- "Kategori mana yang punya banyak buyer?"
-- "Kategori mana yang punya nilai order tinggi?"
-- "Kategori mana yang harus diprioritaskan untuk campaign,
-- bundling, cross-selling, atau inventory planning?"
--
-- Ini penting karena setiap kategori punya peran bisnis berbeda.
-- Ada kategori yang kuat secara revenue, ada yang kuat secara volume order,
-- dan ada yang kuat secara nilai transaksi per order.
--
-- Contoh:
-- Kategori dengan GMV tinggi cocok untuk strategi revenue growth.
-- Kategori dengan order tinggi cocok untuk strategi repeat purchase.
-- Kategori dengan AOV tinggi cocok untuk strategi premium positioning.
--
-- Query ini membantu stakeholder melihat kategori prioritas
-- berdasarkan GMV, jumlah buyer, jumlah order, AOV, GMV per buyer,
-- kontribusi GMV, dan ranking performa.
-- ============================================================


-- CTE 1: valid_order_items
-- Kenapa mulai dari order_items:
-- Analisis GMV harus dihitung dari level item, bukan hanya level order.
-- Dalam e-commerce, satu order bisa berisi lebih dari satu produk.
-- Kalau memakai tabel orders saja, kita tidak bisa melihat kontribusi
-- masing-masing kategori produk secara akurat.
--
-- Kenapa mengambil order_id:
-- order_id dipakai untuk menghitung jumlah order unik.
-- Karena data berasal dari order_items, satu order bisa muncul beberapa kali.
-- COUNT(DISTINCT order_id) mencegah order yang sama dihitung berulang.
--
-- Kenapa mengambil user_id:
-- user_id dipakai untuk menghitung unique buyers.
-- Ini penting untuk membedakan kategori yang dibeli banyak orang
-- dengan kategori yang hanya menghasilkan GMV besar dari sedikit pembeli.
--
-- Kenapa mengambil product_id:
-- product_id dipakai untuk menghubungkan transaksi dengan tabel products.
-- Dari tabel products, kita bisa mengambil category dan department.
--
-- Kenapa memakai sale_price:
-- sale_price dipakai sebagai proxy GMV.
-- Karena dataset tidak memuat komponen seperti voucher, shipping fee,
-- seller commission, platform subsidy, atau contribution margin,
-- maka GMV di sini harus dibaca sebagai total nilai penjualan item valid.
--
-- Kenapa filter status Cancelled dan Returned:
-- Transaksi yang dibatalkan dan dikembalikan tidak boleh dihitung
-- sebagai penjualan valid. Kalau tetap dihitung, GMV akan terlihat
-- lebih besar daripada performa riil.
--
-- Kenapa menghapus bulan berjalan:
-- DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
-- digunakan agar data bulan berjalan tidak masuk ke analisis.
-- Bulan berjalan belum lengkap, sehingga bisa menimbulkan bias.
-- Contoh: jika hari ini baru tanggal 6, GMV bulan ini pasti terlihat turun,
-- padahal penurunannya hanya karena data belum penuh.

WITH valid_order_items AS (
  SELECT
    oi.order_id,
    oi.user_id,
    oi.product_id,
    oi.sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
    AND DATE(oi.created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),


-- CTE 2: category_summary
-- Kenapa LEFT JOIN ke tabel products:
-- order_items hanya menyimpan product_id.
-- Untuk mengetahui kategori produk, kita perlu menghubungkan product_id
-- dengan tabel products.
--
-- Kenapa LEFT JOIN, bukan INNER JOIN:
-- LEFT JOIN menjaga agar transaksi valid tetap masuk analisis meskipun
-- product_id tidak menemukan pasangan di tabel products.
-- Ini lebih aman untuk data produksi karena data produk bisa saja tidak lengkap.
--
-- Kenapa COALESCE category dan department menjadi 'Unknown':
-- Jika category atau department bernilai NULL, data tetap bisa dikelompokkan
-- ke kategori 'Unknown'. Ini mencegah transaksi hilang dari agregasi
-- hanya karena atribut produk tidak lengkap.
--
-- Kenapa GROUP BY category dan department:
-- Kategori saja kadang belum cukup.
-- Department memberi konteks tambahan, misalnya apakah kategori tersebut
-- berasal dari produk Men atau Women.
--
-- Kenapa menghitung total_orders:
-- total_orders menunjukkan volume transaksi pada kategori tersebut.
-- Ini membantu melihat kategori yang sering dibeli.
--
-- Kenapa menghitung unique_buyers:
-- unique_buyers menunjukkan seberapa luas kategori tersebut menjangkau pembeli.
-- Kategori dengan buyer tinggi berarti punya daya tarik pasar yang besar.
--
-- Kenapa menghitung total_gmv:
-- total_gmv menunjukkan kontribusi revenue utama dari setiap kategori.
-- Ini metrik utama untuk menentukan kategori prioritas secara bisnis.
--
-- Kenapa menghitung avg_order_value:
-- AOV = GMV / total order.
-- Metrik ini menunjukkan rata-rata nilai transaksi per order pada kategori.
-- Kategori dengan AOV tinggi biasanya cocok untuk strategi premium,
-- bundling bernilai tinggi, atau upselling.
--
-- Kenapa menghitung gmv_per_buyer:
-- GMV per buyer = GMV / unique buyers.
-- Metrik ini menunjukkan rata-rata kontribusi GMV per pembeli.
-- Ini membantu membedakan kategori yang ramai pembeli
-- dengan kategori yang memiliki pembeli bernilai tinggi.
  
category_summary AS (
  SELECT
    COALESCE(p.category, 'Unknown') AS category,
    COALESCE(p.department, 'Unknown') AS department,
    COUNT(DISTINCT v.order_id) AS total_orders,
    COUNT(DISTINCT v.user_id) AS unique_buyers,
    ROUND(SUM(v.sale_price), 2) AS total_gmv,
    ROUND(SAFE_DIVIDE(SUM(v.sale_price), COUNT(DISTINCT v.order_id)), 2) AS avg_order_value,
    ROUND(SAFE_DIVIDE(SUM(v.sale_price), COUNT(DISTINCT v.user_id)), 2) AS gmv_per_buyer
  FROM valid_order_items v
  LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` p
    ON v.product_id = p.id
  GROUP BY 1, 2
)


-- FINAL SELECT
-- Kenapa menampilkan category dan department:
-- Dua kolom ini menjadi dimensi utama untuk visualisasi dashboard.
-- Stakeholder bisa melihat kategori mana yang kuat dan department mana
-- yang paling berkontribusi.
--
-- Kenapa menampilkan total_orders:
-- total_orders digunakan untuk melihat kategori dengan volume transaksi tinggi.
-- Kategori dengan order tinggi bisa menjadi kandidat untuk campaign repeat purchase.
--
-- Kenapa menampilkan unique_buyers:
-- unique_buyers digunakan untuk melihat seberapa banyak pelanggan
-- yang membeli kategori tersebut.
-- Ini penting untuk membaca market reach per kategori.
--
-- Kenapa menampilkan total_gmv:
-- total_gmv adalah metrik utama untuk melihat kontribusi pendapatan.
-- Kategori dengan total_gmv tertinggi biasanya menjadi prioritas bisnis.
--
-- Kenapa menampilkan avg_order_value:
-- avg_order_value membantu membaca kualitas transaksi.
-- Kategori dengan AOV tinggi dapat dipakai untuk strategi upselling,
-- bundling, atau premium product positioning.
--
-- Kenapa menampilkan gmv_per_buyer:
-- gmv_per_buyer membantu membaca nilai rata-rata setiap pembeli
-- dalam satu kategori.
-- Jika gmv_per_buyer tinggi, berarti pembeli kategori tersebut
-- cenderung memiliki nilai belanja lebih besar.
--
-- Kenapa menghitung gmv_contribution_pct:
-- GMV contribution menunjukkan persentase kontribusi kategori terhadap
-- total GMV semua kategori.
-- Ini penting agar dashboard tidak hanya menampilkan angka absolut,
-- tetapi juga proporsi kontribusi bisnis.
--
-- Contoh:
-- Jika satu kategori memiliki kontribusi 20%,
-- artinya 1 dari 5 dolar GMV berasal dari kategori tersebut.
--
-- Kenapa memakai SUM(total_gmv) OVER():
-- Window function ini menghitung total GMV seluruh kategori
-- tanpa perlu membuat CTE tambahan.
-- Dengan begitu, setiap baris kategori bisa dibandingkan
-- dengan total GMV keseluruhan.
--
-- Kenapa memakai SAFE_DIVIDE:
-- SAFE_DIVIDE mencegah error division by zero.
-- Ini defensive programming yang baik, terutama jika suatu saat
-- data kosong atau total GMV bernilai nol.
--
-- Kenapa membuat gmv_rank:
-- gmv_rank menunjukkan urutan kategori berdasarkan total GMV.
-- Ini berguna untuk memilih kategori utama dalam dashboard dan rekomendasi bisnis.
--
-- Kenapa membuat aov_rank:
-- aov_rank menunjukkan kategori dengan rata-rata nilai order tertinggi.
-- Kategori ranking tinggi di AOV belum tentu ranking tinggi di GMV.
-- Ini membantu menemukan kategori niche yang bernilai tinggi.
--
-- Kenapa membuat buyer_rank:
-- buyer_rank menunjukkan kategori dengan jumlah pembeli terbanyak.
-- Ini berguna untuk membaca kategori dengan daya tarik pasar paling luas.
--
-- Kenapa ORDER BY total_gmv DESC:
-- Output diurutkan dari kategori dengan GMV terbesar.
-- Untuk analisis bisnis, kategori dengan kontribusi GMV terbesar
-- biasanya menjadi prioritas pertama untuk dibaca.
  
SELECT
  category,
  department,
  total_orders,
  unique_buyers,
  total_gmv,
  avg_order_value,
  gmv_per_buyer,
  ROUND(SAFE_DIVIDE(total_gmv, SUM(total_gmv) OVER()) * 100, 2) AS gmv_contribution_pct,
  RANK() OVER (ORDER BY total_gmv DESC) AS gmv_rank,
  RANK() OVER (ORDER BY avg_order_value DESC) AS aov_rank,
  RANK() OVER (ORDER BY unique_buyers DESC) AS buyer_rank
FROM category_summary
ORDER BY total_gmv DESC;
```
