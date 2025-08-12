CREATE TABLE Categories (
							CategoryID INT PRIMARY KEY,
							CategoryName VARCHAR(50) NOT NULL UNIQUE
						);

CREATE TABLE Products (
						ProductID INT PRIMARY KEY,
						ProductName VARCHAR(100) not null,
						CategoryID INT NOT NULL,
						Price DECIMAL(10,2) NOT NULL CHECK (Price>0),
						FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) on update cascade
						);

Create Index Idx_Products_CategoryID on Products(CategoryID);

INSERT INTO Categories VALUES
(1, 'Electronics'), (2, 'Clothing'), (3, 'Home Appliances');

INSERT INTO Products VALUES
(101, 'Laptop', 1, 60000),
(102, 'Smartphone', 1, 25000),
(103, 'T-Shirt', 2, 1200),
(104, 'Microwave', 3, 8000),
(105, 'Jeans', 2, 2500);

CREATE TABLE Customers (
						CustomerID INT PRIMARY KEY,
						CustomerName VARCHAR(100) NOT NULL,
						City VARCHAR(50) NOT NULL,
						JoinDate DATE NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE())
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE NOT NULL,
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE 
					);

Create Index Idx_Orders_CustomerID on Orders(CustomerID);

INSERT INTO Customers VALUES
(1, 'Ravi', 'Delhi', '2021-01-15'),
(2, 'Simran', 'Mumbai', '2020-03-20'),
(3, 'John', 'Bangalore', '2022-06-10'),
(4, 'Asha', 'Pune', '2021-07-25');

INSERT INTO Orders VALUES
(1001, 1, '2023-01-15'),
(1002, 2, '2023-02-17'),
(1003, 1, '2023-03-20'),
(1004, 3, '2023-03-22'),
(1005, 4, '2023-04-10');

CREATE TABLE OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductID INT NOT NULL,
							Quantity INT CHECK (Quantity>=0),
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE
							);

Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);

INSERT INTO OrderDetails VALUES
(1, 1001, 101, 1),
(2, 1001, 103, 2),
(3, 1002, 102, 1),
(4, 1003, 105, 3),
(5, 1004, 104, 1),
(6, 1005, 103, 4);

Select * from Categories 
Select * from Products 
Select * from Customers 
Select * from Orders 
Select * from OrderDetails 

--1) Find the total sales amount for each category.
Select
	c.CategoryID,c.CategoryName,
	Coalesce(SUM (p.Price*od.Quantity),0) as [Total Sales]
from
	Categories c
left join
	Products p
on c.CategoryID =p.CategoryID 
left join
	OrderDetails od
on od.ProductID =p.ProductID 
Group by
	c.CategoryID,c.CategoryName
Order by
	[Total Sales] Desc;

--2) List customers who have placed more than 1 order.
Select
	c.CustomerID,c.CustomerName,
	Count(o.OrderID) as [Total Orders]
from
	Customers c
join
	Orders o
on c.CustomerID =o.CustomerID 
Group by
	c.CustomerID,c.CustomerName
Having
	Count(o.OrderID)>1
Order by
	[Total Orders] Desc;

--3) Find the top 2 highest-selling products by total quantity sold.
Select Top 2
	p.ProductID,p.ProductName,
	Sum(od.Quantity) as [Total Quantity Sold]
from
	Products p
join
	OrderDetails od
on p.ProductID =od.ProductID 
Group by
	p.ProductID,p.ProductName
Order by
	[Total Quantity Sold] Desc;


--4) Show the month-wise total sales for the year 2023.
SELECT 
    MONTH(o.OrderDate) AS [Month],
    DATENAME(MONTH, o.OrderDate) AS [MonthName],
    SUM(p.Price * od.Quantity) AS [TotalSales]
FROM 
    Orders o
JOIN 
    OrderDetails od ON o.OrderID = od.OrderID
JOIN 
    Products p ON od.ProductID = p.ProductID
WHERE 
    YEAR(o.OrderDate) = 2023
GROUP BY 
    MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate)
ORDER BY 
    [Month];

--5) Find customers who joined before 2022 and have never ordered Electronics products.
SELECT 
    c.CustomerID,c.CustomerName,c.JoinDate
