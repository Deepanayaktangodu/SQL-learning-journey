Create table Customers (
						CustomerID INT Primary Key,
						Name Varchar(50) Not Null Check(Len(Name)>=2),
						Country Varchar(30) Not Null Check(Len(Country)>=2),
						JoinDate Date Not Null Default GetDate() Check(JoinDate<=GetDate()),
						Tier Varchar(10) Not Null Check(Tier in ('Gold','Silver','Bronze'))
						);

Create table Orders (
						OrderID Int Primary Key,
						CustomerID Int Not Null,
						OrderDate Date Not Null,
						Status Varchar(50) Not Null Check(Status in ('Completed','Cancelled')),
						TotalAmount Decimal(8,2) Null Check(TotalAmount>=0),
						Foreign key(CustomerID) references Customers(CustomerID) on update cascade on delete no action
					);

Create table Payments (
						PaymentID Int Primary Key,
						OrderID Int Not Null,
						PaymentDate Date Not Null Check(PaymentDate<=GetDate()),
						Mode Varchar(50) Not Null,
						Amount Decimal(8,2) Null Check(Amount>=0),
						UNIQUE (OrderID, PaymentDate),
						Foreign Key(OrderID) references Orders(OrderID) on update cascade on delete no action
						);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Customers_Tier on Customers(Tier);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_Payments_Mode on Payments(Mode);
Create Index Idx_Payments_OrderID on Payments(OrderID);

INSERT INTO Customers (CustomerID, Name, Country, JoinDate, Tier) VALUES
(1, 'Alice', 'USA', '2021-01-01', 'Gold'),
(2, 'Bob', 'India', '2021-03-15', 'Silver'),
(3, 'Charlie', 'UK', '2022-02-20', 'Bronze'),
(4, 'David', 'Canada', '2022-07-10', 'Silver'),
(5, 'Emma', 'India', '2023-01-05', 'Gold');

INSERT INTO Orders (OrderID, CustomerID, OrderDate, Status, TotalAmount) VALUES
(101, 1, '2023-01-10', 'Completed', 300),
(102, 2, '2023-01-12', 'Cancelled', 0),
(103, 3, '2023-02-01', 'Completed', 450),
(104, 4, '2023-02-18', 'Completed', 120),
(105, 5, '2023-03-01', 'Completed', 700),
(106, 1, '2023-03-05', 'Completed', 200),
(107, 2, '2023-03-12', 'Completed', 350),
(108, 3, '2023-04-01', 'Completed', 500),
(109, 4, '2023-04-10', 'Completed', 150),
(110, 5, '2023-04-15', 'Completed', 600);

INSERT INTO Payments (PaymentID, OrderID, PaymentDate, Mode, Amount) VALUES
(1, 101, '2023-01-10', 'Card', 300),
(2, 103, '2023-02-01', 'PayPal', 450),
(3, 104, '2023-02-18', 'Card', 120),
(4, 105, '2023-03-01', 'NetBanking', 700),
(5, 106, '2023-03-05', 'Card', 200),
(6, 107, '2023-03-12', 'UPI', 350),
(7, 108, '2023-04-01', 'Card', 500),
(8, 109, '2023-04-10', 'PayPal', 150),
(9, 110, '2023-04-15', 'Card', 600),
(10, 102, '2023-01-12', 'Card', 0);

Select * from Customers 
Select * from Orders 
Select * from Payments 

--1) Revenue by Country
--Find the total confirmed revenue contributed by each country.
SELECT
	c.Country,
	ROUND(SUM(o.TotalAmount),2) as [Total Revenue],
	COUNT(o.OrderID) as [Total Orders]
from Customers c
join Orders o on c.CustomerID =o.CustomerID and o.Status='Completed'
group by c.Country 
Order by [Total Revenue] DESC;

--2) Customer Lifetime Value
--Calculate total spend of each customer and rank them.
SELECT
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	ROUND(SUM(o.TotalAmount),2) as [Total Spend],
	RANK() OVER (Order BY SUM(o.TotalAmount) DESC) AS SpendRank
from Customers c
join Orders o on c.CustomerID =o.CustomerID AND o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
order by SpendRank ASC;

--3) Cancellation Rate
--Compute the percentage of cancelled orders for each country.
SELECT
    c.Country,
    COUNT(o.OrderID) as [Total Orders],
    SUM(CASE WHEN o.Status = 'Cancelled' THEN 1 ELSE 0 END) AS [Total Cancelled Orders],
    ROUND(
        SUM(CASE WHEN o.Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.00 / 
        NULLIF(COUNT(o.OrderID), 0), 2) as [Cancelled Order %]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID 
GROUP BY c.Country 
ORDER BY [Cancelled Order %] DESC;

--4) Monthly Sales Trend
--Show total monthly revenue and compare with the previous month using LAG.
SELECT
    YEAR(p.PaymentDate) as [Year],
    MONTH(p.PaymentDate) as [Month Number],
    DATENAME(MONTH, p.PaymentDate) as [Month Name],
    ROUND(SUM(p.Amount), 2) as [Total Revenue],
    LAG(ROUND(SUM(p.Amount), 2)) OVER (ORDER BY YEAR(p.PaymentDate), MONTH(p.PaymentDate)) as [Previous Month Revenue],
    ROUND(SUM(p.Amount) - LAG(SUM(p.Amount)) OVER (ORDER BY YEAR(p.PaymentDate), MONTH(p.PaymentDate)), 2) as [Monthly Change],
    ROUND(
        (SUM(p.Amount) - LAG(SUM(p.Amount)) OVER (ORDER BY YEAR(p.PaymentDate), MONTH(p.PaymentDate))) / 
        NULLIF(LAG(SUM(p.Amount)) OVER (ORDER BY YEAR(p.PaymentDate), MONTH(p.PaymentDate)), 0) * 100, 
        2
    ) as [Percentage Change %]
