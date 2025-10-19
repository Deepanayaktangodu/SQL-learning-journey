Create Table Products (
						ProductID INT PRIMARY KEY,
						ProductName VARCHAR(100) NOT NULL CHECK(LEN(ProductName)>=2),
						Category VARCHAR(30) NOT NULL CHECK(Category in ('Electronics','Furniture','Stationery')),
						UnitPrice DECIMAL(10,2) NOT NULL CHECK(UnitPrice>0),
						ReorderLevel INT NOT NULL CHECK(ReorderLevel>0)
						);

Create Table Suppliers (
						SupplierID INT PRIMARY KEY,
						SupplierName VARCHAR(50) NOT NULL,
						Country VARCHAR(30) NOT NULL CHECK(LEN(Country)>=2),
						Rating DECIMAL(10,2) NOT NULL CHECK(Rating>=0)
						);

Create Table Inventory(
						InventoryID INT PRIMARY KEY,
						ProductID INT NOT NULL,
						SupplierID INT NOT NULL,
						StockQuantity INT NOT NULL CHECK(StockQuantity>=0),
						LastRestockDate DATE NOT NULL DEFAULT GETDATE() CHECK(LastRestockDate<=GETDATE()),
						UNIQUE(ProductID,SupplierID),
						FOREIGN KEY(ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE CASCADE,
						FOREIGN KEY(SupplierID) REFERENCES Suppliers(SupplierID) ON UPDATE CASCADE ON DELETE CASCADE
						);

Create Table Sales (
						SaleID INT PRIMARY KEY,
						ProductID INT NOT NULL,
						SaleDate DATE NOT NULL DEFAULT GETDATE() CHECK(SaleDate<=GETDATE()),
						QuantitySold INT NOT NULL CHECK(QuantitySold>0),
						Region VARCHAR(10) NOT NULL CHECK(Region in ('South','North','West','East')),
						FOREIGN KEY(ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE CASCADE
					);

CREATE INDEX Idx_Inventory_ProductID ON Inventory(ProductID);
CREATE INDEX Idx_Inventory_SupplierID ON Inventory(SupplierID);
CREATE INDEX Idx_Sales_ProductID ON Sales(ProductID);
CREATE INDEX Idx_Products_ProductName_Category_UnitPrice ON Products(ProductName,Category,UnitPrice);
CREATE INDEX Idx_Suppliers_SupplierName_Country_Rating ON Suppliers(SupplierName,Country,Rating);
CREATE INDEX Idx_Inventory_LastRestockDate ON Inventory(LastRestockDate);
CREATE INDEX Idx_Sales_SaleDate ON Sales(SaleDate);
CREATE INDEX Idx_Sales_QuantitySold_Region ON Sales(QuantitySold,Region);

INSERT INTO Products (ProductID, ProductName, Category, UnitPrice, ReorderLevel) VALUES
(1, 'Laptop', 'Electronics', 55000, 10),
(2, 'Mobile Phone', 'Electronics', 25000, 15),
(3, 'Office Chair', 'Furniture', 5000, 20),
(4, 'Study Table', 'Furniture', 8000, 12),
(5, 'Water Bottle', 'Stationery', 300, 50),
(6, 'Pen Set', 'Stationery', 200, 100);

INSERT INTO Suppliers (SupplierID, SupplierName, Country, Rating) VALUES
(101, 'TechWorld', 'India', 4.7),
(102, 'FurniCraft', 'Germany', 4.5),
(103, 'OfficeMate', 'USA', 4.2),
(104, 'HandyDeals', 'India', 4.0),
(105, 'StationPlus', 'China', 3.9);

INSERT INTO Inventory (InventoryID, ProductID, SupplierID, StockQuantity, LastRestockDate) VALUES
(201, 1, 101, 25, '2022-08-10'),
(202, 2, 101, 18, '2022-08-12'),
(203, 3, 102, 40, '2022-08-15'),
(204, 4, 102, 10, '2022-08-20'),
(205, 5, 105, 55, '2022-08-22'),
(206, 6, 105, 90, '2022-08-25');


INSERT INTO Sales (SaleID, ProductID, SaleDate, QuantitySold, Region) VALUES
(301, 1, '2022-09-01', 5, 'South'),
(302, 1, '2022-09-10', 3, 'North'),
(303, 2, '2022-09-12', 6, 'West'),
(304, 3, '2022-09-13', 10, 'North'),
(305, 4, '2022-09-15', 5, 'East'),
(306, 5, '2022-09-18', 25, 'South'),
(307, 6, '2022-09-20', 40, 'East'),
(308, 2, '2022-09-25', 8, 'West'),
(309, 3, '2022-09-26', 5, 'South'),
(310, 5, '2022-09-30', 30, 'North');

SELECT * FROM Products;
SELECT * FROM Suppliers;
SELECT * FROM Inventory;
SELECT * FROM Sales;

--1)Join Practice
--Display product name, supplier name, and stock quantity.
SELECT
	p.ProductName,s.SupplierName,i.StockQuantity
FROM Products p
JOIN Inventory i ON p.ProductID =i.ProductID 
JOIN Suppliers s ON s.SupplierID =i.SupplierID 
GROUP BY p.ProductName,s.SupplierName,i.StockQuantity
ORDER BY i.StockQuantity DESC;

--2) Aggregation
--Calculate total sales revenue per category.
SELECT
	p.Category,
	ROUND(SUM(p.UnitPrice*s.QuantitySold),2) AS [Total Revenue]
