Create table Customers (
						CustomerID	Int Primary key,
						CustomerName varchar(100) not null Check(len(CustomerName)>3),
						City varchar(100) not null,
						JoinDate date not null default getdate() Check (JoinDate<=getdate())
						);

Create table Products (
						ProductID int Primary key,
						ProductName varchar(100) unique not null,
						Category varchar(75) not null Check (Category in ('Electronics','Home Appliances')),
						Price decimal (10,2) not null check (Price>0)
						);

Create table Orders (
						OrderID int Primary Key,
						CustomerID int not null,
						OrderDate date not null default getdate(),
						TotalAmount decimal (10,2) not null Check(TotalAmount>0),
						Status varchar(50) not null Check (Status in ('Delivered','Cancelled')),
						foreign key(CustomerID) references Customers(CustomerID) on update cascade on delete no action
					);

Create table OrderDetails(
							OrderDetailID int Primary key,
							OrderID int not null,
							ProductID int not null,
							Quantity int not null Check(Quantity>=0),
							foreign key(OrderID) references Orders(OrderID) on update cascade on delete cascade,
							foreign key(ProductID) references Products(ProductID) on update cascade on delete no action,
							Unique (OrderID,ProductID)
						);

Create table Inventory (
						ProductID int Primary Key,
						Stock int not null Check(Stock>=0),
						ReOrderLevel int not null Check (ReOrderLevel>0),
						FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE NO ACTION
						);


Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);
Create Index Idx_Inventory_ProductID on Inventory(ProductID);
Create Index Idx_Customers_CustomerID on Customers(CustomerID);
Create Index Idx_Customers_CustomerName on Customers(CustomerName);
Create Index Idx_Products_ProductID on Products(ProductID);
Create Index Idx_Products_ProductName on Products(ProductName);

INSERT INTO Customers VALUES
(1, 'Amit Sharma', 'Delhi', '2021-01-15'),
(2, 'Priya Kapoor', 'Mumbai', '2021-03-10'),
(3, 'Rahul Mehta', 'Bangalore', '2022-02-25'),
(4, 'Sara Khan', 'Delhi', '2022-07-05');

INSERT INTO Products VALUES
(101, 'Laptop', 'Electronics', 60000),
(102, 'Smartphone', 'Electronics', 30000),
(103, 'Washing Machine', 'Home Appliances', 25000),
(104, 'Microwave Oven', 'Home Appliances', 12000),
(105, 'Headphones', 'Electronics', 3000);

INSERT INTO Orders VALUES
(1001, 1, '2023-01-15', 90000, 'Delivered'),
(1002, 2, '2023-01-20', 30000, 'Cancelled'),
(1003, 3, '2023-02-05', 25000, 'Delivered'),
(1004, 4, '2023-02-15', 12000, 'Delivered'),
(1005, 1, '2023-03-10', 6000, 'Delivered');

INSERT INTO OrderDetails VALUES
(1, 1001, 101, 1),
(2, 1001, 102, 1),
(3, 1002, 102, 1),
(4, 1003, 103, 1),
(5, 1004, 104, 1),
(6, 1005, 105, 2);

INSERT INTO Inventory VALUES
(101, 5, 2),
(102, 10, 5),
(103, 2, 1),
(104, 3, 1),
(105, 15, 5);

Select * from Customers 
Select*from Products 
Select * from Orders 
Select * from OrderDetails 
Select * from Inventory 

--1) Calculate total delivered revenue per city.
SELECT
    c.City,
    SUM(p.Price * od.Quantity) AS [Delivered Revenue]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID 
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON p.ProductID = od.ProductID 
WHERE o.Status = 'Delivered'
GROUP BY c.City
ORDER BY [Delivered Revenue] DESC;

--2) Find the top 2 customers by total delivered spending.
Select Top 2
	c.CustomerID,c.CustomerName,
	SUM(o.TotalAmount) as [Total Delivered Spending]
from Customers c
join Orders o
on c.CustomerID =o.CustomerID 
where o.Status ='Delivered'
Group by c.CustomerID,c.CustomerName
Order by [Total Delivered Spending] Desc;

--3) List products that have never been ordered.
Select
	p.ProductID,p.ProductName
from Products p
left join OrderDetails od
on p.ProductID =od.ProductID 
where od.OrderID is null;

--Alternative
SELECT
    p.ProductID,p.ProductName
FROM Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID);

--4) Show each product's total quantity sold in 2023.
SELECT
    p.ProductID,p.ProductName,
    SUM(od.Quantity) AS [Total Quantity Sold]
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID 
JOIN Orders o ON o.OrderID = od.OrderID 
WHERE o.Status = 'Delivered' 
  AND o.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p.ProductID, p.ProductName
