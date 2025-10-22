Create Table Customers (
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						Region VARCHAR(25) NOT NULL CHECK(Region IN ('South','North','West','East')),
						JoinDate DATE NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE())
						);

Create Table Products (
						ProductID INT PRIMARY KEY,
						ProductName VARCHAR(50) NOT NULL,
						Category VARCHAR(50) NOT NULL CHECK(Category IN ('Electronics','Furniture','Accessories')),
						UnitPrice DECIMAL(10,2) NOT NULL CHECK(UnitPrice>0),
						CostPrice DECIMAL(10,2) NOT NULL CHECK(CostPrice>0),
						CHECK(CostPrice <= UnitPrice)
						);

Create Table Sales (
					SaleID INT PRIMARY KEY,
					CustomerID INT NOT NULL,
					ProductID INT NOT NULL,
					Quantity INT NOT NULL CHECK(Quantity>0),
					SaleDate DATE NOT NULL DEFAULT GETDATE(),
					PaymentMode VARCHAR(50) NOT NULL CHECK(PaymentMode IN ('Card','UPI','Wallet')),
					Region VARCHAR(25) NOT NULL CHECK(Region IN ('South','North','West','East')),
					UNIQUE(ProductID,CustomerID),
					FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION,
					FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

Create Table Returns (
						ReturnID INT PRIMARY KEY,
						SaleID INT NOT NULL,
						ReturnDate DATE NOT NULL,
						RefundAmount DECIMAL(10,2) NOT NULL CHECK(RefundAmount>0),
						Reason VARCHAR(100) NOT NULL,
						FOREIGN KEY(SaleID) REFERENCES Sales(SaleID) ON UPDATE CASCADE ON DELETE NO ACTION
					 );

Create Index Idx_Customers_Name_Region ON Customers(Name,Region);
Create Index Idx_Customers_JoinDate ON Customers(JoinDate);
Create Index Idx_Products_ProductName_Category ON Products(ProductName,Category);
Create Index Idx_Products_UnitPrice_CostPrice ON Products(UnitPrice,CostPrice);
Create Index Idx_Sales_CustomerID ON Sales(CustomerID);
Create Index Idx_Sales_ProductID ON Sales(ProductID);
Create Index Idx_Sales_SaleDate ON Sales(SaleDate);
Create Index Idx_Returns_ReturnDate ON Returns(ReturnDate);
Create Index Idx_Returns_RefundAmount ON Returns(RefundAmount);
Create Index Idx_Returns_SaleID ON Returns(SaleID);
CREATE INDEX Idx_Sales_Date_Region ON Sales(SaleDate, Region);
CREATE INDEX Idx_Sales_Product_Date ON Sales(ProductID, SaleDate);
CREATE INDEX Idx_Products_Price ON Products(UnitPrice) WHERE UnitPrice > 100;

INSERT INTO Customers (CustomerID, Name, Region, JoinDate) VALUES
(1, 'Priya Nair', 'South', '2020-03-15'),
(2, 'Rohan Mehta', 'North', '2021-02-10'),
(3, 'Maria Garcia', 'West', '2020-06-05'),
(4, 'David Lee', 'East', '2022-01-20'),
(5, 'Fatima Noor', 'South', '2019-12-01');

INSERT INTO Products (ProductID, ProductName, Category, UnitPrice, CostPrice) VALUES
(101, 'Laptop', 'Electronics', 60000.00, 48000.00),
(102, 'Smartphone', 'Electronics', 30000.00, 22000.00),
(103, 'Chair', 'Furniture', 5000.00, 3500.00),
(104, 'Table', 'Furniture', 8000.00, 6000.00),
(105, 'Headphones', 'Accessories', 2000.00, 1000.00);

INSERT INTO Sales (SaleID, CustomerID, ProductID, Quantity, SaleDate, PaymentMode, Region) VALUES
(201, 1, 101, 2, '2022-07-05', 'Card', 'South'),
(202, 2, 102, 3, '2022-07-07', 'UPI', 'North'),
(203, 3, 103, 5, '2022-07-08', 'Wallet', 'West'),
(204, 4, 105, 6, '2022-07-10', 'Card', 'East'),
(205, 5, 104, 4, '2022-07-12', 'Card', 'South'),
(206, 1, 102, 2, '2022-08-01', 'Card', 'South'),
(207, 2, 101, 1, '2022-08-05', 'Wallet', 'North'),
(208, 3, 105, 4, '2022-08-07', 'UPI', 'West'),
(209, 5, 103, 2, '2022-08-10', 'Card', 'South'),
(210, 4, 102, 3, '2022-08-15', 'Wallet', 'East');

INSERT INTO Returns (ReturnID, SaleID, ReturnDate, RefundAmount, Reason) VALUES
(301, 203, '2022-07-15', 2500.00, 'Damaged Product'),
(302, 204, '2022-07-20', 4000.00, 'Wrong Item'),
(303, 209, '2022-08-20', 5000.00, 'Customer Dissatisfaction');

SELECT * FROM Customers;
SELECT * FROM Products;
SELECT * FROM Sales;
SELECT * FROM Returns;

--1) JOIN Practice
--Display each sale with customer name, product name, category, and total sale amount (Quantity * UnitPrice).
SELECT
    s.SaleID,s.SaleDate,c.Name AS CustomerName,p.ProductName,p.Category,s.Quantity,p.UnitPrice,
    (s.Quantity * p.UnitPrice) AS TotalSaleAmount