FROM Products p
JOIN Sales s ON p.ProductID =s.ProductID 
GROUP BY p.Category 
ORDER BY [Total Revenue] DESC;

--3) CASE + Conditional Logic
--Identify products that are:
--“Overstocked” (StockQuantity > 2 × ReorderLevel)
--“Normal Stock” (ReorderLevel ≤ StockQuantity ≤ 2 × ReorderLevel)
--“Low Stock” (StockQuantity < ReorderLevel)
SELECT
    p.ProductID,p.ProductName,p.Category,i.StockQuantity,p.ReorderLevel,
    CASE 
        WHEN i.StockQuantity > 2 * p.ReorderLevel THEN 'Over Stocked'
        WHEN i.StockQuantity < p.ReorderLevel THEN 'Low Stock'
        ELSE 'Normal Stock'
    END AS StockCategory
FROM Products p
JOIN Inventory i ON p.ProductID = i.ProductID
ORDER BY 
    CASE 
        WHEN i.StockQuantity < p.ReorderLevel THEN 1
        WHEN i.StockQuantity > 2 * p.ReorderLevel THEN 3
        ELSE 2
    END,
    i.StockQuantity ASC;

--4) Subquery
--List suppliers who provide products with an average selling price above ₹10,000.
SELECT 
    s.SupplierID,s.SupplierName, s.Country,
    ROUND(AVG(p.UnitPrice), 2) AS [Average Selling Price]
FROM Suppliers s
JOIN Inventory i ON s.SupplierID = i.SupplierID
JOIN Products p ON p.ProductID = i.ProductID
GROUP BY s.SupplierID, s.SupplierName, s.Country
HAVING AVG(p.UnitPrice) > 10000
ORDER BY [Average Selling Price] DESC;

--Using Subquery
-- Using subquery to find suppliers with average product price > ₹10,000
SELECT 
    s.SupplierID,s.SupplierName,s.Country,
    supplier_avg.AvgPrice AS [Average Selling Price]
FROM Suppliers s
JOIN (
    -- Subquery to calculate average price per supplier
    SELECT 
        i.SupplierID,
        ROUND(AVG(p.UnitPrice), 2) AS AvgPrice
    FROM Inventory i
    JOIN Products p ON i.ProductID = p.ProductID
    GROUP BY i.SupplierID
    HAVING AVG(p.UnitPrice) > 10000
) supplier_avg ON s.SupplierID = supplier_avg.SupplierID
ORDER BY supplier_avg.AvgPrice DESC;

