-- ============================================================
-- PROJECT 1: Retail Sales Performance Dashboard
-- SCRIPT 02: Load Data via BULK INSERT (Staging Pipeline)
-- Author  : Raghu G | Data Analyst
-- NOTE    : Update file paths to match your local folder
-- ============================================================

USE RetailSalesDB;
GO

-- ── IMPORTANT: Update this path to where you saved the CSVs ──
-- Example: C:\Projects\RetailSales\data\

DECLARE @DataPath NVARCHAR(200) = 'C:\Projects\RetailSales\data\';

-- ── Load Dim_Product ─────────────────────────────────────────
BULK INSERT dbo.Dim_Product
FROM 'C:\Projects\RetailSales\data\dim_product.csv'
WITH (
    FIRSTROW        = 2,        -- skip header row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
PRINT 'Dim_Product loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- ── Load Dim_Customer ────────────────────────────────────────
BULK INSERT dbo.Dim_Customer
FROM 'C:\Projects\RetailSales\data\dim_customer.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
PRINT 'Dim_Customer loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- ── Load Dim_Date ────────────────────────────────────────────
BULK INSERT dbo.Dim_Date
FROM 'C:\Projects\RetailSales\data\dim_date.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
PRINT 'Dim_Date loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- ── Load Dim_ShipMode ────────────────────────────────────────
BULK INSERT dbo.Dim_ShipMode
FROM 'C:\Projects\RetailSales\data\dim_shipping.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
PRINT 'Dim_ShipMode loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- ── Load Fact_Sales ──────────────────────────────────────────
BULK INSERT dbo.Fact_Sales
FROM 'C:\Projects\RetailSales\data\fact_sales.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
PRINT 'Fact_Sales loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- ── Verify row counts ────────────────────────────────────────
SELECT 'Dim_Product'  AS TableName, COUNT(*) AS RowCount FROM dbo.Dim_Product  UNION ALL
SELECT 'Dim_Customer',               COUNT(*)             FROM dbo.Dim_Customer UNION ALL
SELECT 'Dim_Date',                   COUNT(*)             FROM dbo.Dim_Date     UNION ALL
SELECT 'Dim_ShipMode',               COUNT(*)             FROM dbo.Dim_ShipMode UNION ALL
SELECT 'Fact_Sales',                 COUNT(*)             FROM dbo.Fact_Sales;
GO
