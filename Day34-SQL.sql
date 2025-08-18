Create table Customers (
						CustomerID int Primary key,
						Name varchar (100) not null Check(Len(Name)>=2),
						JoinDate date not null default getdate() Check (JoinDate<=getdate()),
						Country varchar(50) not null 
						);

Create table Products (
						ProductID int Primary key,
						ProductName varchar(75) not null Check(Len(ProductName)>=2),
						Category varchar(75) not null Check (Category in ('Electronics','Furniture','Appliances')),
						Price decimal (10,2) not null check (Price>0)
						);

Create table Sales (
					SaleID int Primary key,
					CustomerID int not null,
					ProductID int not null,
					SaleDate date not null default getdate(),
					Quantity int not null Check (Quantity>0),
					foreign key(CustomerID) references Customers(CustomerID) on update cascade on delete no action,
					foreign key(ProductID) references Products(ProductID) on update cascade on delete no action
					);

Create Index Idx_Sales_CustomerID on Sales(CustomerID);
Create Index Idx_Sales_ProductID on Sales(ProductID);
Create Index Idx_Customers_Name on Customers(Name);
Create index Idx_Products_ProductName on Products(ProductName);
CREATE INDEX Idx_Sales_DateCustomer ON Sales(SaleDate,CustomerID);

INSERT INTO Customers VALUES
(1, 'Alice', '2020-01-15', 'USA'),
(2, 'Bob', '2019-07-23', 'Canada'),
(3, 'Charlie', '2021-03-12', 'USA'),
(4, 'Diana', '2020-11-05', 'UK'),
(5, 'Ethan', '2019-09-20', 'USA');

INSERT INTO Products VALUES
(101, 'Laptop', 'Electronics', 1200.00),
(102, 'Headphones', 'Electronics', 150.00),
(103, 'Office Chair', 'Furniture', 300.00),
(104, 'Desk', 'Furniture', 450.00),
(105, 'Coffee Machine', 'Appliances', 200.00);

INSERT INTO Sales VALUES
(1001, 1, 101, '2021-01-10', 1),
(1002, 2, 103, '2021-02-15', 2),
(1003, 1, 102, '2021-03-05', 1),
(1004, 3, 105, '2021-04-12', 1),
(1005, 4, 104, '2021-05-20', 1),
(1006, 5, 101, '2021-06-25', 1),
(1007, 1, 105, '2021-07-14', 1),
(1008, 2, 102, '2021-08-19', 2),
(1009, 3, 101, '2021-09-22', 1),
(1010, 4, 103, '2021-10-30', 1);

Select * from Customers 
Select * from Products 
Select * from Sales 

--1) List all customers with their total spending.
Select
	c.CustomerID,c.Name as 'CustomerName',c.Country,
	Coalesce(SUM(p.Price*s.Quantity),0) as [Total Spending]
from Customers c
left join Sales s
on c.CustomerID =s.CustomerID 
left join Products p
on p.ProductID =s.ProductID 
group by c.CustomerID,c.Name,c.Country 
order by [Total Spending]Desc;

--2) Find the top 3 highest revenue-generating products.
SELECT TOP 3
    p.ProductID,p.ProductName,
    SUM(p.Price * s.Quantity) AS TotalRevenue
FROM Products p
INNER JOIN Sales s 
ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalRevenue DESC;

--3)Show monthly sales totals for 2021.
SELECT
    YEAR(s.SaleDate) AS [Year],
    DATENAME(MONTH, s.SaleDate) AS [Month],
    SUM(p.Price * s.Quantity) AS [Monthly Sales]
FROM Sales s
JOIN Products p 
ON p.ProductID = s.ProductID
WHERE YEAR(s.SaleDate) = 2021
GROUP BY YEAR(s.SaleDate), DATENAME(MONTH, s.SaleDate), MONTH(s.SaleDate)
ORDER BY [Year], MONTH(s.SaleDate);

--4) Find customers who purchased products from more than one category.
SELECT
    c.CustomerID,c.Name AS 'Customer Name',
    COUNT(DISTINCT p.Category) AS 'Total Categories',
    STRING_AGG(CONVERT(NVARCHAR(100), p.Category), ', ') WITHIN GROUP (ORDER BY p.Category) AS 'Categories Purchased'
FROM Customers c
JOIN Sales s 
ON c.CustomerID = s.CustomerID
JOIN Products p 
ON s.ProductID = p.ProductID
GROUP BY c.CustomerID, c.Name
HAVING COUNT(DISTINCT p.Category) > 1
ORDER BY COUNT(DISTINCT p.Category) DESC, c.Name;

--5) Using LAG, show each customer's purchase date and the gap from their previous purchase.
WITH CustomerPurchases AS (
    SELECT
        c.CustomerID,c.Name AS CustomerName,s.SaleDate,
        LAG(s.SaleDate) OVER (PARTITION BY c.CustomerID ORDER BY s.SaleDate) AS PreviousPurchaseDate,
        ROW_NUMBER() OVER (PARTITION BY c.CustomerID ORDER BY s.SaleDate) AS PurchaseNumber
    FROM
        Customers c
    JOIN
        Sales s ON c.CustomerID = s.CustomerID)
