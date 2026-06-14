# 📦 TheLook E-Commerce: Growth, Retention, Funnel, RFM & Forecast Analysis

> Growth Analysis · Customer Retention · New vs Returning Buyer · Category Performance · RFM Segmentation · Conversion Funnel · GMV Forecasting · Business Insight

![Dashboard Preview](assets/dashboard_preview.png)

## Project Overview

This project is an end-to-end e-commerce analytics case study using the Google BigQuery public dataset `bigquery-public-data.thelook_ecommerce`.

The analysis simulates how a marketplace data analyst investigates business growth, customer retention, product category performance, buyer behavior, conversion funnel leakage, customer segmentation, and GMV forecasting.

The project covers the full analytics workflow, starting from SQL-based data extraction in BigQuery, cohort retention analysis, category-level performance analysis, new vs returning buyer analysis, RFM customer segmentation, funnel analysis, Python-based time-series forecasting, and executive dashboard storytelling in Looker Studio.

**Live Dashboard:** [View in Looker Studio](https://datastudio.google.com/reporting/4305cf69-83f3-483c-b8dc-3e02a43edca3)

## Business Questions

This project answers the following business questions:

1. Is the e-commerce business growing consistently over time?
2. Is GMV growth driven by more buyers, more orders, or higher order value?
3. How much GMV comes from new buyers and returning buyers each month?
4. Which product categories contribute the most to GMV, buyers, and orders?
5. How balanced is customer contribution by gender?
6. How strong is customer retention after the first purchase?
7. Which customer segments have the highest business value based on RFM?
8. Where do users drop off the most in the product-to-purchase funnel?
9. Which traffic sources generate stronger funnel performance?
10. How much GMV can be expected in the next six months based on historical trends?

## Tools & Tech Stack

| Tool                  | Usage                                                                                                      |
| --------------------- | ---------------------------------------------------------------------------------------------------------- |
| Google BigQuery       | Querying and aggregating large-scale e-commerce data                                                       |
| SQL                   | Growth metrics, cohort retention, funnel analysis, category analysis, buyer segmentation, RFM segmentation |
| Python / Google Colab | Time-series forecasting and model evaluation                                                               |
| Prophet               | Monthly GMV forecasting                                                                                    |
| Looker Studio         | Executive dashboard and stakeholder communication                                                          |

## Dataset

| Item                       | Description                                              |
| -------------------------- | -------------------------------------------------------- |
| Source                     | `bigquery-public-data.thelook_ecommerce`                 |
| Platform                   | Google BigQuery Public Dataset                           |
| Data Period                | January 2019 – May 2026 for complete historical analysis |
| Main Tables                | `order_items`, `orders`, `events`                        |
| Optional Enrichment Tables | `products`, `users`                                      |
| Data Type                  | Simulated e-commerce transaction and clickstream data    |

## Important Data Note

The sharp decline at the far right of the dashboard chart in June 2026 should be treated as data noise. June 2026 only contains partial-month data because the month had only run for six days at the time of extraction.

Therefore, the latest complete business performance should be evaluated using May 2026, not June 2026. Based on the dashboard, May 2026 recorded the strongest full-month performance in the historical period.

## Executive KPI Summary

| KPI                         |  Value |
| --------------------------- | -----: |
| Peak Monthly GMV            | 467.2K |
| Peak Monthly Buyers         |  5,057 |
| Average Order Value         |  83.95 |
| Month-1 Retention Rate      |  1.30% |
| Cart-to-Purchase Conversion | 26.65% |
| Average Forecast GMV        | 355.8K |
| Peak Forecast GMV           | 376.9K |

## Metric Definitions

| Metric            | Definition                                                                            |
| ----------------- | ------------------------------------------------------------------------------------- |
| GMV Proxy         | Total `sale_price` from valid order items, excluding `Cancelled` and `Returned` items |
| AOV               | GMV divided by number of unique orders                                                |
| Unique Buyers     | Number of distinct users with valid transactions                                      |
| Unique Orders     | Number of distinct valid orders                                                       |
| MoM Growth        | Month-over-month GMV percentage change                                                |
| Cohort Month      | User's first valid purchase month                                                     |
| Retention Rate    | Percentage of users from a cohort who made another valid purchase in later months     |
| New Buyer         | Buyer whose first purchase occurred in the same month as the transaction month        |
| Returning Buyer   | Buyer who had already purchased before the transaction month                          |
| RFM               | Customer segmentation method based on Recency, Frequency, and Monetary value          |
| Funnel Conversion | Percentage of sessions moving from product page to cart and purchase                  |
| Drop-off Rate     | Percentage of sessions lost between funnel stages                                     |
| Forecast GMV      | Predicted monthly GMV based on historical GMV trend and seasonality                   |

Important note: because this dataset does not include voucher cost, shipping fee, payment fee, seller commission, platform subsidy, advertising spend, and contribution margin, GMV in this project should be interpreted as a net merchandise sales proxy, not full marketplace profitability.

## Milestone 1: Business Growth Analysis

**SQL Files:**

* [`sql/milestone1_business_growth.sql`](sql/milestone1_business_growth.sql)

### What Was Analyzed

This milestone analyzes monthly GMV, unique buyers, unique orders, average order value, GMV per buyer, and month-over-month growth.

### Key Findings

* GMV showed strong long-term growth from 2019 to 2026.
* The latest complete month, May 2026, recorded the strongest full-month performance.
* AOV remained relatively stable around the $80 range.
* GMV growth was mainly driven by higher buyer and order volume, not by a major increase in basket size.
* June 2026 should not be interpreted as a real business decline because it only contains partial-month data.

### Business Interpretation

The business shows a strong acquisition-driven growth pattern. More customers and more orders are the main growth drivers. However, stable AOV means the company still has room to improve revenue quality through bundling, cross-selling, free shipping thresholds, and personalized recommendations.

![Business Growth Analysis](assets/growth_gmv.png)

![MoM GMV Growth](assets/mom_gmv_growth.png)

---

## Milestone 2: Cohort Retention Analysis

**SQL Files:**

* [`sql/milestone1_cohort_retention.sql`](sql/milestone1_cohort_retention.sql)

### What Was Analyzed

This milestone analyzes whether first-time buyers return in the following months. Users are grouped by their first purchase month, then tracked across later months.

### Key Findings

* Month-1 retention is very low, around 1.30%.
* Around 92–98% of users do not return in Month 1.
* A small retained user group continues to show repeat purchase behavior in later months.
* This indicates that the platform has repeat-purchase potential, but early lifecycle activation is weak.

### Business Interpretation

The business has a retention problem, especially after the first purchase. Growth can continue through acquisition, but long-term efficiency will be weak if first-time buyers do not return. CRM, post-purchase communication, reorder reminders, and personalized vouchers should become business priorities.

![Cohort_Retention_Analysis](assets/milestone_2.pgn)


---

## Milestone 3: Category and Gender Performance Analysis

**SQL Files:**

* [`sql/milestone4_category_gmv_aov.sql`](sql/milestone4_category_gmv_aov.sql)

### What Was Analyzed

This milestone analyzes product category performance based on total GMV, total buyers, and total orders. It also compares GMV, buyer count, and order contribution by gender.

### Key Findings

* Outerwear & Coats generated the highest total GMV.
* Jeans appeared as one of the strongest categories across GMV and buyer contribution.
* Intimates contributed the highest total order volume.
* Gender contribution was relatively balanced by buyer count and order count.
* GMV contribution showed a slight difference between men and women, but the gap was not extreme.

### Business Interpretation

Different categories play different business roles. Outerwear & Coats contributes strong GMV, while Intimates and Jeans show strong buyer and order volume. High-GMV categories should be optimized for margin and premium positioning. High-volume categories should be optimized for repeat purchase and bundling.

![Category and Gender Performance Analysis](assets/milestone_3.png)

---

## Milestone 4: New vs Returning Buyer GMV Contribution

**SQL Files:**

* [`sql/milestone4_new_vs_returning_buyer.sql`](sql/milestone4_new_vs_returning_buyer.sql)

### What Was Analyzed

This milestone compares monthly GMV contribution from new buyers and returning buyers.

A buyer is classified as a New Buyer when the transaction month is the same as the user's first purchase month. A buyer is classified as a Returning Buyer when the user had already purchased before the transaction month.

### Key Metrics

| Metric                     | Description                                                     |
| -------------------------- | --------------------------------------------------------------- |
| Unique Buyers              | Number of distinct buyers by month and buyer type               |
| Total Orders               | Number of unique orders by month and buyer type                 |
| Total GMV                  | Total valid sales value                                         |
| Average Order Value        | GMV divided by total orders                                     |
| GMV per Buyer              | GMV divided by unique buyers                                    |
| Monthly GMV Contribution % | Percentage contribution of each buyer type to total monthly GMV |

### Key Findings

* New buyers contributed a large share of GMV in earlier periods.
* Returning buyer contribution increased over time.
* The growing returning buyer share suggests that part of the customer base started to show repeat purchase behavior.
* However, the low Month-1 retention rate shows that the majority of first-time buyers still do not return quickly.

### Business Interpretation

The business still depends heavily on new buyer acquisition, but returning buyers are becoming more relevant to GMV contribution. This is a positive sign, but it does not remove the retention issue. The company should improve onboarding and post-purchase engagement to convert more new buyers into repeat buyers.

![New vs Returning Buyer GMV Share](assets/new_vs_returning_buyer.png)

---

## Milestone 5: RFM Customer Segmentation

**SQL Files:**

* [`sql/milestone4_rfm_customer_segmentation.sql`](sql/milestone4_rfm_customer_segmentation.sql)

### What Was Analyzed

This milestone segments customers using RFM analysis:

* Recency: how recently a customer purchased.
* Frequency: how often a customer purchased.
* Monetary: how much a customer spent.

Customers are grouped into seven segments:

| Segment             | Description                                                   |
| ------------------- | ------------------------------------------------------------- |
| Champions           | Best customers. Recent, frequent, and high-value buyers       |
| Loyal Customers     | Active customers with relatively frequent purchases           |
| New / Promising     | Recent buyers with potential but still low frequency          |
| Potential Loyalists | Customers who show early signs of loyalty                     |
| At Risk             | Previously frequent buyers who have not purchased recently    |
| Dormant             | Inactive customers with low purchase frequency                |
| Regular Customers   | Customers who do not fall into the special segment categories |

### Key Findings

* Dormant customers formed the largest customer group.
* Champions and Potential Loyalists contributed high monetary value.
* Some segments with smaller customer counts produced stronger spending contribution.
* This shows that customer count and revenue contribution are not always proportional.

### Business Interpretation

The company should not treat all customers equally. Champions should receive loyalty rewards and exclusive offers. Potential Loyalists should receive personalized recommendations and repeat-purchase incentives. At Risk customers should receive reactivation campaigns. Dormant customers should be handled through low-cost campaigns because their conversion probability is likely lower.

![RFM Customer Segmentation](assets/rfm_segmentation.png)

---

## Milestone 6: Strict Session-Level Conversion Funnel

**SQL Files:**

* [`sql/milestone2_funnel_overview.sql`](sql/milestone2_funnel_overview.sql)
* [`sql/milestone2_funnel_by_traffic_source.sql`](sql/milestone2_funnel_by_traffic_source.sql)

### What Was Analyzed

This milestone analyzes clickstream events from product page to add-to-cart and purchase. The funnel logic uses session-level timestamp ordering, so a session is counted as converted only when the user moves through the expected sequence:

`Product Page → Add to Cart → Purchase`

### Key Findings

| Funnel Stage | Sessions | % from Entry Point | Drop-off |
| ------------ | -------: | -----------------: | -------: |
| Product Page |  681,667 |            100.00% |        — |
| Add to Cart  |  432,099 |             63.39% |   36.61% |
| Purchase     |  181,667 |             26.65% |   57.96% |

* The largest drop-off occurred from Add to Cart to Purchase.
* Product discovery was not the biggest issue.
* The main friction likely happened near checkout.
* Email contributed the largest session share.
* YouTube showed strong purchase quality, but the result should still be validated using cost data.

### Business Interpretation

The platform does not only need more traffic. It needs better checkout completion. Marketplace teams should prioritize checkout UX, abandoned cart automation, clearer shipping cost information, payment method availability, and stronger purchase urgency.

Channel recommendations should be treated carefully because this dataset does not include advertising cost, CAC, ROAS, or campaign spend.

![Strict Session-Level Conversion Funnel](assets/funnel_overview.png)

---

## Milestone 7: GMV Forecasting

**Notebook:**

* [`notebooks/milestone3_gmv_forecasting.ipynb`](notebooks/milestone3_gmv_forecasting.ipynb)

**Forecast Evaluation Template:**

* [`notebooks/forecasting_evaluation_template.py`](notebooks/forecasting_evaluation_template.py)

### What Was Analyzed

Monthly GMV proxy was forecasted using Prophet. The model projects the next six months of GMV and decomposes the time series into trend and seasonality components.

### Model Setup

| Item                | Value                      |
| ------------------- | -------------------------- |
| Model               | Prophet                    |
| Frequency           | Monthly                    |
| Training Data       | January 2019 – May 2026    |
| Forecast Horizon    | June 2026 – November 2026  |
| Seasonality         | Yearly seasonality enabled |
| Confidence Interval | 95%                        |

### Forecast Result

| Month    | Forecast GMV | Lower Bound | Upper Bound |
| -------- | -----------: | ----------: | ----------: |
| Jun 2026 |     $323,322 |    $301,414 |    $343,578 |
| Jul 2026 |     $331,799 |    $309,853 |    $353,218 |
| Aug 2026 |     $346,765 |    $326,753 |    $368,871 |
| Sep 2026 |     $354,523 |    $332,077 |    $373,626 |
| Oct 2026 |     $369,132 |    $347,850 |    $390,936 |
| Nov 2026 |     $376,897 |    $353,809 |    $397,807 |

### Business Interpretation

The forecast suggests continued GMV growth in the next six months. However, the forecast should be interpreted as a directional estimate, not as a guaranteed business outcome. The model does not include marketing spend, pricing changes, stock availability, campaign events, macroeconomic factors, or operational constraints.

![GMV Forecasting](assets/forecasting.png)

### Model Reliability Note

A narrow confidence interval does not automatically prove that a model is reliable. To make the forecasting work stronger, the notebook should include backtesting using MAE, RMSE, and MAPE, then compare Prophet against a naive or seasonal naive baseline.

## Executive Dashboard

**Live Dashboard:** [View in Looker Studio](https://datastudio.google.com/reporting/4305cf69-83f3-483c-b8dc-3e02a43edca3)

The dashboard is designed for non-technical stakeholders. It summarizes technical analysis into business-facing metrics, visual trends, and action-oriented recommendations.

| Section                 | Content                                                         |
| ----------------------- | --------------------------------------------------------------- |
| Growth Overview         | Monthly GMV, unique orders, buyer growth, MoM growth, AOV trend |
| Category Performance    | Top categories by GMV, buyers, and orders                       |
| Gender Analysis         | GMV, buyer, and order contribution by gender                    |
| Retention Analysis      | Cohort retention heatmap and retention curve                    |
| New vs Returning Buyer  | Monthly GMV share from new and returning buyers                 |
| RFM Segmentation        | Customer segment size and spending contribution                 |
| Funnel Analysis         | Product page, add-to-cart, and purchase conversion              |
| Traffic Source Analysis | Funnel breakdown and session share by source                    |
| Forecasting             | Actual vs forecast GMV, forecast table, trend and seasonality   |

## Strategic Recommendations

### 1. Improve First-Time Buyer Retention

Run a post-purchase CRM sequence for first-time buyers within 24 hours after their first transaction. The sequence can include order status updates, personalized product recommendations, reorder reminders, and limited-time vouchers.

Target KPI: increase Month-1 retention from 1.30% to at least 5% in the next three months.

### 2. Reduce Cart-to-Purchase Drop-off

Prioritize checkout improvements such as guest checkout, clearer shipping fee visibility, faster payment options, easier voucher application, and one-click payment for returning users.

Target KPI: reduce cart-to-purchase drop-off from 57.96% to below 50%.

### 3. Convert New Buyers into Returning Buyers

Create a structured first-time buyer lifecycle program. The program should include welcome messages, product education, cross-sell recommendations, second-purchase vouchers, and reminder campaigns.

Target KPI: increase returning buyer GMV contribution and reduce dependence on new buyer acquisition.

### 4. Prioritize High-Value Customer Segments

Use RFM segmentation to prioritize CRM campaigns. Champions should receive VIP rewards. Potential Loyalists should receive personalized recommendations. At Risk customers should receive reactivation campaigns. Dormant customers should receive low-cost win-back campaigns.

Target KPI: increase GMV from Champions and Potential Loyalists while reducing revenue loss from At Risk customers.

### 5. Optimize Product Category Strategy

Use category-level performance to separate high-GMV categories from high-volume categories. High-GMV categories should support margin growth. High-volume categories should support repeat purchase, bundling, and retention programs.

Target KPI: increase AOV and repeat purchase rate in top categories.

### 6. Validate Channel Reallocation with Cost Data

Email and Adwords generate large session volume, while YouTube shows strong funnel quality. However, final budget decisions require CAC, ROAS, ad spend, and contribution margin data.

Target KPI: evaluate each channel using conversion rate, CAC, ROAS, GMV per session, and repeat purchase rate.

## Limitations

This project uses a simulated public dataset, so the results do not represent the real performance of Shopee, Lazada, Tokopedia, or any specific marketplace.

The dataset does not include important commercial variables such as voucher cost, shipping fee, platform subsidy, seller commission, payment fee, advertising cost, CAC, ROAS, stock availability, product margin, and contribution margin. Therefore, the analysis focuses on transaction behavior and conversion patterns, not profitability.

Checkout friction is inferred from funnel drop-off. Since the dataset does not include detailed checkout step events such as payment page, shipping selection, voucher application, or payment failure, the exact cause of checkout drop-off cannot be proven from this dataset alone.

New buyer and returning buyer classification depends on the available transaction history. If earlier customer history is missing from the dataset, some returning buyers may be misclassified as new buyers.

RFM segmentation is based on relative scoring using the available dataset. Segment labels should be used for business prioritization, not as fixed customer identities.

Forecasting results are based on historical GMV patterns. The model does not include external business drivers such as campaign calendars, pricing changes, seasonality from real holidays, competitor activity, or marketing budget.

## Repository Structure

```text
TheLook-E-Commerce-Growth-Retention-RFM-Funnel-Forecast-Analysis/
├── README.md
├── requirements.txt
├── .gitignore
├── COMMIT_MESSAGE.txt
│
├── sql/
│   ├── milestone1_business_growth.sql
│   ├── milestone1_cohort_retention.sql
│   ├── milestone2_funnel_by_traffic_source.sql
│   ├── milestone2_funnel_overview.sql
│   ├── milestone3_gmv_monthly_extract.sql
│   ├── milestone4_category_gmv_aov.sql
│   ├── milestone4_new_vs_returning_buyer.sql
│   ├── milestone4_rfm_customer_segmentation.sql
│   ├── milestone5_cart_abandonment_by_source.sql
│   ├── milestone5_category_repeat_purchase.sql
│   └── milestone5_cohort_retention_by_source.sql
│
├── notebooks/
│   ├── forecasting_evaluation_template.py
│   └── milestone3_gmv_forecasting.ipynb
│
├── data/
│   ├── cohort_retention.csv
│   ├── forecast_looker.csv
│   ├── funnel_by_traffic_source.csv
│   ├── funnel_overview.csv
│   ├── growth_monthly.csv
│   ├── milestone4_category_gmv_aov.sql.csv
│   ├── milestone4_new_vs_returning_buyer.sql.csv
│   ├── milestone4_rfm_customer_segmentation.sql.csv
│   ├── milestone5_cart_abandonment_by_source.sql.csv
│   ├── milestone5_category_repeat_purchase.sql.csv
│   └── milestone5_cohort_retention_by_source.sql.csv
│
├── assets/
│   ├── funnel_overview.png
│   ├── growth_gmv.png
│   ├── milestone_2.png
│   ├── milestone_3.png
│   ├── mom_gmv_growth.png
│   ├── new_vs_returning_buyer.png
│   └── rfm_segmentation.png
│
├── docs/
│   ├── assets/
│   ├── dashboard_export.pdf
│   ├── index.html
│   ├── limitations.md
│   ├── metric_definitions.md
│   ├── repository_cleanup_guide.md
│   ├── script.js
│   └── style.css
│
└── scripts/
    └── organize_repo.sh
```


## How to Reproduce

1. Open Google BigQuery.
2. Run SQL files from the `sql/` folder in order.
3. Export query results into the `data/` folder.
4. Run the forecasting notebook or the evaluation template in Google Colab.
5. Connect cleaned CSV outputs to Looker Studio.
6. Build dashboard sections for growth, retention, category, gender, new vs returning buyer, RFM, funnel, and forecast.
7. Export dashboard screenshots and update the `assets/` folder.
8. Update README visuals and metric values if the dashboard data changes.

## Author

**Achmad Faishal**
Program Studi Ekonomi Pembangunan — UPN "Veteran" Yogyakarta

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://www.linkedin.com/in/achmad-faishal-062313274/)
[![Looker Studio](https://img.shields.io/badge/Dashboard-Live-green)](https://datastudio.google.com/reporting/4305cf69-83f3-483c-b8dc-3e02a43edca3)

