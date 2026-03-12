# Database scripts

**SQLModel** (schema) + **pandas** `to_sql` (load) + **Pydantic settings** (config). Python only.

## Prerequisites

- DB running: `db/start.sh`. `db/.env` from `db/.env.example`.
- Excel file at `data/dataset.xlsx` (or pass path).
- `pip install -r requirements.txt`

## Commands (from `nashville-housing/`)

```bash
./create_tables.sh                 # create nashville_housing table
./load_data.sh                     # load from data/dataset.xlsx
./load_data.sh path/to/file.xlsx   # or pass .xlsx path
./verify_data.sh                   # verify dataset loaded correctly (optional path)
```

Or run with Python: `python scripts/create_tables.py`, `python scripts/load_data.py [path]`, `python scripts/verify_data.py [path]`.

Re-running load_data appends; truncate table for a fresh load.

## Layout

| File | Role |
|------|------|
| `config.py` | Settings from `db/.env` (DB + `TABLE_NAME`), engine, `get_table_name()` |
| `models.py` | SQLModel table `NashvilleHousing` |
| `create_tables.py` | Create table from metadata |
| `load_data.py` | Read .xlsx, bulk insert via `to_sql` |
| `verify_data.py` | Compare source file vs DB (row count, non-null per column) |

**Table:** `nashville_housing`. For `queries/queries.sql` (SQL Server), use PostgreSQL equivalents: `SaleDate::date`, `STRPOS`, `COALESCE`, `LENGTH`, etc.
