"""
data_loader.py
Mục đích: Đọc 9 file CSV gốc của Olist và load vào các bảng Postgres
đã được tạo sẵn bởi sql/01_create_tables.sql.

Cách chạy:
    python scripts/data_loader.py

Yêu cầu trước khi chạy:
    1. Đã chạy sql/01_create_tables.sql để tạo schema
    2. Đã đặt 9 file CSV gốc vào data/raw/
    3. Đã chỉnh thông tin kết nối DB ở phần CONFIG dưới đây
"""

import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv
load_dotenv()
# ============================================================
# CONFIG - chỉnh lại theo máy của bạn
# ============================================================

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "olist_db")

RAW_DATA_DIR = "data/raw"

# Thứ tự load PHẢI tuân theo ràng buộc khóa ngoại đã khai báo:
# customers -> orders (orders.customer_id FK tới customers)
# orders -> order_items / order_payments / order_reviews (đều FK tới orders)
# products, sellers, category_translation, geolocation: độc lập, load lúc nào cũng được
FILE_TABLE_MAP = {
    "olist_customers_dataset.csv": "customers",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "category_translation",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
}


def get_engine():
    conn_str = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    return create_engine(conn_str)


def load_csv_to_table(engine, file_name: str, table_name: str):
    file_path = os.path.join(RAW_DATA_DIR, file_name)
    print(f"Loading {file_name} -> table '{table_name}' ...")

    df = pd.read_csv(file_path)


    df.to_sql(table_name, engine, if_exists="append", index=False)
    print(f"  -> Done: {len(df):,} rows loaded.")


def main():
    engine = get_engine()
    for file_name, table_name in FILE_TABLE_MAP.items():
        load_csv_to_table(engine, file_name, table_name)
    print("\nAll 9 tables loaded successfully.")


if __name__ == "__main__":
    main()