FROM Sales s
JOIN Customers c ON s.CustomerID = c.CustomerID
JOIN Products p ON s.ProductID = p.ProductID
ORDER BY TotalSaleAmount DESC;

--2) CTE + Profit Analysis
--Using a CTE, calculate profit ((UnitPrice - CostPrice) * Quantity) for each sale 
--and find which category generated the highest total profit.
WITH SalesProfit AS (
    SELECT
        s.SaleID,p.Category,p.ProductName,s.Quantity,p.UnitPrice,p.CostPrice,
        (p.UnitPrice - p.CostPrice) AS ProfitPerUnit,
        ((p.UnitPrice - p.CostPrice) * s.Quantity) AS TotalProfit
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
)
SELECT
    Category,
    COUNT(SaleID) AS NumberOfSales,
    SUM(Quantity) AS TotalQuantitySold,
    ROUND(SUM(TotalProfit), 2) AS TotalProfit,
    ROUND(AVG(ProfitPerUnit), 2) AS AvgProfitPerUnit
FROM SalesProfit
GROUP BY Category
ORDER BY TotalProfit DESC;

--3) Subquery + Filtering
--List customers whose total sales value exceeds the average total sales value of all customers.
SELECT
    c.CustomerID,c.Name,
    ROUND(SUM(s.Quantity * p.UnitPrice), 2) AS TotalSalesValue
FROM Customers c
JOIN Sales s ON c.CustomerID = s.CustomerID
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY c.CustomerID, c.Name
HAVING SUM(s.Quantity * p.UnitPrice) > (
    SELECT AVG(CustomerTotal)
    FROM (
        SELECT SUM(s2.Quantity * p2.UnitPrice) AS CustomerTotal
        FROM Sales s2
        JOIN Products p2 ON s2.ProductID = p2.ProductID
        GROUP BY s2.CustomerID
    ) AS CustomerTotals
)
ORDER BY TotalSalesValue DESC;

--Alternative Using CTE
-- Using CTE for better readability
WITH CustomerSales AS (
    SELECT
        s.CustomerID,
        SUM(s.Quantity * p.UnitPrice) AS TotalSalesValue
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY s.CustomerID
),
AverageSales AS (
    SELECT AVG(TotalSalesValue) AS AvgTotalSales
    FROM CustomerSales
)
SELECT
    c.CustomerID,c.Name,c.Region,
    ROUND(cs.TotalSalesValue, 2) AS TotalSalesValue,
    ROUND(av.AvgTotalSales, 2) AS AverageTotalSalesValue
FROM CustomerSales cs
JOIN Customers c ON cs.CustomerID = c.CustomerID
CROSS JOIN AverageSales av
WHERE cs.TotalSalesValue > av.AvgTotalSales
ORDER BY cs.TotalSalesValue DESC;

--4) CASE + Conditional Logic
--Classify customers as:
--“High Value” (Total purchase > 1,00,000), “Medium Value” (50,000–1,00,000), “Low Value” (<50,000)
SELECT
    c.CustomerID, c.Name,c.Region,c.JoinDate,
    ROUND(SUM(s.Quantity * p.UnitPrice), 2) AS TotalPurchaseValue,
    CASE 
        WHEN SUM(s.Quantity * p.UnitPrice) > 100000 THEN 'High Value'
        WHEN SUM(s.Quantity * p.UnitPrice) BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerCategory
FROM Customers c
JOIN Sales s ON c.CustomerID = s.CustomerID
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY c.CustomerID, c.Name, c.Region, c.JoinDate
ORDER BY TotalPurchaseValue DESC;

