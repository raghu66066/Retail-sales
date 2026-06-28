-- ============================================================
-- PROJECT 1: Retail Sales Performance Dashboard
-- SCRIPT 01: Create Database, Schema & Tables (Star Schema)
-- Author  : Raghu G | Data Analyst
-- Tool    : SQL Server (T-SQL / SSMS)
-- ============================================================

-- ── Step 1: Create Database ──────────────────────────────────
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RetailSalesDB')
BEGIN
    CREATE DATABASE RetailSalesDB;
    PRINT 'Database RetailSalesDB created.';
END
GO

USE RetailSalesDB;
GO

-- ── Step 2: Drop tables if they exist (clean slate) ──────────
IF OBJECT_ID('dbo.Fact_Sales',      'U') IS NOT NULL DROP TABLE dbo.Fact_Sales;
IF OBJECT_ID('dbo.Dim_Product',     'U') IS NOT NULL DROP TABLE dbo.Dim_Product;
IF OBJECT_ID('dbo.Dim_Customer',    'U') IS NOT NULL DROP TABLE dbo.Dim_Customer;
IF OBJECT_ID('dbo.Dim_Date',        'U') IS NOT NULL DROP TABLE dbo.Dim_Date;
IF OBJECT_ID('dbo.Dim_ShipMode',    'U') IS NOT NULL DROP TABLE dbo.Dim_ShipMode;
GO

-- ── Step 3: Dimension Tables ─────────────────────────────────

-- DIM_PRODUCT
CREATE TABLE dbo.Dim_Product (
    ProductKey      INT           NOT NULL PRIMARY KEY,
    ProductName     NVARCHAR(100) NOT NULL,
    Category        NVARCHAR(50)  NOT NULL,
    UnitPrice       DECIMAL(10,2) NOT NULL
);

-- DIM_CUSTOMER
CREATE TABLE dbo.Dim_Customer (
    CustomerKey     INT           NOT NULL PRIMARY KEY,
    CustomerName    NVARCHAR(100) NOT NULL,
    Segment         NVARCHAR(50)  NOT NULL,
    Region          NVARCHAR(50)  NOT NULL,
    City            NVARCHAR(50)  NOT NULL
);

-- DIM_DATE
CREATE TABLE dbo.Dim_Date (
    DateKey         INT           NOT NULL PRIMARY KEY,  -- YYYYMMDD surrogate
    FullDate        DATE          NOT NULL,
    Day             TINYINT       NOT NULL,
    Month           TINYINT       NOT NULL,
    Year            SMALLINT      NOT NULL,
    MonthName       NVARCHAR(15)  NOT NULL,
    DayName         NVARCHAR(10)  NOT NULL,
    Quarter         TINYINT       NOT NULL,
    IsWeekday       BIT           NOT NULL
);

-- DIM_SHIPMODE
CREATE TABLE dbo.Dim_ShipMode (
    ShipModeKey     INT           NOT NULL PRIMARY KEY,
    ShipMode        NVARCHAR(30)  NOT NULL
);

-- ── Step 4: Fact Table ───────────────────────────────────────

CREATE TABLE dbo.Fact_Sales (
    OrderID         INT            NOT NULL PRIMARY KEY,
    OrderDateKey    INT            NOT NULL,   -- FK -> Dim_Date
    ShipDateKey     INT            NOT NULL,   -- FK -> Dim_Date
    ProductKey      INT            NOT NULL,   -- FK -> Dim_Product
    CustomerKey     INT            NOT NULL,   -- FK -> Dim_Customer
    ShipMode        NVARCHAR(30)   NOT NULL,
    PaymentMethod   NVARCHAR(20)   NOT NULL,
    Quantity        SMALLINT       NOT NULL,
    UnitPrice       DECIMAL(10,2)  NOT NULL,
    DiscountPct     TINYINT        NOT NULL,
    DiscountAmount  DECIMAL(10,2)  NOT NULL,
    SalesAmount     DECIMAL(12,2)  NOT NULL,
    CostAmount      DECIMAL(12,2)  NOT NULL,
    Profit          DECIMAL(12,2)  NOT NULL,
    ShipDays        TINYINT        NOT NULL,

    CONSTRAINT FK_Sales_OrderDate  FOREIGN KEY (OrderDateKey) REFERENCES dbo.Dim_Date(DateKey),
    CONSTRAINT FK_Sales_ShipDate   FOREIGN KEY (ShipDateKey)  REFERENCES dbo.Dim_Date(DateKey),
    CONSTRAINT FK_Sales_Product    FOREIGN KEY (ProductKey)   REFERENCES dbo.Dim_Product(ProductKey),
    CONSTRAINT FK_Sales_Customer   FOREIGN KEY (CustomerKey)  REFERENCES dbo.Dim_Customer(CustomerKey)
);

PRINT 'All tables created successfully (Star Schema).';
GO
