-- ============================================================
-- PROJECT 1: Retail Sales Performance Dashboard
-- SCRIPT 04: Advanced Analytics Queries
--            (CTEs, Window Functions, Subqueries, CASE WHEN)
-- Author  : Raghu G | Data Analyst
-- ============================================================

USE RetailSalesDB;
GO

-- ============================================================
-- QUERY 1: Monthly Sales Trend with MOM Growth %
--          (Window Function: LAG)
-- ============================================================
WITH MonthlySales AS (
    SELECT
        d.Year,
        d.Month,
        d.MonthName,
        CAST(d.Year AS VARCHAR) + '-' + RIGHT('0' + CAST(d.Month AS VARCHAR), 2) AS YearMonth,
        SUM(f.SalesAmount) AS TotalSales,
        SUM(f.Profit)      AS TotalProfit,
        COUNT(DISTINCT f.OrderID) AS TotalOrders
    FROM dbo.Fact_Sales f
    JOIN dbo.Dim_Date d ON f.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.Month, d.MonthName
)
SELECT
    YearMonth,
    MonthName,
    Year,
    TotalSales,
    TotalProfit,
    TotalOrders,
    LAG(TotalSales) OVER (ORDER BY Year, Month) AS PrevMonthSales,
    ROUND(
        (TotalSales - LAG(TotalSales) OVER (ORDER BY Year, Month))
        / NULLIF(LAG(TotalSales) OVER (ORDER BY Year, Month), 0) * 100,
    2) AS MoM_Growth_Pct
FROM MonthlySales
ORDER BY Year, Month;
GO

-- ============================================================
-- QUERY 2: Top 5 Products by Revenue per Category
--          (Window Function: RANK with PARTITION BY)
-- ============================================================
WITH ProductRevenue AS (
    SELECT
        p.Category,
        p.ProductName,
        SUM(f.SalesAmount) AS TotalRevenue,
        SUM(f.Profit)      AS TotalProfit,
        SUM(f.Quantity)    AS UnitsSold,
        RANK() OVER (
            PARTITION BY p.Category
            ORDER BY SUM(f.SalesAmount) DESC
        ) AS RevenueRank
    FROM dbo.Fact_Sales f
    JOIN dbo.Dim_Product p ON f.ProductKey = p.ProductKey
    GROUP BY p.Category, p.ProductName
)
SELECT
    Category,
    ProductName,
    TotalRevenue,
    TotalProfit,
    UnitsSold,
    RevenueRank
FROM ProductRevenue
WHERE RevenueRank <= 5
ORDER BY Category, RevenueRank;
GO

-- ============================================================
-- QUERY 3: Regional Sales Performance vs. National Average
--          (Subquery for benchmark comparison)
-- ============================================================
WITH RegionSales AS (
    SELECT
        c.Region,
        SUM(f.SalesAmount)        AS RegionSales,
        SUM(f.Profit)             AS RegionProfit,
        COUNT(DISTINCT f.OrderID) AS TotalOrders,
        ROUND(AVG(f.SalesAmount), 2) AS AvgOrderValue
    FROM dbo.Fact_Sales f
    JOIN dbo.Dim_Customer c ON f.CustomerKey = c.CustomerKey
    GROUP BY c.Region
),
NationalAvg AS (
    SELECT AVG(RegionSales) AS NatAvgSales FROM RegionSales
)
SELECT
    r.Region,
    r.RegionSales,
    r.RegionProfit,
    r.TotalOrders,
    r.AvgOrderValue,
    n.NatAvgSales,
    ROUND((r.RegionSales - n.NatAvgSales) / n.NatAvgSales * 100, 2) AS VsNationalAvgPct,
    CASE
        WHEN r.RegionSales > n.NatAvgSales THEN 'Above Average'
        WHEN r.RegionSales < n.NatAvgSales THEN 'Below Average'
        ELSE 'At Average'
    END AS PerformanceStatus
FROM RegionSales r
CROSS JOIN NationalAvg n
ORDER BY r.RegionSales DESC;
GO
    
-- ============================================================
-- other method without cross join
-- ============================================================
WITH RegionSales AS (
    SELECT
        c.Region,
        SUM(f.SalesAmount)        AS RegionSales,
        SUM(f.Profit)             AS RegionProfit,
        COUNT(DISTINCT f.OrderID) AS TotalOrders,
        ROUND(AVG(f.SalesAmount), 2) AS AvgOrderValue
    FROM dbo.Fact_Sales f
    JOIN dbo.Dim_Customer c ON f.CustomerKey = c.CustomerKey
    GROUP BY c.Region
), 
NationalAvg AS (
    SELECT*,
    AVG(RegionSales) over() AS NatAvgSales             -- avg sales of total sales by region
   FROM RegionSales
)
   select *,
    ROUND((RegionSales - NatAvgSales) / NatAvgSales * 100, 2) AS VsNationalAvgPct,
    CASE
        WHEN RegionSales > NatAvgSales THEN 'Above Average'
        WHEN RegionSales < NatAvgSales THEN 'Below Average'
        ELSE 'At Average'
    END AS PerformanceStatus
   from NationalAvg
   ORDER BY RegionSales DESC;
GO    

