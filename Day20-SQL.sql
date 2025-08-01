Create table Customers (
						CustomerID int primary key,
						Name varchar (50) not null,
						Age int not null Check(Age>0),
						Gender varchar(20) not null CHECK (Gender IN ('Male', 'Female', 'Other')),
						City varchar (30) not null,
						JoinDate date default getdate() Check(JoinDate<=GetDate())
						);

Create table ServicePlans(
							PlanID int primary key,
							PlanName varchar(20) not null check (PlanName in ('Silver','Gold','Platinum')),
							MonthlyFee decimal (10,2) not null Check (MonthlyFee>0),
							FreeMinutes bigint not null check (FreeMinutes>0)
						);

Create table Subscriptions (
							SubscriptionID int primary key,
							CustomerID int not null,
							PlanID int not null,
							StartDate date not null,
							EndDate date,
							foreign key(CustomerID) references Customers(CustomerID) on delete cascade,
							foreign key(PlanID) references ServicePlans(PlanID) on delete cascade,
							CONSTRAINT chk_subscription_dates CHECK (EndDate IS NULL OR EndDate > StartDate)
							);

Create table CallRecords(
							CallID int primary key,
							CustomerID int not null,
							CallDate date default getdate() check (CallDate<=GetDate()),
							Duration bigint not null check (Duration>0),
							CallType varchar(30) not null CHECK (CallType IN ('Local', 'International')),
							foreign key (CustomerID) references Customers(CustomerID) on delete cascade
						);

Create Index Idx_Subscriptions_CustomerID on Subscriptions(CustomerID);
Create Index Idx_Subscriptions_PlanID on Subscriptions(PlanID);
Create Index Idx_CallRecords_CustomerID on CallRecords(CustomerID);

INSERT INTO Customers VALUES
(1, 'Anita', 28, 'Female', 'Delhi', '2022-03-15'),
(2, 'Ravi', 35, 'Male', 'Mumbai', '2022-07-01'),
(3, 'Meena', 40, 'Female', 'Chennai', '2021-11-23'),
(4, 'Kiran', 30, 'Male', 'Hyderabad', '2023-01-10'),
(5, 'Sneha', 22, 'Female', 'Bangalore', '2022-12-05');

INSERT INTO ServicePlans VALUES
(101, 'Silver', 299.00, 300),
(102, 'Gold', 499.00, 600),
(103, 'Platinum', 799.00, 1200);

INSERT INTO Subscriptions VALUES
(1001, 1, 101, '2022-03-15', NULL),
(1002, 2, 102, '2022-07-01', '2023-07-01'),
(1003, 3, 103, '2021-11-23', NULL),
(1004, 4, 101, '2023-01-10', NULL),
(1005, 5, 102, '2022-12-05', NULL);

INSERT INTO CallRecords VALUES
(1, 1, '2023-06-01', 20, 'Local'),
(2, 1, '2023-06-05', 45, 'International'),
(3, 2, '2023-06-10', 300, 'Local'),
(4, 3, '2023-06-15', 500, 'Local'),
(5, 4, '2023-06-18', 15, 'International'),
(6, 5, '2023-06-20', 250, 'Local');

Select * from Customers 
Select * from ServicePlans 
Select * from Subscriptions 
Select * from CallRecords 

--1) List all customers along with their current service plan and monthly fee.
Select
	cu.CustomerID,cu.Name as 'CustomerName',
	sp.PlanID,sp.PlanName,sp.MonthlyFee
from
	Customers cu
left join
	Subscriptions s
on cu.CustomerID =s.CustomerID AND (s.EndDate IS NULL OR s.EndDate > GETDATE()) -- Only active subscriptions
left join
	ServicePlans sp
on sp.PlanID =s.PlanID ;

--2) Show total minutes used by each customer in June 2023.
SELECT
    c.CustomerID,c.Name AS 'Customer Name', 
    COALESCE(SUM(cr.Duration), 0) AS 'Total Minutes Used'
FROM
    Customers c
LEFT JOIN
    CallRecords cr ON c.CustomerID = cr.CustomerID 
    AND cr.CallDate BETWEEN '2023-06-01' AND '2023-06-30'
GROUP BY
    c.CustomerID, c.Name
ORDER BY
    [Total Minutes Used] DESC;

--3) Find customers who made more than 1 international call in June 2023.
Select
	c.CustomerID,c.Name as 'Customer Name', count (cr. CallType) as 'International Calls Count'
from
	Customers c
join
	CallRecords cr 
on c.CustomerID =cr.CustomerID
where 
	cr.CallType = 'International'
    AND cr.CallDate BETWEEN '2023-06-01' AND '2023-06-30'
Group by
	c.CustomerID,c.Name
HAVING
    COUNT(cr.CallID) > 1
ORDER BY
    [International Calls Count] DESC;

--4) Identify customers who exceeded their plan's free minutes in total calls.
SELECT
    c.CustomerID,c.Name AS 'CustomerName',
    sp.PlanName,sp.FreeMinutes AS 'AllowedMinutes',
    SUM(cr.Duration) AS 'TotalMinutesUsed',
    SUM(cr.Duration) - sp.FreeMinutes AS 'MinutesOverLimit'
FROM
    Customers c
