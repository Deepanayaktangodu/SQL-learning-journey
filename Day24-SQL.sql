Create table Customers(
						CustomerID int primary key,
						CustomerName varchar(30) not null,
						Email varchar (75) not null unique Check (Email like '%@%.%'),
						Country varchar(25) not null
						);

Create table Products (
						ProductID int primary key,
						ProductName varchar(75) not null unique,
						Category varchar(30) not null,
						Price decimal (10,2) not null check (Price>0)
						);

Create table Orders (
						OrderID int primary key,
						CustomerID int not null,
						ProductID int not null,
						Quantity int not null check (Quantity>0),
						OrderDate date not null,
						foreign key(CustomerID) references Customers(CustomerID) on update cascade on delete cascade,
						foreign key (ProductID) references Products(ProductID) on update cascade on delete cascade
					);

Create table Returns (
						ReturnID int primary key,
						OrderID int not null,
						ReturnDate date not null,
						Reason varchar(100) not null,
						foreign key (OrderID) references Orders(OrderID) on update cascade on delete cascade
						);

CREATE TRIGGER ValidateReturnDate
ON Returns
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted r
        JOIN Orders o ON r.OrderID = o.OrderID
        WHERE r.ReturnDate <= o.OrderDate
    )
    BEGIN
        RAISERROR('Return date must be after the order date', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

Create Index Idx_Customers_CustomerID on Customers(CustomerID);
Create Index Idx_Customers_CustomerName on Customers(CustomerName);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Products_Category on Products(Category);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_Orders_ProductID on Orders(ProductID);
Create Index Idx_Orders_OrderDate on Orders(OrderDate);
Create Index Idx_Returns_OrderID on Returns(OrderID);

INSERT INTO Customers VALUES
(1, 'Aarav Patel', 'aarav@example.com', 'India'),
(2, 'Sara Khan', 'sara@example.com', 'India'),
(3, 'John Doe', 'john@example.com', 'USA'),
(4, 'Emma Watson', 'emma@example.com', 'UK');

INSERT INTO Products VALUES
(101, 'Wireless Mouse', 'Electronics', 499.00),
(102, 'Yoga Mat', 'Fitness', 899.00),
(103, 'Bluetooth Speaker', 'Electronics', 1599.00),
(104, 'Running Shoes', 'Footwear', 2499.00);

INSERT INTO Orders VALUES
(1001, 1, 101, 2, '2023-06-01'),
(1002, 2, 102, 1, '2023-06-03'),
(1003, 3, 103, 1, '2023-06-05'),
(1004, 3, 101, 3, '2023-06-06'),
(1005, 4, 104, 1, '2023-06-10');


INSERT INTO Returns VALUES
(1, 1002, '2023-06-08', 'Wrong Item'),
(2, 1004, '2023-06-10', 'Damaged Product');

Select*from Customers 
Select*from Products 
Select*from Orders 
Select*from Returns 

--1) List all customers along with their total number of orders and total amount spent.
Select
	c.CustomerID, c.CustomerName,
	count (Distinct o.OrderID) as [Total Orders],
	Coalesce(Sum(p.Price*o.Quantity),0)as [Total Amount Spent]
from
	Customers c
left join
	Orders o
on c.CustomerID =o.CustomerID 
left join
	Products p
on p.ProductID =o.ProductID 
Group by
	c.CustomerID, c.CustomerName
Order by
	[Total Amount Spent] Desc;

--2) Display the most sold product and its total quantity sold.
Select Top 1
	p.ProductID,p.ProductName,
	Sum(o.Quantity) as [Total Sold Quantity]
from 
	Products p
join
	Orders o
on p.ProductID =o.ProductID 
Group by
	p.ProductID,p.ProductName
Order by
	[Total Sold Quantity] Desc;

--3) Show the average order value per customer.
SELECT
    c.CustomerID,c.CustomerName,
    ROUND(COALESCE(AVG(p.Price * o.Quantity), 0), 2) AS [Average Order Value]
FROM
    Customers c
LEFT JOIN
    Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN
    Products p ON o.ProductID = p.ProductID
GROUP BY
    c.CustomerID, c.CustomerName
ORDER BY
    [Average Order Value] DESC;

--4) List customers who have returned at least one product.
SELECT DISTINCT
    c.CustomerID,c.CustomerName
