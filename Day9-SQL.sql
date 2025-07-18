Create table Products (
						ProductID int primary key,
						ProductName varchar (50) not null unique CHECK (LEN(ProductName) > 0),
						CategoryID int not null,
						Price decimal (12,2) not null check (Price>0),
						foreign key (CategoryID) references Categories (CategoryID)
						);

Create table Categories (
						CategoryID int primary key,
						CategoryName varchar (50) not null unique,
						);

Create table Inventory (
						InventoryID int primary key,
						ProductID int not null,
						QuantityInStock bigint not null check (QuantityInStock>=0) default 0,
						foreign key (ProductID) references Products(ProductID)
						);

Create index idx_products_category on Products(CategoryID);
Create index idx_inventory_products on Inventory (ProductID);

Insert into Products (ProductID, ProductName, CategoryID, Price)
Values
	(1,'Laptop',10,800),
	(2,'Mouse',11,25),
	(3,'Keyboard',11,40),
	(4,'Monitor',10,200),
	(5,'Printer',12,150);

Insert into Categories (CategoryID,CategoryName)
Values
	(10,'Electronics'),
	(11,'Accessories'),
	(12,'Peripherals');

Insert into Inventory (InventoryID,ProductID,QuantityInStock)
Values
	(501,1,20),
	(502,2,200),
	(503,3,150),
	(504,4,35);

Select *from Products 
Select * from Categories 
Select * from Inventory 

-- 1) List all products with their category names.

Select
	p.ProductID,p.ProductName, c.CategoryName
from
	Products p
join
	Categories c
on p.CategoryID =c.CategoryID;

-- 2) Show total stock value (Price × QuantityInStock) for each product.

SELECT 
    p.ProductID,  p.ProductName, Sum (p.Price * i.QuantityInStock) AS StockValueUSD
FROM
    Products p
JOIN
    Inventory i ON p.ProductID = i.ProductID
Group by
	p.ProductID,  p.ProductName
ORDER BY 
    StockValueUSD DESC;

-- 3) Display total quantity in stock per category.

SELECT
    c.CategoryID, c.CategoryName,
    COALESCE(SUM(i.QuantityInStock), 0) AS [Total Quantity]
FROM
    Categories c
LEFT JOIN
    Products p ON c.CategoryID = p.CategoryID
LEFT JOIN
    Inventory i ON p.ProductID = i.ProductID
GROUP BY
    c.CategoryID, c.CategoryName
ORDER BY
    [Total Quantity] DESC;

-- 4) Find categories that don’t have any products.

SELECT 
    c.CategoryID, c.CategoryName
FROM 
    Categories c
LEFT JOIN 
    Products p ON c.CategoryID = p.CategoryID
WHERE 
    p.ProductID IS NULL;

-- 5) Show products with no inventory records.

Select
	p.ProductID,p.ProductName
from
	Products p
left join
	Inventory i
on p.ProductID =i.ProductID 
Where
	i.InventoryID is null;

-- Alternative Using NOT EXISTS
SELECT
    p.ProductID,p.ProductName
FROM
    Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM Inventory i
    WHERE i.ProductID = p.ProductID );

--  6) Display the most expensive product in each category.

WITH RankedProducts AS (
    SELECT 
        p.ProductID,p.ProductName,p.Price,c.CategoryID,c.CategoryName,
        RANK() OVER (PARTITION BY c.CategoryID ORDER BY p.Price DESC) AS PriceRank
    FROM
        Products p
    JOIN
        Categories c ON p.CategoryID = c.CategoryID
)
SELECT 
    ProductID,ProductName,CategoryID,CategoryName,Price AS [Most Expensive Price]
FROM 
    RankedProducts
WHERE 
    PriceRank = 1;

-- 7) Identify products whose stock value is below $1000.

SELECT 
    p.ProductID,  p.ProductName, SUM(p.Price * i.QuantityInStock) AS StockValueUSD
FROM
    Products p
JOIN
    Inventory i ON p.ProductID = i.ProductID
GROUP BY
    p.ProductID, p.ProductName
HAVING
    SUM(p.Price * i.QuantityInStock) < 1000
ORDER BY 
    StockValueUSD ASC;

-- 8) Show the average product price for each category.

Select
	c.CategoryID,c.CategoryName, AVG (p.Price) as [Average Product Price]
from
	Products p
left join
	Categories c
on p.CategoryID =c.CategoryID 
Group by
	c.CategoryID,c.CategoryName
Order by 
	[Average Product Price] Desc;

-- 9) Rank products by their stock value (high to low).

Select
	p.ProductID,p.ProductName,p.Price,i.QuantityInStock,
	(p.Price*i.QuantityInStock) as [Stock Value],
	Rank() over (order by (p.Price * i.QuantityInStock) DESC) AS StockValueRank
from
	Products p
join
	Inventory i
on p.ProductID  =i.ProductID 
order by
	[Stock Value] Desc;

-- 10) Find the product with the lowest stock across all inventory.

SELECT TOP 1
    p.ProductID, p.ProductName, i.QuantityInStock AS [Lowest Stock]
FROM
    Products p
JOIN
    Inventory i ON p.ProductID = i.ProductID
ORDER BY
    i.QuantityInStock ASC;

--Bonus Challenge
--Write a query to list the top 2 products (by stock value) in each category.

WITH ProductStockValues AS (
    SELECT
        p.ProductID, p.ProductName,  
        c.CategoryID, c.CategoryName, p.Price,
		i.QuantityInStock,
        (p.Price * i.QuantityInStock) AS StockValue,
        DENSE_RANK() OVER (
            PARTITION BY c.CategoryID 
            ORDER BY (p.Price * i.QuantityInStock) DESC
        ) AS StockRank
    FROM
        Products p
    JOIN
        Categories c ON p.CategoryID = c.CategoryID
    JOIN
        Inventory i ON p.ProductID = i.ProductID
)
SELECT
    ProductID,ProductName,CategoryID,CategoryName,Price,QuantityInStock,StockValue
FROM
    ProductStockValues
WHERE
    StockRank <= 2
ORDER BY
    CategoryName,
    StockValue DESC;