# Project Limitations

This project uses `bigquery-public-data.thelook_ecommerce`, a simulated public e-commerce dataset. The results do not represent actual performance of Shopee, Lazada, or any specific marketplace.

The dataset does not include several variables that are important in real marketplace analytics:

- Voucher cost
- Shipping fee
- Free shipping subsidy
- Platform subsidy
- Seller commission
- Payment fee
- Advertising cost
- CAC
- ROAS
- Contribution margin
- Checkout step details
- Payment failure reason
- Inventory stockout events

Because of these limitations, the project focuses on transaction behavior, retention pattern, clickstream funnel, and GMV proxy forecasting.

Any recommendation related to advertising budget reallocation should be treated as a hypothesis unless cost data, CAC, and ROAS are available.

Checkout friction is inferred from cart-to-purchase drop-off. The exact cause cannot be proven because the dataset does not include detailed checkout events such as payment page visit, voucher application, shipping method selection, or payment failure.
