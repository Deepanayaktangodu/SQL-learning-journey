CREATE TABLE Customers (
							CustomerID INT PRIMARY KEY,
							Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
							Segment VARCHAR(20) NOT NULL CHECK (Segment in('Retail','Corporate','Small Business')),
							Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2)
						);

CREATE TABLE Products (
						ProductID INT PRIMARY KEY,
						ProductName VARCHAR(50) NOT NULL UNIQUE CHECK(LEN(ProductName)>=2),
						Category VARCHAR(30) NOT NULL CHECK(Category in ('Electronics','Furniture')),
						Price DECIMAL(10,2) NOT NULL CHECK(Price>0)
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE DEFAULT GETDATE(),
						Status VARCHAR(20) NOT NULL CHECK(Status in ('Completed','Returned','Cancelled')),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

CREATE TABLE OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductID INT NOT NULL,
							Quantity INT NOT NULL CHECK(Quantity>0),
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE NO ACTION,
							FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Segment on Customers(Segment);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Products_ProductName on Products(ProductName);
Create Index Idx_Products_Category on Products(Category);
Create Index Idx_Products_Price on Products(Price);
Create Index Idx_Orders_Status on Orders(Status);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);

INSERT INTO Customers VALUES
(1, 'Alice', 'Retail', 'USA'),
(2, 'Bob', 'Corporate', 'India'),
(3, 'Charlie', 'Retail', 'Canada'),
(4, 'David', 'Small Business', 'UK'),
(5, 'Emma', 'Retail', 'India'),
(6, 'Frank', 'Corporate', 'USA');

INSERT INTO Products VALUES
(101, 'Laptop', 'Electronics', 800.00),
(102, 'Mouse', 'Electronics', 40.00),
(103, 'Chair', 'Furniture', 150.00),
(104, 'Desk', 'Furniture', 300.00),
(105, 'Phone', 'Electronics', 600.00),
(106, 'Printer', 'Electronics', 200.00);

INSERT INTO Orders VALUES
(1001, 1, '2024-01-10', 'Completed'),
(1002, 2, '2024-01-12', 'Completed'),
(1003, 2, '2024-01-15', 'Cancelled'),
(1004, 3, '2024-02-05', 'Completed'),
(1005, 3, '2024-02-06', 'Returned'),
(1006, 4, '2024-02-10', 'Completed'),
(1007, 5, '2024-03-01', 'Completed'),
(1008, 6, '2024-03-03', 'Completed'),
(1009, 6, '2024-03-10', 'Completed'),
(1010, 1, '2024-04-01', 'Completed');


INSERT INTO OrderDetails VALUES
(1, 1001, 101, 1),
(2, 1002, 102, 2),
(3, 1002, 103, 1),
(4, 1003, 105, 1),
(5, 1004, 104, 1),
(6, 1005, 102, 3),
(7, 1006, 103, 2),
(8, 1007, 101, 1),
(9, 1008, 105, 2),
(10, 1009, 106, 1),
(11, 1010, 101, 1),
(12, 1010, 102, 2);

Select* from Customers 
Select * from Products 
Select * from Orders 
Select * from OrderDetails 

--1) Total Sales by Segment
--Calculate total revenue for each customer segment (Retail, Corporate, Small Business).
Select
	c.Segment,
	SUM(p.Price*od.Quantity) as [Total Revenue]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
join OrderDetails od on o.OrderID =od.OrderID 
join Products p on p.ProductID =od.ProductID 
group by c.Segment 
order by [Total Revenue] Desc;

--2) Category-Wise Performance
--Find the top 2 categories contributing maximum revenue.
Select Top 2
	p.Category,
	ROUND(SUM(p.Price*od.Quantity),2) as [Total Revenue]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
join OrderDetails od on o.OrderID =od.OrderID 
join Products p on p.ProductID =od.ProductID 
group by p.Category 
order by [Total Revenue] Desc;

--3) Customer Order Frequency
--Find customers who have placed more than 2 completed orders.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	count(Distinct o.OrderID ) as [Order Count]
from Customers c
join Orders o on c.CustomerID=o.CustomerID 
where o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
having count(Distinct o.OrderID )>2
order by [Order Count] Desc;

