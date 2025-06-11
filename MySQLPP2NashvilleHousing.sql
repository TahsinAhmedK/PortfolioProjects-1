/*
Cleaning Data in SQL Queries
*/

SELECT *
FROM sqlpp2_data_cleaning.nashvillehousing;

-- Standardize Date Format

ALTER TABLE sqlpp2_data_cleaning.nashvillehousing
ADD SaleDateConverted DATE;

UPDATE sqlpp2_data_cleaning.nashvillehousing
SET SaleDateConverted = CASE
    WHEN SaleDate LIKE '%[a-zA-Z]%' THEN STR_TO_DATE(SaleDate, '%M %e, %Y')
    ELSE CAST(SaleDate AS DATE)
END;

SELECT *
FROM sqlpp2_data_cleaning.nashvillehousing;

-- Populate Property Address data

SELECT *
FROM sqlpp2_data_cleaning.nashvillehousing
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress)
FROM sqlpp2_data_cleaning.nashvillehousing AS a
JOIN sqlpp2_data_cleaning.nashvillehousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE sqlpp2_data_cleaning.nashvillehousing AS a
JOIN sqlpp2_data_cleaning.nashvillehousing AS b
  ON a.ParcelID = b.ParcelID
  AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL;

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM sqlpp2_data_cleaning.nashvillehousing;

SELECT
  SUBSTRING_INDEX(PropertyAddress, ',', 1) AS PropertySplitAddress,
  TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)) AS PropertySplitCity
FROM sqlpp2_data_cleaning.nashvillehousing;

ALTER TABLE sqlpp2_data_cleaning.nashvillehousing
ADD COLUMN PropertySplitAddress VARCHAR(255), 
ADD COLUMN PropertySplitCity VARCHAR(255);

UPDATE sqlpp2_data_cleaning.nashvillehousing
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1),
    PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));
    
SELECT *
FROM sqlpp2_data_cleaning.nashvillehousing;

SELECT OwnerAddress
FROM sqlpp2_data_cleaning.nashvillehousing;

SELECT
  SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerSplitAddress,
  TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)) AS OwnerSplitCity,
  TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS OwnerSplitState
FROM sqlpp2_data_cleaning.nashvillehousing;

ALTER TABLE sqlpp2_data_cleaning.nashvillehousing
ADD COLUMN OwnerSplitAddress VARCHAR(255),
ADD COLUMN OwnerSplitCity VARCHAR(255),
ADD COLUMN OwnerSplitState VARCHAR(255);

UPDATE sqlpp2_data_cleaning.nashvillehousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
    OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)),
    OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));
    
SELECT *
FROM sqlpp2_data_cleaning.nashvillehousing;

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM sqlpp2_data_cleaning.nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
       CASE 
           WHEN SoldAsVacant = 'Y' THEN 'Yes'
           WHEN SoldAsVacant = 'N' THEN 'No'
           ELSE SoldAsVacant
       END AS SoldAsVacantCleaned
FROM sqlpp2_data_cleaning.nashvillehousing;

UPDATE sqlpp2_data_cleaning.nashvillehousing
SET SoldAsVacant = CASE 
                       WHEN SoldAsVacant = 'Y' THEN 'Yes'
                       WHEN SoldAsVacant = 'N' THEN 'No'
                       ELSE SoldAsVacant
                   END;
                   
-- Remove Duplicates

WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM sqlpp2_data_cleaning.nashvillehousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM sqlpp2_data_cleaning.nashvillehousing
)
DELETE FROM sqlpp2_data_cleaning.nashvillehousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM RowNumCTE
    WHERE row_num > 1
);

-- Delete Unused Columns using a backup table

SELECT *
FROM sqlpp2_data_cleaning.nashvillehousing;

CREATE TABLE sqlpp2_data_cleaning.nashvillehousing_backup AS
SELECT * FROM sqlpp2_data_cleaning.nashvillehousing;

ALTER TABLE sqlpp2_data_cleaning.nashvillehousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;

SELECT *
FROM sqlpp2_data_cleaning.nashvillehousing;