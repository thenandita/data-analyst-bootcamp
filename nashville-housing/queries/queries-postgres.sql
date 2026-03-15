/*

  Cleaning Data in SQL Queries (PostgreSQL)

  Nashville Housing data cleaning pipeline. Run sections in order; some steps depend on
  previous ones (e.g. populate property address before splitting addresses).

*/

--------------------------------------------------------------------------------------------------------------------------

/*
  1. Select All

  Fetches all rows and columns from nashville_housing. Use to inspect raw data before
  or after cleaning steps.
*/

SELECT *
FROM nashville_housing;

--------------------------------------------------------------------------------------------------------------------------

/*
  2. Standardize Date Format

  Converts sale_date from TIMESTAMP to date-only values.

  First approach: UPDATE in place. Sets each sale_date to its date part (stored as
  midnight if column stays TIMESTAMP). Run the SELECT to preview; run the UPDATE to apply.

  Fallback: If the UPDATE does not behave as expected (e.g. column type prevents it),
  add sale_date_converted (DATE), populate it from sale_date, then optionally drop
  sale_date and rename. ALTER TABLE ADD COLUMN adds the new column; UPDATE fills it.
*/

ALTER TABLE nashville_housing
  ADD COLUMN sale_date_converted DATE;

UPDATE nashville_housing
SET sale_date_converted = sale_date::date;

-- Alternative approach

SELECT sale_date, sale_date::date
FROM nashville_housing;

UPDATE nashville_housing
SET sale_date = sale_date::date;

--------------------------------------------------------------------------------------------------------------------------

/*
  3. Populate Property Address Data

  Fills NULL property_address values by copying from another row with the same parcel_id.
  Same parcel_id often implies same property; the other row may have the address.

  Self-join: Table aliased as a (rows with NULL address) and b (candidate source).
  ON a.parcel_id = b.parcel_id: same parcel.
  AND a.unique_id <> b.unique_id: different row (exclude self).
  WHERE a.property_address IS NULL: only rows missing an address.

  COALESCE(a.property_address, b.property_address): use a's address if present, else b's.

  UPDATE ... FROM: PostgreSQL syntax to update a using values from a join. Sets
  property_address to the coalesced value for each matched row.
*/

SELECT *
FROM nashville_housing
ORDER BY parcel_id;

SELECT a.parcel_id, a.property_address, b.parcel_id, b.property_address,
       COALESCE(a.property_address, b.property_address)
FROM nashville_housing a
JOIN nashville_housing b
  ON a.parcel_id = b.parcel_id
  AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL;

UPDATE nashville_housing a
SET property_address = COALESCE(a.property_address, b.property_address)
FROM nashville_housing b
WHERE a.parcel_id = b.parcel_id
  AND a.unique_id <> b.unique_id
  AND a.property_address IS NULL;

--------------------------------------------------------------------------------------------------------------------------

/*
  4. Break Out Address into Individual Columns (Address, City, State)

  Splits comma-separated address strings into separate columns for easier filtering
  and analysis.

  Property address (format: "123 Main St, Nashville"):
  - STRPOS(property_address, ','): 1-based position of the first comma.
  - SUBSTRING(str, start, length): extract a substring. Start and length are 1-based.
  - Address: from start to comma - 1. City: from comma + 1 to end (LENGTH gives rest).

  Owner address (format: "123 Main St, Nashville, TN"):
  - SPLIT_PART(str, delimiter, n): returns the nth part (1-based) after splitting.
  - TRIM: removes leading/trailing spaces from each part.

  ALTER TABLE ADD COLUMN: adds new columns. UPDATE: populates them from the split logic.
*/

SELECT property_address
FROM nashville_housing;

SELECT
  SUBSTRING(property_address, 1, STRPOS(property_address, ',') - 1) AS address,
  SUBSTRING(property_address, STRPOS(property_address, ',') + 1, LENGTH(property_address)) AS city
FROM nashville_housing;

ALTER TABLE nashville_housing
  ADD COLUMN property_split_address VARCHAR(255);

UPDATE nashville_housing
SET property_split_address = SUBSTRING(property_address, 1, STRPOS(property_address, ',') - 1);

ALTER TABLE nashville_housing
  ADD COLUMN property_split_city VARCHAR(255);

