#!/usr/bin/env python3
"""Create nashville_housing table from SQLModel. Run from nashville-housing/: python scripts/create_tables.py"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sqlmodel import SQLModel

from config import get_engine, get_table_name
from models import NashvilleHousing  # noqa: F401 — register table


def main():
    SQLModel.metadata.create_all(get_engine())
    print(f"Tables created: {get_table_name()}.")


if __name__ == "__main__":
    main()
