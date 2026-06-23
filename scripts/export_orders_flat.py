"""
export_orders_flat.py
Mục đích: Export bảng orders_flat (đã tạo bởi sql/02_data_cleaning_and_join.sql)
từ Postgres ra data/processed/orders_flat.csv để dùng cho Python ở các
notebook EDA / RFM / model.

Cách chạy:
    python scripts/export_orders_flat.py

Yêu cầu: file .env ở thư mục gốc project đã có đủ DB_USER/DB_PASSWORD/...
"""

import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "olist_db")

OUTPUT_PATH = "data/processed/orders_flat.csv"


def main():
    engine = create_engine(
        f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

    print("Reading orders_flat from Postgres...")
    df = pd.read_sql("SELECT * FROM orders_flat", engine)
    print(f"  -> {len(df):,} rows, {len(df.columns)} columns")

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"Saved to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
