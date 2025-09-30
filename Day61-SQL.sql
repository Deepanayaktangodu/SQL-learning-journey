CREATE TABLE Customers (
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						Age INT NOT NULL CHECK(Age>0),
						Gender CHAR(1) NOT NULL CHECK(Gender in ('F','M')),
						City VARCHAR(50) NOT NULL CHECK(LEN(City)>=2),
						JoinDate DATE NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE())
						);

CREATE TABLE Products (
						ProductID INT PRIMARY KEY,
						Name VARCHAR(100) NOT NULL UNIQUE CHECK(LEN(Name)>=2),
						Category VARCHAR(50) NOT NULL CHECK(LEN(Category)>=2) ,
						Price DECIMAL(10,2) NOT NULL CHECK(Price>0)
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE NOT NULL DEFAULT GETDATE() CHECK(OrderDate<=GETDATE()),
						Status VARCHAR(20) NOT NULL CHECK(Status in ('Completed','Cancelled')),
						UNIQUE(CustomerID,OrderID),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

CREATE TABLE OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductID INT NOT NULL,
							Quantity INT NOT NULL CHECK(Quantity>0),
							UNIQUE(OrderID,ProductID),
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE CASCADE
							);

CREATE TABLE MarketingCampaigns (
									CampaignID INT PRIMARY KEY,
									CampaignName VARCHAR(100) NOT NULL,
									StartDate DATE NOT NULL,
									EndDate DATE NOT NULL,
									CHECK(EndDate >= StartDate),
									TargetCategory VARCHAR(50) NOT NULL UNIQUE
								);

CREATE TABLE CampaignResponses (
									ResponseID INT PRIMARY KEY,
									CampaignID INT NOT NULL,
									CustomerID INT NOT NULL,
									Response VARCHAR(20) NOT NULL CHECK(Response in ('Interested','Not Interested')),
									UNIQUE(ResponseID,CampaignID,CustomerID),
									FOREIGN KEY (CampaignID) REFERENCES MarketingCampaigns(CampaignID) ON UPDATE CASCADE ON DELETE CASCADE,
									FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE CASCADE
								);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Age on Customers(Age);
Create Index Idx_Customers_Gender on Customers(Gender);
Create Index Idx_Customers_City on Customers(City);
Create Index Idx_Customers_JoinDate on Customers(JoinDate);
Create Index Idx_Products_Name on Products(Name);
Create Index Idx_Products_Category on Products(Category);
Create Index Idx_Products_Price on Products(Price);
Create Index Idx_Orders_OrderDate on Orders(OrderDate);
Create Index Idx_Orders_Status on Orders(Status);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);
Create Index Idx_MarketingCampaigns_CampaignName on MarketingCampaigns(CampaignName);
Create Index Idx_CampaignResponses_Response on CampaignResponses(Response);
Create Index Idx_CampaignResponses_CampaignID on CampaignResponses(CampaignID);
Create Index Idx_CampaignResponses_CustomerID on CampaignResponses(CustomerID);
CREATE INDEX Idx_Orders_CustomerID_OrderDate ON Orders(CustomerID, OrderDate);
CREATE INDEX Idx_Customers_Demographics ON Customers(City, Gender, Age);
CREATE INDEX Idx_Products_CategoryPrice ON Products(Category, Price);
CREATE INDEX Idx_Orders_CustomerStatusDate ON Orders(CustomerID, Status, OrderDate);

INSERT INTO Customers VALUES
(1, 'Alice', 28, 'F', 'New York', '2021-01-15'),
(2, 'Bob', 35, 'M', 'London', '2020-03-22'),
(3, 'Charlie', 42, 'M', 'Delhi', '2019-07-19'),
(4, 'David', 31, 'M', 'Toronto', '2022-11-11'),
(5, 'Eva', 26, 'F', 'Berlin', '2020-05-01');

INSERT INTO Products VALUES
(101, 'Laptop', 'Electronics', 1200.00),
(102, 'Shoes', 'Fashion', 80.00),
(103, 'Phone', 'Electronics', 800.00),
(104, 'Desk', 'Furniture', 250.00),
(105, 'Book', 'Books', 20.00);


INSERT INTO Orders VALUES
(201, 1, '2022-01-10', 'Completed'),
(202, 2, '2022-01-15', 'Completed'),
(203, 3, '2022-02-05', 'Cancelled'),
(204, 4, '2022-02-10', 'Completed'),
(205, 5, '2022-03-12', 'Completed'),
(206, 1, '2022-04-01', 'Completed'),
(207, 3, '2022-04-15', 'Completed'),
(208, 2, '2022-05-01', 'Completed'),
(209, 4, '2022-05-10', 'Completed'),
(210, 5, '2022-06-01', 'Completed');