--5) CTE + Ranking
--Rank products by total sales quantity across all regions.
With ProductSalesQuantity AS(
				SELECT
					P.productID,p.ProductName,p.Category,
					SUM(s.QuantitySold) AS TotalSoldQuantity,
					RANK() OVER (ORDER BY SUM(s.QuantitySold) DESC) AS SalesRank
				FROM Products p
				JOIN sales s ON p.ProductID =s.ProductID 
				GROUP BY p.ProductID,p.ProductName,p.Category)
SELECT
	ProductID,ProductName,Category,TotalSoldQuantity,SalesRank
FROM ProductSalesQuantity 
ORDER BY SalesRank;

--6) Window Function (LAG)
--For each product, find the number of days since its previous sale.
SELECT
    p.ProductID,p.ProductName,p.Category,s.SaleDate,
    LAG(s.SaleDate) OVER (PARTITION BY p.ProductID ORDER BY s.SaleDate) AS PreviousSaleDate,
    DATEDIFF(DAY, LAG(s.SaleDate) OVER (PARTITION BY p.ProductID ORDER BY s.SaleDate), s.SaleDate) AS DaysSincePreviousSale
FROM Products p
JOIN Sales s ON p.ProductID = s.ProductID
ORDER BY p.ProductID, s.SaleDate;

--7) Analytical Query (NTILE)
--Divide suppliers into 3 performance tiers based on their average product rating and stock supplied.
SELECT
    s.SupplierID,s.SupplierName,s.Country,
    ROUND(AVG(s.Rating ), 2) AS AvgProductRating,
    SUM(i.StockQuantity) AS TotalStockSupplied,
    NTILE(3) OVER (ORDER BY AVG(s.Rating) DESC, SUM(i.StockQuantity) DESC) AS PerformanceTier
FROM Suppliers s
JOIN Inventory i ON s.SupplierID = i.SupplierID
JOIN Products p ON p.ProductID = i.ProductID
GROUP BY s.SupplierID, s.SupplierName, s.Country
ORDER BY PerformanceTier, AvgProductRating DESC, TotalStockSupplied DESC;

--8) Nested CTE + Joins
--Find the top-selling category in each region based on total revenue.
WITH CategoryRevenueByRegion AS (
    SELECT
        s.Region,p.Category,
        ROUND(SUM(p.UnitPrice * s.QuantitySold), 2) AS TotalRevenue,
        SUM(s.QuantitySold) AS TotalQuantitySold
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY s.Region, p.Category
),
RankedCategories AS (
    SELECT
        Region,Category,TotalRevenue,TotalQuantitySold,
        RANK() OVER (PARTITION BY Region ORDER BY TotalRevenue DESC) AS RevenueRank,
        DENSE_RANK() OVER (PARTITION BY Region ORDER BY TotalRevenue DESC) AS DenseRevenueRank
    FROM CategoryRevenueByRegion
)
SELECT
    Region,Category AS TopSellingCategory,TotalRevenue,TotalQuantitySold,RevenueRank
FROM RankedCategories
WHERE RevenueRank = 1
ORDER BY TotalRevenue DESC;

--9) Correlated Subquery
--Find products whose total sales quantity is greater than their average sales across all products.
SELECT
    p.ProductID,p.ProductName,p.Category,p.UnitPrice,
    (SELECT SUM(QuantitySold) FROM Sales s WHERE s.ProductID = p.ProductID) AS TotalSalesQuantity
FROM Products p
WHERE (SELECT SUM(QuantitySold) FROM Sales s WHERE s.ProductID = p.ProductID) > 
      (SELECT AVG(TotalSales) 
       FROM (SELECT SUM(QuantitySold) AS TotalSales 
             FROM Sales 
             GROUP BY ProductID) AS ProductTotals)
