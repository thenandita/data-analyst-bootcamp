#!/usr/bin/env python3
"""Load Nashville Housing from Excel (.xlsx) into Postgres via pandas to_sql. Run create_tables.py first. Re-run appends; truncate for fresh load."""

import re
import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sqlalchemy import text

from config import get_engine, get_table_name

COLUMN_MAP = {
    "Unique ID": "unique_id",
    "Parcel ID": "parcel_id",
    "Land Use": "land_use",
    "Property Address": "property_address",
    "Sale Date": "sale_date",
    "Sale Price": "sale_price",
    "Legal Reference": "legal_reference",
    "Sold As Vacant": "sold_as_vacant",
    "Owner Name": "owner_name",
    "Owner Address": "owner_address",
    "Acreage": "acreage",
    "Tax District": "tax_district",
    "Land Value": "land_value",
    "Building Value": "building_value",
    "Total Value": "total_value",
    "Year Built": "year_built",
    "Bedrooms": "bedrooms",
    "Full Bath": "full_bath",
    "Half Bath": "half_bath",
}
TABLE_COLUMNS = list(COLUMN_MAP.values())
DATA_DIR = Path(__file__).resolve().parent.parent / "data"
DEFAULT_PATH = DATA_DIR / "dataset.xlsx"


def _to_snake(name: str) -> str:
    s = name.strip()
    s = re.sub(r"(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])|\s+|-", "_", s)
    return s.lower().strip("_")


def read_data(path: Path) -> pd.DataFrame:
    path = path.resolve()
    if not path.is_file():
        raise SystemExit(f"File not found: {path}")
    if path.suffix.lower() != ".xlsx":
        raise SystemExit("Expecting .xlsx file")
    df = pd.read_excel(path, engine="openpyxl")
    df.columns = df.columns.str.strip()
    rename = {}
    for col in df.columns:
        if col in COLUMN_MAP:
            rename[col] = COLUMN_MAP[col]
        else:
            snake = _to_snake(col)
            if snake in TABLE_COLUMNS:
                rename[col] = snake
    df = df.rename(columns=rename)
    df = df[[c for c in TABLE_COLUMNS if c in df.columns]]
    return df.where(pd.notna(df), None)


def main():
    path = Path(sys.argv[1]) if len(sys.argv) >= 2 else DEFAULT_PATH
    if not path.is_file():
        raise SystemExit(f"Data file not found: {path}. Use: python scripts/load_data.py <path>")
    df = read_data(path)
    print(f"Read {len(df)} rows from {path}")
    engine = get_engine()
    table_name = get_table_name()
    df.to_sql(table_name, engine, if_exists="append", index=False, method="multi", chunksize=5000)
    with engine.connect() as conn:
        count = conn.execute(text(f"SELECT count(*) FROM {table_name}")).scalar()
    print(f"Done. Total rows in {table_name}: {count}")


if __name__ == "__main__":
    main()
