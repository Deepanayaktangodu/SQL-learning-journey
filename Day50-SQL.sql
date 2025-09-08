Create table Customers (	
						CustomerID Int Primary key,
						Name Varchar(50) Not Null Check(Len(Name)>=2),
						Country Varchar(30) Not Null Check(Len(Country)>=2),
						Segment Varchar(30) Not Null Check(Segment in ('Retail','Corporate','Small Business')),
						JoinDate Date Not Null Default Getdate() Check(JoinDate<=GetDate())
						);

Create table Orders (
						OrderID Int Primary Key,
						CustomerID Int Not Null,
						OrderDate Date Not Null Default Getdate(),
						Status Varchar(30) Not Null Check(Status in ('Completed','Cancelled','Returned')),
						TotalAmount Decimal(8,2) Null Check(TotalAmount>=0),
						Foreign Key(CustomerID) references Customers(CustomerID) on update cascade on delete no action
					);

Create table OrderDetails(
							OrderDetailID Int Primary Key,
							OrderID Int Not Null,
							ProductName Varchar(75) Not Null unique Check(Len(ProductName)>=2),
							Category varchar(30) Not Null Check(Category in ('Electronics','Furniture')),
							Quantity int Not Null Check(Quantity>0),
							Price Decimal(8,2) Not Null Check(Price>0),
							Foreign Key(OrderID) references Orders(OrderID) on update cascade on delete no action
						);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Customers_Segment on Customers(Segment);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_ProductName on OrderDetails(ProductName);
Create Index Idx_OrderDetails_Category on OrderDetails(Category);
Create Index Idx_OrderDetails_Quantity on OrderDetails(Quantity);
Create Index Idx_OrderDetails_Price on OrderDetails(Price);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);

INSERT INTO Customers (CustomerID, Name, Country, Segment, JoinDate) VALUES
(1, 'Alice', 'USA', 'Retail', '2020-01-01'),
(2, 'Bob', 'India', 'Corporate', '2021-02-15'),
(3, 'Charlie', 'UK', 'Small Business', '2021-05-01'),
(4, 'David', 'Canada', 'Retail', '2022-03-10'),
(5, 'Emma', 'India', 'Retail', '2022-06-25');

INSERT INTO Orders (OrderID, CustomerID, OrderDate, Status, TotalAmount) VALUES
(101, 1, '2023-01-05', 'Completed', 500.00),
(102, 1, '2023-02-10', 'Completed', 300.00),
(103, 2, '2023-02-15', 'Cancelled', 0.00),
(104, 3, '2023-03-01', 'Completed', 700.00),
(105, 4, '2023-03-12', 'Returned', 0.00),
(106, 5, '2023-04-01', 'Completed', 900.00),
(107, 2, '2023-04-15', 'Completed', 1200.00),
(108, 3, '2023-05-01', 'Completed', 650.00),
(109, 1, '2023-06-01', 'Completed', 400.00),
(110, 5, '2023-06-15', 'Completed', 750.00);

INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductName, Category, Quantity, Price) VALUES
(1, 101, 'Laptop', 'Electronics', 1, 500.00),
(2, 102, 'Mouse', 'Electronics', 2, 150.00),
(3, 104, 'Desk Chair', 'Furniture', 1, 700.00),
(4, 106, 'Smartphone', 'Electronics', 1, 900.00),
(5, 107, 'Laptop', 'Electronics', 1, 1200.00),
(6, 108, 'Desk', 'Furniture', 1, 650.00),
(7, 109, 'Keyboard', 'Electronics', 2, 200.00),
(8, 110, 'Tablet', 'Electronics', 1, 750.00);

ALTER TABLE OrderDetails
DROP CONSTRAINT UQ__OrderDet__DD5A978AECABB55E;

Select * from Customers 
Select * from Orders 
Select * from OrderDetails 

--1) Customer Revenue Analysis
--Find total revenue, total orders, and average order value per customer (Completed only).
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,c.Segment,
	ROUND(SUM(o.TotalAmount),2) as [Total Revenue],
	COUNT(o.OrderID) as [Total Orders],
	ROUND(AVG(o.TotalAmount),2) as [Average Order Value]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country,c.Segment 
order by c.CustomerID;

--2) Top Categories by Revenue
--Rank product categories based on total revenue.
-- Top Categories by Revenue (Completed Orders Only)
SELECT
    d.Category,
    ROUND(SUM(o.TotalAmount), 2) as [Total Revenue],
    COUNT(DISTINCT o.OrderID) as [Total Orders],
    COUNT(d.OrderDetailID) as [Total Items Sold],
    RANK() OVER (ORDER BY SUM(o.TotalAmount) DESC) as RevenueRank,
    DENSE_RANK() OVER (ORDER BY SUM(o.TotalAmount) DESC) as DenseRevenueRank,
    ROUND(SUM(o.TotalAmount) * 100.0 / SUM(SUM(o.TotalAmount)) OVER (), 2) as [Revenue Percentage]
