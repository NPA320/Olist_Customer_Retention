"""
export_repeat_purchase_features.py
Mục đích: Export bảng repeat_purchase_features (từ sql/04_repeat_purchase_features.sql)
ra data/processed/repeat_purchase_features.csv để train model ở
notebooks/03_churn_model.ipynb.

Cách chạy:
    python scripts/export_repeat_purchase_features.py
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

OUTPUT_PATH = "data/processed/repeat_purchase_features.csv"


def main():
    engine = create_engine(
        f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

    print("Reading repeat_purchase_features from Postgres...")
    df = pd.read_sql("SELECT * FROM repeat_purchase_features", engine)
    print(f"  -> {len(df):,} rows, {len(df.columns)} columns")
    print(df['repeat_within_180d'].value_counts(normalize=True).round(4))

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"Saved to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
