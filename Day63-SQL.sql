Create Table Customers(
						CustomerID INT PRIMARY KEY,
						Name Varchar(75) NOT NULL CHECK(LEN(Name)>=2),
						Country Varchar(30) NOT NULL CHECK(LEN(Country)>=2),
						SignupDate Date NOT NULL DEFAULT GETDATE() CHECK(SignupDate<=GETDATE()),
						LoyaltyPoints INT NOT NULL CHECK(LoyaltyPoints>=0)
					);

Create Table Products (
						ProductID INT PRIMARY KEY,
						ProductName Varchar(100) NOT NULL UNIQUE CHECK(LEN(ProductName)>=2),
						Category Varchar(20) NOT NULL CHECK(LEN(Category)>=2),
						Price Decimal(10,2) NOT NULL CHECK(Price>0),
						Stock INT NOT NULL CHECK(Stock>=0)
						);

Create Table Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate Date NOT NULL DEFAULT GETDATE(),
						TotalAmount DECIMAL(10,2) NOT NULL CHECK(TotalAmount>0),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

Create Table OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductID INT NOT NULL,
							Quantity INT NOT NULL CHECK(Quantity>0),
							UNIQUE(OrderID,ProductID),
							FOREIGN KEY(OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY(ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE CASCADE
							);

Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Customers_LoyaltyPoints on Customers(LoyaltyPoints);
Create Index Idx_Products_Category on Products(Category);
Create Index Idx_Orders_OrderDate_CustomerID on Orders(OrderDate, CustomerID);
Create Index Idx_OrderDetails_ProductID_Quantity on OrderDetails(ProductID, Quantity);
Create Index Idx_Orders_TotalAmount on Orders(TotalAmount);

INSERT INTO Customers (CustomerID, Name, Country, SignupDate, LoyaltyPoints) VALUES
(1, 'Ananya Rao', 'India', '2020-01-10', 1200),
(2, 'John Smith', 'USA', '2019-11-25', 2300),
(3, 'Priya Patel', 'India', '2021-02-15', 800),
(4, 'David Green', 'UK', '2020-06-20', 1500),
(5, 'Meera Nair', 'India', '2021-09-10', 400);

INSERT INTO Products (ProductID, ProductName, Category, Price, Stock) VALUES
(101, 'Laptop', 'Electronics', 75000.00, 15),
(102, 'Mobile Phone', 'Electronics', 35000.00, 30),
(103, 'Headphones', 'Accessories', 4000.00, 50),
(104, 'Coffee Maker', 'HomeAppliance', 7000.00, 10),
(105, 'Office Chair', 'Furniture', 12000.00, 20);

INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount) VALUES
(5001, 1, '2021-12-01', 75000.00),
(5002, 2, '2021-12-05', 39000.00),
(5003, 3, '2022-01-15', 35000.00),
(5004, 4, '2022-02-10', 16000.00),
(5005, 1, '2022-03-05', 115000.00),
(5006, 5, '2022-03-15', 7000.00);

INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductID, Quantity) VALUES
(1, 5001, 101, 1),
(2, 5002, 102, 1),
(3, 5002, 103, 1),
(4, 5003, 102, 1),
(5, 5004, 103, 2),
(6, 5004, 104, 1),
(7, 5005, 101, 1),
(8, 5005, 105, 2),
(9, 5006, 104, 1);

SELECT * FROM Customers;
SELECT * FROM Products;
SELECT * FROM Orders;
SELECT * FROM OrderDetails;

--1) Basic Join – List all customers with their total order amount.
SELECT
	c.CustomerID,c.Name,c.Country,
	ROUND(SUM(o.TotalAmount),2) AS [Total Order Amount]
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
GROUP BY c.CustomerID,c.Name,c.Country 
ORDER BY [Total Order Amount] DESC;

--2) Aggregation – Find the top 3 products with the highest sales revenue.
SELECT TOP 3
	p.ProductID,p.ProductName,p.Category,
	ROUND(SUM(p.Price*od.Quantity),2) as [Total Sales Revenue]
FROM Products p
JOIN OrderDetails od ON p.ProductID =od.ProductID 
GROUP BY p.ProductID,p.ProductName,p.Category 
ORDER BY [Total Sales Revenue] DESC;