ORDER BY TotalSalesQuantity DESC;

--10) Real-World Analytical KPI Query (Advanced)
--Identify the most profitable product by total revenue, 
--and show what % it contributes to the total company revenue (rounded to 2 decimals).
--10) Real-World Analytical KPI Query (Advanced)
--Identify the most profitable product by total revenue, and show what % it contributes to the total company revenue.
WITH ProductRevenue AS (
    SELECT
        p.ProductID,p.ProductName,p.Category,p.UnitPrice,
        SUM(s.QuantitySold) AS TotalUnitsSold,
        ROUND(SUM(p.UnitPrice * s.QuantitySold), 2) AS TotalRevenue,
        -- Rank products by revenue
        RANK() OVER (ORDER BY SUM(p.UnitPrice * s.QuantitySold) DESC) AS RevenueRank,
        ROW_NUMBER() OVER (ORDER BY SUM(p.UnitPrice * s.QuantitySold) DESC) AS RevenueRowNum
    FROM Products p
    JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.ProductID, p.ProductName, p.Category, p.UnitPrice
),
CompanyTotal AS (
    SELECT
        ROUND(SUM(TotalRevenue), 2) AS CompanyTotalRevenue
    FROM ProductRevenue
),
TopProduct AS (
    SELECT
        ProductID,ProductName,Category,UnitPrice,
        TotalUnitsSold,TotalRevenue,RevenueRank
    FROM ProductRevenue
    WHERE RevenueRank = 1
)
SELECT
    tp.ProductID,tp.ProductName,tp.Category,tp.UnitPrice,
    tp.TotalUnitsSold,tp.TotalRevenue,ct.CompanyTotalRevenue,
    ROUND((tp.TotalRevenue / ct.CompanyTotalRevenue) * 100, 2) AS RevenueContributionPercent,
    tp.RevenueRank,
    '🏆 Top Revenue Generator' AS PerformanceStatus
FROM TopProduct tp
CROSS JOIN CompanyTotal ct;

--11)  Bonus Challenge (Complex Analytical Logic)
--Write a query to identify potential stockout products —
--i.e., products where (StockQuantity – average daily sales for last 30 days) < ReorderLevel.
--(Assume 30-day sales window from 2022-09-01 to 2022-09-30.)
WITH DailySales AS (
    SELECT
        ProductID,
        CAST(SUM(QuantitySold) AS FLOAT) / COUNT(DISTINCT SaleDate) AS AvgDailySales
    FROM Sales
    WHERE SaleDate BETWEEN '2022-09-01' AND '2022-09-30'
    GROUP BY ProductID
)
SELECT
    p.ProductID,p.ProductName,p.Category,p.ReorderLevel,i.StockQuantity,
    ROUND(COALESCE(ds.AvgDailySales, 0), 2) AS AvgDailySales,
    ROUND(i.StockQuantity - COALESCE(ds.AvgDailySales, 0), 1) AS NetStockAfterSales,
    CASE 
        WHEN (i.StockQuantity - COALESCE(ds.AvgDailySales, 0)) < p.ReorderLevel 
        THEN 'POTENTIAL STOCKOUT RISK'
        ELSE 'STOCK OK'
    END AS StockStatus,
    -- Days until stockout
    CASE 
        WHEN COALESCE(ds.AvgDailySales, 0) > 0 
        THEN ROUND((i.StockQuantity - p.ReorderLevel) / ds.AvgDailySales, 1)
        ELSE NULL
    END AS EstimatedDaysUntilReorder
FROM Products p
JOIN Inventory i ON p.ProductID = i.ProductID
LEFT JOIN DailySales ds ON p.ProductID = ds.ProductID
WHERE (i.StockQuantity - COALESCE(ds.AvgDailySales, 0)) < p.ReorderLevel
ORDER BY (i.StockQuantity - COALESCE(ds.AvgDailySales, 0)) ASC;