JOIN
    Subscriptions s ON c.CustomerID = s.CustomerID
    AND (s.EndDate IS NULL OR s.EndDate > GETDATE()) -- Only active subscriptions
JOIN
    ServicePlans sp ON s.PlanID = sp.PlanID
JOIN
    CallRecords cr ON c.CustomerID = cr.CustomerID
GROUP BY
    c.CustomerID, c.Name, sp.PlanName, sp.FreeMinutes
HAVING
    SUM(cr.Duration) > sp.FreeMinutes
ORDER BY
    MinutesOverLimit DESC;

--5) Display city-wise average call duration for the month of June.
SELECT
    c.City,
    ROUND(AVG(CAST(cr.Duration AS DECIMAL(10,2))), 2) AS 'AVG Call Duration',
    COUNT(cr.CallID) AS 'Total Calls'
FROM
    Customers c
LEFT JOIN
    CallRecords cr ON c.CustomerID = cr.CustomerID 
    AND cr.CallDate BETWEEN '2023-06-01' AND '2023-06-30'
GROUP BY
    c.City
ORDER BY
    [AVG Call Duration] DESC;

--6) Find customers who have changed their plan (i.e., have multiple subscriptions).
SELECT
    c.CustomerID, c.Name AS 'Customer Name',
    COUNT(DISTINCT s.PlanID) AS 'Number of Plans',
    STRING_AGG(sp.PlanName, ', ') WITHIN GROUP (ORDER BY s.StartDate) AS 'Plan History'
FROM
    Customers c
JOIN
    Subscriptions s ON c.CustomerID = s.CustomerID
JOIN
    ServicePlans sp ON s.PlanID = sp.PlanID
GROUP BY
    c.CustomerID, c.Name
HAVING
    COUNT(DISTINCT s.PlanID) > 1
ORDER BY
    [Number of Plans] DESC;

--7) Show total revenue generated from active subscriptions grouped by plan.
SELECT
    sp.PlanID,sp.PlanName,
    COUNT(s.SubscriptionID) AS 'ActiveSubscriptions',
    sp.MonthlyFee, SUM(sp.MonthlyFee) AS 'TotalMonthlyRevenue'
FROM
    ServicePlans sp
JOIN
    Subscriptions s ON sp.PlanID = s.PlanID
WHERE
    s.EndDate IS NULL OR s.EndDate > GETDATE() -- Active subscriptions only
GROUP BY
    sp.PlanID, sp.PlanName, sp.MonthlyFee
ORDER BY
    TotalMonthlyRevenue DESC;

--8) List customers whose subscriptions ended before June 2023.
SELECT
    c.CustomerID,c.Name AS 'Customer Name',
    s.PlanID,sp.PlanName,s.StartDate,s.EndDate
FROM
    Customers c
JOIN
    Subscriptions s ON c.CustomerID = s.CustomerID
JOIN
    ServicePlans sp ON s.PlanID = sp.PlanID
WHERE
    s.EndDate IS NOT NULL -- Ensure there is an EndDate
    AND s.EndDate < '2023-06-01' -- Ended before June 2023
ORDER BY
    s.EndDate DESC;

--9) Find the plan with the highest number of currently active subscribers.
SELECT TOP 1
    sp.PlanID,sp.PlanName,
    COUNT(DISTINCT s.CustomerID) AS 'ActiveSubscribers'
FROM
    ServicePlans sp
JOIN
    Subscriptions s ON sp.PlanID = s.PlanID
WHERE
    s.EndDate IS NULL OR s.EndDate > GETDATE() -- Active subscriptions only
GROUP BY
    sp.PlanID, sp.PlanName
ORDER BY
    ActiveSubscribers DESC;

--10) Display the gender-wise average usage (total call minutes).
SELECT
    c.Gender,
    ROUND(AVG(CAST(cr.Duration AS DECIMAL(10,2))), 2) AS 'Average Call Duration',
    COUNT(cr.CallID) AS 'Total Calls',
    COUNT(DISTINCT c.CustomerID) AS 'Customers With Calls'
FROM
    Customers c
LEFT JOIN
    CallRecords cr ON c.CustomerID = cr.CustomerID
GROUP BY
    c.Gender
ORDER BY
    [Average Call Duration] DESC;

-- Bonus Challenge
-- Identify customers who joined before 2023 and are still on the same plan since joining. 
SELECT
    c.CustomerID,c.Name AS 'Customer Name',c.JoinDate,
    sp.PlanName AS 'Original Plan',sp.MonthlyFee,
    DATEDIFF(MONTH, c.JoinDate, GETDATE()) AS 'MonthsWithPlan'
FROM
    Customers c
JOIN
    Subscriptions s ON c.CustomerID = s.CustomerID
JOIN
    ServicePlans sp ON s.PlanID = sp.PlanID
WHERE
    c.JoinDate < '2023-01-01' -- Joined before 2023
    AND s.StartDate = c.JoinDate -- Started plan when they joined
    AND (s.EndDate IS NULL OR s.EndDate > GETDATE()) -- Still active
    AND NOT EXISTS (
        -- Ensure no other subscriptions exist for this customer
        SELECT 1 
        FROM Subscriptions s2 
        WHERE s2.CustomerID = c.CustomerID 
        AND s2.SubscriptionID != s.SubscriptionID
    )
ORDER BY
    c.JoinDate;
	