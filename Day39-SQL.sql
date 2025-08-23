Create table Customers (
							CustomerID int Primary key,
							Name varchar(100) not null unique Check(len(Name)>=2),
							Country varchar(100) not null Check(len(Country)>=2),
							JoinDate date not null default getdate() Check(JoinDate<=getdate())
						);

Create table Orders (
						OrderID int Primary key,
						CustomerID int not null,
						OrderDate date not null default getdate() Check(OrderDate<=getdate()),
						TotalAmount decimal(10,2) not null Check (TotalAmount>0),
						foreign key(CustomerID) references Customers(CustomerID) on update cascade on delete no action
					);

Create table OrderDetails (
							DetailID int Primary key,
							OrderID int not null,
							ProductName varchar(100) not null Check(len(ProductName)>=2),
							Quantity int not null Check(Quantity>0),
							Price decimal(10,2) not null Check(Price>0),
							foreign key(OrderID) references Orders(OrderID) on update cascade on delete no action
							);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_OrderDetails_ProductName on OrderDetails(ProductName);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);

INSERT INTO Customers VALUES 
(1,'Alice','USA','2021-01-15'),
(2,'Bob','Canada','2021-03-20'),
(3,'Charlie','USA','2022-07-10'),
(4,'David','UK','2022-08-25'),
(5,'Emma','USA','2023-01-05');

INSERT INTO Orders VALUES
(101,1,'2023-03-15',250.00),
(102,2,'2023-03-17',120.00),
(103,3,'2023-04-01',320.00),
(104,1,'2023-05-10',150.00),
(105,5,'2023-06-12',500.00),
(106,4,'2023-06-25',220.00),
(107,2,'2023-07-01',100.00),
(108,5,'2023-07-10',600.00);

INSERT INTO OrderDetails VALUES
(1,101,'Laptop',1,250.00),
(2,102,'Headphones',2,60.00),
(3,103,'Monitor',2,160.00),
(4,104,'Mouse',3,50.00),
(5,105,'iPhone',1,500.00),
(6,106,'Keyboard',2,110.00),
(7,107,'Charger',2,50.00),
(8,108,'iPad',1,600.00);

Select * from Customers 
Select * from Orders 
Select * from OrderDetails 

--1) Retrieve all customers who placed more than 2 orders in 2023.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where YEAR(o.OrderDate)=2023
group by c.CustomerID,c.Name,c.Country 
having count(o.OrderID)>2
order by c.CustomerID;

--2) Find the total revenue per country using JOIN.
Select
	c.Country,
	SUM(o.TotalAmount) as [Total Revenue]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
Group by c.Country 
Order by [Total Revenue] Desc;

--3) List the top 3 highest spending customers (by total order amount).
Select top 3
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	SUM(o.TotalAmount) as [Total Order Amount]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
group by c.CustomerID,c.Name,c.Country 
order by [Total Order Amount] Desc;

--4) Using a window function, calculate the running total of orders by each customer.
SELECT
  CustomerID,OrderDate,TotalAmount,
  SUM(TotalAmount) OVER (
    PARTITION BY CustomerID
    ORDER BY OrderDate) AS RunningTotal
FROM Orders
ORDER BY CustomerID, OrderDate;

--5) Find customers who haven’t placed any orders in 2023.
SELECT
  CustomerID, Name AS 'Customer Name'
FROM Customers
WHERE
  CustomerID NOT IN (
    SELECT DISTINCT
      CustomerID
    FROM Orders
    WHERE YEAR(OrderDate) = 2023);

--6) Display the most sold product (by total quantity) with its total sales.
SELECT TOP 1
    ProductName,
    SUM(Quantity) AS [Total Quantity],
    SUM(Price * Quantity) AS [Total Sales]
FROM OrderDetails
GROUP BY ProductName
ORDER BY [Total Quantity] DESC;

--7) For each customer, calculate the average order value and filter only those with avg > 200.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	ROUND(AVG(o.TotalAmount),2) as [Avg Order Value]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
Group by c.CustomerID,c.Name,c.Country 
having AVG(o.TotalAmount)>200
order by [Avg Order Value] Desc;

--8) Write a query using a CTE to find the latest order date for each customer.
WITH LatestOrders AS (
  SELECT
    CustomerID,
    MAX(OrderDate) AS LatestOrderDate
  FROM Orders
  GROUP BY CustomerID)
SELECT
  c.CustomerID,c.Name AS CustomerName,c.Country,l.LatestOrderDate
FROM Customers AS c
JOIN LatestOrders AS l ON c.CustomerID = l.CustomerID
ORDER BY c.CustomerID;

--9) Rank customers by their total spending using RANK() function.
With CustomerSpending as (
				Select
					c.CustomerID,c.Name as 'Customer Name',c.Country,
					SUM(o.TotalAmount) as [Total Spending]
				from Customers c
				join Orders o on c.CustomerID =o.CustomerID 
				Group by c.CustomerID,c.Name,c.Country)
Select 
	*,
	RANK() over (Order by [Total Spending] Desc) as SpendingRank
	from CustomerSpending 
	Order by SpendingRank ;

--10) Identify customers who spent above the overall average order amount.
SELECT
  c.CustomerID,c.Name AS 'Customer Name',
  SUM(o.TotalAmount) AS [Total Spending]
FROM Customers AS c
JOIN Orders AS o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID,c.Name
HAVING
  SUM(o.TotalAmount) > (
    SELECT
      AVG(TotalAmount)
    FROM
      Orders);

-- Bonus Challenge
--Write a query to find the customer who made consecutive monthly purchases in 2023 (March, April, May, etc.).
WITH CustomerMonthlyPurchases AS (
  SELECT
    CustomerID,
    -- Extract the first day of the month from the order date.
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth
  FROM Orders
  WHERE YEAR(OrderDate) = 2023
  GROUP BY
    CustomerID,
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)),
ConsecutivePurchases AS (
  SELECT
    CustomerID,OrderMonth,
    -- Get the previous month's purchase date for the same customer.
    LAG(OrderMonth, 1) OVER (
      PARTITION BY CustomerID
      ORDER BY OrderMonth
    ) AS PreviousMonth
  FROM CustomerMonthlyPurchases)
SELECT
  cp.CustomerID, c.Name AS CustomerName
FROM ConsecutivePurchases AS cp
JOIN Customers AS c
  ON cp.CustomerID = c.CustomerID
WHERE
  -- Check if the current month is exactly one month after the previous one.
  DATEDIFF(
    month,
    cp.PreviousMonth,
    cp.OrderMonth
  ) = 1
GROUP BY
  cp.CustomerID,c.Name;

