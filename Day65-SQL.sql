Create Table Customers(
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(75) NOT NULL CHECK(LEN(Name)>=2),
						Country VARCHAR(25) NOT NULL CHECK(LEN(Country)>=2),
						JoinDate Date NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE())
					);

Create Table Orders(
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE NOT NULL,
						TotalAmount DECIMAL (10,2) NOT NULL CHECK(TotalAmount>0),
						PaymentMode VARCHAR(20) NOT NULL CHECK(PaymentMode in ('Card','Wallet','COD','UPI')),
						Status VARCHAR(15) NOT NULL CHECK(Status in ('Delivered','Returned','Cancelled')),
						FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

Create Table OrderItems (
							ItemID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductName VARCHAR(75) NOT NULL CHECK(LEN(ProductName)>=2),
							Category VARCHAR(30) NOT NULL CHECK(Category in ('Fashion','Accessories','Electronics','Lifestyle')),
							Quantity INT NOT NULL CHECK(Quantity>0),
							UnitPrice DECIMAL(10,2) NOT NULL CHECK(UnitPrice>0),
							FOREIGN KEY(OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderItems_OrderID on OrderItems(OrderID);
Create Index Idx_Customers_Name_Country on Customers(Name,Country);
Create Index Idx_Orders_OrderDate_TotalAmount on Orders(OrderDate,TotalAmount);
Create Index Idx_Orders_Status on Orders(Status);
Create Index Idx_OrderItems_ProductName_Category on OrderItems(ProductName,Category);
Create Index Idx_OrderItems_Quantity_UnitPrice on OrderItems(Quantity,UnitPrice);

INSERT INTO Customers (CustomerID, Name, Country, JoinDate) VALUES
(1, 'Priya Nair', 'India', '2020-02-10'),
(2, 'David Smith', 'USA', '2021-03-12'),
(3, 'Aisha Khan', 'UAE', '2019-08-20'),
(4, 'Rohan Verma', 'India', '2022-01-18'),
(5, 'Maria Garcia', 'Spain', '2020-11-05');

INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount, PaymentMode, Status) VALUES
(101, 1, '2022-05-10', 1500.00, 'Card', 'Delivered'),
(102, 2, '2022-05-12', 3200.00, 'Wallet', 'Delivered'),
(103, 3, '2022-06-15', 1800.00, 'COD', 'Returned'),
(104, 4, '2022-06-20', 5600.00, 'Card', 'Delivered'),
(105, 1, '2022-07-10', 2400.00, 'UPI', 'Cancelled'),
(106, 2, '2022-07-15', 3700.00, 'UPI', 'Delivered'),
(107, 5, '2022-08-01', 4200.00, 'Wallet', 'Delivered'),
(108, 1, '2022-08-05', 2900.00, 'Card', 'Delivered'),
(109, 3, '2022-08-15', 2300.00, 'UPI', 'Delivered'),
(110, 4, '2022-09-01', 1500.00, 'Card', 'Returned');

INSERT INTO OrderItems (ItemID, OrderID, ProductName, Category, Quantity, UnitPrice) VALUES
(1, 101, 'Shoes', 'Fashion', 2, 750.00),
(2, 102, 'Laptop Bag', 'Accessories', 1, 3200.00),
(3, 103, 'Headphones', 'Electronics', 1, 1800.00),
(4, 104, 'Phone Case', 'Accessories', 2, 2800.00),
(5, 105, 'Perfume', 'Lifestyle', 1, 2400.00),
(6, 106, 'Jeans', 'Fashion', 2, 1850.00),
(7, 107, 'Watch', 'Lifestyle', 1, 4200.00),
(8, 108, 'T-shirt', 'Fashion', 2, 1450.00),
(9, 109, 'Bluetooth', 'Electronics', 1, 2300.00),
(10, 110, 'Charger', 'Electronics', 1, 1500.00);

SELECT * FROM Customers;
SELECT * FROM Orders;
SELECT * FROM OrderItems;

--1) Join Practice: Display each order with customer name, payment mode, and total amount.
SELECT
	o.OrderID,o.CustomerID,c.Name as CustomerName,
	o.OrderDate,o.TotalAmount,o.PaymentMode
FROM Orders o
JOIN Customers c ON o.CustomerID =c.CustomerID 
ORDER BY o.OrderID;

--2) Aggregate Analysis: Calculate total sales and total number of delivered orders for each country.
SELECT
    c.Country,
    SUM(o.TotalAmount) AS TotalSales,
    COUNT(CASE WHEN o.Status = 'Delivered' THEN 1 END) AS DeliveredOrderCount
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalSales DESC;

--3) Date & String Functions: Display month-wise sales summary (MonthName + Total Sales).
SELECT
	YEAR(OrderDate) as [Year],
	MONTH(OrderDate) as [MonthCount],
	DATENAME(MONTH,OrderDate) as [Month Name],
	ROUND(SUM(TotalAmount),2) as [Monthly Sales]
