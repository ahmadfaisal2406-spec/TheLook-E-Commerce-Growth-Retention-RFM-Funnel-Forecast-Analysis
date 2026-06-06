# 📦 TheLook E-Commerce: End-to-End Analytics
> **Growth · Cohort Retention · Conversion Funnel · GMV Forecasting**

![Dashboard Preview](https://ahmadfaisal2406-spec.github.io/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/#recommendations)

## 📌 Project Overview

Proyek analitik end-to-end menggunakan dataset publik BigQuery `thelook_ecommerce` yang mensimulasikan platform e-commerce skala besar. Proyek ini mencakup seluruh workflow seorang data analyst — mulai dari eksplorasi data menggunakan SQL di BigQuery, cohort retention analysis, conversion funnel analysis dari data clickstream, time-series forecasting dengan Python, hingga penyajian insight dalam executive dashboard interaktif.

**🔗 Live Dashboard:** [Lihat di Looker Studio](https://datastudio.google.com/reporting/4305cf69-83f3-483c-b8dc-3e02a43edca3)

---

## 🛠️ Tools & Tech Stack

| Tool | Kegunaan |
|------|----------|
| Google BigQuery | Query & agregasi data skala besar |
| SQL | Growth metrics, cohort analysis, funnel analysis |
| Python — Google Colab | Time-series forecasting & visualisasi |
| Facebook Prophet | Model forecasting GMV bulanan |
| Looker Studio | Executive dashboard & komunikasi insight |

---

## 🗃️ Dataset

| | |
|---|---|
| **Source** | `bigquery-public-data.thelook_ecommerce` |
| **Platform** | Google BigQuery Public Dataset |
| **Periode data** | Januari 2019 – Mei 2026 |
| **Tabel yang digunakan** | `order_items`, `orders`, `events` |
| **Volume** | ~2.5 juta baris transaksi |

---

## 📊 Milestone & Key Findings

### Milestone 1 — Business Growth & Cohort Retention Analysis

**Query:** [`sql/milestone1_business_growth.sql`](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/milestone1_business_growth.sql) · [`sql/milestone1_cohort_retention.sql`](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/milestone1_cohort_retention.sql))

**Apa yang dianalisis:**
Menghitung pertumbuhan GMV (Gross Merchandise Value), Average Order Value (AOV), dan Month-over-Month growth rate. Dilanjutkan dengan Cohort Retention Analysis untuk melihat persentase user yang kembali berbelanja di bulan-bulan setelah pembelian pertama mereka.

**Temuan utama:**
- GMV tumbuh dari **$382/bulan** (Jan 2019) menjadi **$462K/bulan** (Mei 2026) — pertumbuhan lebih dari **120,000%**
- Average Order Value stagnan di kisaran **$80–90** sepanjang periode — pertumbuhan omset murni didorong oleh **penambahan volume buyer**, bukan kenaikan harga
- Retensi bulan pertama hanya **1–2%**, mengindikasikan **krisis onboarding**: hampir 98% pelanggan hanya belanja sekali lalu tidak kembali
- Kelompok kecil yang bertahan (1–2%) terbukti sangat loyal hingga bulan ke-10, menandakan **Product-Market Fit yang valid** namun belum dikomunikasikan dengan baik ke mayoritas user baru

![Cohort Heatmap](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/Cohort%20Retention.png)

---

### Milestone 2 — User Conversion Funnel Analysis

**Query:** [`sql/milestone2_funnel_overview.sql`](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/milestone2_funnel_overview.sql) · [`sql/milestone2_funnel_by_traffic_source.sql`](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/milestone2_funnel_by_traffic_source.sql)

**Apa yang dianalisis:**
Menganalisis data clickstream dari tabel `events` untuk melacak perjalanan user dari halaman produk → keranjang → pembelian. Dilengkapi dengan breakdown conversion rate per traffic source untuk mengidentifikasi channel paling efisien.

**Temuan utama:**

| Tahap Funnel | Sessions | % dari Titik Masuk | Drop-off |
|---|---|---|---|
| Product Page | 681,667 | 100% | — |
| Add to Cart | 432,099 | 63.39% | 36.61% |
| Purchase | 181,667 | 26.65% | **57.96%** |

- **Drop-off terbesar terjadi di Cart → Purchase (57.96%)** — friction ada di halaman checkout, bukan di halaman produk
- Kemungkinan penyebab: ongkos kirim yang muncul mendadak di akhir, proses checkout yang terlalu panjang, atau pilihan metode pembayaran yang terbatas
- **YouTube** memiliki cart-to-purchase conversion tertinggi (**42.74%**) meski volume sessions-nya hanya sepertiga Email — mengindikasikan purchase intent yang lebih kuat
- **Email** adalah channel dengan volume transaksi terbesar (**81,549 purchased**) — kandidat utama untuk implementasi cart abandonment automation

**Rekomendasi:**
1. Implementasi **cart abandonment email** dalam 1–2 jam setelah user meninggalkan keranjang, dengan insentif voucher gratis ongkir
2. Pertimbangkan **Guest Checkout** untuk mengurangi friction di tahap registrasi
3. Tambahkan opsi **e-wallet dan Quick Payment** untuk memperluas pilihan pembayaran

![Funnel Dashboard](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/Funnel%20Over%20View.png)
![Funnel Dashboard](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/Funnel%20by%20source.png)
---

### Milestone 3 — GMV Forecasting dengan Time-Series Model

**Notebook:** [`notebooks/milestone3_gmv_forecasting.ipynb`](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/The_Look_E_Commerce_Forecasting_GMV.ipynb)

**Apa yang dianalisis:**
Menarik data agregasi bulanan dari BigQuery ke Google Colab, lalu menerapkan model **Facebook Prophet** untuk memproyeksikan GMV 6 bulan ke depan. Dilengkapi dengan decomposition analysis untuk memahami komponen trend dan seasonality.

**Model & Parameter:**
- Model: Facebook Prophet
- Training data: 89 bulan (Jan 2019 – Mei 2026)
- `yearly_seasonality = True`
- `changepoint_prior_scale = 0.05`
- Forecast horizon: Jun – Nov 2026
- Confidence interval: 95%

**Hasil Forecast:**

| Bulan | Forecast GMV | Lower Bound | Upper Bound |
|-------|-------------|-------------|-------------|
| Jun 2026 | $323,322 | $301,414 | $343,578 |
| Jul 2026 | $331,799 | $309,853 | $353,218 |
| Aug 2026 | $346,765 | $326,753 | $368,871 |
| Sep 2026 | $354,523 | $332,077 | $373,626 |
| Oct 2026 | $369,132 | $347,850 | $390,936 |
| Nov 2026 | $376,897 | $353,809 | $397,807 |

- Rata-rata GMV forecast Jun–Nov 2026: **$350,406/bulan** (+10.6% vs baseline 6 bulan terakhir)
- Confidence interval yang sempit mengindikasikan pola historis yang konsisten dan model yang reliable

**Seasonality Pattern:**
- **Peak season:** April–Mei (GMV di atas rata-rata tren) → rekomendasi: tingkatkan stok di Februari
- **Low season:** Juni–Juli dan November → rekomendasi: kurangi budget iklan, simpan untuk periode Desember–Januari

![Forecast Chart](https://github.com/ahmadfaisal2406-spec/TheLook-E-Commerce-Growth-Retention-Funnel-Forecast-Analysis/blob/main/Forecasting.png)

---

### Milestone 4 — Executive Dashboard

**Live:** [🔗 Lihat Dashboard di Looker Studio](https://datastudio.google.com/reporting/4305cf69-83f3-483c-b8dc-3e02a43edca3)

Dashboard interaktif 3 halaman yang menyederhanakan seluruh analisis ke dalam format yang dapat dikonsumsi oleh non-technical stakeholders, dilengkapi dengan filter tanggal dan narasi insight bisnis.

| Halaman | Konten |
|---------|--------|
| Growth & Retention | GMV trend, MoM growth rate, AOV, cohort heatmap |
| Funnel Analysis | Conversion funnel, drop-off rate, breakdown per traffic source |
| Forecast | Actual vs forecast chart, tabel proyeksi 6 bulan, seasonality insight |

---

## 💡 Strategic Recommendations

1. **Loyalty program** — Alokasikan sebagian profit Mei 2026 untuk membangun sistem onboarding dan email sequence pasca-pembelian pertama. Target: menurunkan churn rate dari 98% menjadi di bawah 90% dalam 3 bulan.

2. **Budget optimization** — Kurangi spend iklan di Juni–Juli dan November (low season). Tumpahkan anggaran di Desember–Januari saat konsumen paling aktif.

3. **AOV improvement** — Implementasi product bundling dan promo gratis ongkir dengan minimum belanja untuk mendorong AOV dari $83 ke $95+.

4. **Channel reallocation** — YouTube menunjukkan kualitas traffic terbaik. Pertimbangkan peningkatan budget YouTube Ads secara bertahap sambil memperkuat SEO untuk menekan Customer Acquisition Cost (CAC).

---

## 📁 Repository Structure

```
thelook-ecommerce-analytics/
├── README.md
├── sql/
│   ├── milestone1_business_growth.sql
│   ├── milestone1_cohort_retention.sql
│   ├── milestone2_funnel_overview.sql
│   └── milestone2_funnel_by_traffic_source.sql
├── notebooks/
│   └── milestone3_gmv_forecasting.ipynb
├── data/
│   ├── growth_monthly.csv
│   ├── cohort_retention.csv
│   ├── funnel_overview.csv
│   ├── funnel_by_traffic_source.csv
│   └── forecast_looker.csv
└── assets/
    ├── dashboard_growth.png
    ├── dashboard_funnel.png
    └── dashboard_forecast.png
```

---

## 👤 Author

**[Achmad Faishal]**  
Program Studi Ekonomi Pembangunan — UPN "Veteran" Yogyakarta  

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://datastudio.google.com/s/uaeQ4tKYuK0)
[![Looker Studio](https://img.shields.io/badge/Dashboard-Live-green)](https://www.linkedin.com/in/achmad-faishal-062313274/)
