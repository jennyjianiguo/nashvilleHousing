/*
Cleaning Nashville Housing Data in SQL Queries
Skills used: Joins, CTEs, CASE Statements, Substrings, Aggregate Functions, Converting Data Types
*/

select * from housing;

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

-- Change strings to date format
select SaleDate, STR_TO_DATE(SaleDate, '%M %D %Y')
from housing;

update housing
set SaleDate = STR_TO_DATE(SaleDate, '%M %D %Y');


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data

-- Update blank property addresses to NULL values
update housing set PropertyAddress = NULL where PropertyAddress = '';

-- Data observation: We find that houses with the same ParcelID have the same Property Address
select * from housing
-- where PropertyAddress IS NULL;
order by ParcelID;

-- Select property addresses as values from identical ParcelID rows
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
from housing a
join housing b
    on a.ParcelID = b.ParcelID
    and a.UniqueID != b.UniqueID
where a.PropertyAddress IS NULL;

-- Populate selected values into null cells
update housing a
join housing b
    on a.ParcelID = b.ParcelID
    and a.UniqueID != b.UniqueID
set a.PropertyAddress = ifnull(a.PropertyAddress, b.PropertyAddress)
where a.PropertyAddress IS NULL;


--------------------------------------------------------------------------------------------------------------------------

-- Breaking up Address into Individual Columns (Street, City)

-- Split PropertyAddress into Street and City
select substring_index(PropertyAddress, ',', 1) as street,
substring_index(PropertyAddress, ',', -1) as city
from housing;

-- Add Street and City columns into table
alter table housing add Street varchar(255);
update housing set Street = substring_index(PropertyAddress, ',', 1);
alter table housing add City varchar(255);
update housing set City = substring_index(PropertyAddress, ',', -1);


--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in Sold as Vacant Field

-- Find the different values in SoldAsVacant column
select distinct SoldAsVacant, count(SoldAsVacant)
from housing
group by SoldAsVacant;

-- Create new column to change Y and N to Yes and No
select SoldAsVacant,
	CASE
		WHEN SoldAsVacant = "Y" THEN "Yes"
		WHEN SoldAsVacant = "N" THEN "No"
        ELSE SoldAsVacant
	END as sold
from housing;

-- Update data to include changes
update housing set SoldAsVacant =
	CASE
		WHEN SoldAsVacant = "Y" THEN "Yes"
		WHEN SoldAsVacant = "N" THEN "No"
        ELSE SoldAsVacant
	END;
    

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Find Duplicate Rows

-- Create CTE to find data with duplicate ParcelID, PropertyAddress, SaleDate, SalePrice, and LegalReference values
with row_num_cte as (
	select *,
		row_number() over (
			partition by ParcelID, 
						PropertyAddress,
						SaleDate,
						SalePrice,
						LegalReference
			order by UniqueID) row_num
	from housing)
    
-- Select duplicate row values
-- Change "select" to "delete" to remove duplicate rows
select *
from row_num_cte
where row_num > 1
order by PropertyAddress;


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

alter table housing
drop column PropertyAddress, 
drop column OwnerAddress,
drop column TaxDistrict;