FROM OrderDetails d
JOIN Orders o ON d.OrderID = o.OrderID 
WHERE o.Status = 'Completed' -- Only completed orders
GROUP BY d.Category 
ORDER BY [Total Revenue] DESC;

--3) Repeat Purchase Customers
--Find customers who placed more than 2 completed orders.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	count(Distinct o.OrderID) as [Order Count]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
having count(Distinct o.OrderID)>2
order by [Order Count] Desc;

--4) Monthly Revenue Trend
--Show total revenue per month and calculate % change from previous month using LAG.
-- Monthly Revenue Trend with Percentage Change
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.OrderDate) as [Year],
        MONTH(o.OrderDate) as [Month],
        DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) as [MonthStart],
        ROUND(SUM(o.TotalAmount), 2) as [Total Revenue],
        COUNT(o.OrderID) as [Total Orders]
    FROM Orders o
    WHERE o.Status = 'Completed'
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT
    [Year],[Month],
    FORMAT([MonthStart], 'yyyy-MM') as [Year-Month],
    [Total Revenue],[Total Orders],
    LAG([Total Revenue]) OVER (ORDER BY [Year], [Month]) as [Previous Month Revenue],
    ROUND(([Total Revenue] - LAG([Total Revenue]) OVER (ORDER BY [Year], [Month])) / 
          LAG([Total Revenue]) OVER (ORDER BY [Year], [Month]) * 100, 2) as [Month over Month % Change],
    ROUND(AVG([Total Revenue]) OVER (ORDER BY [Year], [Month] ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as [3MonthMovingAvg]
FROM MonthlyRevenue
ORDER BY [Year], [Month];

--5) Returned vs Completed Orders
--For each customer, calculate ratio of Returned orders vs Completed orders.
-- Returned vs Completed Orders Ratio per Customer
-- Returned vs Completed with financial impact analysis
WITH OrderFinancials AS (
    SELECT
        c.CustomerID,c.Name as 'Customer Name',c.Segment,o.Status,
        COUNT(o.OrderID) as OrderCount,
        SUM(o.TotalAmount) as TotalAmount,
        AVG(o.TotalAmount) as AvgOrderValue
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.Status IN ('Completed', 'Returned') OR o.OrderID IS NULL
    GROUP BY c.CustomerID, c.Name, c.Segment, o.Status
),
PivotedData AS (
    SELECT
        CustomerID,[Customer Name],Segment,
        COALESCE(SUM(CASE WHEN Status = 'Completed' THEN OrderCount END), 0) as CompletedOrders,
        COALESCE(SUM(CASE WHEN Status = 'Returned' THEN OrderCount END), 0) as ReturnedOrders,
        COALESCE(SUM(CASE WHEN Status = 'Completed' THEN TotalAmount END), 0) as CompletedRevenue,
        COALESCE(SUM(CASE WHEN Status = 'Returned' THEN TotalAmount END), 0) as ReturnedAmount
    FROM OrderFinancials
    GROUP BY CustomerID, [Customer Name], Segment
)
SELECT
    CustomerID,[Customer Name],Segment,
    CompletedOrders,ReturnedOrders,CompletedRevenue,ReturnedAmount,
    CASE 
        WHEN CompletedOrders = 0 THEN NULL 
        ELSE ROUND(CAST(ReturnedOrders AS FLOAT) / NULLIF(CompletedOrders, 0), 3) 
    END as [OrderReturnRatio],
    CASE 
        WHEN CompletedRevenue = 0 THEN NULL 
        ELSE ROUND(ReturnedAmount / NULLIF(CompletedRevenue, 0), 3) 
    END as [RevenueReturnRatio],
    ROUND(CompletedRevenue - ReturnedAmount, 2) as [NetRevenue],
    CASE 
        WHEN ReturnedOrders = 0 THEN 'No Returns'
        WHEN CAST(ReturnedOrders AS FLOAT) / NULLIF(CompletedOrders, 0) > 0.3 THEN 'High Return Rate (>30%)'
        WHEN CAST(ReturnedOrders AS FLOAT) / NULLIF(CompletedOrders, 0) > 0.1 THEN 'Medium Return Rate (10-30%)'
        ELSE 'Low Return Rate (<10%)'
    END as [ReturnRateCategory]
FROM PivotedData
ORDER BY [OrderReturnRatio] DESC, ReturnedOrders DESC;

--6) High-Value Customers
--Find customers whose average completed order value > $500.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	ROUND(AVG(o.TotalAmount),2) as [Average Order Value]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Completed'
group by c.CustomerID,c.Name,c.Country 
having AVG(o.TotalAmount)>500
order by [Average Order Value] Desc;

