Create table Customers (
						CustomerID int Primary Key,
						Name varchar(100) not null Check(len(Name)>=2),
						Country varchar(50) not null,
						JoinDate date not null default getdate() Check(JoinDate<=getdate())
						);

Create table Products (
						ProductID int Primary key,
						ProductName varchar(75) unique not null Check(len(ProductName)>=2),
						Category varchar(50) not null Check(Category in ('Electronics','Furniture')),
						Price decimal (10,2) not null Check(Price>0)
						);

Create table Orders (
						OrderID int Primary Key,
						CustomerID int not null,
						OrderDate date not null default getdate() Check (OrderDate<=getdate()),
						Status varchar(100) not null Check(Status in ('Completed','Cancelled')),
						foreign key (CustomerID) references Customers(CustomerID) on update cascade on delete no action
					);

Create table OrderDetails (
							OrderDetailID int Primary Key,
							OrderID int not null ,
							ProductID int not null,
							Quantity int not null Check(Quantity>0),
							foreign key (OrderID) references Orders(OrderID) on update cascade on delete no action,
							foreign key (ProductID) references Products(ProductID) on update cascade on delete no action
							);

Create table Employees (
						EmployeeID int Primary key,
						Name varchar(100) not null Check(len(Name)>=2),
						ManagerID int null,
						FOREIGN KEY (ManagerID) REFERENCES Employees(EmployeeID)
						);

Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);
Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Products_ProductName on Products(ProductName);
Create Index Idx_Employees_Name on Employees(Name);
Create Index Idx_Orders_Status ON Orders(Status);

INSERT INTO Customers VALUES
(1, 'Alice', 'USA', '2020-01-15'),
(2, 'Bob', 'Canada', '2019-07-23'),
(3, 'Charlie', 'USA', '2021-03-12'),
(4, 'Diana', 'UK', '2020-11-05');

INSERT INTO Products VALUES
(101, 'Laptop', 'Electronics', 1200.00),
(102, 'Headphones', 'Electronics', 150.00),
(103, 'Office Chair', 'Furniture', 300.00),
(104, 'Desk', 'Furniture', 450.00);

INSERT INTO Orders VALUES
(1001, 1, '2021-01-10', 'Completed'),
(1002, 2, '2021-02-15', 'Completed'),
(1003, 1, '2021-03-05', 'Cancelled'),
(1004, 3, '2021-04-12', 'Completed'),
(1005, 4, '2021-05-20', 'Completed');

INSERT INTO OrderDetails VALUES
(1, 1001, 101, 1),
(2, 1001, 102, 2),
(3, 1002, 103, 1),
(4, 1004, 104, 1),
(5, 1005, 101, 1);

INSERT INTO Employees VALUES
(1, 'Emma', NULL),
(2, 'John', 1),
(3, 'Sophia', 1),
(4, 'Liam', 2),
(5, 'Olivia', 2);

Select * from Customers 
Select * from  Products 
Select * from Orders 
Select * from OrderDetails 
Select * from Employees 

--1) List customers with their total revenue from completed orders.
SELECT
    c.CustomerID,c.Name AS 'Customer Name', c.Country,
    COALESCE(SUM(p.Price * od.Quantity), 0) AS [Total Revenue]
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID AND o.Status = 'Completed'
LEFT JOIN OrderDetails od ON od.OrderID = o.OrderID 
LEFT JOIN Products p ON p.ProductID = od.ProductID 
GROUP BY c.CustomerID, c.Name, c.Country 
ORDER BY [Total Revenue] DESC;

--2) Find the top 2 products by revenue in each category.
With ProductRevenue as (
				Select
					p.ProductID,p.ProductName,p.Category,
					SUM(p.Price*od.Quantity) as [Total Revenue],
					Rank() over (Partition by p.Category Order by SUM(p.Price*od.Quantity) Desc) as RevenueRank
				from Products p
				join OrderDetails od on p.ProductID =od.ProductID 
				join Orders o on o.OrderID =od.OrderID and o.Status ='Completed'
				Group by p.ProductID,p.ProductName,p.Category)
Select
	ProductID,ProductName,Category,[Total Revenue]
from ProductRevenue 
where RevenueRank <=2
Order by Category, [Total Revenue] DESC;

--3) Show customers who bought both Electronics and Furniture.
SELECT
    c.CustomerID,c.Name AS 'Customer Name',c.Country
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.CustomerID = c.CustomerID
    AND o.Status = 'Completed'
    AND p.Category = 'Electronics')
AND EXISTS (
    SELECT 1 
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.CustomerID = c.CustomerID
    AND o.Status = 'Completed'
    AND p.Category = 'Furniture')
ORDER BY c.Name;

--4) Using LAG, find the days between consecutive orders for each customer.
WITH OrderedOrders AS (
    SELECT
        CustomerID,OrderID,OrderDate,
        LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PreviousOrderDate
    FROM Orders
    WHERE Status = 'Completed'  -- Only consider completed orders
)
SELECT
    c.CustomerID,c.Name AS 'Customer Name',
    o.OrderID,o.OrderDate,o.PreviousOrderDate,
    DATEDIFF(day, o.PreviousOrderDate, o.OrderDate) AS DaysBetweenOrders
FROM OrderedOrders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.PreviousOrderDate IS NOT NULL  -- Exclude first orders (no previous order)
ORDER BY c.CustomerID, o.OrderDate;
	
--5) Write a query to pivot order counts per status (Completed, Cancelled) by Customer.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	Coalesce(SUM(case when o.Status='Completed' then 1 else 0 END),0) as 'Completed Orders',
	Coalesce(SUM(case when o.Status='Cancelled' then 1 else 0 END),0) as 'Cancelled Orders',
	Coalesce(Count(o.OrderID),0) as 'Total Orders'
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Name, c.Country
ORDER BY c.CustomerID;