UPDATE nashville_housing
SET property_split_city = SUBSTRING(property_address, STRPOS(property_address, ',') + 1, LENGTH(property_address));

SELECT *
FROM nashville_housing;

SELECT owner_address
FROM nashville_housing;

SELECT
  TRIM(SPLIT_PART(owner_address, ',', 1)) AS address,
  TRIM(SPLIT_PART(owner_address, ',', 2)) AS city,
  TRIM(SPLIT_PART(owner_address, ',', 3)) AS state
FROM nashville_housing;

ALTER TABLE nashville_housing
  ADD COLUMN owner_split_address VARCHAR(255);

UPDATE nashville_housing
SET owner_split_address = TRIM(SPLIT_PART(owner_address, ',', 1));

ALTER TABLE nashville_housing
  ADD COLUMN owner_split_city VARCHAR(255);

UPDATE nashville_housing
SET owner_split_city = TRIM(SPLIT_PART(owner_address, ',', 2));

ALTER TABLE nashville_housing
  ADD COLUMN owner_split_state VARCHAR(255);

UPDATE nashville_housing
SET owner_split_state = TRIM(SPLIT_PART(owner_address, ',', 3));

SELECT *
FROM nashville_housing;

--------------------------------------------------------------------------------------------------------------------------

/*
  5. Change Y and N to Yes and No in "Sold as Vacant" Field

  Standardizes sold_as_vacant to "Yes" and "No" for consistency.

  First SELECT: Shows distinct values and counts (GROUP BY sold_as_vacant) to see
  current mix (Y, N, Yes, No). ORDER BY 2: sort by the second column (count).

  CASE: Maps 'Y' → 'Yes', 'N' → 'No', leaves other values unchanged. UPDATE applies
  the same logic to all rows.
*/

SELECT DISTINCT sold_as_vacant, COUNT(sold_as_vacant)
FROM nashville_housing
GROUP BY sold_as_vacant
ORDER BY 2;

SELECT sold_as_vacant,
  CASE
    WHEN sold_as_vacant = 'Y' THEN 'Yes'
    WHEN sold_as_vacant = 'N' THEN 'No'
    ELSE sold_as_vacant
  END
FROM nashville_housing;

UPDATE nashville_housing
SET sold_as_vacant = CASE
  WHEN sold_as_vacant = 'Y' THEN 'Yes'
  WHEN sold_as_vacant = 'N' THEN 'No'
  ELSE sold_as_vacant
END;

--------------------------------------------------------------------------------------------------------------------------

/*
  6. Remove Duplicates

  Identifies duplicate rows based on parcel_id, property_address, sale_price,
  sale_date, and legal_reference. Does not delete; use the result to decide.

  ROW_NUMBER() OVER (PARTITION BY ... ORDER BY unique_id): assigns 1, 2, 3, ... to
  rows within each group. Same (parcel_id, property_address, sale_price, sale_date,
  legal_reference) = one group. ORDER BY unique_id: deterministic ordering.

  row_num > 1: keeps only duplicates (second and later rows in each group). To delete
  duplicates, use DELETE with a subquery or CTE that targets row_num > 1.
*/

WITH row_num_cte AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY parcel_id, property_address, sale_price, sale_date, legal_reference
      ORDER BY unique_id
    ) AS row_num
  FROM nashville_housing
)
SELECT *
FROM row_num_cte
WHERE row_num > 1
ORDER BY property_address;

SELECT *
FROM nashville_housing;

--------------------------------------------------------------------------------------------------------------------------

/*
  7. Delete Unused Columns

  Drops columns that are redundant after cleaning (split addresses replace full
  addresses; sale_date_converted may replace sale_date if used).

  ALTER TABLE ... DROP COLUMN: removes each column. Data is lost. Ensure you have
  backups or have migrated needed data to the split columns before dropping.
*/

SELECT *
FROM nashville_housing;

ALTER TABLE nashville_housing
  DROP COLUMN owner_address,
  DROP COLUMN tax_district,
  DROP COLUMN property_address,
  DROP COLUMN sale_date;

--------------------------------------------------------------------------------------------------------------------------

/*
  8. Importing Data (SQL Server Specific)

  OPENROWSET and BULK INSERT are SQL Server features. For PostgreSQL, use:
  - scripts/load_data.py: loads Excel (.xlsx) via pandas to_sql
  - COPY ... FROM: for CSV files
*/