FROM Orders 
GROUP BY YEAR(OrderDate),MONTH(OrderDate),DATENAME(MONTH,OrderDate)
ORDER BY YEAR(OrderDate),MONTH(OrderDate) DESC; 

--4)CASE + Conditional Aggregation
--Categorize each customer as “High Spender” (>5000), “Moderate” (3000–5000), or “Low Spender” (<3000) based on average order value.
SELECT
	c.CustomerID,c.Name as CustomerName,c.Country,
	ROUND(AVG(o.TotalAmount),2) as [Average Order Value],
	CASE 
		WHEN AVG(o.TotalAmount) >5000 THEN 'High Spender'
		WHEN AVG(o.TotalAmount) BETWEEN 3000 AND 5000 THEN 'Moderate Spender'
		ELSE 'Low Spender' END as SpendingCategory
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
GROUP BY c.CustomerID,c.Name,c.Country 
ORDER BY [Average Order Value] DESC;
 
 --5) Subquery: Find customers who have never returned or cancelled any order.
SELECT
    CustomerID,Name
FROM Customers
WHERE
    CustomerID NOT IN (
        SELECT DISTINCT CustomerID FROM Orders
        WHERE Status IN ('Returned', 'Cancelled'))
ORDER BY CustomerID;

--6) Window Function (RANK): Rank customers based on total sales amount in descending order.
SELECT
	c.CustomerID,c.Name,c.Country,
	ROUND(SUM(o.TotalAmount),2) as [Total Sales],
	RANK() OVER (ORDER BY SUM(o.TotalAmount) Desc)as  SalesRank
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
GROUP BY c.CustomerID,c.Name,c.Country 
ORDER BY SalesRank;

--7)Window Function (NTILE): Divide all customers into 3 spending tiers using NTILE(3) based on total purchase value.
SELECT
    c.CustomerID,c.Name AS CustomerName,
    SUM(o.TotalAmount) AS TotalPurchaseValue,
    NTILE(3) OVER (ORDER BY SUM(o.TotalAmount) DESC) AS SpendingTier
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID,c.Name
ORDER BY TotalPurchaseValue DESC;

--8) CTE with Aggregation
--Using a CTE, calculate each customer’s order frequency and average spend per order, then display only those with more than 2 orders.
WITH CustomerOrderStatistics AS (
					SELECT
						c.CustomerID,c.Name,c.Country,
						COUNT (DISTINCT o.OrderID) as [Order Frequency],
						ROUND(AVG(o.TotalAmount),2) as [Average Spend]
					FROM Customers C
					JOIN Orders o ON c.CustomerID =o.CustomerID 
					GROUP BY c.CustomerID,c.Name,c.Country)
SELECT
	CustomerID,Name,Country,[Order Frequency],[Average Spend] FROM CustomerOrderStatistics 
where [Order Frequency]>2
ORDER BY [Order Frequency] DESC;

--9) Analytical Query (LAG): For each customer, find the time gap (in days) between their consecutive orders.
SELECT
    c.CustomerID,c.Name AS CustomerName,o.OrderID,o.OrderDate,
    LAG(o.OrderDate, 1, o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) AS PreviousOrderDate,
    DATEDIFF(day,LAG(o.OrderDate, 1, o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate),o.OrderDate) AS DaysSincePreviousOrder
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY c.CustomerID, o.OrderDate;

--10) Advanced Filtering Query
--Identify categories where average order value > 2000 and more than 2 distinct customers purchased items.
SELECT
    i.Category,
    ROUND(AVG(o.TotalAmount), 2) AS AverageOrderValue,
    COUNT(DISTINCT o.CustomerID) AS DistinctCustomerCount
FROM OrderItems i
JOIN Orders o ON i.OrderID = o.OrderID
GROUP BY i.Category
HAVING
    AVG(o.TotalAmount) > 2000 -- Average order value > 2000
    AND COUNT(DISTINCT o.CustomerID) > 2 -- More than 2 distinct customers (>3)
ORDER BY AverageOrderValue DESC;

--11)Bonus Challenge (Real Interview Simulation)
--Find the top customer per country by total order value, and also display what percentage of that country’s sales they contributed to (rounded to 2 decimals).
WITH CustomerSpend AS (
    SELECT
        c.CustomerID,c.Name,c.Country,
        SUM(o.TotalAmount) AS TotalCustomerSales
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.Name, c.Country
),
RankedCustomers AS (
    SELECT
        CustomerID,Name,Country,TotalCustomerSales,
        SUM(TotalCustomerSales) OVER (PARTITION BY Country) AS TotalCountrySales,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY TotalCustomerSales DESC) AS RankInCountry
    FROM CustomerSpend
)
SELECT
    Country,Name AS TopCustomer,
    TotalCustomerSales AS TopCustomerSales,
    ROUND((TotalCustomerSales * 100.0) / TotalCountrySales, 2) AS PercentageContribution
FROM RankedCustomers
WHERE RankInCountry = 1
ORDER BY TotalCustomerSales DESC;
