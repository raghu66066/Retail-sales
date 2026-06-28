# 🛒 Retail Sales Performance Dashboard
### End-to-End Data Analytics Project | SQL Server + Power BI

---

## 📌 Project Overview

A complete retail analytics solution built using **SQL Server** and **Power BI**, analyzing 3,000 orders across 3 years (2022–2024) for a fictional Indian e-commerce retailer.

The project demonstrates the full data analyst workflow:
- Designing a **Star Schema** data model
- Engineering **SQL pipelines** for cleansing, validation, and analytics
- Building a **3-page executive Power BI dashboard** with drill-through and risk alerts

---

## 🎯 Business Questions Answered

| # | Business Question | Tool Used |
|---|-------------------|-----------|
| 1 | Which categories and regions drive the most revenue? | Power BI + SQL |
| 2 | How is sales trending month-over-month and year-over-year? | DAX Time Intelligence |
| 3 | Which orders are high-discount, loss-making, or late-shipped? | SQL CASE WHEN + Power BI Alerts |
| 4 | How does each customer segment perform by region? | SQL ROLLUP + Power BI Matrix |
| 5 | Which are the top 5 products per category? | SQL RANK() Window Function |

---

## 🗂️ Project Structure

```
RetailSalesDashboard/
│
├── data/
│   ├── dim_product.csv       # 20 products across 7 categories
│   ├── dim_customer.csv      # 200 customers (4 segments, 5 regions)
│   ├── dim_date.csv          # 1,096 date records (2022–2024)
│   ├── dim_shipping.csv      # 4 shipping modes
│   └── fact_sales.csv        # 3,000 order transactions
│
├── sql/
│   ├── 01_create_schema.sql  # Database, tables, FK constraints
│   ├── 02_load_data.sql      # BULK INSERT pipeline
│   ├── 03_cleansing_validation.sql  # Data quality checks + risk view
│   └── 04_analytics_queries.sql    # 7 advanced analytical queries
│
├── powerbi/
│   ├── DAX_Measures.dax      # All 25+ DAX measures with comments
│   └── Dashboard_Layout_Guide.txt  # Step-by-step Power BI build guide
│
└── README.md
```

---

## 🏗️ Data Model — Star Schema

```
                    ┌─────────────────┐
                    │   Dim_Date      │
                    │─────────────────│
                    │ DateKey (PK)    │
                    │ FullDate        │
                    │ Year, Quarter   │
                    │ Month, MonthName│
                    └────────┬────────┘
                             │ 1
                             │
┌─────────────────┐    ┌─────┴────────────────────────┐    ┌──────────────────┐
│  Dim_Product    │    │        Fact_Sales             │    │  Dim_Customer    │
│─────────────────│    │──────────────────────────────│    │──────────────────│
│ ProductKey (PK) │◄───│ OrderID (PK)                 │───►│ CustomerKey (PK) │
│ ProductName     │    │ OrderDateKey (FK → Dim_Date) │    │ CustomerName     │
│ Category        │    │ ShipDateKey  (FK → Dim_Date) │    │ Segment          │
│ UnitPrice       │    │ ProductKey   (FK)             │    │ Region           │
└─────────────────┘    │ CustomerKey  (FK)             │    │ City             │
                        │ Quantity, UnitPrice           │    └──────────────────┘
                        │ SalesAmount, CostAmount       │
                        │ Profit, DiscountPct           │
                        │ ShipDays, PaymentMethod       │
                        └───────────────────────────────┘
```

**Design Decisions:**
- Integer surrogate keys for all dimension tables (compressed, fast joins)
- DateKey format: YYYYMMDD (e.g., 20230415) — avoids date string parsing
- Inactive ShipDateKey relationship activated in DAX with `USERELATIONSHIP()`
- All FK constraints enforced at database level

---

## 🔧 SQL Highlights

### Advanced Techniques Used

**Window Functions**
```sql
-- Month-over-Month growth using LAG()
LAG(TotalSales) OVER (ORDER BY Year, Month) AS PrevMonthSales
```

**CTEs (Common Table Expressions)**
```sql
WITH MonthlySales AS (
    SELECT Year, Month, SUM(SalesAmount) AS TotalSales ...
)
SELECT *, ROUND((TotalSales - PrevSales)/PrevSales * 100, 2) AS MoM_Growth
FROM MonthlySales
```