SELECT
    CustomerID,CustomerName,
    SaleDate AS CurrentPurchaseDate,PreviousPurchaseDate,
    DATEDIFF(DAY, PreviousPurchaseDate, SaleDate) AS DaysSinceLastPurchase
FROM CustomerPurchases
WHERE PurchaseNumber > 1  -- Only show purchases after the first one
ORDER BY CustomerID, SaleDate;

--6) Calculate the percentage contribution of each product to total revenue.
WITH ProductRevenue AS (
    SELECT
        p.ProductID,p.ProductName,
        SUM(p.Price * s.Quantity) AS ProductRevenue
    FROM
        Products p
    JOIN
        Sales s ON p.ProductID = s.ProductID
    GROUP BY
        p.ProductID, p.ProductName
),
TotalRevenue AS (
    SELECT SUM(ProductRevenue) AS GrandTotal
    FROM ProductRevenue
)
SELECT
    pr.ProductID,pr.ProductName,pr.ProductRevenue,
    ROUND((pr.ProductRevenue * 100.0 / tr.GrandTotal), 2) AS RevenuePercentage
FROM
    ProductRevenue pr
CROSS JOIN
    TotalRevenue tr
ORDER BY
    pr.ProductRevenue DESC;

--7) Identify customers who have not purchased anything in the last 6 months of 2021.
SELECT
    c.CustomerID,c.Name AS CustomerName,
    c.JoinDate,c.Country
FROM Customers c
LEFT JOIN Sales s 
ON c.CustomerID = s.CustomerID
    AND s.SaleDate BETWEEN '2021-07-01' AND '2021-12-31'
WHERE s.SaleID IS NULL
ORDER BY c.CustomerID;

--8) Use NTILE(4) to divide products into 4 price quartiles.
SELECT
    ProductID,ProductName,Category,Price,
    NTILE(4) OVER (ORDER BY Price) AS PriceQuartile,
    CASE NTILE(4) OVER (ORDER BY Price)
        WHEN 1 THEN 'Q1 (Lowest Prices)'
        WHEN 2 THEN 'Q2'
        WHEN 3 THEN 'Q3'
        WHEN 4 THEN 'Q4 (Highest Prices)'
    END AS QuartileDescription
FROM Products
ORDER BY PriceQuartile, Price;

--9) Find the product category with the highest average order quantity.
SELECT TOP 1
    p.Category,
    ROUND(AVG(CAST(s.Quantity AS DECIMAL(10,2))), 2) AS [Average Order Quantity]
FROM Products p
JOIN Sales s 
ON p.ProductID = s.ProductID
GROUP BY p.Category
ORDER BY [Average Order Quantity] DESC;

--10) For each country, calculate the churn rate: percentage of customers who joined before 2021 but made no purchases in 2021.
WITH 
-- Customers who joined before 2021
Pre2021Customers AS (
    SELECT 
        CustomerID,Country
    FROM Customers
    WHERE YEAR(JoinDate) < 2021
),
-- Customers who made purchases in 2021
Active2021Customers AS (
    SELECT DISTINCT
        c.CustomerID,c.Country
    FROM Customers c
    JOIN Sales s 
	ON c.CustomerID = s.CustomerID
    WHERE 
        YEAR(s.SaleDate) = 2021
),
-- Counts per country
CountryStats AS (
    SELECT
        p.Country,
        COUNT(p.CustomerID) AS TotalPre2021Customers,
        COUNT(CASE WHEN a.CustomerID IS NULL THEN 1 END) AS ChurnedCustomers
    FROM Pre2021Customers p
    LEFT JOIN 
        Active2021Customers a ON p.CustomerID = a.CustomerID
    GROUP BY
        p.Country
)
-- Final calculation with churn rate
SELECT
    Country,TotalPre2021Customers,ChurnedCustomers,
    CASE 
        WHEN TotalPre2021Customers = 0 THEN 0.00
        ELSE ROUND((ChurnedCustomers * 100.0 / TotalPre2021Customers), 2)
    END AS ChurnRatePercentage
FROM CountryStats
ORDER BY ChurnRatePercentage DESC;

-- Bonus Challenge
--Find the top 2 customers in each country ranked by total spending, using window functions.
WITH CustomerSpending AS (
    SELECT
        c.Country,c.CustomerID,c.Name AS CustomerName,
        SUM(p.Price * s.Quantity) AS TotalSpending,
        RANK() OVER (PARTITION BY c.Country ORDER BY SUM(p.Price * s.Quantity) DESC) AS SpendingRank
    FROM Customers c
    JOIN Sales s ON c.CustomerID = s.CustomerID
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY c.Country, c.CustomerID, c.Name)
SELECT
    Country,CustomerID,CustomerName,TotalSpending,SpendingRank
FROM CustomerSpending
WHERE SpendingRank <= 2
ORDER BY Country, SpendingRank;