--4) First Purchase Date vs Latest Purchase Date
--For each customer, show FirstOrderDate, LatestOrderDate, and OrderGap (days).
SELECT
    c.CustomerID,c.Name as 'Customer Name',c.Country,c.Segment,
    MIN(o.OrderDate) as [FirstOrderDate],
    MAX(o.OrderDate) as [LastOrderDate],
    DATEDIFF(DAY, MIN(o.OrderDate), MAX(o.OrderDate)) as [OrderGapDays],
    COUNT(DISTINCT o.OrderID) as [TotalOrders],
    CASE 
        WHEN DATEDIFF(DAY, MIN(o.OrderDate), MAX(o.OrderDate)) = 0 THEN 'One-time Customer'
        WHEN DATEDIFF(DAY, MIN(o.OrderDate), MAX(o.OrderDate)) <= 30 THEN 'Active (≤30 days)'
        WHEN DATEDIFF(DAY, MIN(o.OrderDate), MAX(o.OrderDate)) <= 90 THEN 'Regular (31-90 days)'
        ELSE 'Long-term (>90 days)'
    END as [CustomerType]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.Status = 'Completed'  -- Consider only completed orders
GROUP BY c.CustomerID, c.Name, c.Country, c.Segment
ORDER BY [OrderGapDays] DESC, [TotalOrders] DESC;

--5) Rolling Revenue
--Use SUM() OVER(ORDER BY OrderDate) to show cumulative revenue trend by order date.
Select
	o.OrderDate,
	SUM(p.Price*od.Quantity) as DailyRevenue,
	SUM(SUM(p.Price*od.Quantity)) over (order by o.OrderDate) as CumulativeRevenue
from Orders o
join OrderDetails od on o.OrderID =od.OrderID 
join Products p on p.ProductID =od.ProductID 
group by o.OrderDate 
order by o.OrderDate;

--6) High-Value Customers
--Customers whose average completed order value > 500.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	ROUND(AVG(p.Price*od.Quantity),2) as [Average Revenue]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
join OrderDetails od on od.OrderID =o.OrderID 
join Products p on p.ProductID =od.ProductID 
where o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
having AVG(p.Price*od.Quantity)>500
order by [Average Revenue] Desc;

--7) Top Products Returned
--List products most frequently found in Returned orders.
SELECT
    p.ProductID,p.ProductName,p.Category,
    COUNT(od.ProductID) AS ReturnedCount
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON p.ProductID = od.ProductID
WHERE o.Status = 'Returned'
GROUP BY p.ProductID,p.ProductName,p.Category
ORDER BY ReturnedCount DESC;

--8) Customer Retention
--Find customers who placed orders in consecutive months.
WITH CustomerMonthlyOrders AS (
    SELECT
        c.CustomerID,c.Name as CustomerName,c.Country, c.Segment,
        YEAR(o.OrderDate) as OrderYear,
        MONTH(o.OrderDate) as OrderMonth,
        COUNT(DISTINCT o.OrderID) as MonthlyOrderCount
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.Status = 'Completed'
    GROUP BY c.CustomerID, c.Name, c.Country, c.Segment, 
             YEAR(o.OrderDate), MONTH(o.OrderDate)
),
OrderSequence AS (
    SELECT
        CustomerID,CustomerName,Country,Segment,
        OrderYear,OrderMonth,MonthlyOrderCount,
        LAG(CONCAT(OrderYear, '-', RIGHT('0' + CAST(OrderMonth as VARCHAR(2)), 2))) 
            OVER (PARTITION BY CustomerID ORDER BY OrderYear, OrderMonth) as PreviousMonth,
        CONCAT(OrderYear, '-', RIGHT('0' + CAST(OrderMonth as VARCHAR(2)), 2)) as CurrentMonth
    FROM CustomerMonthlyOrders
)
SELECT
    CustomerID,CustomerName,Country,Segment,
    COUNT(*) as ConsecutiveMonthsCount,
    MIN(CurrentMonth) as FirstConsecutiveMonth,
    MAX(CurrentMonth) as LastConsecutiveMonth
FROM OrderSequence
WHERE PreviousMonth IS NOT NULL
    AND DATEDIFF(MONTH, 
                 CAST(PreviousMonth + '-01' as DATE), 
                 CAST(CurrentMonth + '-01' as DATE)) = 1
GROUP BY CustomerID, CustomerName, Country, Segment
HAVING COUNT(*) >= 1  -- At least 2 consecutive months
ORDER BY ConsecutiveMonthsCount DESC, CustomerID;

