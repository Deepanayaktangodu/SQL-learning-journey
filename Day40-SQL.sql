Create table Customers (
						CustomerID int Primary key Identity(1,1),
						Name varchar(100) not null Check(len(Name)>=2),
						Country varchar(50) not null Check(len(Country)>=2),
						JoinDate date not null default getdate() Check(JoinDate<=getdate())
						);

Create table Orders (
						OrderID int Primary Key Identity(1,1),
						CustomerID int not null,
						OrderDate date not null default getdate() Check(OrderDate<=getdate()),
						Amount decimal not null Check(Amount>0),
						Status varchar(50) not null Check(Status in ('Completed','Cancelled','Pending')),
						foreign key (CustomerID) references Customers(CustomerID) on update cascade on delete no action
					);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);


-- Enable manual insertion into the IDENTITY column
SET IDENTITY_INSERT Customers ON;

-- Insert the data with explicit CustomerID values
INSERT INTO Customers (CustomerID, Name, Country, JoinDate)
VALUES
(1, 'Alice Smith', 'USA', '2021-01-10'),
(2, 'Bob Johnson', 'UK', '2021-02-15'),
(3, 'Carol Davis', 'USA', '2021-03-05'),
(4, 'David Lee', 'Canada', '2021-03-20'),
(5, 'Eva Green', 'USA', '2021-04-12');

-- Disable manual insertion to return to normal behavior
SET IDENTITY_INSERT Customers OFF;

-- Now insert data into the Orders table
SET IDENTITY_INSERT Orders ON;

INSERT INTO Orders (OrderID, CustomerID, OrderDate, Amount, Status)
VALUES
(101, 1, '2021-01-15', 120.50, 'Completed'),
(102, 1, '2021-02-20', 80.00, 'Completed'),
(103, 2, '2021-02-25', 200.00, 'Cancelled'),
(104, 3, '2021-03-10', 150.75, 'Completed'),
(105, 4, '2021-03-25', 300.00, 'Completed'),
(106, 5, '2021-04-15', 50.00, 'Completed'),
(107, 5, '2021-05-01', 75.50, 'Pending'),
(108, 3, '2021-05-05', 180.00, 'Completed'),
(109, 1, '2021-06-01', 90.25, 'Completed'),
(110, 2, '2021-06-10', 220.00, 'Completed');

SET IDENTITY_INSERT Orders OFF;

Select * from Customers 
Select * from Orders 

--1) Retrieve all customers who have placed at least one order.
SELECT DISTINCT
    c.CustomerID,c.Name AS 'Customer Name',c.Country
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID;

--2) Find total revenue from completed orders per customer.
Select
    c.CustomerID,c.Name AS 'Customer Name',c.Country,
	SUM(Amount) as [Total Revenue]
FROM Customers c
join Orders o on c.CustomerID =o.CustomerID 	
where o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
order by [Total Revenue] Desc;

--3) Get customers who have more than 1 completed order.
Select 
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	Count(o.OrderID) as [Completed Order Count]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
having Count(o.OrderID)>1
order by [Completed Order Count] Desc;

--4) Find the first and last order date for each customer.
Select 
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	Min(o.OrderDate) as [First Order Date],
	MAX(o.OrderDate) as [Last Order Date]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
group by c.CustomerID,c.Name,c.Country 
order by c.CustomerID;

--5) List customers with their average order value, only considering completed orders.
Select 
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	ROUND(AVG(o.Amount),2) as [Average order value]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Completed'
Group by c.CustomerID,c.Name,c.Country 
order by [Average order value] Desc;

--6) Use a window function to rank customers by their total spending (completed orders only).
SELECT
    CustomerID,Name AS 'Customer Name',TotalSpending,
    DENSE_RANK() OVER (ORDER BY TotalSpending DESC) AS Ranking
FROM (
    SELECT
        c.CustomerID,c.Name,
        SUM(o.Amount) AS TotalSpending
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.Status = 'Completed'
    GROUP BY c.CustomerID,c.Name) AS CustomerSpending
ORDER BY Ranking;

--7) Find the month with the highest total revenue.
Select top 1
	DATENAME(MONTH,OrderDate) as [Month],
	SUM(Amount) as [Total Revenue]
from Orders o
Group by DATENAME(MONTH,OrderDate)
order by [Total Revenue] Desc;

--8) For each customer, calculate the difference between their first and last order amount.
WITH CustomerOrders AS (
    SELECT
        CustomerID,OrderDate,Amount,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate ASC) AS FirstOrderRank,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) AS LastOrderRank
    FROM
        Orders)
SELECT
    c.Name AS 'Customer Name',
    first_order.Amount AS 'First Order Amount',
    last_order.Amount AS 'Last Order Amount',
    last_order.Amount - first_order.Amount AS 'Difference'
FROM
    Customers c
JOIN
    CustomerOrders first_order ON c.CustomerID = first_order.CustomerID AND first_order.FirstOrderRank = 1
JOIN
    CustomerOrders last_order ON c.CustomerID = last_order.CustomerID AND last_order.LastOrderRank = 1
WHERE
    first_order.Amount IS NOT NULL AND last_order.Amount IS NOT NULL;

--9) Find customers who never had a cancelled order.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country
from Customers c
where not exists(
		Select 1
		from Orders o
		where c.CustomerID =o.CustomerID 
		and o.Status ='Cancelled');


--10) Write a query to return each customer's name, total completed orders, total revenue, 
--and their rank based on revenue (highest first).
Select
	c.Name as 'Customer Name',
	COUNT(o.OrderID) as [Completed Order Count],
	SUM(o.Amount)as [Total Revenue],
	DENSE_RANK () over (Order by SUM(o.Amount) Desc) as 'Revenue Rank'
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Completed'
group by c.Name 
order by 'Revenue Rank';


-- Bonus Challenge:
-- Write a query that returns each customer’s order history in chronological order 
--with a running total of their spending (only completed orders).
SELECT
    c.Name AS 'Customer Name',
    o.OrderDate,o.Amount,
    SUM(o.Amount) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) AS 'Running Total'
FROM
    Customers c
JOIN
    Orders o ON c.CustomerID = o.CustomerID
WHERE
    o.Status = 'Completed'
ORDER BY
    c.CustomerID,
    o.OrderDate;