--3) Filtering – Show all orders placed by customers from India.
SELECT
	o.OrderID,c.CustomerID,c.Name,o.OrderDate,o.TotalAmount
FROM Orders o
JOIN Customers c ON o.CustomerID =c.CustomerID 
WHERE c.Country ='India'
ORDER BY o.OrderID;

--4) Date Functions – Find the number of orders placed in each month of 2022.
SELECT
	YEAR(OrderDate) AS [Year],
	MONTH(OrderDate) AS [MONTH COUNT],
	DATENAME(MONTH,OrderDate) AS [Month Name],
	COUNT(OrderID) AS [Order Count]
FROM Orders 
WHERE YEAR(OrderDate)='2022'
GROUP BY YEAR(OrderDate),MONTH(OrderDate),DATENAME(MONTH,OrderDate)
ORDER BY [Order Count] DESC;

--5) CASE Statement – Categorize customers into “High Value” (Total ≥ 1,00,000) and “Regular” based on their order spend.
SELECT
    c.CustomerID,c.Name,c.Country,
    ROUND(SUM(o.TotalAmount), 2) AS [Total Order Spend],
    CASE WHEN SUM(o.TotalAmount) >= 100000 THEN 'High Value' ELSE 'Regular' END AS [Customer Value Category]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID,c.Name,c.Country
ORDER BY [Total Order Spend] DESC;

--6) Window Function (ROW_NUMBER) – Get the most recent order per customer.
WITH RankedOrders AS (
		SELECT
			OrderID,CustomerID,OrderDate,TotalAmount,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC ) AS rn
		FROM Orders)
SELECT
    OrderID,CustomerID,OrderDate,TotalAmount
FROM RankedOrders
WHERE rn = 1;

--7) Window Function (RANK) – Rank customers by their loyalty points.
SELECT
	CustomerID,Name,Country,LoyaltyPoints,
	RANK() OVER (ORDER BY LoyaltyPoints DESC) AS LoyaltyRank
FROM Customers c
ORDER BY LoyaltyRank;

--8) Subquery – Find products that have never been ordered.
SELECT
    p.ProductID,p.ProductName,p.Category
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE od.ProductID IS NULL;

--Subquery method
SELECT
    ProductID,ProductName,Category
FROM Products
WHERE
    ProductID NOT IN (
        SELECT DISTINCT ProductID
        FROM OrderDetails
    );

--9) CTE (Recursive) – Generate a running total of order amounts by order date.
WITH OrderRunningTotal AS (
    SELECT
        OrderID,OrderDate,TotalAmount,
        SUM(TotalAmount) OVER (ORDER BY OrderDate ASC, OrderID ASC ROWS UNBOUNDED PRECEDING) AS RunningTotalAmount
    FROM Orders)
SELECT
    OrderID,OrderDate,TotalAmount,RunningTotalAmount
FROM OrderRunningTotal
ORDER BY OrderDate ASC, OrderID ASC;

--10) Advanced Join + Aggregation – For each category, find the average spend per customer.
WITH CustomerCategorySpend AS (
		SELECT
        c.CustomerID,p.Category,
        SUM(p.Price * od.Quantity) AS TotalSpend
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, p.Category)
SELECT
    Category,
    ROUND(AVG(TotalSpend), 2) AS AverageSpendPerCustomer
FROM CustomerCategorySpend
GROUP BY Category
ORDER BY AverageSpendPerCustomer DESC;

--11) Bonus Challenge 
-- Write a query to find the customer who contributed the highest % of total revenue and display their contribution percentage.
WITH CustomerRevenue AS (
				SELECT
					CustomerID,
					SUM(TotalAmount) AS IndividualRevenue
				FROM Orders 
				GROUP BY CustomerID),
TotalRevenue AS (
		SELECT
			SUM(TotalAmount) AS GrandTotal
		FROM Orders)
SELECT TOP 1
	c.Name AS CustomerName,
	cr.IndividualRevenue  AS TotalSpend,
	ROUND((cr.IndividualRevenue * 100.0) / tr.GrandTotal, 2) AS ContributionPercentage
FROM CustomerRevenue cr
CROSS JOIN TotalRevenue tr  -- CROSS JOIN combines every row from cr with every row from tr (only one row exists in tr)
JOIN Customers c ON cr.CustomerID = c.CustomerID
ORDER BY
    ContributionPercentage DESC;