FROM 
    Customers c
WHERE 
    YEAR(c.JoinDate) < 2022
    AND c.CustomerID NOT IN (
        SELECT DISTINCT o.CustomerID
        FROM Orders o
        JOIN OrderDetails od ON o.OrderID = od.OrderID
        JOIN Products p ON od.ProductID = p.ProductID
        JOIN Categories cat ON p.CategoryID  = cat.CategoryID
        WHERE cat.CategoryName = 'Electronics')
ORDER BY 
    c.JoinDate;

--6) Retrieve the category with the highest average order value.
WITH CategoryOrderTotals AS (
    SELECT
        c.CategoryID,c.CategoryName,o.OrderID,
        SUM(p.Price * od.Quantity) AS OrderTotal
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    GROUP BY c.CategoryID, c.CategoryName, o.OrderID
)
SELECT TOP 1
    CategoryID,CategoryName,
    ROUND(AVG(OrderTotal), 2) AS [AvgOrderValue]
FROM CategoryOrderTotals
GROUP BY CategoryID, CategoryName
ORDER BY [AvgOrderValue] DESC;

--7) Show customers along with their first order date and last order date.
SELECT 
    c.CustomerID,c.CustomerName,
    MIN(o.OrderDate) AS FirstOrderDate,
    MAX(o.OrderDate) AS LastOrderDate,
    COUNT(o.OrderID) AS TotalOrders
FROM 
    Customers c
LEFT JOIN 
    Orders o ON c.CustomerID = o.CustomerID
GROUP BY 
    c.CustomerID, c.CustomerName
ORDER BY 
    c.CustomerID;

--8) Calculate the running total of sales amount for each customer.
WITH CustomerSales AS (
    SELECT
        c.CustomerID,c.CustomerName,
        o.OrderDate,o.OrderID,
        SUM(p.Price * od.Quantity) AS OrderAmount
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.CustomerName, o.OrderDate, o.OrderID)
SELECT
    CustomerID,CustomerName,
    OrderDate,OrderID,OrderAmount,
    SUM(OrderAmount) OVER (
        PARTITION BY CustomerID
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM CustomerSales
ORDER BY CustomerID, OrderDate;

--9) Find products that were never ordered.
SELECT
    p.ProductID,p.ProductName
FROM
    Products p
WHERE
    NOT EXISTS (
        SELECT 1
        FROM OrderDetails od
        WHERE od.ProductID = p.ProductID
    );

--10) Show the best-selling product in each category (handle ties).
With CategoryProductsSale as (
					Select
						c.CategoryID,c.CategoryName,
						p.ProductID,p.ProductName,
						Sum(od.Quantity) as TotalQuantitySold,
						DENSE_RANK () over (
								Partition by c.CategoryID
								Order by Sum(od.Quantity) Desc) as SalesRank
						from
							Categories c
						join
							Products p
						on c.CategoryID =p.CategoryID 
						left join
							OrderDetails  od
						on od.ProductID =p.ProductID 
						Group by
								c.CategoryID,c.CategoryName,p.ProductID,p.ProductName)
Select
	CategoryID,CategoryName,ProductID,ProductName,TotalQuantitySold
from
	CategoryProductsSale 
where
	SalesRank =1
Order by
	CategoryID ;

-- Bonus Challenge
-- Find the percentage contribution of each category to total sales.
WITH CategorySales AS (
    SELECT
		c.CategoryID,c.CategoryName,
        SUM(p.Price * od.Quantity) AS CategoryTotal
    FROM
        Categories c
    JOIN
        Products p ON c.CategoryID = p.CategoryID 
    JOIN
        OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY
        c.CategoryID, c.CategoryName),
GrandTotal AS (
    SELECT SUM(CategoryTotal) AS TotalSales
    FROM CategorySales)
SELECT
    cs.CategoryID,cs.CategoryName,cs.CategoryTotal,
    ROUND((cs.CategoryTotal * 100.0 / gt.TotalSales), 2) AS PercentageContribution
FROM
    CategorySales cs
CROSS JOIN
    GrandTotal gt
ORDER BY
    PercentageContribution DESC;
					
							
	



						


