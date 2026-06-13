# Olist E-Commerce Sales Analytics

**Tools:** SQL (MySQL) · Tableau Public · Excel  
**Dataset:** [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — 100K+ orders, 8 tables  
**Dashboard:** [View on Tableau Public](https://public.tableau.com/views/Olist_Ecommerce_Sales_Analytics/OlistE-CommerceSalesAnalytics20172018?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

## Overview

End-to-end data analysis project on Brazil's largest e-commerce dataset (2017–2018). Covers data cleaning, exploratory analysis, customer segmentation, and an interactive Tableau dashboard with 4 views.

---

## Key Insights

**1. Late deliveries drive a 40% drop in review score**  
Orders delivered late averaged 2.57/5 stars vs 4.29/5 for on-time deliveries — identifying delivery performance as the #1 driver of customer satisfaction across 96K orders.

**2. Top 20% of products generate 75% of revenue (Pareto)**  
6,444 products out of 32,215 account for R$9.89M of the total R$13.2M product revenue — confirming the 80/20 rule on real transactional data.

**3. São Paulo dominates with 36% of total revenue**  
SP (R$5.77M), RJ (R$2.06M), and MG (R$1.82M) together contribute 60% of nationwide revenue, revealing a strong geographic concentration.

**4. 97% one-time buyer rate signals a major retention gap**  
Only 3% of 99K customers made repeat purchases — RFM segmentation identified ~3,700 Champions and ~3,700 At Risk customers as priority retention targets.

**5. Credit card dominates at 74% of transactions**  
Boleto (Brazil's pay-slip method) accounts for 19%, reflecting the unique payment landscape of the Brazilian market.

---

## Dashboard

4-view interactive Tableau dashboard:

| View | Description |
|---|---|
| **Revenue Trend** | Monthly revenue & order volume (2017–2018) with dual axis |
| **Product Performance** | Top 10 revenue categories with gradient color encoding |
| **Customer Geo Map** | Revenue by Brazilian state — filled choropleth map |
| **Delivery Performance** | On-time vs late delivery impact on review score |

→ [View Live Dashboard](https://public.tableau.com/views/Olist_Ecommerce_Sales_Analytics/OlistE-CommerceSalesAnalytics20172018?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

## SQL Analysis

15+ queries across 6 sections — full file: [`olist_analysis.sql`](olist_analysis.sql)

| Section | Techniques Used |
|---|---|
| Data Exploration | UNION ALL, COUNT, NULL check |
| Revenue Analysis | GROUP BY, DATE_FORMAT, LAG() window function |
| Product Analysis | JOIN, NTILE(5), Pareto segmentation |
| Customer Analysis | CTE, RFM scoring, NTILE window function |
| Delivery Analysis | DATEDIFF, CASE WHEN, correlation analysis |
| Export Views | CREATE VIEW for Tableau integration |

---

## Project Structure

```
olist-ecommerce-analytics/
│
├── sql/
│   ├── olist_schema.sql        # Database & table creation
│   ├── import_olist.sql        # CSV import script
│   └── olist_analysis.sql      # Full analysis — 6 sections, 20+ queries
│
├── data/
│   ├── monthly_revenue.csv
│   ├── category_performance.csv
│   ├── customer_geo.csv
│   └── delivery_full.csv
│
└── README.md
```

---

## Dataset

| Table | Rows | Description |
|---|---|---|
| orders | 99,441 | Order status & timestamps |
| order_items | 112,650 | Products per order |
| order_payments | 103,886 | Payment type & value |
| order_reviews | 99,223 | Customer review scores |
| customers | 99,441 | Customer location data |
| products | 32,951 | Product categories |
| sellers | 3,095 | Seller information |

Source: [Kaggle — Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