--9) Country Revenue Share
--Show revenue contribution per country and calculate % contribution out of total.
With CountryRevenue as (
				Select
					c.Country,
					ROUND(SUM(p.Price*od.Quantity),2) as TotalRevenue,
					SUM(SUM(p.Price*od.Quantity)) over() as GlobalRevenue
				from Customers c
				join Orders o on c.CustomerID =o.CustomerID 
				join OrderDetails od on o.OrderID =od.OrderID 
				join Products p on p.ProductID =od.ProductID 
				where o.Status ='Completed'
				group by c.Country)
Select
	Country,TotalRevenue,
	ROUND((TotalRevenue * 100.0 / GlobalRevenue), 2) as RevenuePercentage,
    RANK() OVER(ORDER BY TotalRevenue DESC) as RevenueRank
FROM CountryRevenue
ORDER BY TotalRevenue DESC;

--10) Profitability Check
--Assume margin: Electronics = 20% and Furniture = 30%
--Calculate profit per order.
SELECT
    o.OrderID,o.OrderDate,
    c.CustomerID,c.Name as CustomerName,c.Country,c.Segment,
    ROUND(SUM(p.Price * od.Quantity), 2) as TotalRevenue,
    ROUND(SUM(CASE 
        WHEN p.Category = 'Electronics' THEN p.Price * od.Quantity * 0.20
        WHEN p.Category = 'Furniture' THEN p.Price * od.Quantity * 0.30
        ELSE p.Price * od.Quantity * 0.25 -- Default margin for other categories
    END), 2) as TotalProfit,
    ROUND(SUM(CASE 
        WHEN p.Category = 'Electronics' THEN p.Price * od.Quantity * 0.20
        WHEN p.Category = 'Furniture' THEN p.Price * od.Quantity * 0.30
        ELSE p.Price * od.Quantity * 0.25
    END) * 100.0 / NULLIF(SUM(p.Price * od.Quantity), 0), 2) as ProfitMarginPercentage,
    COUNT(od.ProductID) as TotalItems
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON p.ProductID = od.ProductID
WHERE o.Status = 'Completed'
GROUP BY o.OrderID, o.OrderDate, c.CustomerID, c.Name, c.Country, c.Segment
ORDER BY TotalProfit DESC;

--Bonus Challenge
--11) RFM Analysis (Recency, Frequency, Monetary)
--Recency = Days since last order, Frequency = Number of completed orders,Monetary = Total Completed Revenue
--Classify customers into segments: High Value (Recent < 60 days, Frequency > 2, Monetary > 1000),Medium Value,Low Value
WITH CustomerRFM AS (
    SELECT
        c.CustomerID,c.Name as CustomerName,c.Country,c.Segment,
        DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) as DaysSinceLastOrder,
        COUNT(DISTINCT o.OrderID) as TotalOrders,
        ROUND(SUM(p.Price * od.Quantity), 2) as TotalRevenue
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON p.ProductID = od.ProductID
    WHERE o.Status = 'Completed'
    GROUP BY c.CustomerID, c.Name, c.Country, c.Segment
)
SELECT
    CustomerID,CustomerName,Country,Segment,
    DaysSinceLastOrder as Recency,
    TotalOrders as Frequency,
    TotalRevenue as Monetary,
    CASE 
        WHEN DaysSinceLastOrder < 60 AND TotalOrders > 2 AND TotalRevenue > 1000 THEN 'High Value'
        WHEN (DaysSinceLastOrder BETWEEN 60 AND 120) OR (TotalOrders BETWEEN 2 AND 5) OR (TotalRevenue BETWEEN 500 AND 1000) THEN 'Medium Value'
        ELSE 'Low Value'
    END as CustomerSegment,
    CASE 
        WHEN DaysSinceLastOrder < 60 THEN 'Recent'
        WHEN DaysSinceLastOrder < 120 THEN 'Moderately Recent'
        ELSE 'Not Recent'
    END as RecencyCategory,
    CASE 
        WHEN TotalOrders > 5 THEN 'Frequent Buyer'
        WHEN TotalOrders > 2 THEN 'Regular Buyer'
        ELSE 'Occasional Buyer'
    END as FrequencyCategory,
    CASE 
        WHEN TotalRevenue > 1500 THEN 'High Spender'
        WHEN TotalRevenue > 800 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END as MonetaryCategory
FROM CustomerRFM
ORDER BY TotalRevenue DESC;

