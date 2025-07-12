Create table Products(
						ProductsID int Primary key ,
						ProductName varchar (100) Not null,
						SupplierID bigint,
						Category varchar (100),
						Price decimal (10,2) Check (Price>0),
						foreign key (SupplierID) references Suppliers(SupplierID)
					);

Create table Orders (
						OrderID int Primary key,
						ProductsID int,
						Quantity bigint not null check (Quantity>0),
						OrderDate Date not null,
						foreign key (ProductsID) references Products(ProductsID)
					);

Create table Suppliers(
						SupplierID bigint Primary key,
						SupplierName char (100) not null,
						City varchar (75)
						);

Insert into Products (ProductsID,ProductName,SupplierID,Category,Price)
Values
	(1,'NoteBook',101,'Stationery',150),
	(2,'Monitor',102,'Electronics',12000),
	(3,'KeyBoard',103,'Electronics',2500),
	(4,'Desk',104,'Furniture',6000),
	(5,'Chair',104,'Furniture',3500);

Insert into Orders (OrderID,ProductsID,Quantity,OrderDate)
Values
	(201,1,10,'2022-09-01'),
	(202,2,3,'2022-09-02'),
	(203,3,5,'2022-09-03'),
	(204,4,2,'2022-09-05'),
	(205,2,1,'2022-09-06'),
	(206,5,4,'2022-09-07');

Insert into Suppliers (SupplierID,SupplierName,City)
Values
		(101,'FineStationery Co.','Chennai'),
		(102,'ElectroMart','Delhi'),
		(103,'KeyBoard Bros','Mumbai'),
		(104,'FurniWorld','Bangalore');

Select * from Products 
Select * from Orders 
Select * from Suppliers 

-- 1) List all products along with their supplier name and city.

Select
	p.ProductName,s.SupplierName,s.City
from
	Products p
join
	Suppliers s
on
p.SupplierID = s.SupplierID;

-- 2) Show the total quantity ordered per product.

Select
	p.ProductName, Sum (o.Quantity) as [Total Quantity]
from
	Products p
Join
	Orders o
on
p.ProductsID=o.ProductsID 
Group by
	p.ProductName ;

-- 3) Find the total sales amount for each category. (Quantity × Price)

SELECT 
    p.Category,
    SUM(o.Quantity * p.Price) AS TotalSalesAmount
FROM 
    Products p
JOIN 
    Orders o ON p.ProductsID  = o.ProductsID 
GROUP BY 
    p.Category
ORDER BY 
    TotalSalesAmount DESC;

-- 4) Identify the supplier(s) who provide products that haven't been ordered.

SELECT DISTINCT
    s.SupplierID,s.SupplierName,s.City
FROM 
    Suppliers s
JOIN 
    Products p ON s.SupplierID = p.SupplierID
LEFT JOIN 
    Orders o ON p.ProductsID  = o.ProductsID
WHERE 
    o.OrderID IS NULL;

-- 5) Display the highest-priced product from each category.

-- Method 1: Using a subquery
SELECT 
	p.Category, p.ProductName, p.Price
FROM 
	Products p
JOIN (
    SELECT Category, MAX(Price) AS MaxPrice
    FROM Products
    GROUP BY Category
) max_prices ON p.Category = max_prices.Category AND p.Price = max_prices.MaxPrice;

-- Method 2: Using ROW_NUMBER() (more efficient for multiple products at same max price)
WITH RankedProducts AS (
    SELECT 
        Category,
        ProductName,
        Price,
        ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Price DESC) AS rank
    FROM Products
)
SELECT Category, ProductName, Price
FROM RankedProducts
WHERE rank = 1;

-- 6) List orders with total amount > 10,000. Show product and supplier info.

SELECT 
    o.OrderID,p.ProductName, p.Category,p.Price, o.Quantity,
	(o.Quantity * p.Price) AS OrderTotal,
    s.SupplierName,
    s.City
FROM 
    Orders o
JOIN 
    Products p ON o.ProductsID  = p.ProductsID
JOIN 
    Suppliers s ON p.SupplierID = s.SupplierID
WHERE 
    (o.Quantity * p.Price) > 10000
ORDER BY 
    OrderTotal DESC;

-- 7) Show the number of products supplied by each supplier.

Select
	s.Suppliername,s.Supplierid, COUNT (p.ProductsID) as [Number of Products]
from
	Products p
join
	Suppliers s
on
p.SupplierID=s.SupplierID 
group by
	s.SupplierName, s. SupplierID
Order by 
	[Number of Products] Desc;

-- 8) List all orders placed in September 2022 along with product category.

SELECT 
    o.OrderID,p.ProductName,p.Category,o.Quantity, o.OrderDate
FROM 
    Orders o
JOIN 
    Products p ON o.ProductsID = p.ProductsID
WHERE 
    o.OrderDate >= '2022-09-01' 
    AND o.OrderDate < '2022-10-01'
ORDER BY 
    o.OrderDate;

-- 9) Which city supplies the most ordered product overall?

SELECT TOP 1
    s.City,SUM(o.Quantity) AS TotalQuantityOrdered
FROM
    Suppliers s
JOIN
    Products p ON s.SupplierID = p.SupplierID
JOIN
    Orders o ON p.ProductsID = o.ProductsID
GROUP BY
    s.City
ORDER BY
    TotalQuantityOrdered DESC;

-- 10) List each supplier with the total value of products they’ve supplied (across all orders).

SELECT
    s.SupplierName,s.SupplierID, SUM(o.Quantity * p.Price) AS [Total Order Value]
FROM
    Suppliers s
JOIN
    Products p ON s.SupplierID = p.SupplierID
JOIN
    Orders o ON p.ProductsID = o.ProductsID
GROUP BY
    s.SupplierName, s.SupplierID
ORDER BY
    [Total Order Value] DESC;

--Bonus Challenge
-- Write a query to rank categories by total sales using RANK() or DENSE_RANK().

WITH CategorySales AS (
    SELECT
        p.Category,
        SUM(o.Quantity * p.Price) AS TotalSales,
        DENSE_RANK() OVER (ORDER BY SUM(o.Quantity * p.Price) DESC) AS SalesRank
    FROM
        Products p
    JOIN
        Orders o ON p.ProductsID = o.ProductsID
    GROUP BY
        p.Category
)
SELECT
    Category,TotalSales,SalesRank
FROM
    CategorySales
ORDER BY
    SalesRank;
	
