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


