# Olist E-Commerce Analytics — End-to-End SQL + EDA Project

**Dataset:** Brazilian E-Commerce Public Dataset by Olist (Kaggle)  
**Stack:** PostgreSQL 16 · Python · pandas · scikit-learn · Jupyter  
**Author:** Avaneesh Srivastava| IIT Kharagpur | CDC 2026

---

## Business Context

Olist is a Brazilian e-commerce marketplace connecting small sellers to major retail platforms. This project analyses 100K+ orders across 2016–2018 to answer real business questions around revenue growth, customer retention, delivery performance, and demand forecasting — the same questions a data analyst would face in a BA/DS role.

---

## Key Business Findings

### 1. Revenue grew 50x in 14 months — but AOV stayed flat
Monthly GMV scaled from R$143 in Sept 2016 to over R$987K by Nov 2017. Average Order Value held steady at R$139–152 throughout, meaning **growth was entirely volume-driven, not ticket-size driven**. This signals strong top-of-funnel acquisition but no upsell momentum.

### 2. Beauty & Health is the #1 revenue category — watches punch above their weight
`beleza_saude` leads with R$1.23M in revenue across 8,647 orders (AOV: R$130). `relogios_presentes` (watches & gifts) is #2 at R$1.17M but with only 5,495 orders and an AOV of R$199 — the highest in the top 10. **Premium categories deserve targeted inventory and ad spend.**

### 3. 78% of GMV flows through credit card — boleto is a meaningful second segment
Credit card dominates at 78.3% of platform GMV, driven by Brazil's installment payment culture. Boleto (bank slip) holds 17.9% — a significant segment representing customers without credit access. **Debit card at 1.36% represents an untapped growth opportunity.**

### 4. 97% fulfilment rate — the funnel is operationally healthy
Of 99,441 orders, 96,478 (97%) reach delivered status. Only 625 (0.63%) are cancelled. **The retention problem is commercial, not logistical** — the platform delivers reliably but fails to bring customers back.

### 5. Retention crisis: 96.9% of customers never return
Cohort analysis across 23 months shows retention rates of 2.8–4.3% across every cohort with no improvement over time. **Growth is almost entirely dependent on new customer acquisition** — a costly and structurally risky model. A loyalty or post-purchase CRM program is the highest-leverage intervention available.

### 6. SP delivers in 8.7 days; northern states wait 24+ days
São Paulo customers receive orders in 8.76 days on average. Alagoas (AL) customers wait 24.54 days — nearly 3x longer. All states show negative delay (delivered before ETA), but **the absolute gap is a regional equity and competitiveness issue** that limits Olist's expansion into underserved markets.

### 7. Late delivery destroys customer satisfaction — by 2.5 rating points
Orders delivered on time or early score 4.15–4.31/5. Orders more than 5 days late score 1.79/5 — a **2.52-point collapse in satisfaction**. These 4,116 very-late orders represent 4.3% of delivered volume but generate disproportionate NPS damage. Targeting last-mile outliers is the fastest path to satisfaction improvement.

### 8. Statistical validation: SP satisfaction gap is real (T-test, p < 0.0001)
SP customers score 4.17 vs 4.02 for non-SP customers. A two-sample t-test (t=17.44, p≈0) confirms this is statistically significant — consistent with SP's faster delivery times. Payment type choice also varies significantly by state (chi-square=200.87, p≈0), confirming regional behavioural differences that should inform localised product strategy.

---

## Forecasting

A linear regression model on monthly GMV (R²=0.838) forecasts:

| Month | Predicted GMV |
|-------|--------------|
| Sept 2018 | R$1,113,569 |
| Oct 2018 | R$1,157,567 |
| Nov 2018 | R$1,201,565 |

The model captures the platform's consistent upward trend. Month-over-month volatility (±10–50%) reflects seasonality not captured by a linear model — a next step would be seasonal decomposition.

---

## Project Structure

```
olist-analytics/
├── data/raw/              # 8 Olist CSVs
├── db/schema.sql          # PostgreSQL schema with FK constraints
├── scripts/
│   ├── db_connect.py      # SQLAlchemy connection utility
│   └── load_data.py       # CSV → PostgreSQL loader
├── queries/
│   ├── batch1_revenue.sql
│   ├── batch2_funnel_deliveries.sql
│   └── batch3_cohort_advanced.sql
├── notebooks/
│   └── 01_eda.ipynb       # Pandas replications + hypothesis tests + forecasting
└── README.md
```

---

## SQL Patterns Demonstrated

| Pattern | Query |
|---------|-------|
| DATE_TRUNC + GROUP BY | Monthly GMV trend (Q1) |
| Multi-table JOIN (3 tables) | Category revenue, delivery delay (Q2, Q6) |
| Window function — SUM() OVER () | Payment share %, running GMV (Q3, Q11) |
| Window function — RANK() / DENSE_RANK() | Seller ranking within state (Q10) |
| Window function — LAG() | MoM growth % (Q11) |
| CTE (single) | Repeat customer rate (Q8) |
| CTE (chained, 2 CTEs) | Cohort retention (Q9) |
| CASE WHEN + EXTRACT | Delivery bucket → review score (Q7) |
| NTILE() | AOV quartile by state (Q12) |