ORDER BY [Total Quantity Sold] DESC;

--5) Identify months where revenue exceeded the previous month’s revenue (use window functions).
With MonthlyRevenue as (
				Select
					FORMAT(o.OrderDate, 'yyyy-MM') as Month,
					SUM(p.Price*od.Quantity) as Revenue
				from Orders o
				join OrderDetails od on o.OrderID =od.OrderID 
				join Products p on p.ProductID =od.ProductID 
				Group by FORMAT(o.OrderDate, 'yyyy-MM')),
RevenueWithPrevious AS (
    SELECT 
        Month,Revenue,
        LAG(Revenue) OVER (ORDER BY Month) AS PreviousMonthRevenue
    FROM MonthlyRevenue)
SELECT 
    Month,Revenue,PreviousMonthRevenue
FROM RevenueWithPrevious
WHERE Revenue > PreviousMonthRevenue
ORDER BY Month;

--6) List categories where all products have stock above their reorder level.
SELECT 
    p.Category
FROM Products p
JOIN Inventory i ON p.ProductID = i.ProductID
GROUP BY p.Category
HAVING MIN(i.Stock - i.ReOrderLevel) > 0;

--7) Retrieve each customer's first and last purchase date.
Select
	c.CustomerID,c.CustomerName,c.City,
	MIN(o.OrderDate) as [First Purchase Date],
	MAX(o.OrderDate) as [Last Purchase Date]
from Customers c
left join Orders o
on c.CustomerID =o.CustomerID
Group by c.CustomerID,c.CustomerName,c.City ;

--8)Find products contributing more than 30% of revenue in their category.
WITH ProductCategoryStats AS (
    SELECT 
        p.ProductID,p.ProductName,p.Category,
        SUM(p.Price * od.Quantity) AS ProductRevenue,
        SUM(SUM(p.Price * od.Quantity)) OVER (PARTITION BY p.Category) AS TotalCategoryRevenue
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    WHERE o.Status = 'Delivered'
    GROUP BY p.ProductID,p.ProductName,p.Category)
SELECT 
    ProductID,ProductName,Category,ProductRevenue,TotalCategoryRevenue,
    CAST((ProductRevenue * 100.0 / TotalCategoryRevenue) AS DECIMAL(5,2)) AS RevenuePercentage
FROM ProductCategoryStats
WHERE (ProductRevenue * 100.0 / TotalCategoryRevenue) > 30
ORDER BY Category, RevenuePercentage DESC;

--9) Calculate running total revenue by month.
WITH MonthlyData AS (
    SELECT 
        YEAR(o.OrderDate) AS OrderYear,
        MONTH(o.OrderDate) AS OrderMonth,
        SUM(p.Price * od.Quantity) AS MonthlyRevenue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.Status = 'Delivered'
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate))
SELECT
    CAST(OrderYear AS VARCHAR) + '-' + RIGHT('0' + CAST(OrderMonth AS VARCHAR(2)), 2) AS Month,
    MonthlyRevenue,
    SUM(MonthlyRevenue) OVER (ORDER BY OrderYear, OrderMonth) AS RunningTotalRevenue
FROM MonthlyData
ORDER BY OrderYear, OrderMonth;

--10)  Identify customers who have ordered from more than 1 product category.SELECT
 Select
	c.CustomerID,c.CustomerName,
    COUNT(DISTINCT p.Category) AS CategoriesOrderedFrom
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.Status = 'Delivered'
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(DISTINCT p.Category) > 1
ORDER BY CategoriesOrderedFrom DESC, c.CustomerName;

--Bonus Challenge: 
--Determine each city’s contribution percentage to total company revenue.
With CityRevenue as (
			Select
				c.City,
				SUM(p.Price*od.Quantity) as CityTotalRevenue
			from Customers c
			join Orders o on c.CustomerID =o.CustomerID 
			join OrderDetails od on od.OrderID =o.OrderID 
			join Products p on p.ProductID =od.ProductID 
			where o.Status ='Delivered'
			Group by c.City),
TotalRevenue AS (
    SELECT SUM(CityTotalRevenue) AS CompanyTotalRevenue
    FROM CityRevenue)
SELECT
    cr.City,cr.CityTotalRevenue,tr.CompanyTotalRevenue,
    ROUND((cr.CityTotalRevenue * 100.0 / tr.CompanyTotalRevenue), 2) AS RevenuePercentage
FROM CityRevenue cr
CROSS JOIN TotalRevenue tr
ORDER BY RevenuePercentage DESC;


	
					
