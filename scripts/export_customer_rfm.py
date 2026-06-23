"""
export_customer_rfm.py
Mục đích: Export bảng customer_rfm (đã tạo bởi sql/03_rfm_features.sql)
từ Postgres ra data/processed/customer_rfm.csv để dùng cho K-Means
clustering ở notebooks/02_rfm_segmentation.ipynb.

Cách chạy:
    python scripts/export_customer_rfm.py
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

OUTPUT_PATH = "data/processed/customer_rfm.csv"


def main():
    engine = create_engine(
        f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

    print("Reading customer_rfm from Postgres...")
    df = pd.read_sql("SELECT * FROM customer_rfm", engine)
    print(f"  -> {len(df):,} rows, {len(df.columns)} columns")

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"Saved to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
