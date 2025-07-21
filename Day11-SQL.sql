Create table Customers(
						CustomerID int primary key,
						CustomerName char (50) not null,
						City varchar (50) not null
						);

Create table Products (
						ProductID int primary key,
						ProductName char (50) not null,
						Category varchar (50) not null,
						Price decimal (12,2) not null check (Price>0)
						);

Create table Orders (
						OrderID int primary key,
						CustomerID int not null,
						ProductID int not null,
						Quantity int not null check (Quantity>0),
						OrderDate Date not null  check (OrderDate<=GetDate ()),
						foreign key (CustomerID) references Customers(CustomerID),
						foreign key (ProductID) references Products(ProductID)
					);

Create table Shipping (
						OrderID int,
						ShippedDate Date not null,
						DeliveryStatus Char (50) not null default 'Pending'
						 CHECK (DeliveryStatus IN ('Delivered', 'Pending', 'Not Shipped'))
						foreign key (OrderID) references Orders(OrderID)
						);

Create index idx_Orders_CustomerID on Orders(CustomerID);
Create index idx_Orders_ProductID on Orders(ProductID);
Create index idx_Shipping_OrderID on Shipping(OrderID);
CREATE INDEX idx_Orders_OrderDate ON Orders(OrderDate);

Insert into Customers (CustomerID,CustomerName,City)
Values
	(1,'Alice','Bangalore'),
	(2,'Bob','Mumbai'),
	(3,'Charlie','Delhi'),
	(4,'David','Chennai'),
	(5,'Eva','Hyderabad');

Insert into Products ( ProductID,ProductName,Category,Price)
Values
	(101,'Laptop','Electronics',800),
	(102,'Keyboard','Electronics',40),
	(103,'T-Shirt','Cloathing',20),
	(104,'Book','Stationery',15),
	(105,'Shoes','Footwear',60);

Insert into Orders(OrderID,CustomerID,ProductID,Quantity,OrderDate)
Values
	(5001,1,101,1,'2023-01-15'),
	(5002,2,102,2,'2023-01-17'),
	(5003,1,103,3,'2023-01-20'),
	(5004,3,104,1,'2023-01-25'),
	(5005,5,105,2,'2023-02-02');

ALTER TABLE Shipping ALTER COLUMN ShippedDate DATE NULL;

INSERT INTO Shipping (OrderID, ShippedDate, DeliveryStatus)
VALUES
    (5001, '2023-01-16', 'Delivered'),
    (5002, '2023-01-19', 'Delivered'),
    (5003, '2023-01-21', 'Delivered'),
    (5004, '2023-01-30', 'Pending'),
	(5005, NULL, 'Not Shipped');

Select *from Customers 
Select *from Products
Select *from Orders 
Select *from Shipping 

--1) List all customer names and their cities.

Select CustomerName ,City from Customers;

--2) Show total quantity of items ordered by each customer.

SELECT
    c.CustomerID,c.CustomerName, 
    COALESCE(SUM(o.Quantity), 0) AS [Total Quantity]
FROM
    Customers c
LEFT JOIN
    Orders o ON c.CustomerID = o.CustomerID
GROUP BY
    c.CustomerID, c.CustomerName
ORDER BY
    [Total Quantity] DESC;

--3) Display total revenue generated per customer (Price × Quantity).

Select
	c.CustomerID, c.CustomerName, Coalesce (sum (p.Price*o.Quantity),0) as [Total Revenue]
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
	[Total Revenue] Desc;

--4) List all products that have not been ordered.

SELECT
    p.ProductID,p.ProductName,p.Category
FROM
    Products p
LEFT JOIN
    Orders o ON p.ProductID = o.ProductID  -- Fixed join condition
WHERE
    o.OrderID IS NULL;

--5) Find customers who haven’t placed any orders.

Select
	c.CustomerID,c.CustomerName
from
	Customers c
left join
	Orders o
on c.CustomerID =o.CustomerID 
WHERE
	o.OrderID is null;

--6) Show order details along with shipping status.

Select 
	o.OrderID,O.customerID,o.ProductID,o.Quantity,o.OrderDate,s.ShippedDate,s.DeliveryStatus 
from 
	Orders o
left join
	Shipping s
on o.OrderID =s.OrderID;

--7) List orders where shipping is pending or not yet shipped.

Select
	o.OrderID,o.OrderDate,s.DeliveryStatus,s.ShippedDate 
from
	Orders o
left join
	Shipping s
on
	o.OrderID =s.OrderID 
where
	 s.DeliveryStatus IN ('Pending', 'Not Shipped')
    OR s.DeliveryStatus IS NULL;

--8) Display top 2 customers by total order value.

SELECT TOP 2
    c.CustomerID,c.CustomerName,SUM(p.Price * o.Quantity) AS [Total Order Value]
FROM
    Customers c
JOIN
    Orders o ON c.CustomerID = o.CustomerID
JOIN
    Products p ON o.ProductID = p.ProductID
GROUP BY
    c.CustomerID, c.CustomerName
ORDER BY
    [Total Order Value] DESC;

--9)  Find the most popular product (highest total quantity ordered).

SELECT TOP 1
    p.ProductID, p.ProductName,
    COALESCE(SUM(o.Quantity), 0) AS [Total Quantity]
FROM
    Products p
LEFT JOIN
    Orders o ON p.ProductID = o.ProductID
GROUP BY
    p.ProductID, p.ProductName
ORDER BY
    [Total Quantity] DESC;

--10) For each category, display the product with highest revenue.

WITH ProductRevenue AS (
    SELECT
        p.Category,p.ProductID,p.ProductName,
        COALESCE(SUM(p.Price * o.Quantity), 0) AS Revenue
    FROM
        Products p
    LEFT JOIN
        Orders o ON p.ProductID = o.ProductID
    GROUP BY
        p.Category, p.ProductID, p.ProductName
)
SELECT
    pr.Category,pr.ProductName,
    pr.Revenue AS [Highest Revenue]
FROM
    ProductRevenue pr
WHERE
    pr.Revenue = (
        SELECT MAX(Revenue)
        FROM ProductRevenue pr2
        WHERE pr2.Category = pr.Category
    )
ORDER BY
    pr.Category;

--Bonus Challenge
-- Write a query to calculate average delivery time (in days) for all delivered orders.

SELECT
    CAST(AVG(CAST(DATEDIFF(day, o.OrderDate, s.ShippedDate) AS DECIMAL(10,2))) AS DECIMAL(10,2)) 
    AS [Average Delivery Time (Days)]
FROM
    Orders o
JOIN
    Shipping s ON o.OrderID = s.OrderID
WHERE
    s.DeliveryStatus = 'Delivered'
    AND s.ShippedDate IS NOT NULL;