INSERT INTO OrderDetails VALUES
(301, 201, 101, 1),
(302, 202, 102, 2),
(303, 203, 103, 1),
(304, 204, 104, 1),
(305, 205, 105, 3),
(306, 206, 101, 1),
(307, 207, 103, 1),
(308, 208, 102, 1),
(309, 209, 104, 2),
(310, 210, 105, 4);

INSERT INTO MarketingCampaigns VALUES
(401, 'Electronics Sale', '2022-01-01', '2022-01-31', 'Electronics'),
(402, 'Fashion Week', '2022-02-01', '2022-02-28', 'Fashion'),
(403, 'Book Fest', '2022-03-01', '2022-03-31', 'Books');

INSERT INTO CampaignResponses VALUES
(501, 401, 1, 'Interested'),
(502, 401, 2, 'Not Interested'),
(503, 402, 3, 'Interested'),
(504, 403, 5, 'Interested'),
(505, 403, 4, 'Not Interested');

SELECT * FROM Customers;
SELECT * FROM Products;
SELECT * FROM Orders;
SELECT * FROM OrderDetails;
SELECT * FROM MarketingCampaigns;
SELECT * FROM CampaignResponses;

--1) Find the total revenue per product category.
SELECT
	p.Category,
	ROUND(SUM(p.Price *od.Quantity),2) as [Total Revenue],
	COUNT(DISTINCT o.OrderID) as [Unique Orders]
FROM Products p
JOIN OrderDetails od ON p.ProductID =od.ProductID 
JOIN Orders o ON od.OrderID =o.OrderID AND o.Status ='Completed'
GROUP BY p.Category 
ORDER BY [Total Revenue] DESC;

--2) Identify customers who purchased from more than 2 different categories.
SELECT
    c.CustomerID,c.Name,c.City,
    COUNT(DISTINCT o.OrderID) as [Unique Order Counts],
    COUNT(DISTINCT p.Category) as [Unique Categories Purchased],
    STRING_AGG(p.Category, ', ') as [Category Names]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID  -- Fixed: was o.OrderID, should be o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID 
JOIN Products p ON p.ProductID = od.ProductID 
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.Name, c.City 
HAVING COUNT(DISTINCT p.Category) > 2
ORDER BY [Unique Categories Purchased] DESC, c.CustomerID;

--3) Calculate the average order value (AOV) for each customer.
WITH OrderTotals AS (
    SELECT
        o.OrderID, o.CustomerID,
        SUM(p.Price * od.Quantity) as OrderAmount
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON p.ProductID = od.ProductID
    WHERE o.Status = 'Completed'
    GROUP BY o.OrderID, o.CustomerID
)
SELECT
    c.CustomerID,c.Name,c.City,
    COUNT(ot.OrderID) as [Total Orders],
    ROUND(AVG(ot.OrderAmount), 2) as [Average Order Value],
    ROUND(SUM(ot.OrderAmount), 2) as [Total Lifetime Value],
    ROUND(MIN(ot.OrderAmount), 2) as [Smallest Order],
    ROUND(MAX(ot.OrderAmount), 2) as [Largest Order]
FROM Customers c
JOIN OrderTotals ot ON c.CustomerID = ot.CustomerID
GROUP BY c.CustomerID, c.Name, c.City
ORDER BY [Average Order Value] DESC;

--4) Find the conversion rate for each marketing campaign (Interested ÷ Total Responses).
SELECT
    mc.CampaignID,mc.CampaignName,mc.TargetCategory,
    COUNT(cr.ResponseID) as [Total Responses],
    SUM(CASE WHEN cr.Response = 'Interested' THEN 1 ELSE 0 END) AS [Interested Count],
    ROUND(SUM(CASE WHEN cr.Response = 'Interested' THEN 1 ELSE 0 END) * 1.0 / COUNT(cr.ResponseID), 2) AS [Conversion Rate]
FROM MarketingCampaigns mc
JOIN CampaignResponses cr ON mc.CampaignID = cr.CampaignID
GROUP BY mc.CampaignID, mc.CampaignName, mc.TargetCategory
ORDER BY [Conversion Rate] DESC;

--5) List the top 3 products by total revenue.
SELECT TOP 3
	p.ProductID,p.Name,p.Category,
	ROUND(SUM(p.Price*od.Quantity),2) as [Total Revenue]
