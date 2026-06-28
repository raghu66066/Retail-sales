import csv
import random
from datetime import date, timedelta

random.seed(42)

# ── Dimension data ──────────────────────────────────────────────────────────
regions    = ["North","South","East","West","Central"]
categories = ["Electronics","Clothing","Home & Kitchen","Sports","Beauty","Books","Toys"]
segments   = ["Consumer","Corporate","Home Office","Small Business"]
ship_modes = ["Standard","Express","Same Day","First Class"]
payment    = ["Credit Card","Debit Card","UPI","Net Banking","COD"]

products = [
    (1, "Samsung 55\" 4K TV",      "Electronics",   45000),
    (2, "Apple iPhone 15",         "Electronics",   79999),
    (3, "Boat Wireless Earbuds",   "Electronics",    2999),
    (4, "Lenovo Laptop 15.6\"",    "Electronics",   55000),
    (5, "Men's Running Shoes",     "Sports",          3499),
    (6, "Yoga Mat Premium",        "Sports",          1299),
    (7, "Cricket Bat SG",          "Sports",          2800),
    (8, "Cotton Formal Shirt",     "Clothing",        1199),
    (9, "Levis 511 Jeans",         "Clothing",        2999),
    (10,"Floral Summer Dress",     "Clothing",        1599),
    (11,"Instant Pot 6Qt",         "Home & Kitchen",  8999),
    (12,"Non-Stick Cookware Set",  "Home & Kitchen",  3499),
    (13,"Air Purifier HEPA",       "Home & Kitchen", 12999),
    (14,"Face Serum Vitamin C",    "Beauty",           999),
    (15,"Hair Dryer 2000W",        "Beauty",          2499),
    (16,"Moisturizer SPF50",       "Beauty",           799),
    (17,"Atomic Habits (Book)",    "Books",             399),
    (18,"Python Crash Course",     "Books",             599),
    (19,"LEGO Technic 42115",      "Toys",            8999),
    (20,"Barbie Dreamhouse",       "Toys",            4999),
]

first = ["Amit","Priya","Rahul","Sneha","Vikram","Anjali","Rohit","Divya",
         "Suresh","Kavya","Arjun","Meena","Kiran","Pooja","Naveen","Rekha",
         "Sanjay","Lakshmi","Vijay","Nisha","Rajesh","Sunita","Manoj","Geeta"]
last  = ["Sharma","Verma","Patel","Reddy","Nair","Iyer","Singh","Gupta",
         "Kumar","Joshi","Rao","Mehta","Das","Shah","Mishra","Pillai"]
cities = ["Mumbai","Delhi","Bangalore","Hyderabad","Chennai",
          "Kolkata","Pune","Jaipur","Ahmedabad","Surat"]

customers = []
for i in range(1, 201):
    customers.append((
        i,
        f"{random.choice(first)} {random.choice(last)}",
        random.choice(segments),
        random.choice(regions),
        random.choice(cities)
    ))

# ── Date dimension ───────────────────────────────────────────────────────────
def build_date_rows(start, end):
    rows, d = [], start
    while d <= end:
        rows.append((
            int(d.strftime("%Y%m%d")), d.isoformat(),
            d.day, d.month, d.year,
            d.strftime("%B"), d.strftime("%A"),
            (d.month - 1) // 3 + 1,
            1 if d.weekday() < 5 else 0
        ))
        d += timedelta(days=1)
    return rows

date_rows = build_date_rows(date(2022, 1, 1), date(2024, 12, 31))

# ── Fact table ───────────────────────────────────────────────────────────────
fact_rows = []
order_id  = 1000
start_d   = date(2022, 1, 1)

for _ in range(3000):
    order_date = start_d + timedelta(days=random.randint(0, 1094))
    ship_delay = random.randint(1, 7)
    ship_date  = order_date + timedelta(days=ship_delay)

    prod       = random.choice(products)
    cust       = random.choice(customers)
    qty        = random.randint(1, 5)
    disc_pct   = random.choice([0, 0, 0, 5, 10, 15, 20])
    unit_price = prod[3]
    discount   = round(unit_price * disc_pct / 100, 2)
    sales      = round((unit_price - discount) * qty, 2)
    cost       = round(unit_price * qty * random.uniform(0.55, 0.75), 2)
    profit     = round(sales - cost, 2)

    fact_rows.append((
        order_id,
        int(order_date.strftime("%Y%m%d")),
        int(ship_date.strftime("%Y%m%d")),
        prod[0], cust[0],
        random.choice(ship_modes),
        random.choice(payment),
        qty, unit_price, disc_pct, discount, sales, cost, profit, ship_delay
    ))
    order_id += 1

# ── Write CSVs ───────────────────────────────────────────────────────────────
files = {
    "dim_product.csv":  (
        ["ProductKey","ProductName","Category","UnitPrice"],
        products
    ),
    "dim_customer.csv": (
        ["CustomerKey","CustomerName","Segment","Region","City"],
        customers
    ),
    "dim_date.csv": (
        ["DateKey","FullDate","Day","Month","Year","MonthName","DayName","Quarter","IsWeekday"],
        date_rows
    ),
    "dim_shipping.csv": (
        ["ShipModeKey","ShipMode"],
        [(i+1, s) for i, s in enumerate(ship_modes)]
    ),
    "fact_sales.csv": (
        ["OrderID","OrderDateKey","ShipDateKey","ProductKey","CustomerKey",
         "ShipMode","PaymentMethod","Quantity","UnitPrice","DiscountPct",
         "DiscountAmount","SalesAmount","CostAmount","Profit","ShipDays"],
        fact_rows
    ),
}

for fname, (headers, rows) in files.items():
    with open(f"/home/claude/project1/data/{fname}", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(headers)
        w.writerows(rows)

print("All CSVs generated successfully!")
for fname in files:
    with open(f"/home/claude/project1/data/{fname}") as f:
        count = sum(1 for _ in f) - 1
    print(f"  {fname} -> {count} rows")