--7) Cross-Category Buyers
--List customers who purchased from more than 1 category.
-- Cross-Category Buyers (Customers who purchased from more than 1 category)
SELECT
    c.CustomerID,c.Name as 'Customer Name',
    c.Country,c.Segment,
    COUNT(DISTINCT d.Category) as [Category Count],
    STRING_AGG(d.Category, ', ') WITHIN GROUP (ORDER BY d.Category) as [Categories Purchased],
    COUNT(DISTINCT o.OrderID) as [Total Orders],
    ROUND(SUM(o.TotalAmount), 2) as [Total Spent],
    ROUND(AVG(o.TotalAmount), 2) as [Average Order Value]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails d ON o.OrderID = d.OrderID
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.Name, c.Country, c.Segment
HAVING COUNT(DISTINCT d.Category) > 1
ORDER BY [Category Count] DESC, [Total Spent] DESC;

--8) Country-Wise Insights
--Show revenue per country and rank them by contribution.
-- Country-Wise Revenue Insights with Ranking
SELECT
    c.Country,
    ROUND(SUM(o.TotalAmount), 2) as [Total Revenue],
    COUNT(o.OrderID) as [Total Orders],
    RANK() OVER (ORDER BY SUM(o.TotalAmount) DESC) as [Revenue Rank],
    ROUND(SUM(o.TotalAmount) * 100.0 / SUM(SUM(o.TotalAmount)) OVER (), 2) as [Contribution %]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.Status = 'Completed'
GROUP BY c.Country
ORDER BY [Total Revenue] DESC;

--9) Window Function – Product Popularity
--Use ROW_NUMBER() to find the top-selling product in each category.
WITH ProductSales AS (
    SELECT
        d.Category,d.ProductName,
        SUM(d.Quantity) as TotalSold,
        ROW_NUMBER() OVER (PARTITION BY d.Category ORDER BY SUM(d.Quantity) DESC) as Rank
    FROM OrderDetails d
    JOIN Orders o ON d.OrderID = o.OrderID
    WHERE o.Status = 'Completed'
    GROUP BY d.Category, d.ProductName
)
SELECT
    Category,ProductName ,TotalSold
FROM ProductSales
WHERE Rank = 1
ORDER BY Category;

--10) Customer Lifetime Value (CLV)
--CLV = (Total Revenue ÷ Years since first order). Round to 2 decimals.
Select
	c.CustomerID,c.Name as 'Customer Name',
	ROUND(SUM(o.TotalAmount),2) as [Total Revenue],
	MIN(o.OrderDate) as [First Order Date],
	DATEDIFF(YEAR, MIN(o.OrderDate), GetDate()) as [Years Of Customer],
	ROUND(SUM(o.TotalAmount) / NULLIF(DATEDIFF(year, MIN(o.OrderDate), GETDATE()), 0), 2) as [CLV]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.Name
ORDER BY [CLV] DESC;

--Bonus Challenge (Milestone Special)
--11) Churn Prediction (Advanced)
--A customer is considered “At Risk” if:Last order date was more than 90 days ago from max order date 
--AND they placed less than 2 orders in the last 12 months
--Write a query to flag such customers.
WITH CustomerOrderStats AS (
    SELECT
        c.CustomerID,c.Name as 'Customer Name',
        c.Country,c.Segment,
        MAX(o.OrderDate) as [Last Order Date],
        COUNT(CASE WHEN o.OrderDate >= DATEADD(MONTH, -12, GETDATE()) THEN o.OrderID END) as [Orders Last 12M],
        DATEDIFF(day, MAX(o.OrderDate), GETDATE()) as [Days Since Last Order]
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID AND o.Status = 'Completed'
    GROUP BY c.CustomerID, c.Name, c.Country, c.Segment
)
SELECT
    CustomerID,[Customer Name],Country,Segment,
    [Last Order Date],[Orders Last 12M],[Days Since Last Order],
    CASE 
        WHEN [Days Since Last Order] > 90 AND [Orders Last 12M] < 2 THEN 'At Risk'
        ELSE 'Not At Risk'
    END as [Churn Risk Status]
FROM CustomerOrderStats
WHERE [Days Since Last Order] > 90 AND [Orders Last 12M] < 2
ORDER BY [Days Since Last Order] DESC;

