Create table Customers(
						CustomerID int Primary key,
						Name varchar(50) not null Check(len(Name)>=2),
						Region varchar(30) not null Check(Region in ('South','North','East','West')),
						SignUpDate date not null default getdate() Check(SignUpDate<=getdate()),
						IsPrime smallint not null Check(IsPrime between 0 and 1),
						Unique(Name,Region),
						);


Create table Orders(
					OrderID int Primary key,
					CustomerID int not null,
					OrderDate date not null default getdate() Check(OrderDate<=getdate()),
					Amount decimal(10,2) not null Check(Amount>0),
					Status varchar(50) not null Check(Status in('Delivered','Cancelled','Returned')),
					PaymentMethod varchar(50) not null Check(PaymentMethod in ('UPI','CreditCard','Wallet','NetBanking'))
					foreign key(CustomerID) references Customers(CustomerID) on update cascade on delete no action
					);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Region on Customers(Region);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);

INSERT INTO Customers (CustomerID, Name, Region, SignupDate, IsPrime) VALUES
(101, 'Alice', 'South', '2021-05-01', 1),
(102, 'Bob', 'North', '2021-07-10', 0),
(103, 'Charlie', 'West', '2021-06-15', 1),
(104, 'Diana', 'East', '2021-08-20', 0),
(105, 'Ethan', 'South', '2021-10-05', 1),
(106, 'Fiona', 'North', '2021-12-01', 0),
(107, 'George', 'West', '2022-01-01', 1);

INSERT INTO Orders (OrderID, CustomerID, OrderDate, Amount, Status, PaymentMethod)
VALUES
    (1, 101, '2022-01-15', 250.00, 'Delivered', 'UPI'),
    (2, 102, '2022-01-20', 400.00, 'Cancelled', 'CreditCard'),
    (3, 101, '2022-02-05', 600.00, 'Delivered', 'Wallet'),
    (4, 103, '2022-02-10', 1200.00, 'Returned', 'UPI'),
    (5, 104, '2022-03-01', 900.00, 'Delivered', 'NetBanking'),
    (6, 105, '2022-03-05', 300.00, 'Delivered', 'UPI'),
    (7, 101, '2022-04-01', 1100.00, 'Delivered', 'CreditCard'),
    (8, 106, '2022-04-05', 700.00, 'Delivered', 'Wallet'),
    (9, 102, '2022-04-20', 450.00, 'Returned', 'UPI'),
    (10, 107, '2022-05-02', 2000.00, 'Delivered', 'UPI');

Select * from Customers 
Select * from Orders 

--1) Write a query to get total revenue per region, excluding cancelled and returned orders.
Select
	c.Region,
	SUM(o.Amount) as [Total Revenue]
from Customers c
join Orders o on c.CustomerID=o.CustomerID 
where o.Status='Delivered'
group by c.Region 
order by [Total Revenue] Desc;

--2) Find the top 2 customers with the highest total spending.
Select Top 2
	c.CustomerID,c.Name as 'Customer Name',
	SUM(o.Amount) as [Total Spending]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Delivered'
group by c.CustomerID,c.Name 
order by [Total Spending] Desc;

--3) Identify the % of prime customers in each region.
SELECT
    Region,
    COUNT(CustomerID) AS [Total Customers],
    SUM(CASE WHEN IsPrime = 1 THEN 1 ELSE 0 END) AS [Prime Customers],
    CAST(SUM(CASE WHEN IsPrime = 1 THEN 1 ELSE 0 END) AS DECIMAL(5, 2)) * 100 / COUNT(CustomerID) AS [Prime Customer Percentage]
FROM Customers
GROUP BY Region
ORDER BY Region;

--4) Retrieve customers who have only placed returned/cancelled orders.
Select
	c.CustomerID,c.Name as 'Customer Name'
from Customers c
where 
	c.CustomerID not in (
				Select CustomerID 
				from Orders 
				where Status='Delivered');

--5) Using a window function, calculate the running total revenue per customer ordered by date.
Select
	c.CustomerID,c.Name as 'Customer Name',
	o.OrderDate,o.Amount,
	SUM(o.Amount) over (partition by c.CustomerID order by o.OrderDate Desc) as [Running Total]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Delivered'
Order by c.CustomerID,o.OrderDate;

--6) Find the average order value (AOV) for prime vs non-prime customers.
Select
	CASE 
		when c.IsPrime=1 then 'Prime Customers' else 'NonPrime Customers' END as [Customer Type],
Round(AVG(o.Amount),2) as [Average Order Value]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Delivered'
Group by c.IsPrime;

--7) Identify the month with the highest total revenue (exclude cancelled/returned).
Select Top 1
	DATENAME(MONTH,o.OrderDate) as [MONTH],
	SUM(o.Amount) as [Total Revenue]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
where o.Status ='Delivered'
Group by DATENAME(MONTH,o.OrderDate)
order by [Total Revenue] Desc;

--8) Show the customer who placed the maximum single order (highest Amount).
SELECT TOP 1
    c.CustomerID,c.Name AS [Customer Name],
    o.Amount AS [Maximum Single Order]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY o.Amount DESC;

--9) Write a query to get repeat customers (those who placed more than 1 order).
Select
	c.CustomerID,c.Name as 'Customer Name',
	COUNT(DISTINCT o.OrderID) as [Order Count]
from Customers c
join Orders o on c.CustomerID =o.CustomerID 
group by c.CustomerID,c.Name 
having COUNT(DISTINCT o.OrderID)>1
order by [Order Count] Desc;

--10) Bonus Challenge 
--Write a query to rank regions by total revenue contribution and display revenue share % using CTE + window functions.
With RegionalRevenue as (
				Select
					c.Region,
					SUM(o.Amount) as TotalRegionalRevenue
				from Customers c
				join Orders o on c.CustomerID =o.CustomerID 
				where o.Status ='Delivered'
				group by c.Region ),
TotalRevenue as (
		Select
			SUM(TotalRegionalRevenue) as OverallTotalRevenue
		from RegionalRevenue )
Select
	rr.Region,rr.TotalRegionalRevenue,
	RANK() OVER (ORDER BY rr.TotalRegionalRevenue DESC) AS RevenueRank,
    CAST(rr.TotalRegionalRevenue AS DECIMAL(10, 2)) * 100 / (SELECT OverallTotalRevenue FROM TotalRevenue) AS RevenueSharePercentage
FROM RegionalRevenue rr
ORDER BY RevenueRank;
