create database sc;
use sc;

SELECT * FROM pallet_masked_fulldata;

show variables like 'secure_file_priv';
show variables like '%local%';
# OPT_LOCAL_INFILE=1   ---> set this parameter in workbench user connection settings (under Advanced)

# load commmand
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/pallet_Masked_fulldata.csv'
INTO TABLE pallet_Masked_fulldata 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

-- 1st moment business decision - Descriptive Statistics  -- Mean value calculate
select avg(QTY) AS mean_qty from pallet_Masked_fulldata;
select avg(QTY) as mean_for_allot from pallet_masked_fulldata where TransactionType = 'Allot';
select avg(QTY) as mean_for_return from pallet_masked_fulldata where TransactionType = 'Return';

-- Median value calculate --
SELECT QTY AS median_QTY
FROM (
SELECT QTY, ROW_NUMBER() OVER (ORDER BY QTY) AS row_num,
COUNT(*) OVER () AS total_count
FROM pallet_Masked_fulldata
) AS subquery
WHERE row_num = (total_count + 1) / 2 OR row_num = (total_count + 2) / 2;

-- Mode value calculate --
SELECT QTY AS mode_QTY
FROM (
SELECT QTY, COUNT(*) AS frequency
FROM pallet_Masked_fulldata
GROUP BY QTY
ORDER BY frequency DESC
LIMIT 1
) AS subquery;

-- 2nd moment business decision - Variance, Standard Deviation, and Range
SELECT
    STDDEV(QTY) AS std_dev_QTY,
    VARIANCE(QTY) AS variance_QTY,
    MAX(QTY) - MIN(QTY) AS range_QTY
FROM
    pallet_Masked_fulldata;
    
-- 3rd moment business decision - Skewness
SELECT
(
SUM(POWER(qty- (SELECT AVG(qty) FROM pallet_Masked_fulldata), 3)) /
(COUNT(*) * POWER((SELECT STDDEV(qty) FROM pallet_Masked_fulldata), 3))
) AS skewness
FROM pallet_Masked_fulldata;

-- 4th moment business decision - Kurtosis
SELECT
(
(SUM(POWER(qty- (SELECT AVG(qty) FROM pallet_Masked_fulldata), 4)) /
(COUNT(*) * POWER((SELECT STDDEV(qty) FROM pallet_Masked_fulldata), 4))) - 3
) AS kurtosis
FROM pallet_Masked_fulldata;

-- Calculate the quartiles and IQR
WITH qtyRanked AS (
    SELECT
        qty,
        ROW_NUMBER() OVER (ORDER BY qty) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM
        pallet_Masked_fulldata
)
, QuartilesCTE AS (
    SELECT
        MAX(CASE WHEN row_num <= CEIL(0.25 * total_rows) THEN qty END) AS Q1,
        MAX(CASE WHEN row_num <= CEIL(0.75 * total_rows) THEN qty END) AS Q3
    FROM
        qtyRanked
)
, IQRCTE AS (
    SELECT
        Q1,
        Q3,
        Q3 - Q1 AS IQR
    FROM
        QuartilesCTE
)
-- Identify outliers
SELECT
    qty
FROM
    pallet_Masked_fulldata
JOIN
    IQRCTE ON qty < Q1 - 1.5 * IQR OR qty > Q3 + 1.5 * IQR;
    

-- Total QTY lessthan 0 over Date and State --
SELECT Date, State, SUM(QTY) AS TotalQuantity
FROM pallet_masked_fulldata
WHERE QTY < 0
GROUP BY Date, State
ORDER BY TotalQuantity
LIMIT 10;

-- QTY Distribution FOR each state --
SELECT State,sum(QTY) AS QTY
FROM pallet_masked_fulldata
GROUP BY State;

-- Distribution of transaction Over Time with Total QTY --
SELECT Date,count(*) AS Transaction_Count,SUM(QTY) AS Total_QTY
FROM pallet_masked_fulldata
GROUP BY Date
ORDER BY Date;

#TOTAL QTY Distribution OVER Top 10 Dates & QTY With most customers
SELECT Date,count(distinct CustName) AS Customer_Count,SUM(QTY) AS TOTAL_QTY
FROM pallet_masked_fulldata
GROUP BY Date,QTY
ORDER BY Customer_Count DESC
LIMIT 10;

-- State vs QTY --
SELECT State,COUNT(QTY) AS QTY
FROM pallet_masked_fulldata
GROUP BY State
ORDER BY QTY ;

-- Region vs High QTY --
select Region,count(QTY) as QTY
from pallet_masked_fulldata
group by Region
order by QTY DESC;

-- Top 10 Customers QTY --
SELECT CustName,count(QTY) AS QTY
FROM pallet_masked_fulldata
GROUP BY CustName
ORDER BY QTY DESC
LIMIT 10;

-- DATA PREPROCESSING --

# Drop duplicates
DELETE p
FROM pallet_Masked_fulldata p
JOIN (
    SELECT 
        Date, CustName, City, Region, State, ProductCode, TransactionType, QTY, WHName,
        ROW_NUMBER() OVER (PARTITION BY 
            Date, CustName, City, Region, State, ProductCode, TransactionType, QTY, WHName
        ORDER BY (SELECT NULL)) AS RowNum
    FROM pallet_Masked_fulldata
) DuplicateCTE ON 
    p.Date = DuplicateCTE.Date
    AND p.CustName = DuplicateCTE.CustName
    AND p.City = DuplicateCTE.City
    AND p.Region = DuplicateCTE.Region
    AND p.State = DuplicateCTE.State
    AND p.ProductCode = DuplicateCTE.ProductCode
    AND p.TransactionType = DuplicateCTE.TransactionType
    AND p.QTY = DuplicateCTE.QTY
    AND p.WHName = DuplicateCTE.WHName
WHERE DuplicateCTE.RowNum > 1;        -- Total 28229 duplicates removed --
select * from pallet_Masked_fulldata;

-- Binning to QTY column --
SELECT
    Date, CustName, City, Region, State, ProductCode,
    TransactionType,QTY,
    CASE
        WHEN QTY <= 0 THEN 'Very_Low_QTY'
        WHEN QTY > 0 AND QTY <= 50 THEN 'Low_QTY'
        WHEN QTY > 50 THEN 'Medium_QTY'
        ELSE 'High_QTY'
    END AS QTY_Bin,
    WHName
FROM pallet_masked_fulldata;

-- Apply log transformation to QTY column --
SELECT
    Date, CustName, City, Region, State, ProductCode,
    TransactionType,LOG(QTY) AS Transformed_QTY, WHName
FROM pallet_masked_fulldata;

-- 1) Univariate Analysis --

SELECT AVG(QTY) AS mean_value, STDDEV(QTY) AS stddev_Value
FROM pallet_masked_fulldata;

-- 2) Bivariate Analysis:

-- Correlation between QTY and WHName:
SELECT
    SUM((QTY - avg_QTY) * (WHName - avg_WHName)) /
    (COUNT(*) * STDDEV(QTY) * STDDEV(WHName)) AS correlation
FROM (
    SELECT
        QTY,
        WHName,
        AVG(QTY) OVER () AS avg_QTY,
        AVG(WHName) OVER () AS avg_WHName
    FROM
        pallet_masked_fulldata
) AS subquery;