--5) Window Function (RANK)
--Rank each customer by total profit contribution across all orders.
SELECT
    c.CustomerID,c.Name,c.Region,
    ROUND(SUM((p.UnitPrice - p.CostPrice) * s.Quantity), 2) AS TotalProfitContribution,
    RANK() OVER (ORDER BY SUM((p.UnitPrice - p.CostPrice) * s.Quantity) DESC) AS ProfitRank
FROM Customers c
JOIN Sales s ON c.CustomerID = s.CustomerID
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY c.CustomerID, c.Name, c.Region
ORDER BY ProfitRank;

--6) LAG Function (Time Gap)
--For each customer, calculate the number of days between consecutive purchases.
SELECT
    CustomerID,SaleID,SaleDate,
    LAG(SaleDate) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS PreviousSaleDate,
    DATEDIFF(DAY, LAG(SaleDate) OVER (PARTITION BY CustomerID ORDER BY SaleDate), SaleDate) AS DaysBetweenPurchases
FROM Sales
ORDER BY CustomerID, SaleDate;

--7) Nested CTE + Category Analysis
--Using nested CTEs, calculate total revenue and return loss for each category, and compute the net category profit.
WITH CategoryRevenue AS (
    -- Calculate total revenue for each category
    SELECT
        p.Category,
        SUM(s.Quantity * p.UnitPrice) AS TotalRevenue,
        SUM(s.Quantity * p.CostPrice) AS TotalCost,
        SUM((p.UnitPrice - p.CostPrice) * s.Quantity) AS GrossProfit
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY p.Category
),
CategoryReturns AS (
    -- Calculate total returns loss for each category
    SELECT
        p.Category,
        SUM(r.RefundAmount) AS TotalReturnLoss
    FROM Returns r
    JOIN Sales s ON r.SaleID = s.SaleID
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY p.Category
),
CategoryNetProfit AS (
    -- Calculate net profit after returns
    SELECT
        cr.Category,cr.TotalRevenue,cr.TotalCost,cr.GrossProfit,
        COALESCE(cret.TotalReturnLoss, 0) AS TotalReturnLoss,
        (cr.GrossProfit - COALESCE(cret.TotalReturnLoss, 0)) AS NetProfit,
        ROUND((cr.GrossProfit - COALESCE(cret.TotalReturnLoss, 0)) * 100.0 / NULLIF(cr.TotalRevenue, 0), 2) AS NetProfitMargin
    FROM CategoryRevenue cr
    LEFT JOIN CategoryReturns cret ON cr.Category = cret.Category
)
SELECT
    Category,
    ROUND(TotalRevenue, 2) AS TotalRevenue,
    ROUND(TotalCost, 2) AS TotalCost,
    ROUND(GrossProfit, 2) AS GrossProfit,
    ROUND(TotalReturnLoss, 2) AS TotalReturnLoss,
    ROUND(NetProfit, 2) AS NetProfit,
    NetProfitMargin AS NetProfitMarginPercent,
    CASE 
        WHEN NetProfitMargin > 20 THEN 'High Profit'
        WHEN NetProfitMargin > 10 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS ProfitCategory
FROM CategoryNetProfit
ORDER BY NetProfit DESC;

--8) Correlated Subquery
--Find customers who purchased a product that was later returned by any other customer.
SELECT DISTINCT
    c.CustomerID,c.Name,c.Region,s.SaleID,s.SaleDate,
    p.ProductID,p.ProductName,p.Category
FROM Sales s
JOIN Customers c ON s.CustomerID = c.CustomerID
JOIN Products p ON s.ProductID = p.ProductID
WHERE EXISTS (
    SELECT 1
    FROM Returns r
    JOIN Sales s2 ON r.SaleID = s2.SaleID
    WHERE s2.ProductID = s.ProductID  -- Same product
    AND s2.CustomerID != s.CustomerID  -- Different customer
    AND r.ReturnDate > s.SaleDate  -- Returned after purchase
)
ORDER BY c.CustomerID, s.SaleDate;

--9) Analytical Query (Percentage Contribution)
--For each region, find the percentage contribution of each category to total regional revenue (rounded to 2 decimals).
WITH RegionalCategoryRevenue AS (
    SELECT
        s.Region,p.Category,
        SUM(s.Quantity * p.UnitPrice) AS CategoryRevenue,
        SUM(SUM(s.Quantity * p.UnitPrice)) OVER (PARTITION BY s.Region) AS TotalRegionalRevenue
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY s.Region, p.Category
)
SELECT
    Region,Category,
    ROUND(CategoryRevenue, 2) AS CategoryRevenue,
    ROUND(TotalRegionalRevenue, 2) AS TotalRegionalRevenue,
    ROUND((CategoryRevenue * 100.0 / TotalRegionalRevenue), 2) AS PercentageContribution