FROM Products p
JOIN OrderDetails od ON p.ProductID =od.ProductID 
JOIN Orders o ON o.OrderID =od.OrderID  AND o.Status ='Completed'
GROUP BY P.ProductID,P.Name,P.Category 
ORDER BY [Total Revenue] DESC;

--6) Identify customers who responded "Interested" but made no purchase during the campaign.
SELECT
    c.CustomerID,c.Name,c.City,c.Age,c.Gender,c.JoinDate,
    mc.CampaignID,mc.CampaignName,mc.TargetCategory,
	mc.StartDate as [Campaign Start],
    mc.EndDate as [Campaign End],
    DATEDIFF(DAY, mc.StartDate, mc.EndDate) as [Campaign Duration]
FROM Customers c
JOIN CampaignResponses cr ON c.CustomerID = cr.CustomerID AND cr.Response = 'Interested'
JOIN MarketingCampaigns mc ON cr.CampaignID = mc.CampaignID
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID 
    AND o.OrderDate BETWEEN mc.StartDate AND mc.EndDate
    AND o.Status = 'Completed'
WHERE o.OrderID IS NULL
ORDER BY mc.CampaignName, c.CustomerID;

--7) Show the revenue trend per month and calculate MoM % growth.
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.OrderDate) as [Year],
        MONTH(o.OrderDate) as [Month],
        DATENAME(MONTH, o.OrderDate) as [Month Name],
        ROUND(SUM(p.Price * od.Quantity), 2) as [Total Revenue]
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.Status = 'Completed'
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate)
),
RevenueWithGrowth AS (
    SELECT
        [Year],[Month],
        [Month Name],[Total Revenue],
        LAG([Total Revenue]) OVER (ORDER BY [Year], [Month]) as [Previous Month Revenue],
        CASE 
            WHEN LAG([Total Revenue]) OVER (ORDER BY [Year], [Month]) IS NOT NULL 
            THEN ROUND(([Total Revenue] - LAG([Total Revenue]) OVER (ORDER BY [Year], [Month])) * 100.0 / 
                 LAG([Total Revenue]) OVER (ORDER BY [Year], [Month]), 2)
            ELSE NULL
        END as [MoM Growth %]
    FROM MonthlyRevenue
)
SELECT
    [Year],[Month],
    [Month Name],[Total Revenue],
    [Previous Month Revenue],[MoM Growth %],
    CASE 
        WHEN [MoM Growth %] > 0 THEN 'Growth'
        WHEN [MoM Growth %] < 0 THEN 'Decline'
        ELSE 'No Change'
    END as [Trend]
FROM RevenueWithGrowth
ORDER BY [Year], [Month];

--8) Using a window function, find the rank of customers by spending within their city.
WITH CustomersSpending AS (
    SELECT
        c.CustomerID,c.Name,c.City,
        ROUND(SUM(p.Price * od.Quantity), 2) AS [Total Spending],
        DENSE_RANK() OVER (PARTITION BY c.City ORDER BY SUM(p.Price * od.Quantity) DESC) AS SpendingRank
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID 
    JOIN OrderDetails od ON o.OrderID = od.OrderID 
    JOIN Products p ON p.ProductID = od.ProductID 
    WHERE o.Status = 'Completed'
    GROUP BY c.CustomerID, c.Name, c.City
)
SELECT
    CustomerID,Name,City,
    [Total Spending],SpendingRank
FROM CustomersSpending 
ORDER BY City, SpendingRank;

--9) Find products that were ordered but never targeted by any campaign.
SELECT DISTINCT
    p.ProductID,p.Name AS ProductName,p.Category
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID AND o.Status = 'Completed'
LEFT JOIN MarketingCampaigns mc ON p.Category = mc.TargetCategory
WHERE mc.CampaignID IS NULL;

--10) Show customers whose spending is above the overall average.
WITH CustomerSpending AS (
    SELECT
        c.CustomerID,c.Name,c.City,
        ROUND(SUM(p.Price * od.Quantity), 2) AS [Total Spending]
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.Status = 'Completed'
    GROUP BY c.CustomerID, c.Name, c.City
)
SELECT
    CustomerID,Name,City,[Total Spending]
FROM CustomerSpending
WHERE [Total Spending] > (SELECT AVG([Total Spending]) FROM CustomerSpending)
ORDER BY [Total Spending] DESC;

