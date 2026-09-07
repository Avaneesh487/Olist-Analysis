import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'scripts')))
from db_connect import get_engine

st.set_page_config(page_title="Olist Analytics", layout="wide", page_icon="🛒")
st.title("🛒 Olist E-Commerce Analytics Dashboard")
st.markdown("Brazilian E-Commerce Dataset · CDC 2026 · IIT KGP")

engine = get_engine()

@st.cache_data
def load_data():
    orders      = pd.read_sql("SELECT * FROM orders", engine)
    order_items = pd.read_sql("SELECT * FROM order_items", engine)
    customers   = pd.read_sql("SELECT * FROM customers", engine)
    reviews     = pd.read_sql("SELECT * FROM reviews", engine)
    products    = pd.read_sql("SELECT * FROM products", engine)

    date_cols = ['order_purchase_timestamp','order_approved_at',
                 'order_delivered_carrier_date','order_delivered_customer_date',
                 'order_estimated_delivery_date']
    for col in date_cols:
        orders[col] = pd.to_datetime(orders[col])

    return orders, order_items, customers, reviews, products

orders, order_items, customers, reviews, products = load_data()

delivered = orders[orders['order_status'] == 'delivered']
merged    = delivered.merge(order_items, on='order_id')

# ── KPI CARDS ────────────────────────────────────────────────────────────────
st.markdown("---")
st.subheader("Key Metrics")

total_gmv      = merged['price'].sum()
total_aov      = merged['price'].mean()
total_orders   = delivered['order_id'].nunique()
funnel_rate    = round(delivered.shape[0] / orders.shape[0] * 100, 2)

cust_orders = customers.merge(orders, on='customer_id')
order_counts = cust_orders.groupby('customer_unique_id')['order_id'].nunique()
retention_rate = round((order_counts > 1).sum() / len(order_counts) * 100, 2)

k1, k2, k3, k4, k5 = st.columns(5)
k1.metric("Total GMV",        f"R${total_gmv:,.0f}")
k2.metric("Avg Order Value",  f"R${total_aov:,.2f}")
k3.metric("Delivered Orders", f"{total_orders:,}")
k4.metric("Funnel Completion",f"{funnel_rate}%")
k5.metric("Repeat Customer %",f"{retention_rate}%")

# ── MONTHLY GMV TREND ─────────────────────────────────────────────────────────
st.markdown("---")
st.subheader("Monthly GMV Trend")

merged['month'] = merged['order_purchase_timestamp'].dt.to_period('M').astype(str)
monthly_gmv = merged.groupby('month').agg(
    gmv=('price', 'sum'),
    orders=('order_id', 'nunique')
).reset_index()

fig1 = px.line(monthly_gmv, x='month', y='gmv',
               markers=True,
               labels={'month': 'Month', 'gmv': 'GMV (R$)'},
               color_discrete_sequence=['#2c5282'])
fig1.update_layout(xaxis_tickangle=-45, height=380)
st.plotly_chart(fig1, use_container_width=True)

# ── CATEGORY REVENUE + DELIVERY DELAY ────────────────────────────────────────
st.markdown("---")
col1, col2 = st.columns(2)

with col1:
    st.subheader("Top 10 Categories by Revenue")
    cat = merged.merge(products, on='product_id')
    cat = cat.dropna(subset=['product_category_name'])
    cat_rev = cat.groupby('product_category_name')['price'].sum().reset_index()
    cat_rev = cat_rev.sort_values('price', ascending=False).head(10)

    fig2 = px.bar(cat_rev, x='price', y='product_category_name',
                  orientation='h',
                  labels={'price': 'Revenue (R$)', 'product_category_name': 'Category'},
                  color='price', color_continuous_scale='Blues')
    fig2.update_layout(yaxis={'categoryorder': 'total ascending'}, height=420, coloraxis_showscale=False)
    st.plotly_chart(fig2, use_container_width=True)

with col2:
    st.subheader("Avg Delivery Days by State")
    delay_df = delivered.merge(customers, on='customer_id')
    delay_df = delay_df.dropna(subset=['order_delivered_customer_date', 'order_purchase_timestamp'])
    delay_df['delivery_days'] = (
        delay_df['order_delivered_customer_date'] - delay_df['order_purchase_timestamp']
    ).dt.total_seconds() / 86400

    state_delay = delay_df.groupby('customer_state')['delivery_days'].mean().reset_index()
    state_delay = state_delay.sort_values('delivery_days', ascending=False)

    fig3 = px.bar(state_delay, x='customer_state', y='delivery_days',
                  labels={'customer_state': 'State', 'delivery_days': 'Avg Delivery Days'},
                  color='delivery_days', color_continuous_scale='Reds')
    fig3.update_layout(height=420, coloraxis_showscale=False)
    st.plotly_chart(fig3, use_container_width=True)

# ── REVIEW SCORE VS DELIVERY BUCKET ──────────────────────────────────────────
st.markdown("---")
st.subheader("Review Score vs Delivery Timing")

rev_df = delivered.merge(reviews, on='order_id')
rev_df = rev_df.dropna(subset=['order_delivered_customer_date', 'order_estimated_delivery_date'])
rev_df['delay_days'] = (
    rev_df['order_delivered_customer_date'] - rev_df['order_estimated_delivery_date']
).dt.total_seconds() / 86400

bins   = [-999, -5, 0, 5, 999]
labels = ['Very Early (>5d)', 'Early (0-5d)', 'Late (1-5d)', 'Very Late (>5d)']
rev_df['delivery_bucket'] = pd.cut(rev_df['delay_days'], bins=bins, labels=labels)

bucket_scores = rev_df.groupby('delivery_bucket', observed=True).agg(
    avg_score=('review_score', 'mean'),
    total_orders=('order_id', 'count')
).reset_index()

fig4 = px.bar(bucket_scores, x='delivery_bucket', y='avg_score',
              text=bucket_scores['avg_score'].round(2),
              labels={'delivery_bucket': 'Delivery Timing', 'avg_score': 'Avg Review Score'},
              color='avg_score',
              color_continuous_scale='RdYlGn',
              range_y=[0, 5])
fig4.update_traces(textposition='outside')
fig4.update_layout(height=400, coloraxis_showscale=False)
st.plotly_chart(fig4, use_container_width=True)

st.markdown("---")
st.caption("Data: Olist Brazilian E-Commerce Dataset · Kaggle · 2016–2018")