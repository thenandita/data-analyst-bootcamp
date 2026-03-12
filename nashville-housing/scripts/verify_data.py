#!/usr/bin/env python3
"""Verify dataset was loaded correctly: compare row count and non-null counts per column to the source file."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sqlalchemy import text

from config import get_engine, get_table_name
from load_data import DEFAULT_PATH, read_data, TABLE_COLUMNS


def main():
    path = Path(sys.argv[1]) if len(sys.argv) >= 2 else DEFAULT_PATH
    if not path.is_file():
        raise SystemExit(f"Dataset not found: {path}. Use: python scripts/verify_data.py [path]")
    df = read_data(path)
    expected_rows = len(df)
    expected_non_null = {c: df[c].notna().sum() for c in df.columns if c in TABLE_COLUMNS}

    table_name = get_table_name()
    engine = get_engine()
    count_cols = ", ".join(f'count("{c}") as "{c}"' for c in TABLE_COLUMNS)
    with engine.connect() as conn:
        row = conn.execute(
            text(f"SELECT count(*) as total, {count_cols} FROM {table_name}")
        ).fetchone()
    total = row.total
    counts = {"total": total, **{c: getattr(row, c) for c in TABLE_COLUMNS}}

    ok = True
    print(f"Dataset: {path}")
    print(f"Table:   {table_name}")
    print()
    if total != expected_rows:
        print(f"  Row count: expected {expected_rows}, got {total}  FAIL")
        ok = False
    else:
        print(f"  Row count: {total}  OK")
    for col in df.columns:
        if col not in TABLE_COLUMNS:
            continue
        exp = expected_non_null.get(col, 0)
        got = counts.get(col, 0)
        if exp > 0 and got == 0:
            print(f"  Column '{col}': expected {exp} non-null, got 0  FAIL")
            ok = False
        elif exp != got:
            print(f"  Column '{col}': expected {exp} non-null, got {got}")
    if ok:
        print()
        print("Verification passed.")
    else:
        print()
        print("Verification failed.")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
