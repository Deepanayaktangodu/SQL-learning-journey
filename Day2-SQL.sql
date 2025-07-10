Create table Products(
						ProductID int Primary Key,
						ProductName varchar (100) Not null,
						Category varchar (50),
						Price bigint CHECK (Price>=0)
						); 

Create table Orders(
					OrderID int Primary Key,
					ProductID int,
					Quantity bigint Not null CHECK (Quantity>0) ,
					OrderDate Date Not null,
					CustomerName char (100) Not null,
					Foreign key (ProductID) references Products(ProductID)
					);

Insert into Products (ProductID,ProductName,Category,Price)
Values
		(1,'Laptop','Electronics',80000),
		(2,'Mobile Phone','Electronics',30000),
		(3,'Office Chair','Furniture',12000),
		(4,'Pen Pack','Stationery',300),
		(5,'Desk Lamp','Furniture',1500);

Insert into Orders (OrderID,ProductID,Quantity,OrderDate,CustomerName)
Values
		(101,1,2,'2022-03-10','Priya Sharma'),
		(102,2,1,'2022-04-12','Rahul Jain'),
		(103,3,3,'2022-05-15','Aarti Desai'),
		(104,2,2,'2022-06-18','Ravi Kumar'),
		(105,5,4,'2022-07-20','Sneha Agarwal');

Select * from Products
Select * from Orders 

-- 1) List all product names and their categories.

Select 
	ProductName, Category
From
	Products;

-- 2) Find the total quantity ordered for each product.

SELECT 
	p.ProductName, SUM(o.Quantity) AS TotalQuantity
FROM 
	Products p
LEFT JOIN 
	Orders o 
ON 
	p.ProductID = o.ProductID
GROUP BY 
	p.ProductName;

-- 3) Display all orders along with product names and category.

Select
	p.ProductName, p. Category, o.OrderID, o.Quantity,o.OrderDate,o.CustomerName
From
	Products p
join
	Orders o
on
p.ProductID =o.ProductID 
Order by
	o.OrderDate;

--4) Calculate the total order value for each customer (Quantity × Price).

Select
	o.CustomerName, sum (p.Price*o.Quantity) as [Total Order Value]
From
	Orders o
Join
	Products p
on
o.ProductID=p.ProductID
Group by
		o.CustomerName ;

-- 5) Which customers have placed orders for Electronics products?

Select
	o.CustomerName, p.Category 
from
	Orders o
join
	Products p
on
o.ProductID= p.ProductID 
where
	p.Category='Electronics' ;

-- Alternative method

SELECT
	DISTINCT 
			o.CustomerName
FROM
	Orders o
JOIN 
Products p ON o.ProductID = p.ProductID
WHERE
	p.Category = 'Electronics';

-- 6) Find the most expensive product and who bought it.

Select
		o.CustomerName,p.ProductName,  p.Price as [Product Price]
From
	Products p
Join 
	Orders o
on
p.ProductID =o.ProductID
where
	p.Price = (SELECT MAX(Price) FROM Products);

-- 7) List the product(s) that have never been ordered. (Hint: LEFT JOIN + NULL)

SELECT 
	p.ProductName,p.ProductID 
FROM 
	Products p
LEFT JOIN 
	Orders o 
ON 
	p.ProductID = o.ProductID
WHERE
	o.OrderID IS NULL;

-- 8) Show the average order quantity per product category.

Select
	 p.Category, AVG (Quantity) as [AVG Order Qty]
from
	Products p
Join
	Orders o
on
p.ProductID= o.ProductID 
Group by
	p.Category ;


-- 9) Find all customers who ordered more than 2 units of any product.

Select
	o.CustomerName, o.Quantity, p.ProductName
from
	Orders o
join 
	Products p 
on
o.ProductID = p.ProductID 
where
	o.Quantity >2
Order by
	o.Quantity Desc;

-- Alternative method 

SELECT 
	DISTINCT 
			CustomerName
FROM 
	Orders
WHERE 
	Quantity > 2;

-- Bonus Challenge:
--Write a query to list customers who ordered products priced above the average price of all products.

SELECT
	DISTINCT
		o.CustomerName, p.ProductName 
FROM 
	Orders o
JOIN 
	Products p 
ON 
o.ProductID = p.ProductID
WHERE 
	p.Price > (SELECT AVG(Price) FROM Products);