FROM
    Customers c
JOIN
    Orders o ON c.CustomerID = o.CustomerID
JOIN
    Returns r ON o.OrderID = r.OrderID;

--5) Identify the category with the highest return rate.
WITH CategoryStats AS (
    SELECT 
        p.Category,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT r.ReturnID) AS ReturnedOrders,
        COUNT(DISTINCT r.ReturnID) * 100.0 / NULLIF(COUNT(DISTINCT o.OrderID), 0) AS ReturnRate
    FROM 
        Products p
    JOIN 
        Orders o ON p.ProductID = o.ProductID
    LEFT JOIN 
        Returns r ON o.OrderID = r.OrderID
    GROUP BY 
        p.Category)
SELECT TOP 1
    Category,ReturnRate AS [Return Rate (%)],
    ReturnedOrders AS [Returned Orders],TotalOrders AS [Total Orders]
FROM 
    CategoryStats
ORDER BY 
    ReturnRate DESC;

--6) Find the top 2 products with the highest total revenue.
SELECT TOP 2
    p.ProductID, p.ProductName,p.Category,
    SUM(p.Price * o.Quantity) AS [Total Revenue]
FROM
    Products p
JOIN
    Orders o ON p.ProductID = o.ProductID
GROUP BY
    p.ProductID, p.ProductName, p.Category
ORDER BY
    [Total Revenue] DESC;

--7) For each country, display the total number of customers and their total order value.
Select
	c.Country,
	Count(Distinct c.CustomerID) as [Total Customers],
	Coalesce(Sum(p.Price*o.Quantity),0) as [Total Order Value]
from
	Customers c
left join
	Orders o
on c.CustomerID =o.CustomerID 
left join
	Products p
on p.ProductID =o.ProductID 
Group by
	c.Country
Order by
	[Total Order Value] Desc;

--8) Display orders that were not returned.
SELECT
    o.OrderID,o.CustomerID,o.ProductID,o.Quantity,o.OrderDate
FROM
    Orders o
LEFT JOIN
    Returns r ON o.OrderID = r.OrderID
WHERE 
    r.ReturnID IS NULL;

--9) Show products that have never been ordered.
Select
	p.ProductID,p.ProductName
from
	Products p
left join
	Orders o
on p.ProductID =o.ProductID 
where 
	o.OrderID is null;

--10) For each product, display its return percentage (returned qty / ordered qty * 100).
SELECT 
    p.ProductID,p.ProductName,
    SUM(o.Quantity) AS TotalOrdered,
    COALESCE(SUM(CASE WHEN r.ReturnID IS NOT NULL THEN o.Quantity ELSE 0 END), 0) AS TotalReturned,
    CASE 
        WHEN SUM(o.Quantity) = 0 THEN 0
        ELSE ROUND(
            COALESCE(SUM(CASE WHEN r.ReturnID IS NOT NULL THEN o.Quantity ELSE 0 END), 0) * 100.0 / 
            SUM(o.Quantity), 
            2) 
    END AS ReturnPercentage
FROM 
    Products p
LEFT JOIN 
    Orders o ON p.ProductID = o.ProductID
LEFT JOIN 
    Returns r ON o.OrderID = r.OrderID
GROUP BY 
    p.ProductID, p.ProductName
ORDER BY 
    ReturnPercentage DESC;

-- Bonus Challenge
-- Rank customers by their net spending (total spent - value of returned items).
SELECT
    c.CustomerID,
    c.CustomerName,
    COALESCE(SUM(p.Price * o.Quantity), 0) AS [Total Spent],
    COALESCE(SUM(CASE WHEN r.ReturnID IS NOT NULL THEN p.Price * o.Quantity ELSE 0 END), 0) AS [Returned Value],
    COALESCE(SUM(p.Price * o.Quantity), 0) - 
    COALESCE(SUM(CASE WHEN r.ReturnID IS NOT NULL THEN p.Price * o.Quantity ELSE 0 END), 0) AS [Net Spending]
FROM
    Customers c
LEFT JOIN
    Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN
    Products p ON o.ProductID = p.ProductID
LEFT JOIN
    Returns r ON o.OrderID = r.OrderID
GROUP BY
    c.CustomerID, c.CustomerName
ORDER BY
    [Net Spending] DESC;
					