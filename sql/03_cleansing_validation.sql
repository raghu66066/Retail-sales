-- ============================================================
-- PROJECT 1: Retail Sales Performance Dashboard
-- SCRIPT 03: Data Cleansing & Validation Pipeline
-- Author  : Raghu G | Data Analyst
-- ============================================================

USE RetailSalesDB;
GO

-- ============================================================
-- SECTION A: Data Quality Checks
-- ============================================================

-- A1. Check for NULL values in Fact_Sales critical columns
SELECT
    SUM(CASE WHEN OrderID       IS NULL THEN 1 ELSE 0 END) AS Null_OrderID,
    SUM(CASE WHEN OrderDateKey  IS NULL THEN 1 ELSE 0 END) AS Null_OrderDate,
    SUM(CASE WHEN ProductKey    IS NULL THEN 1 ELSE 0 END) AS Null_ProductKey,
    SUM(CASE WHEN CustomerKey   IS NULL THEN 1 ELSE 0 END) AS Null_CustomerKey,
    SUM(CASE WHEN SalesAmount   IS NULL THEN 1 ELSE 0 END) AS Null_SalesAmount,
    SUM(CASE WHEN Quantity      IS NULL THEN 1 ELSE 0 END) AS Null_Quantity
FROM dbo.Fact_Sales;

-- A2. Check for negative or zero Sales / Quantity (data anomaly flag)
SELECT
    COUNT(*) AS Anomaly_Count,
    'Negative or Zero SalesAmount' AS Issue
FROM dbo.Fact_Sales
WHERE SalesAmount <= 0

UNION ALL

SELECT COUNT(*), 'Negative Profit (potential loss orders)'
FROM dbo.Fact_Sales
WHERE Profit < 0

UNION ALL

SELECT COUNT(*), 'ShipDate before OrderDate'
FROM dbo.Fact_Sales
WHERE ShipDateKey < OrderDateKey;

-- A3. Duplicate order check
SELECT OrderID, COUNT(*) AS DupeCount
FROM dbo.Fact_Sales
GROUP BY OrderID
HAVING COUNT(*) > 1;

-- A4. Orphan FK check — ProductKeys in Fact not in Dim
SELECT DISTINCT f.ProductKey
FROM dbo.Fact_Sales f
LEFT JOIN dbo.Dim_Product p ON f.ProductKey = p.ProductKey
WHERE p.ProductKey IS NULL;

-- A5. Orphan FK check — CustomerKeys in Fact not in Dim
SELECT DISTINCT f.CustomerKey
FROM dbo.Fact_Sales f
LEFT JOIN dbo.Dim_Customer c ON f.CustomerKey = c.CustomerKey
WHERE c.CustomerKey IS NULL;

-- ============================================================
-- SECTION B: Data Cleansing
-- ============================================================

-- B1. Trim whitespace from dimension text columns (safe UPDATE)
UPDATE dbo.Dim_Product
SET
    ProductName = LTRIM(RTRIM(ProductName)),
    Category    = LTRIM(RTRIM(Category));

UPDATE dbo.Dim_Customer
SET
    CustomerName = LTRIM(RTRIM(CustomerName)),
    Segment      = LTRIM(RTRIM(Segment)),
    Region       = LTRIM(RTRIM(Region)),
    City         = LTRIM(RTRIM(City));

PRINT 'Whitespace trimmed from dimension tables.';

-- B2. Standardise Segment values (handle case inconsistency)
UPDATE dbo.Dim_Customer
SET Segment = CASE
    WHEN UPPER(Segment) = 'CONSUMER'        THEN 'Consumer'
    WHEN UPPER(Segment) = 'CORPORATE'       THEN 'Corporate'
    WHEN UPPER(Segment) = 'HOME OFFICE'     THEN 'Home Office'
    WHEN UPPER(Segment) = 'SMALL BUSINESS'  THEN 'Small Business'
    ELSE Segment
END;

PRINT 'Segment values standardised.';

-- B3. Flag high-discount orders (> 15% = procurement risk signal)
-- We add a computed view rather than altering fact (non-destructive)
IF OBJECT_ID('dbo.v_Sales_RiskFlags', 'V') IS NOT NULL
    DROP VIEW dbo.v_Sales_RiskFlags;
GO

CREATE VIEW dbo.v_Sales_RiskFlags AS
SELECT
    f.OrderID,
    f.OrderDateKey,
    p.Category,
    p.ProductName,
    c.Region,
    c.Segment,
    f.SalesAmount,
    f.Profit,
    f.DiscountPct,
    f.ShipDays,
    -- Risk categorisation using CASE WHEN
    CASE
        WHEN f.DiscountPct >= 20              THEN 'High Discount Risk'
        WHEN f.Profit < 0                     THEN 'Loss Order'
        WHEN f.ShipDays >= 6                  THEN 'Late Shipment Risk'
        ELSE 'Normal'
    END AS RiskFlag,
    -- Profit Margin %
    CASE
        WHEN f.SalesAmount = 0 THEN 0
        ELSE ROUND((f.Profit / f.SalesAmount) * 100, 2)
    END AS ProfitMarginPct
FROM dbo.Fact_Sales f
JOIN dbo.Dim_Product  p ON f.ProductKey  = p.ProductKey
JOIN dbo.Dim_Customer c ON f.CustomerKey = c.CustomerKey;
GO

PRINT 'Risk flag view created: dbo.v_Sales_RiskFlags';

-- Quick preview
SELECT TOP 10 * FROM dbo.v_Sales_RiskFlags ORDER BY RiskFlag;
GO