FROM RegionalCategoryRevenue
ORDER BY Region, PercentageContribution DESC;

--10) Real-World KPI (Customer Retention)
--Identify repeat customers — customers who made purchases in more than one month — and show their total spend and profit.
WITH CustomerPurchaseMonths AS (
    SELECT
        c.CustomerID,c.Name,c.Region,
        DENSE_RANK() OVER (PARTITION BY c.CustomerID ORDER BY FORMAT(s.SaleDate, 'yyyy-MM')) AS MonthRank,
        FORMAT(s.SaleDate, 'yyyy-MM') AS PurchaseMonth
    FROM Customers c
    JOIN Sales s ON c.CustomerID = s.CustomerID
),
RepeatCustomers AS (
    SELECT
        CustomerID,Name,Region,
        MAX(MonthRank) AS PurchaseMonthsCount,
        COUNT(DISTINCT PurchaseMonth) AS DistinctMonths
    FROM CustomerPurchaseMonths
    GROUP BY CustomerID, Name, Region
    HAVING COUNT(DISTINCT PurchaseMonth) > 1
)
SELECT
    rc.CustomerID,rc.Name,rc.Region,rc.PurchaseMonthsCount,rc.DistinctMonths,
    ROUND(SUM(s.Quantity * p.UnitPrice), 2) AS TotalSpend,
    ROUND(SUM((p.UnitPrice - p.CostPrice) * s.Quantity), 2) AS TotalProfit,
    COUNT(DISTINCT s.SaleID) AS TotalOrders
FROM RepeatCustomers rc
JOIN Sales s ON rc.CustomerID = s.CustomerID
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY rc.CustomerID, rc.Name, rc.Region, rc.PurchaseMonthsCount, rc.DistinctMonths
ORDER BY TotalSpend DESC;

--11)  Bonus Challenge (Complex Analytical Logic)
--Find the most profitable region after adjusting for returns. Formula:
--Net Profit = Total Sales Profit – Total Refund Amount
--Display region name, total profit, total refunds, and net profit percentage.
WITH RegionalSalesProfit AS (
    -- Calculate total sales profit by region
    SELECT
        s.Region,
        SUM((p.UnitPrice - p.CostPrice) * s.Quantity) AS TotalSalesProfit,
        SUM(s.Quantity * p.UnitPrice) AS TotalRevenue
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY s.Region
),
RegionalReturns AS (
    -- Calculate total refund amount by region
    SELECT
        s.Region,
        SUM(r.RefundAmount) AS TotalRefundAmount,
        COUNT(r.ReturnID) AS TotalReturns
    FROM Returns r
    JOIN Sales s ON r.SaleID = s.SaleID
    GROUP BY s.Region
),
RegionalNetProfit AS (
    -- Calculate net profit after returns
    SELECT
        rsp.Region,
        rsp.TotalSalesProfit,
        rsp.TotalRevenue,
        COALESCE(rr.TotalRefundAmount, 0) AS TotalRefundAmount,
        COALESCE(rr.TotalReturns, 0) AS TotalReturns,
        (rsp.TotalSalesProfit - COALESCE(rr.TotalRefundAmount, 0)) AS NetProfit,
        -- Net Profit Percentage = (Net Profit / Total Revenue) * 100
        CASE 
            WHEN rsp.TotalRevenue > 0 THEN 
                ((rsp.TotalSalesProfit - COALESCE(rr.TotalRefundAmount, 0)) / rsp.TotalRevenue) * 100
            ELSE 0
        END AS NetProfitPercentage
    FROM RegionalSalesProfit rsp
    LEFT JOIN RegionalReturns rr ON rsp.Region = rr.Region
)
SELECT
    Region,
    ROUND(TotalSalesProfit, 2) AS TotalSalesProfit,
    ROUND(TotalRevenue, 2) AS TotalRevenue,
    ROUND(TotalRefundAmount, 2) AS TotalRefundAmount,
    TotalReturns,
    ROUND(NetProfit, 2) AS NetProfit,
    ROUND(NetProfitPercentage, 2) AS NetProfitPercentage,
    RANK() OVER (ORDER BY NetProfit DESC) AS NetProfitRank,
    RANK() OVER (ORDER BY NetProfitPercentage DESC) AS ProfitMarginRank
FROM RegionalNetProfit
ORDER BY NetProfit DESC;