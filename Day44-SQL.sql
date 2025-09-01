CREATE TABLE Customers (
							CustomerID INT PRIMARY KEY,
							Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
							Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2)
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE NOT NULL Default getdate(),
						TotalAmount DECIMAL(10,2) NOT NULL CHECK(TotalAmount>0),
						Status VARCHAR(20) NOT NULL CHECK(Status in ('Completed','Returned','Cancelled')),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) on update cascade on delete no action
					);

CREATE TABLE OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL ,
							ProductName VARCHAR(50) NOT NULL CHECK(LEN(ProductName)>=2),
							Quantity INT NOT NULL CHECK(Quantity>0),
							Price DECIMAL(10,2) NOT NULL CHECK(Price>0),
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) on update cascade on delete no action
						);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Orders_Status on Orders(Status);
Create Index Idx_OrderDetails_ProductName on OrderDetails(ProductName);
Create Index Idx_OrderDetails_Price on OrderDetails(Price);
Create Index Idx_OrderDetails_Quanity on OrderDetails(Quantity);
CREATE INDEX Idx_Orders_CustomerID_OrderDate ON Orders(CustomerID, OrderDate);
CREATE INDEX Idx_OrderDetails_OrderID_ProductName ON OrderDetails(OrderID, ProductName);

INSERT INTO Customers (CustomerID, Name, Country) VALUES
(1, 'Alice', 'USA'),
(2, 'Bob', 'UK'),
(3, 'Charlie', 'India'),
(4, 'David', 'USA'),
(5, 'Emma', 'Canada');

INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount, Status) VALUES
(101, 1, '2024-01-10', 250.00, 'Completed'),
(102, 1, '2024-01-11', 180.00, 'Returned'),
(103, 2, '2024-02-05', 600.00, 'Completed'),
(104, 3, '2024-02-06', 300.00, 'Completed'),
(105, 3, '2024-02-07', 100.00, 'Cancelled'),
(106, 4, '2024-03-01', 1200.00, 'Completed'),
(107, 4, '2024-03-02', 500.00, 'Completed'),
(108, 5, '2024-04-01', 800.00, 'Returned'),
(109, 1, '2024-04-05', 900.00, 'Completed'),
(110, 2, '2024-04-10', 100.00, 'Completed');

INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductName, Quantity, Price) VALUES
(1, 101, 'Laptop', 1, 250.00),
(2, 102, 'Headphones', 2, 90.00),
(3, 103, 'Smartphone', 2, 300.00),
(4, 104, 'Tablet', 1, 300.00),
(5, 105, 'Keyboard', 2, 50.00),
(6, 106, 'Laptop', 2, 600.00),
(7, 107, 'Smartwatch', 1, 500.00),
(8, 108, 'Laptop', 1, 800.00),
(9, 109, 'Camera', 1, 900.00),
(10, 110, 'Mouse', 2, 50.00);

Select * from Customers 
Select * from Orders 
Select * from OrderDetails 

--1) 1.	Top Customers by Spend
--Write a query to list the top 5 customers who spent the most overall (only include orders with Status='Completed').
Select Top 5
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	SUM(o.TotalAmount) as [Total Spend]
from Customers c
join Orders o on c.CustomerID=o.CustomerID 
where o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
order by [Total Spend] Desc;

--2) 2.	Monthly Revenue Trend
--Calculate the total monthly revenue (from Completed orders only). Display Month-Year and total revenue.
Select
	YEAR(o.OrderDate) as [YEAR],
	DATENAME(MONTH,o.OrderDate) as [Month],
	SUM(o.TotalAmount) as [Total Revenue]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status='Completed'
group by YEAR(o.OrderDate),DATENAME(MONTH,o.OrderDate)
order by [Total Revenue] Desc;

--3) 3.	Average Order Value
--Find the average order value (AOV) for each customer, rounded to 2 decimals.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	ROUND(AVG(o.TotalAmount),2) as [Average Order Value]
from Customers c
join Orders o on c.CustomerID=o.CustomerID 
group by c.CustomerID,c.Name,c.Country 
order by [Average Order Value] Desc;