--6) Using a recursive CTE, display the employee hierarchy under Manager Emma.
WITH EmployeeHierarchy AS (
    SELECT 
        EmployeeID,Name,ManagerID,
        0 AS Level,
        CAST(Name AS VARCHAR(255)) AS HierarchyPath
    FROM Employees
    WHERE Name = 'Emma'  
UNION ALL
SELECT 
        e.EmployeeID,e.Name,e.ManagerID,
        eh.Level + 1,
        CAST(eh.HierarchyPath + ' > ' + e.Name AS VARCHAR(255))
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID)
SELECT 
    EmployeeID,Name,ManagerID,
    Level AS 'Hierarchy Level',
    HierarchyPath AS 'Reporting Chain'
FROM EmployeeHierarchy
ORDER BY Level, Name;

--7) Find the product contributing the highest percentage of revenue in each category.
WITH CategoryRevenue AS (
    SELECT
        p.Category,
        SUM(p.Price * od.Quantity) AS TotalCategoryRevenue
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    WHERE o.Status = 'Completed'
    GROUP BY p.Category),
ProductRevenue AS (
    SELECT
        p.ProductID,p.ProductName,p.Category,
        SUM(p.Price * od.Quantity) AS TotalProductRevenue,
        cr.TotalCategoryRevenue
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN CategoryRevenue cr ON p.Category = cr.Category
    WHERE o.Status = 'Completed'
    GROUP BY p.ProductID, p.ProductName, p.Category, cr.TotalCategoryRevenue),
RankedProducts AS (
    SELECT
        ProductID,ProductName,Category,TotalProductRevenue,
        (TotalProductRevenue * 100.0 / NULLIF(TotalCategoryRevenue, 0)) AS RevenuePercentage,
        RANK() OVER (PARTITION BY Category ORDER BY TotalProductRevenue DESC) AS RankInCategory
    FROM ProductRevenue)
SELECT
    ProductID,ProductName,Category,
    TotalProductRevenue AS 'Revenue',
    ROUND(RevenuePercentage, 2) AS 'Percentage of Category Revenue'
FROM RankedProducts
WHERE RankInCategory = 1
ORDER BY Category;

--8) Identify customers who made no purchases in 2021.
SELECT
    c.CustomerID,c.Name AS 'Customer Name'
FROM Customers c
WHERE c.CustomerID NOT IN (
    SELECT DISTINCT o.CustomerID
    FROM Orders o
    WHERE YEAR(o.OrderDate) = 2021)
ORDER BY c.CustomerID;

--9) For each customer, calculate their first purchase date and most recent purchase date.
SELECT
    c.CustomerID,c.Name AS 'CustomerName',c.Country,
    MIN(o.OrderDate) AS 'First Purchase Date',
    MAX(o.OrderDate) AS 'Most Recent Purchase Date',
    DATEDIFF(day, MIN(o.OrderDate), MAX(o.OrderDate)) AS 'Days as Customer',
    COUNT(o.OrderID) AS 'Total Orders'
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    AND o.Status = 'Completed'
GROUP BY c.CustomerID, c.Name, c.Country
ORDER BY c.CustomerID;

--10) Find customers who generated above-average revenue compared to all customers.
WITH CustomerRevenue AS (
    SELECT
        c.CustomerID,c.Name AS 'CustomerName',c.Country,
        COALESCE(SUM(p.Price * od.Quantity), 0) AS TotalRevenue
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID AND o.Status = 'Completed'
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.Name, c.Country),
AverageRevenue AS (
    SELECT AVG(TotalRevenue) AS AvgRevenue
    FROM CustomerRevenue)
SELECT
    cr.CustomerID,cr.CustomerName, cr.Country,
    cr.TotalRevenue,
    ar.AvgRevenue AS 'AverageRevenueAcrossAllCustomers',
    (cr.TotalRevenue - ar.AvgRevenue) AS 'RevenueAboveAverage'
FROM CustomerRevenue cr
CROSS JOIN AverageRevenue ar
WHERE cr.TotalRevenue > ar.AvgRevenue
ORDER BY cr.TotalRevenue DESC;

--Bonus Challenge
--Using DENSE_RANK, find the top 3 employees by number of subordinates in the hierarchy.
WITH EmployeeHierarchy AS (
    -- Recursive CTE to find all subordinates for each manager
    SELECT
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        0 AS HierarchyLevel
    FROM Employees e
    
    UNION ALL
    
    SELECT
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        eh.HierarchyLevel + 1
    FROM Employees e
    JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
),
SubordinateCounts AS (
    -- Count subordinates for each employee
    SELECT
        e.EmployeeID,
        e.Name,
        COUNT(eh.EmployeeID) AS NumberOfSubordinates
    FROM Employees e
    LEFT JOIN EmployeeHierarchy eh ON e.EmployeeID = eh.ManagerID
    GROUP BY e.EmployeeID, e.Name
),
RankedEmployees AS (
    -- Rank employees by number of subordinates
    SELECT
        EmployeeID,
        Name,
        NumberOfSubordinates,
        DENSE_RANK() OVER (ORDER BY NumberOfSubordinates DESC) AS RankBySubordinates
    FROM SubordinateCounts
)
-- Get top 3 employees
SELECT
    EmployeeID,
    Name,
    NumberOfSubordinates
FROM RankedEmployees
WHERE RankBySubordinates <= 3
ORDER BY RankBySubordinates, Name;