-- 11) Detect the most effective campaign:
--Highest conversion rate AND Highest revenue impact in its target category.
WITH CampaignConversion AS (
    -- Calculate conversion rates for each campaign
    SELECT
        mc.CampaignID,mc.CampaignName,mc.TargetCategory,mc.StartDate,mc.EndDate,
        COUNT(cr.ResponseID) as [Total Responses],
        SUM(CASE WHEN cr.Response = 'Interested' THEN 1 ELSE 0 END) AS [Interested Count],
        ROUND(SUM(CASE WHEN cr.Response = 'Interested' THEN 1 ELSE 0 END) * 100.0 / 
              NULLIF(COUNT(cr.ResponseID), 0), 2) AS [Conversion Rate %]
    FROM MarketingCampaigns mc
    LEFT JOIN CampaignResponses cr ON mc.CampaignID = cr.CampaignID
    GROUP BY mc.CampaignID, mc.CampaignName, mc.TargetCategory, mc.StartDate, mc.EndDate
),
CampaignRevenue AS (
    -- Calculate revenue impact for each campaign's target category during campaign period
    SELECT
        mc.CampaignID,mc.CampaignName,mc.TargetCategory,
        ROUND(SUM(p.Price * od.Quantity), 2) AS [Campaign Period Revenue],
        COUNT(DISTINCT o.CustomerID) AS [Unique Purchasing Customers],
        COUNT(DISTINCT o.OrderID) AS [Total Orders]
    FROM MarketingCampaigns mc
    JOIN Orders o ON o.OrderDate BETWEEN mc.StartDate AND mc.EndDate
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID AND p.Category = mc.TargetCategory
    WHERE o.Status = 'Completed'
    GROUP BY mc.CampaignID, mc.CampaignName, mc.TargetCategory
),
BaselineRevenue AS (
    -- Calculate baseline revenue for each category before campaign
    SELECT
        p.Category,
        ROUND(SUM(p.Price * od.Quantity), 2) AS [Baseline Revenue],
        COUNT(DISTINCT o.CustomerID) AS [Baseline Customers]
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    WHERE o.Status = 'Completed'
      AND o.OrderDate < (SELECT MIN(StartDate) FROM MarketingCampaigns)
    GROUP BY p.Category
),
CampaignEffectiveness AS (
    -- Combine all metrics and calculate effectiveness scores
    SELECT
        cc.CampaignID,cc.CampaignName,cc.TargetCategory,cc.StartDate,cc.EndDate,
        DATEDIFF(DAY, cc.StartDate, cc.EndDate) AS [Campaign Duration],
        cc.[Total Responses],cc.[Interested Count],cc.[Conversion Rate %],
        COALESCE(cr.[Campaign Period Revenue], 0) AS [Campaign Revenue],
        COALESCE(br.[Baseline Revenue], 0) AS [Baseline Revenue],
        COALESCE(cr.[Unique Purchasing Customers], 0) AS [Campaign Customers],
        COALESCE(br.[Baseline Customers], 0) AS [Baseline Customers],
        COALESCE(cr.[Total Orders], 0) AS [Campaign Orders],
        -- Calculate revenue growth
        CASE 
            WHEN COALESCE(br.[Baseline Revenue], 0) > 0 
            THEN ROUND((COALESCE(cr.[Campaign Period Revenue], 0) - br.[Baseline Revenue]) * 100.0 / br.[Baseline Revenue], 2)
            ELSE NULL
        END AS [Revenue Growth %],
        -- Calculate normalized scores for ranking (0-100 scale)
        ROUND((cc.[Conversion Rate %] / NULLIF(MAX(cc.[Conversion Rate %]) OVER (), 0)) * 100, 2) AS [Conversion Score],
        ROUND((COALESCE(cr.[Campaign Period Revenue], 0) / NULLIF(MAX(COALESCE(cr.[Campaign Period Revenue], 0)) OVER (), 0)) * 100, 2) AS [Revenue Score]
    FROM CampaignConversion cc
    LEFT JOIN CampaignRevenue cr ON cc.CampaignID = cr.CampaignID
    LEFT JOIN BaselineRevenue br ON cc.TargetCategory = br.Category
)
SELECT
    CampaignID,CampaignName,TargetCategory,StartDate,EndDate,
    [Campaign Duration],[Total Responses],[Interested Count],[Conversion Rate %],[Campaign Revenue],
    [Baseline Revenue],[Revenue Growth %],[Campaign Customers],[Campaign Orders],[Conversion Score],[Revenue Score],
    ROUND(([Conversion Score] * 0.5 + [Revenue Score] * 0.5), 2) AS [Overall Effectiveness Score],
    RANK() OVER (ORDER BY ([Conversion Score] * 0.5 + [Revenue Score] * 0.5) DESC) AS [Effectiveness Rank]
FROM CampaignEffectiveness
ORDER BY [Overall Effectiveness Score] DESC;