--4)Country-Wise Revenue Contribution
--Show the total revenue per Country and rank them using RANK() based on revenue contribution.
Select
	c.Country,
	SUM(o.TotalAmount) as [TotalRevenue],
	RANK() over (order by SUM(o.TotalAmount) Desc) as RevenueRank
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
group by c.Country 
order by RevenueRank Asc;

--5) Products with Highest Returns
--Identify the top 3 products most frequently found in orders with Status='Returned'.
SELECT TOP 3
    d.ProductName AS [Frequently Returned Product],
    COUNT(d.ProductName) AS [ReturnCount]
FROM OrderDetails d
JOIN Orders o ON d.OrderID = o.OrderID
WHERE o.Status = 'Returned'
GROUP BY d.ProductName
ORDER BY [ReturnCount] DESC;

--6) Customers with Consecutive Orders
--Using a window function (LAG), find customers who placed back-to-back orders on consecutive days.
WITH RankedOrders AS (
    SELECT
        CustomerID,OrderDate,
        LAG(OrderDate, 1) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PreviousOrderDate
    FROM Orders),
ConsecutiveOrderCustomers AS (
    SELECT DISTINCT CustomerID
    FROM RankedOrders
    WHERE DATEDIFF(day, PreviousOrderDate, OrderDate) = 1)
SELECT
    c.CustomerID,c.Name AS "Customer Name",c.Country
FROM Customers c
JOIN ConsecutiveOrderCustomers coc ON c.CustomerID = coc.CustomerID;

--7) 7.	Repeat Purchase Customers
--List all customers who placed more than 3 orders in a single month.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	YEAR(o.OrderDate) as [Year],
	DATENAME(MONTH,o.OrderDate) as [Month],
	COUNT(o.OrderID) as [OrderCount]
from Customers c
join Orders o on c.CustomerID =o.CustomerID
Group by c.CustomerID,c.Name,c.Country,YEAR(o.OrderDate),DATENAME(MONTH,o.OrderDate)
having COUNT(o.OrderID)>3
order by [OrderCount] Desc;

--8)Cancelled vs Completed Orders %
--Calculate the percentage of cancelled orders compared to completed orders, month-wise.
WITH MonthlyOrderStatus AS (
				SELECT
					YEAR(OrderDate) AS OrderYear,
					MONTH(OrderDate) AS OrderMonth,
					FORMAT(OrderDate, 'yyyy-MM') AS YearMonth,
					COUNT(CASE WHEN Status = 'Cancelled' THEN OrderID END) AS CancelledOrders,
					COUNT(CASE WHEN Status = 'Completed' THEN OrderID END) AS CompletedOrders,
					COUNT(OrderID) AS TotalOrders
				FROM Orders
				GROUP BY YEAR(OrderDate),MONTH(OrderDate),FORMAT(OrderDate, 'yyyy-MM'))
SELECT
    OrderYear,OrderMonth,YearMonth,CancelledOrders,CompletedOrders,TotalOrders,
    CASE 
        WHEN CompletedOrders > 0 THEN 
            ROUND((CAST(CancelledOrders AS DECIMAL(10,2)) / CompletedOrders) * 100, 2)
        ELSE 
            CASE WHEN CancelledOrders > 0 THEN 100.00 ELSE 0.00 END
    END AS CancelledToCompletedPercentage,
    ROUND((CAST(CancelledOrders AS DECIMAL(10,2)) / TotalOrders) * 100, 2) AS CancelledToTotalPercentage
FROM MonthlyOrderStatus
ORDER BY OrderYear, OrderMonth;

