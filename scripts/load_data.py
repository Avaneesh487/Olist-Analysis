import pandas as pd
import os
import sys

sys.path.append(os.path.dirname(__file__))
from db_connect import get_engine

RAW_DATA_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw')

engine = get_engine()

files_to_tables = [
    ("olist_customers_dataset.csv",         "customers"),
    ("olist_sellers_dataset.csv",           "sellers"),
    ("olist_products_dataset.csv",          "products"),
    ("olist_orders_dataset.csv",            "orders"),
    ("olist_order_items_dataset.csv",       "order_items"),
    ("olist_order_payments_dataset.csv",    "payments"),
    ("olist_order_reviews_dataset.csv",     "reviews"),
    ("olist_geolocation_dataset.csv",       "geolocation"),
]

for filename, table in files_to_tables:
    path = os.path.join(RAW_DATA_PATH, filename)
    print(f"Loading {filename} → {table}...")
    df = pd.read_csv(path)
    df.to_sql(table, engine, if_exists="append", index=False)
    print(f"  Done. {len(df)} rows inserted.")

print("\nAll tables loaded successfully.")