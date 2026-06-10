# Metric Definitions

This document defines the key metrics used in the TheLook E-Commerce analytics project.

## GMV Proxy

GMV proxy is calculated as:

```sql
SUM(sale_price)
```

Only valid order items are included. Order items with status `Cancelled` or `Returned` are excluded.

This metric should be interpreted as net merchandise sales proxy because the dataset does not include voucher cost, shipping fee, seller commission, platform subsidy, payment fee, or advertising cost.

## Average Order Value

AOV is calculated as:

```sql
GMV / number_of_unique_orders
```

AOV is used to understand whether GMV growth is driven by higher basket size or by higher order volume.

## Unique Buyers

Unique buyers are counted using distinct `user_id` values from valid transactions.

## Cohort Retention

A user's cohort month is the month of their first valid purchase.

Retention rate is calculated as:

```text
active users in month N / original cohort size
```

## Funnel Conversion

The main funnel is:

```text
Product Page → Add to Cart → Purchase
```

The improved funnel logic uses timestamp ordering, meaning that cart must happen after product view and purchase must happen after cart.

## Drop-off Rate

Drop-off rate is calculated as:

```text
1 - current_stage_sessions / previous_stage_sessions
```

This metric helps identify the stage where users leave the journey.
