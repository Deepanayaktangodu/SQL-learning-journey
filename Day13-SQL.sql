Create table Customers (
						CustomerID int primary key,
						Name varchar (50) not null,
						Country varchar (50) not null
						);

Create table Products (
						ProductID int primary key,
						ProductName varchar (50) not null,
						Category varchar(50) not null,
						Price decimal (10,2) not null check (Price>0)
						);

Create table Orders (
						OrderID int primary key,
						CustomerID int not null,
						OrderDate date not null DEFAULT GETDATE() CHECK (OrderDate <= GETDATE()),
						TotalAmount decimal (10,2) not null check (TotalAmount>0),
						foreign key (CustomerID) references Customers(CustomerID)
						ON DELETE CASCADE
						ON UPDATE CASCADE
					);

CREATE TABLE OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductID INT NOT NULL,
							Quantity INT NOT NULL CHECK (Quantity >= 0),
							FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
							ON DELETE CASCADE
							ON UPDATE CASCADE,
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
							ON DELETE CASCADE
							ON UPDATE CASCADE
							);


Create index idx_Orders_CustomerID on Orders(CustomerID);
Create index idx_OrderDetails_ProductID on OrderDetails(ProductID);
Create index idx_OrderDetails_OrderID on OrderDetails(OrderID);

-- Insert data into Customers table
INSERT INTO Customers (CustomerID, Name, Country) VALUES
(1, 'Alice', 'USA'),
(2, 'Bob', 'UK'),
(3, 'Charlie', 'India'),
(4, 'Diana', 'Canada'),
(5, 'Ethan', 'USA');

-- Insert data into Products table
INSERT INTO Products (ProductID, ProductName, Category, Price) VALUES
(1, 'Wireless Mouse', 'Electronics', 25.00),
(2, 'Coffee Mug', 'Kitchen', 12.00),
(3, 'Notebook', 'Stationery', 5.00),
(4, 'Bluetooth Speaker', 'Electronics', 45.00),
(5, 'Water Bottle', 'Sports', 10.00);

-- Insert data into Orders table
INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount) VALUES
(101, 1, '2024-07-01', 70.00),
(102, 2, '2024-07-03', 25.00),
(103, 3, '2024-07-05', 50.00),
(104, 4, '2024-07-08', 12.00),
(105, 5, '2024-07-09', 45.00);

-- Insert data into OrderDetails table
INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductID, Quantity) VALUES
(1, 101, 1, 2),
(2, 101, 4, 1),
(3, 102, 2, 2),
(4, 103, 3, 10),
(5, 105, 4, 1);

Select * from Customers 
Select * from Products 
Select *from Orders 
Select * from OrderDetails 

--1) List all products and their categories.

Select
	ProductID,ProductName,Category
from Products;

--2) Show the total quantity sold per product.

Select
	p.ProductID,p.ProductName, Coalesce (SUM(od.Quantity),0) as [Total Quantity Sold]
from
	Products p
left join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	p.ProductID,p.ProductName
Order by
	[Total Quantity Sold] Desc;

--3) Display total revenue earned from each product (price × quantity).

Select
	p.ProductID,p.ProductName, Coalesce(sum(p.Price*od.Quantity),0) as [Total Revenue]
from
	Products p
left join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	p.ProductID,p.ProductName
Order by
	[Total Revenue] Desc;

--4) List the top 3 best-selling products by quantity.

SELECT TOP 3
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

--5) Show customer names and the total amount they have spent.

Select
	c.Name,SUm (o.TotalAmount) as [Total Spent]
from
	Customers c
join
	Orders o
on c.CustomerID =o.CustomerID
Group by
	c.Name
Order by
	[Total Spent] desc;
	
-- 6) Identify the most popular product category by number of units sold.

Select top 1
	p.Category, Sum (od.Quantity) as [Units Sold]
from
	Products p
join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	p.Category
Order by
	[Units Sold] Desc;

--7) Show the total number of orders placed by customers from the USA.

SELECT 
    COUNT(o.OrderID) AS [Total USA Orders]
FROM 
    Customers c
JOIN 
    Orders o ON c.CustomerID = o.CustomerID
WHERE 
    c.Country = 'USA';

--8) Display the average order value per country.

Select
	c.Country, Round(AVG(o.TotalAmount),2) as [AVG Order Value]
from
	Customers c
join
	Orders o
on c.CustomerID =o.CustomerID 
Group by
	c.Country
Order by
	[AVG Order Value] Desc;

--9) List products that have never been ordered.

Select
	p.ProductID,p.ProductName
from
	Products p
left join
	OrderDetails od
on p.ProductID =od.ProductID  
where
	od.OrderID is null;

--10) For each category, show the highest-selling product by revenue.

With ProductRevenue as(
			Select
				p.ProductID,p.ProductName,p.Category,
				SUM (p.Price*od.Quantity) as [Revenue],
				Rank() over (Partition by p.Category Order by SUM (p.Price*od.Quantity)Desc) As RevenueRank
From
	products P
left join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	p.ProductID,p.ProductName,p.Category)
Select 
	ProductID,ProductName,Category,Revenue
From
	ProductRevenue 
where
	RevenueRank =1
Order by
	Revenue desc;

--Bonus Challenge
--Find the product with the highest average units sold per order.

With ProductOrderAverage As(
				Select
					p.ProductID,p.ProductName,
					AVG (od.Quantity*1.0) as AvgUnitsPerOrder,
					Count (od.OrderID) as OrderCount
from
	Products p
join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	p.ProductID,p.ProductName)
Select Top 1
	ProductID,ProductName,AvgUnitsPerOrder,OrderCount
from
	ProductOrderAverage 
Order by
	AvgUnitsPerOrder Desc;