-- ============================================================
-- QUERY 4: Customer Segment Profitability Breakdown
--          (Multi-level aggregation + COALESCE)
-- ============================================================
SELECT
    c.Segment,
    c.Region,
    COUNT(DISTINCT f.OrderID)           AS Orders,
    COUNT(DISTINCT f.CustomerKey)       AS UniqueCustomers,
    SUM(f.SalesAmount)                  AS TotalSales,
    SUM(f.Profit)                       AS TotalProfit,
    ROUND(SUM(f.Profit)/
          NULLIF(SUM(f.SalesAmount),0)*100, 2) AS ProfitMarginPct,
    COALESCE(
        ROUND(SUM(f.SalesAmount) /
              NULLIF(COUNT(DISTINCT f.CustomerKey),0), 2),
        0
    ) AS RevenuePerCustomer
FROM dbo.Fact_Sales f
JOIN dbo.Dim_Customer c ON f.CustomerKey = c.CustomerKey
GROUP BY ROLLUP(c.Segment, c.Region)
ORDER BY c.Segment, c.Region;
GO

-- ============================================================
-- QUERY 5: Shipping Performance Analysis
--          (CASE WHEN buckets + ROW_NUMBER for ranking)
-- ============================================================
WITH ShipAnalysis AS (
    SELECT
        f.ShipMode,
        f.ShipDays,
        c.Region,
        f.SalesAmount,
        CASE
            WHEN f.ShipDays <= 2 THEN 'Fast  (1-2 days)'
            WHEN f.ShipDays <= 4 THEN 'Normal (3-4 days)'
            WHEN f.ShipDays <= 6 THEN 'Slow   (5-6 days)'
            ELSE                      'Very Slow (7+ days)'
        END AS ShipSpeedBucket
    FROM dbo.Fact_Sales f
    JOIN dbo.Dim_Customer c ON f.CustomerKey = c.CustomerKey
)
SELECT
    ShipMode,
    ShipSpeedBucket,
    COUNT(*)              AS OrderCount,
    ROUND(AVG(ShipDays),2)AS AvgShipDays,
    SUM(SalesAmount)      AS TotalSales,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY ShipMode), 2) AS PctOfMode
FROM ShipAnalysis
GROUP BY ShipMode, ShipSpeedBucket
ORDER BY ShipMode, AvgShipDays;
GO

-- ============================================================
-- QUERY 6: YoY Sales Comparison (2022 vs 2023 vs 2024)
--          (PIVOT-style with CASE WHEN)
-- ============================================================
SELECT
    p.Category,
    SUM(CASE WHEN d.Year = 2022 THEN f.SalesAmount ELSE 0 END) AS Sales_2022,
    SUM(CASE WHEN d.Year = 2023 THEN f.SalesAmount ELSE 0 END) AS Sales_2023,
    SUM(CASE WHEN d.Year = 2024 THEN f.SalesAmount ELSE 0 END) AS Sales_2024,
    ROUND(
        (SUM(CASE WHEN d.Year = 2023 THEN f.SalesAmount ELSE 0 END)
       - SUM(CASE WHEN d.Year = 2022 THEN f.SalesAmount ELSE 0 END))
       / NULLIF(SUM(CASE WHEN d.Year = 2022 THEN f.SalesAmount ELSE 0 END),0) * 100,
    1) AS YoY_Growth_22_23_Pct,
    ROUND(
        (SUM(CASE WHEN d.Year = 2024 THEN f.SalesAmount ELSE 0 END)
       - SUM(CASE WHEN d.Year = 2023 THEN f.SalesAmount ELSE 0 END))
       / NULLIF(SUM(CASE WHEN d.Year = 2023 THEN f.SalesAmount ELSE 0 END),0) * 100,
    1) AS YoY_Growth_23_24_Pct
FROM dbo.Fact_Sales f
JOIN dbo.Dim_Product p ON f.ProductKey  = p.ProductKey
JOIN dbo.Dim_Date   d ON f.OrderDateKey = d.DateKey
GROUP BY p.Category
ORDER BY Sales_2024 DESC;
GO

-- ============================================================
-- QUERY 7: Executive Summary View (for Power BI Direct Query)
-- ============================================================
IF OBJECT_ID('dbo.v_Executive_Summary', 'V') IS NOT NULL
    DROP VIEW dbo.v_Executive_Summary;
GO

CREATE VIEW dbo.v_Executive_Summary AS
SELECT
    f.OrderID,
    d.FullDate         AS OrderDate,
    d.Year,
    d.Quarter,
    d.Month,
    d.MonthName,
    p.Category,
    p.ProductName,
    c.CustomerName,
    c.Segment,
    c.Region,
    c.City,
    f.ShipMode,
    f.PaymentMethod,
    f.Quantity,
    f.UnitPrice,
    f.DiscountPct,
    f.DiscountAmount,
    f.SalesAmount,
    f.CostAmount,
    f.Profit,
    f.ShipDays,
    ROUND(f.Profit / NULLIF(f.SalesAmount,0) * 100, 2) AS ProfitMarginPct
FROM dbo.Fact_Sales   f
JOIN dbo.Dim_Date     d ON f.OrderDateKey = d.DateKey
JOIN dbo.Dim_Product  p ON f.ProductKey   = p.ProductKey
JOIN dbo.Dim_Customer c ON f.CustomerKey  = c.CustomerKey;
GO

PRINT 'Executive Summary View created: dbo.v_Executive_Summary';
SELECT TOP 5 * FROM dbo.v_Executive_Summary;
GO