**CASE WHEN Risk Categorisation**
```sql
CASE
    WHEN DiscountPct >= 20 THEN 'High Discount Risk'
    WHEN Profit < 0        THEN 'Loss Order'
    WHEN ShipDays >= 6     THEN 'Late Shipment Risk'
    ELSE 'Normal'
END AS RiskFlag
```

**RANK() with PARTITION BY (Top 5 per Category)**
```sql
RANK() OVER (
    PARTITION BY p.Category
    ORDER BY SUM(f.SalesAmount) DESC
) AS RevenueRank
```

---

## 📊 Power BI Dashboard — 3 Pages

### Page 1: Executive Summary
- 6 KPI Cards (Sales, Profit, Margin %, Orders, YoY Growth, AOV)
- Line chart: Monthly Sales & Profit Trend
- Donut chart: Sales by Category
- Bar chart: Sales by Region
- Table: Top 10 Products with conditional formatting
- Slicers: Year, Category, Region, Segment

### Page 2: Regional Drill-Through
- Drill-through from Region → deep-dive analysis
- Stacked column: Monthly Sales by Category
- Scatter chart: City Sales vs Profit (bubble size = order count)
- Matrix heat map: City × Category sales intensity

### Page 3: Risk & Exception Report
- Alert KPI cards (High Discount Orders, Loss Orders, Late Shipments)
- Dynamic narrative text summary
- Risk-flagged order table with conditional row coloring
- Risk distribution bar chart

---

## 📈 Key DAX Measures

```dax
-- Year-over-Year Growth
YoY Growth % =
    DIVIDE([Total Sales] - [Sales PY], [Sales PY], 0) * 100

-- Sales Running Total (Cumulative)
Sales Running Total =
    CALCULATE([Total Sales],
        FILTER(ALL(Dim_Date),
            Dim_Date[FullDate] <= MAX(Dim_Date[FullDate])))

-- Dynamic Executive Narrative
Executive Summary Text =
    "Total sales: ₹" & FORMAT([Total Sales], "#,##0") &
    " | YoY: " & FORMAT([YoY Growth %], "+0.0;-0.0") & "%"
```

---

## 🚀 How to Run This Project

### Prerequisites
- SQL Server 2019+ or SQL Server Express (free)
- SQL Server Management Studio (SSMS)
- Power BI Desktop (free)

### Steps

**1. Set up the database**
```sql
-- Run scripts in order:
01_create_schema.sql    -- Creates DB, tables, FK constraints
02_load_data.sql        -- Loads all 5 CSVs (update file path first)
03_cleansing_validation.sql  -- Cleans data, creates risk view
04_analytics_queries.sql     -- Run analytics queries (optional, for validation)
```

**2. Update file path in 02_load_data.sql**
```sql
-- Change this line to your local path:
FROM 'C:\Projects\RetailSales\data\dim_product.csv'
```

**3. Build Power BI Dashboard**
- Open Power BI Desktop
- Get Data → SQL Server → localhost → RetailSalesDB
- Import: Dim_Product, Dim_Customer, Dim_Date, Fact_Sales, v_Executive_Summary
- Follow `powerbi/Dashboard_Layout_Guide.txt` to build all 3 pages
- Paste measures from `powerbi/DAX_Measures.dax`

---

## 💡 Skills Demonstrated

| Skill | Details |
|-------|---------|
| SQL Server | T-SQL, SSMS, RDBMS, BULK INSERT |
| Data Modeling | Star Schema, Fact & Dimension tables, Surrogate Keys |
| ETL Pipeline | Staging → Target, Cleansing, Deduplication, Validation |
| Advanced SQL | CTEs, Window Functions (LAG, RANK, ROW_NUMBER), Complex Joins |
| Power BI | Star Schema design, Relationship management, Cross-filter |
| DAX | CALCULATE, Time Intelligence (TOTALYTD, SAMEPERIODLASTYEAR), RANKX |
| Dashboard UX | Drill-through, Dynamic narratives, Matrix heat maps, KPI alerts |
| Excel | Pivot analysis, data validation (supplementary) |

---

## 👤 Author

**Raghu G** — Data Analyst, 5+ years experience
- 📧 raghu66066@gmail.com
- 🔗 [LinkedIn](https://www.linkedin.com/in/raghug-data-analyst)
- 💻 [GitHub](https://github.com/raghu66066)

---

*This project is part of a 3-project retail analytics portfolio. See also:*
- *Project 2: Customer Churn & RFM Segmentation Analysis*
- *Project 3: Product Returns & Profitability Analysis*