FROM Payments p
JOIN Orders o ON p.OrderID = o.OrderID
WHERE o.Status = 'Completed'  -- Only include completed orders
GROUP BY YEAR(p.PaymentDate), MONTH(p.PaymentDate), DATENAME(MONTH, p.PaymentDate)
ORDER BY [Year], [Month Number];

--5) Top Payment Mode
--Identify the most frequently used payment mode for completed orders.
Select
	p.Mode,
	COUNT(p.PaymentID) as [Total Payments]
from Payments p
join Orders o on p.OrderID =o.OrderID and o.Status ='Completed'
group by p.Mode 
order by [Total Payments] Desc;

--6) Customer Repeat Rate
--Find customers who have placed more than 2 completed orders.
SELECT
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	COUNT(Distinct o.OrderID) as [Completed Order Count]
from Customers c
join Orders o on c.CustomerID =o.CustomerID AND o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
having COUNT(Distinct o.OrderID)>2
order by [Completed Order Count] Desc;

--7) Window Function – Order Timeline
--For each customer, display their order history along with previous order amount (LAG).
SELECT
    c.CustomerID,c.Name as 'Customer Name', c.Country,c.Tier,
    o.OrderID,o.OrderDate,o.Status,o.TotalAmount,
    LAG(o.OrderID) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) as [Previous Order ID],
    LAG(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) as [Previous Order Date],
    LAG(o.TotalAmount) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) as [Previous Order Amount],
    ROUND(o.TotalAmount - LAG(o.TotalAmount) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate), 2) as [Amount Change],
    ROUND(
        (o.TotalAmount - LAG(o.TotalAmount) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate)) / 
        NULLIF(LAG(o.TotalAmount) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate), 0) * 100, 
        2
    ) as [Percentage Change],
    DATEDIFF(DAY, 
        LAG(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate), 
        o.OrderDate
    ) as [Days Since Last Order]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.Status = 'Completed'
ORDER BY c.CustomerID, o.OrderDate;

--8) Revenue by Tier
--Find average spend per order for each loyalty tier.
SELECT
	c.Tier,
	ROUND(AVG(o.TotalAmount),2) as [Average Spend]
from Customers c
join Orders o on c.CustomerID =o.CustomerID and o.Status ='Completed'
group by c.Tier 
order by [Average Spend] Desc;

--9) Late Payment Check
--Find orders where the payment date was later than the order date.
SELECT
    o.OrderID,c.CustomerID,c.Name as 'Customer Name',c.Country,c.Tier,
    o.TotalAmount,o.OrderDate,p.PaymentDate,p.Mode as 'Payment Method',
    DATEDIFF(DAY, o.OrderDate, p.PaymentDate) as [Days Delay],
    CASE 
        WHEN DATEDIFF(DAY, o.OrderDate, p.PaymentDate) = 0 THEN 'Same Day'
        WHEN DATEDIFF(DAY, o.OrderDate, p.PaymentDate) = 1 THEN '1 Day Late'
        WHEN DATEDIFF(DAY, o.OrderDate, p.PaymentDate) BETWEEN 2 AND 7 THEN '2-7 Days Late'
        WHEN DATEDIFF(DAY, o.OrderDate, p.PaymentDate) > 7 THEN 'Over 1 Week Late'
    END as [Delay Category]
FROM Orders o
JOIN Payments p ON o.OrderID = p.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.Status = 'Completed'
    AND o.OrderDate < p.PaymentDate
ORDER BY [Days Delay] DESC, o.OrderDate;

--10) High-Value Orders
--List orders where amount > average order value (use subquery).
SELECT
    o.OrderID,o.CustomerID,c.Name as 'Customer Name',c.Country,
    c.Tier,o.OrderDate,o.Status,o.TotalAmount,
    (SELECT ROUND(AVG(TotalAmount), 2) FROM Orders WHERE Status = 'Completed') as [Average Order Value],
    ROUND(o.TotalAmount - (SELECT AVG(TotalAmount) FROM Orders WHERE Status = 'Completed'), 2) as [Above Average By]
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.Status = 'Completed'
    AND o.TotalAmount > (SELECT AVG(TotalAmount) FROM Orders WHERE Status = 'Completed')
ORDER BY o.TotalAmount DESC;

--Bonus Challenge (Advanced & Optimization)
--11) Query Optimization Scenario
--Suppose the Orders table has 10 million rows and queries involving OrderDate filtering are slow.
--Write a query to get monthly revenue for 2023.
--Suggest which index(es) you would create to optimize such queries and why.
SELECT
    YEAR(o.OrderDate) as [Year],
    MONTH(o.OrderDate) as [Month],
    DATENAME(MONTH, o.OrderDate) as [MonthName],
    ROUND(SUM(o.TotalAmount), 2) as [MonthlyRevenue],
    COUNT(o.OrderID) as [TotalOrders],
    ROUND(AVG(o.TotalAmount), 2) as [AverageOrderValue]
FROM Orders o
WHERE o.Status = 'Completed'
    AND o.OrderDate >= '2023-01-01' AND o.OrderDate < '2024-01-01'
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate)
ORDER BY [Year], [Month];

CREATE INDEX IX_Orders_OrderDate_Status_TotalAmount 
ON Orders (OrderDate, Status) 
INCLUDE (TotalAmount, OrderID);
