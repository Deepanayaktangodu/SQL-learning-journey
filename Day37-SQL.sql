CREATE TABLE Customers (
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(100) NOT NULL CHECK(len(Name)>=2),
						Age INT NOT NULL CHECK (Age >0),
						Country VARCHAR(50) NOT NULL CHECK(len(Country)>=2),
						Gender VARCHAR(10) NOT NULL CHECK(Gender in ('Male','Female'))
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE not null default getdate() CHECK(OrderDate<=getdate()),
						OrderAmount DECIMAL(10,2) NOT NULL CHECK(OrderAmount>0),
						OrderStatus VARCHAR(20) NOT NULL CHECK (OrderStatus IN ('Completed','Cancelled','Returned')),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION
					);


CREATE TABLE Products (
						ProductID INT PRIMARY KEY,
						ProductName VARCHAR(100)NOT NULL UNIQUE CHECK(len(ProductName)>=2),
						Category VARCHAR(50) NOT NULL CHECK (Category in ('Electronics','Fashion','Home Appliances')),
						Price DECIMAL(10,2) NOT NULL CHECK(Price>0)
					);

CREATE TABLE OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductID INT NOT NULL,
							Quantity INT NOT NULL CHECK(Quantity>0),
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY (ProductID) REFERENCES Products(ProductID)ON UPDATE CASCADE ON DELETE NO ACTION
						);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_Products_ProductName on Products(ProductName);
Create Index Idx_Products_Category on Products(Category);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);

INSERT INTO Customers VALUES
(1, 'Aarav Mehta', 28, 'India', 'Male'),
(2, 'Sophia Johnson', 35, 'USA', 'Female'),
(3, 'Wei Chen', 42, 'China', 'Male'),
(4, 'Maria Gonzalez', 30, 'Spain', 'Female'),
(5, 'David Smith', 50, 'UK', 'Male');

INSERT INTO Orders VALUES
(101, 1, '2024-06-10', 250.00, 'Completed'),
(102, 2, '2024-06-12', 450.00, 'Cancelled'),
(103, 3, '2024-06-15', 300.00, 'Completed'),
(104, 4, '2024-06-18', 700.00, 'Returned'),
(105, 5, '2024-06-20', 200.00, 'Completed'),
(106, 1, '2024-07-01', 600.00, 'Completed'),
(107, 2, '2024-07-05', 150.00, 'Completed'),
(108, 3, '2024-07-10', 900.00, 'Cancelled');

INSERT INTO Products VALUES
(201, 'Laptop', 'Electronics', 800.00),
(202, 'Headphones', 'Electronics', 150.00),
(203, 'Shoes', 'Fashion', 120.00),
(204, 'Watch', 'Fashion', 300.00),
(205, 'Microwave', 'Home Appliances', 400.00);

INSERT INTO OrderDetails VALUES
(301, 101, 201, 1),
(302, 101, 202, 2),
(303, 103, 203, 1),
(304, 104, 204, 1),
(305, 105, 205, 1),
(306, 106, 201, 1),
(307, 106, 203, 2),
(308, 107, 202, 1),
(309, 108, 201, 1);

Select*from Customers 
Select * from Orders 
Select * from Products 
Select * from OrderDetails 

--1) List all customers with their latest order date.
Select
	c.CustomerID,c.Name as 'CustomerName',c.Country,
	MAX(o.OrderDate) as [Latest Order Date]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
Group by c.CustomerID,c.Name,c.Country
Order by [Latest Order Date] Desc;

--2) Find the total revenue generated from "Electronics" category.
Select
    SUM(p.Price * od.Quantity) AS [Total Revenue Generated]
from Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
where p.Category = 'Electronics' AND o.OrderStatus = 'Completed';

--3) Get the customers who have placed more than 2 orders.
Select
	c.CustomerID,c.Name as 'CustomerName',c.Country,
	Count(o.OrderID) as [Total Orders]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
Group by c.CustomerID,c.Name ,c.Country
having Count(o.OrderID)>2
order by [Total Orders] Desc;

--4) Find the average order amount per customer.
Select
	c.CustomerID,c.Name as 'CustomerName',c.Country,
	ROUND(AVG(o.OrderAmount),2) as [Average Order Amount]
from Customers c 
join Orders o on c.CustomerID =o.CustomerID 
Group by c.CustomerID,c.Name,c.Country 
Order by [Average Order Amount] desc;

--5) Retrieve the top 2 highest-value orders.
Select top 2
	o.OrderID,o.OrderDate,
	SUM(p.Price*od.Quantity) as [Highest Value Orders]
from Orders o
join OrderDetails od on o.OrderID =od.OrderID
join Products p on p.ProductID =od.ProductID 
Group by o.OrderID ,o.OrderDate 
Order by [Highest Value Orders] Desc;

--6) List customers who have never placed a completed order.
Select
	c.CustomerID,c.Name as 'CustomerName',c.Country
from Customers c
left join Orders o on c.CustomerID =o.CustomerID 
where o.OrderID is null;

--7) Calculate category-wise total sales.
Select
	p.Category,
	SUM(p.Price*od.Quantity) as [Total Sales]
from Products p
join OrderDetails od on p.ProductID =od.ProductID 
join Orders o on o.OrderID =od.OrderID 
where o.OrderStatus ='Completed'
Group by p.Category 
Order by [Total Sales] Desc;

--8) Show the month with the highest total revenue.
Select top 1
	DateName(Month,o.OrderDate) as [Month],
	SUM(p.Price*od.Quantity) as [Total Revenue]
from Orders o
join OrderDetails od on o.OrderID =od.OrderID 
join Products p on p.ProductID =od.ProductID
GROUP BY DATENAME(month, o.OrderDate)
ORDER BY [Total Revenue] DESC;

--9) Find customers whose all orders are completed.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country
from Customers c
where not exists (
			Select 1
			from Orders o
			where c.CustomerID =o.CustomerID  and o.OrderStatus !='Completed');

--10) Rank products by sales quantity (highest to lowest).
WITH ProductSalesQuantity AS (
					SELECT
						p.ProductID,p.ProductName,p.Category,
						SUM(od.Quantity) AS [Total Sales Quantity]
					FROM Products p
					JOIN OrderDetails od ON p.ProductID = od.ProductID
					GROUP BY p.ProductID,p.ProductName,p.Category)
SELECT
    *,
    RANK() OVER (ORDER BY [Total Sales Quantity] DESC) AS QuantityRank
FROM ProductSalesQuantity
ORDER BY [Total Sales Quantity] DESC;

--Bonus Challenge:
--Find the percentage of cancelled orders for each customer.
SELECT
	c.CustomerID, c.Name AS 'CustomerName',
	CAST(SUM(CASE WHEN o.OrderStatus = 'Cancelled' THEN 1 ELSE 0 END) AS DECIMAL(10, 2)) * 100 / COUNT(o.OrderID) AS [Cancellation Rate %]
FROm Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Name
ORDER BY [Cancellation Rate %] DESC;