Create table Categories (
							CategoryID int primary key,
							CategoryName varchar(50) not null
						);

Create table Products (
						ProductID int primary key,
						ProductName varchar(50) not null unique,
						CategoryID int not null,
						Price decimal (10,2) not null check(Price>0),
						Stock int not null DEFAULT 0 check(Stock>=0)
						Foreign key (CategoryID) references Categories(CategoryID) on update cascade on delete cascade
						);

Create table Customers (
						CustomerID int primary key,
						CustomerName varchar(75) not null CHECK (LEN(CustomerName) >= 3),
						City varchar(50) not null CHECK (City IN ('Delhi', 'Mumbai', 'Bangalore'))
						);

Create table Orders (
						OrderID int primary key,
						CustomerID int not null,
						OrderDate date not null default getdate(),
						foreign key(CustomerID) references Customers(CustomerID) on update cascade,
					);

Create table OrderDetails (
							OrderDetailID int primary key,
							OrderID int not null,
							ProductID int not null,
							Quantity int not null check (Quantity>=0),
							UNIQUE (OrderID, ProductID),
							foreign key (OrderID) references Orders(OrderID) on update cascade on delete cascade,
							foreign key (ProductID) references Products(ProductID) on update cascade
							);

Create Index Idx_Products_CategoryID on Products(CategoryID);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);

INSERT INTO Categories VALUES
(1, 'Electronics'),
(2, 'Clothing'),
(3, 'Books');

INSERT INTO Products VALUES
(101, 'Smartphone', 1, 25000, 50),
(102, 'Laptop', 1, 55000, 30),
(103, 'T-Shirt', 2, 800, 100),
(104, 'Novel', 3, 400, 200);

INSERT INTO Customers VALUES
(1, 'Amit Sharma', 'Delhi'),
(2, 'Priya Singh', 'Mumbai'),
(3, 'Rahul Verma', 'Bangalore');

INSERT INTO Orders VALUES
(1001, 1, '2024-01-15'),
(1002, 2, '2024-02-10'),
(1003, 1, '2024-02-12'),
(1004, 3, '2024-03-05');

INSERT INTO OrderDetails VALUES
(1, 1001, 101, 1),
(2, 1001, 103, 2),
(3, 1002, 102, 1),
(4, 1003, 104, 3),
(5, 1004, 101, 2);

Select * from Categories 
Select * from Products 
Select * from Customers 
Select * from Orders 
Select * from OrderDetails 

--1) List all products with their category names.
Select
	p.ProductID,p.ProductName,ca.CategoryName, p.Price, p.Stock
from
	Products p
join
	Categories ca
on p.CategoryID =ca.CategoryID 
Order by
	p.ProductID;

--2) Show all orders with customer names and order dates.
SELECT
	o.OrderID, c.CustomerName, o.OrderDate
FROM 
	Orders o
JOIN 
	Customers c 
ON o.CustomerID = c.CustomerID;

--3) Find total sales amount (Price * Quantity) per product.
Select
	p.ProductID,p.ProductName,
	Sum(od.Quantity*p.Price) as [Total Sales Amount]
from
	Products p
join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	p.ProductID,p.ProductName
Order by
	[Total Sales Amount] Desc;

--4) Display customers who have placed more than 1 order.
SELECT 
	c.CustomerID, c.CustomerName, 
	COUNT(o.OrderID) AS OrderCount
FROM 
	Customers c
JOIN 
	Orders o ON c.CustomerID = o.CustomerID
GROUP BY 
	c.CustomerID, c.CustomerName
HAVING 
	COUNT(o.OrderID) > 1;

--5) Find the category with the highest total sales.
Select top 1
	ca.CategoryID,ca.CategoryName,
	SUM(p.Price*od.Quantity) as [Total Sales]
from
	Categories ca
join
	Products p
on ca.CategoryID =p.CategoryID 
join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	ca.CategoryID,ca.CategoryName
Order by
	[Total Sales] Desc;

--6) List products that are out of stock.
Select
	ProductID,ProductName
from
	Products 
 where
	Stock is null;

--7) Show top 2 selling products by quantity.
SELECT TOP 2
	p.ProductID, p.ProductName, 
    SUM(od.Quantity) AS TotalQuantitySold
FROM 
	Products p
JOIN 
	OrderDetails od ON p.ProductID = od.ProductID
GROUP BY
	p.ProductID, p.ProductName
ORDER BY 
	TotalQuantitySold DESC;

--8) Display total quantity sold per category.
Select
	ca.CategoryID,ca.CategoryName,
	Sum(od.Quantity) as TotalQuantitySold
from
	Categories ca
join
	Products p
on ca.CategoryID =p.CategoryID 
join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	ca.CategoryID,ca.CategoryName
Order by
	TotalQuantitySold Desc;

--9) Find customers who have not placed any orders.
Select
	cu.CustomerID,cu.CustomerName
from
	Customers cu
left join
	Orders o
on cu.CustomerID =o.CustomerID 
where
	o.OrderID is null;

--10) List products that were never sold.
SELECT 
	p.ProductID, p.ProductName
FROM 
	Products p
LEFT JOIN 
	OrderDetails od 
ON p.ProductID = od.ProductID
WHERE 
	od.OrderDetailID IS NULL;

-- Bonus Challenge: 
-- Identify the month with the highest total sales amount.
SELECT TOP 1 
    FORMAT(o.OrderDate, 'yyyy-MM') AS Month,
    SUM(p.Price * od.Quantity) AS TotalSalesAmount
FROM 
	Orders o
JOIN 
	OrderDetails od ON o.OrderID = od.OrderID
JOIN 
	Products p ON od.ProductID = p.ProductID
GROUP BY 
	FORMAT(o.OrderDate, 'yyyy-MM')
ORDER BY 
	TotalSalesAmount DESC;