--9) High-Value Orders
--Find all orders where the order value is more than double the average order value of that customer.
WITH CustomerOrderStats AS (
    SELECT
        o.CustomerID,o.OrderID,o.OrderDate,o.TotalAmount AS OrderValue,
        AVG(o2.TotalAmount) OVER (PARTITION BY o.CustomerID) AS AvgCustomerOrderValue
    FROM Orders o
    JOIN Orders o2 ON o.CustomerID = o2.CustomerID
    WHERE o2.OrderDate <= o.OrderDate -- Only consider orders up to the current order date
),
OrderStats AS (
    SELECT
        CustomerID,OrderID,OrderDate,OrderValue,AvgCustomerOrderValue,
        OrderValue / NULLIF(AvgCustomerOrderValue, 0) AS ValueRatio
    FROM CustomerOrderStats
)
SELECT
    os.CustomerID,c.Name AS CustomerName,c.Country,
	os.OrderID,os.OrderDate,os.OrderValue,
    ROUND(os.AvgCustomerOrderValue, 2) AS AvgCustomerOrderValue,
    ROUND(os.ValueRatio, 2) AS ValueRatio,
    CASE 
        WHEN os.OrderValue > 2 * os.AvgCustomerOrderValue THEN 'More than double'
        ELSE 'Within range'
    END AS Status
FROM OrderStats os
JOIN Customers c ON os.CustomerID = c.CustomerID
WHERE os.OrderValue > 2 * os.AvgCustomerOrderValue
ORDER BY os.ValueRatio DESC, os.CustomerID, os.OrderDate;

--10) Inactive Customers
--List customers who have not placed any orders in the last 6 months (from the max order date in table).
WITH MaxOrderDate AS (
    SELECT MAX(OrderDate) AS LatestOrderDate FROM Orders
),
SixMonthsAgo AS (
    SELECT DATEADD(MONTH, -6, LatestOrderDate) AS CutoffDate
    FROM MaxOrderDate
)
SELECT
    c.CustomerID,c.Name AS CustomerName,c.Country,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(MONTH, MAX(o.OrderDate), (SELECT LatestOrderDate FROM MaxOrderDate)) AS MonthsSinceLastOrder
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders o2 
    WHERE o2.CustomerID = c.CustomerID 
    AND o2.OrderDate >= (SELECT CutoffDate FROM SixMonthsAgo)
)
GROUP BY c.CustomerID, c.Name,c.Country 
ORDER BY MonthsSinceLastOrder DESC, c.CustomerID;

--Bonus Challenge (Advanced): Customer Lifetime Value (CLV)
--Write a query to calculate Customer Lifetime Value = (Total Revenue from Completed Orders ÷ Number of Years as Customer).
--Assume first_order_date = min(OrderDate) per customer, Round CLV to 2 decimals.
With CustomerFirstOrder as (
				Select
					CustomerID,
					MIN(OrderDate) as FirstOrderDate
				from Orders 
				group by CustomerID
),
CustomerRevenue as (
		 SELECT
			o.CustomerID,
			SUM(o.TotalAmount) AS TotalRevenue
    FROM Orders o
    WHERE o.Status = 'Completed'
    GROUP BY o.CustomerID
),
CustomerTenure AS (
    SELECT
        cfo.CustomerID,cfo.FirstOrderDate,
        DATEDIFF(DAY, cfo.FirstOrderDate, GETDATE()) AS DaysAsCustomer,
        DATEDIFF(DAY, cfo.FirstOrderDate, GETDATE()) / 365.0 AS YearsAsCustomer
    FROM CustomerFirstOrder cfo
)
SELECT
    c.CustomerID,c.Name AS CustomerName,c.Country,
    cfo.FirstOrderDate,cr.TotalRevenue,ct.YearsAsCustomer,
    ROUND(
        CASE 
            WHEN ct.YearsAsCustomer > 0 THEN cr.TotalRevenue / ct.YearsAsCustomer
            ELSE cr.TotalRevenue -- If customer for less than a year
        END, 
        2
    ) AS CustomerLifetimeValue,
    ROUND(cr.TotalRevenue / NULLIF(ct.YearsAsCustomer, 0), 2) AS CLV_Alternative -- Handles division by zero
FROM Customers c
JOIN CustomerFirstOrder cfo ON c.CustomerID = cfo.CustomerID
JOIN CustomerRevenue cr ON c.CustomerID = cr.CustomerID
JOIN CustomerTenure ct ON c.CustomerID = ct.CustomerID
ORDER BY CustomerLifetimeValue DESC;


