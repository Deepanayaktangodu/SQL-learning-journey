Create Table Customers (
							CustomerID INT PRIMARY KEY,
							Name VARCHAR(75) NOT NULL CHECK(LEN(Name)>=2),
							Gender VARCHAR(1) CHECK(Gender IN ('M','F')),
							Age INT NOT NULL CHECK(Age>0),
							City VARCHAR(50) NOT NULL CHECK(LEN(City)>=2),
							SignUpDate DATE NOT NULL CHECK(SignUpDate<=GETDATE())
						);


Create Table Campaigns (
							CampaignID INT PRIMARY KEY,
							CampaignName VARCHAR(75) NOT NULL,
							StartDate DATE NOT NULL DEFAULT GETDATE(),
							EndDate DATE NOT NULL,
							Budget DECIMAL(8,2) NOT NULL CHECK(Budget>0),
							Channel Varchar(20) NOT NULL,
							CHECK (EndDate >= StartDate)
						);


Create Table Interactions (
							InteractionID INT PRIMARY KEY,
							CustomerID INT NOT NULL,
							CampaignID INT NOT NULL,
							InteractionDate DATE NOT NULL CHECK(InteractionDate<=GETDATE()),
							ActionTaken VARCHAR(20) NOT NULL CHECK(ActionTaken IN ('Clicked','Opened','Purchased')),
							Device VARCHAR(20) NOT NULL CHECK(Device IN ('Mobile','Desktop','Tablet')),
							UNIQUE(CustomerID,CampaignID),
							FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION,
							FOREIGN KEY(CampaignID) REFERENCES Campaigns(CampaignID)ON UPDATE CASCADE ON DELETE NO ACTION
						);


Create Table Sales (
						SaleID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						CampaignID INT NOT NULL,
						SaleDate DATE NOT NULL CHECK(SaleDate<=GETDATE()),
						SaleAmount DECIMAL(8,2) NOT NULL CHECK(SaleAmount>0),
						FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION,
						FOREIGN KEY(CampaignID) REFERENCES Campaigns(CampaignID)ON UPDATE CASCADE ON DELETE NO ACTION
					);


Create Index Idx_Customers_Name_Gender_Age_City ON Customers(Name,Gender,Age,City);
Create Index Idx_Customers_SignUpDate ON Customers(SignUpDate);
Create Index Idx_Campaigns_CampaignName_StartDate_EndDate ON Campaigns(CampaignName,StartDate,EndDate);
Create Index Idx_Campaigns_Budget ON Campaigns(Budget);
Create Index Idx_Interactions_CustomerID ON Interactions(CustomerID);
Create Index Idx_Interactions_CampaignID ON Interactions(CampaignID);
Create Index Idx_Interactions_InteractionDate ON Interactions(InteractionDate);
Create Index Idx_Sales_CustomerID ON Sales(CustomerID);
Create Index Idx_Sales_CampaignID ON Sales(CampaignID);
Create Index Idx_Sales_SaleDate ON Sales(SaleDate);
Create Index Idx_Sales_SaleAmount ON Sales(SaleAmount);
CREATE INDEX Idx_Customers_City_Age ON Customers(City, Age);
CREATE INDEX Idx_Customers_SignUpDate_City ON Customers(SignUpDate, City);
CREATE INDEX Idx_Campaigns_DateRange ON Campaigns(StartDate, EndDate);
CREATE INDEX Idx_Campaigns_Channel_Date ON Campaigns(Channel, StartDate);
CREATE INDEX Idx_Interactions_Date_Action ON Interactions(InteractionDate, ActionTaken);
CREATE INDEX Idx_Interactions_Campaign_Action_Date ON Interactions(CampaignID, ActionTaken, InteractionDate);
CREATE INDEX Idx_Sales_Date_Amount ON Sales(SaleDate, SaleAmount);
CREATE INDEX Idx_Sales_Campaign_Date ON Sales(CampaignID, SaleDate);
CREATE INDEX Idx_Sales_Customer_Campaign ON Sales(CustomerID, CampaignID);
CREATE INDEX Idx_Interactions_Customer_Campaign_Date ON Interactions(CustomerID, CampaignID, InteractionDate);

INSERT INTO Customers (CustomerID, Name, Gender, Age, City, SignUpDate) VALUES
(1, 'Priya Nair', 'F', 28, 'Bengaluru', '2021-05-10'),
(2, 'Rohan Mehta', 'M', 33, 'Mumbai', '2020-03-14'),
(3, 'Maria Garcia', 'F', 42, 'Madrid', '2021-01-20'),
(4, 'David Lee', 'M', 36, 'New York', '2019-08-15'),
(5, 'Fatima Noor', 'F', 30, 'Dubai', '2022-02-05'),
(6, 'Arjun Sharma', 'M', 26, 'Delhi', '2020-10-11');

INSERT INTO Campaigns (CampaignID, CampaignName, StartDate, EndDate, Budget, Channel) VALUES
(101, 'Summer Bonanza', '2022-06-01', '2022-06-30', 50000.00, 'Email'),
(102, 'Independence Offer', '2022-08-01', '2022-08-31', 80000.00, 'Social Media'),
(103, 'Festive Discount', '2022-09-15', '2022-10-15', 120000.00, 'Paid Ads'),
(104, 'Winter Clearout', '2022-12-01', '2022-12-31', 60000.00, 'SMS');

INSERT INTO Interactions (InteractionID, CustomerID, CampaignID, InteractionDate, ActionTaken, Device) VALUES
(201, 1, 101, '2022-06-10', 'Clicked', 'Mobile'),
(202, 2, 101, '2022-06-12', 'Opened', 'Desktop'),
(203, 3, 101, '2022-06-15', 'Purchased', 'Tablet'),
(204, 4, 102, '2022-08-05', 'Clicked', 'Mobile'),
(205, 5, 102, '2022-08-07', 'Purchased', 'Desktop'),
(206, 1, 103, '2022-09-20', 'Purchased', 'Mobile'),
(207, 2, 103, '2022-09-22', 'Clicked', 'Mobile'),
(208, 6, 103, '2022-09-25', 'Opened', 'Desktop'),
(209, 3, 104, '2022-12-05', 'Purchased', 'Mobile'),
(210, 4, 104, '2022-12-08', 'Opened', 'Tablet');

INSERT INTO Sales (SaleID, CustomerID, CampaignID, SaleDate, SaleAmount) VALUES
(301, 3, 101, '2022-06-16', 1800.00),
(302, 5, 102, '2022-08-08', 2500.00),
(303, 1, 103, '2022-09-21', 3200.00),
(304, 3, 104, '2022-12-06', 2700.00);

SELECT * FROM Customers;
SELECT * FROM Campaigns;
SELECT * FROM Interactions;
SELECT * FROM Sales;

--1) JOIN Practice
--Display customer name, campaign name, channel, and action taken.
SELECT
	c.CustomerID,c.Name,h.CampaignName,h.Channel,i.ActionTaken
FROM Customers c
JOIN Interactions i ON c.CustomerID =i.CustomerID 
JOIN Campaigns h ON h.CampaignID =i.CampaignID 
ORDER BY c.CustomerID;

--2) CTE + Aggregation
--Calculate total interactions and number of purchases for each campaign.
--Then find the conversion rate = Purchases ÷ Interactions × 100.
WITH CampaignStats AS (
    SELECT
        c.CampaignID,c.CampaignName,
        COUNT(i.InteractionID) AS 'Total Interactions',
        SUM(CASE WHEN i.ActionTaken = 'Purchased' THEN 1 ELSE 0 END) AS TotalPurchases,
        (SUM(CASE WHEN i.ActionTaken = 'Purchased' THEN 1 ELSE 0 END) * 100.0 / COUNT(i.InteractionID)) AS ConversionRate
    FROM Campaigns c
    LEFT JOIN Interactions i ON c.CampaignID = i.CampaignID
    GROUP BY c.CampaignID, c.CampaignName
)
SELECT 
    CampaignID,CampaignName,[Total Interactions],TotalPurchases,
    ROUND(ConversionRate, 2) AS ConversionRate
FROM CampaignStats
ORDER BY ConversionRate DESC;
	
--3) Window Function (RANK)
--Rank campaigns by total sales amount (highest first).
SELECT
    c.CampaignID,c.CampaignName,
    ROUND(SUM(s.SaleAmount), 2) AS TotalSalesAmount,
    RANK() OVER (ORDER BY SUM(s.SaleAmount) DESC) AS SalesRank
FROM Campaigns c
JOIN Sales s ON s.CampaignID = c.CampaignID 
GROUP BY c.CampaignID, c.CampaignName
ORDER BY SalesRank;

--4) Subquery Filtering
--Find customers who participated in more than one campaign.
SELECT 
    c.CustomerID,c.Name,c.City,
    COUNT(DISTINCT i.CampaignID) AS CampaignsParticipated
FROM Customers c
JOIN Interactions i ON c.CustomerID = i.CustomerID
GROUP BY c.CustomerID, c.Name, c.City
HAVING COUNT(DISTINCT i.CampaignID) > 1;

--5) CASE + Conditional Aggregation
--Categorize campaigns based on conversion rate: “Excellent” (>50%), “Good” (30–50%),“Poor” (<30%).
WITH CampaignStats AS (
    SELECT
        c.CampaignID,c.CampaignName,
        COUNT(i.InteractionID) AS 'Total Interactions',
        SUM(CASE WHEN i.ActionTaken = 'Purchased' THEN 1 ELSE 0 END) AS TotalPurchases,
        (SUM(CASE WHEN i.ActionTaken = 'Purchased' THEN 1 ELSE 0 END) * 100.0 / COUNT(i.InteractionID)) AS ConversionRate,
		CASE 
			WHEN (SUM(CASE WHEN i.ActionTaken = 'Purchased' THEN 1 ELSE 0 END) * 100.0 / COUNT(i.InteractionID))>50 THEN 'Excellent'
			WHEN (SUM(CASE WHEN i.ActionTaken = 'Purchased' THEN 1 ELSE 0 END) * 100.0 / COUNT(i.InteractionID)) BETWEEN 30 AND 50
			THEN 'Good'
			ELSE 'Poor'
			END AS CampaignCategory
    FROM Campaigns c
    LEFT JOIN Interactions i ON c.CampaignID = i.CampaignID
    GROUP BY c.CampaignID, c.CampaignName
)
SELECT 
    CampaignID,CampaignName,[Total Interactions],TotalPurchases, CampaignCategory,
    ROUND(ConversionRate, 2) AS ConversionRate
FROM CampaignStats
ORDER BY ConversionRate DESC;

--6) Correlated Subquery
--Find campaigns whose average sale value is higher than the overall average across all campaigns.
SELECT
	c.campaignID,c.CampaignName,
	ROUND(AVG(s.SaleAmount),2) AS AverageSaleValue
FROM Campaigns c
JOIN Sales s ON c.CampaignID =s.CampaignID 
GROUP BY c.CampaignID,c.CampaignName 
HAVING AVG(s.SaleAmount)>(SELECT AVG(SaleAmount) FROM Sales);

--7) Nested CTE + Channel Analysis
--Using nested CTEs, calculate the total budget, total sales, and ROI per channel.
--ROI = (Total Sales ÷ Total Budget) × 100.
WITH ChannelStats AS (
    SELECT
        c.Channel,
        ROUND(SUM(c.Budget), 2) AS 'Total Budget',
        ROUND(SUM(s.SaleAmount), 2) AS 'Total Sales',
        (SUM(s.SaleAmount) / SUM(c.Budget) * 100) AS ROI
    FROM Campaigns c
    JOIN Sales s ON c.CampaignID = s.CampaignID 
    GROUP BY c.Channel)
SELECT 
    Channel,[Total Budget],[Total Sales],
    ROUND(ROI, 2) AS ROI_Percentage
FROM ChannelStats
ORDER BY ROI DESC;

--8) Analytical Query (LAG)
--For each campaign, calculate the number of days between consecutive customer interactions..
WITH InteractionSequence AS (
    SELECT
        CampaignID,CustomerID,InteractionDate,
        LAG(InteractionDate) OVER (PARTITION BY CampaignID, CustomerID ORDER BY InteractionDate) AS PreviousInteractionDate
    FROM Interactions)
SELECT
    c.CampaignName,cust.Name AS CustomerName,
    iseq.CustomerID,iseq.InteractionDate,iseq.PreviousInteractionDate,
    CASE 
        WHEN iseq.PreviousInteractionDate IS NOT NULL THEN
            DATEDIFF(DAY, iseq.PreviousInteractionDate, iseq.InteractionDate)
        ELSE NULL
    END AS DaysBetweenInteractions
FROM InteractionSequence iseq
JOIN Campaigns c ON iseq.CampaignID = c.CampaignID
JOIN Customers cust ON iseq.CustomerID = cust.CustomerID
ORDER BY c.CampaignName, cust.Name, iseq.InteractionDate;

--9) Date Function + Retargeting
--Identify customers who took action again (clicked/purchased) within 15 days of their previous interaction.
WITH InteractionSequence AS (
    SELECT
        CustomerID,InteractionDate,ActionTaken,CampaignID,
        LAG(InteractionDate) OVER (PARTITION BY CustomerID ORDER BY InteractionDate) AS PreviousInteractionDate,
        DATEDIFF(DAY, LAG(InteractionDate) OVER (PARTITION BY CustomerID ORDER BY InteractionDate), InteractionDate
		) AS DaysBetweenInteractions
    FROM Interactions)
SELECT
    c.CustomerID,c.Name,c.City,
    iseq.InteractionDate AS RecentActionDate,iseq.ActionTaken AS RecentAction,
    iseq.PreviousInteractionDate,iseq.DaysBetweenInteractions,camp.CampaignName
FROM InteractionSequence iseq
JOIN Customers c ON iseq.CustomerID = c.CustomerID
JOIN Campaigns camp ON iseq.CampaignID = camp.CampaignID
WHERE iseq.DaysBetweenInteractions IS NOT NULL
  AND iseq.DaysBetweenInteractions <= 15
ORDER BY iseq.DaysBetweenInteractions ASC, c.CustomerID;

--10) Real-World KPI Query (Advanced)
--For each campaign, compute cost per acquisition (CPA) = Budget ÷ Number of Purchases.
--Then find which campaign achieved the lowest CPA.
WITH CampaignPurchases AS (
				SELECT
					c.CampaignID,c.CampaignName,c.Budget,c.Channel,
					COUNT(s.SaleID) AS NumberOfPurchases
				FROM Campaigns c
				JOIN Sales s ON c.CampaignID =s.CampaignID 
				GROUP BY c.CampaignID,c.CampaignName,c.Budget,c.Channel),
CampaignCPA AS (
    SELECT
        CampaignID,CampaignName,Channel,Budget,NumberOfPurchases,
        CASE 
            WHEN NumberOfPurchases > 0 THEN Budget / NumberOfPurchases
            ELSE NULL  -- Handle campaigns with no purchases
        END AS CPA,
        RANK() OVER (ORDER BY 
            CASE 
                WHEN NumberOfPurchases > 0 THEN Budget / NumberOfPurchases
                ELSE NULL
            END ASC
        ) AS CPARank
    FROM CampaignPurchases
)
SELECT
    CampaignID,CampaignName,Channel,Budget,
    NumberOfPurchases,ROUND(CPA, 2) AS CostPerAcquisition,CPARank
FROM CampaignCPA
WHERE CPA IS NOT NULL
ORDER BY CPA ASC;

--11)  Bonus Challenge (Complex Analytical Logic)
--Write a query to identify the most profitable channel, where
--Net ROI = (Total Sales - Total Budget) ÷ Total Budget × 100 and display the top performing campaign within that channel.
WITH ChannelPerformance AS (
    -- Calculate Net ROI for each channel
    SELECT
        c.Channel,
        SUM(c.Budget) AS TotalChannelBudget,
        SUM(COALESCE(s.SaleAmount, 0)) AS TotalChannelSales,
        COUNT(DISTINCT s.SaleID) AS TotalChannelPurchases,
        CASE 
            WHEN SUM(c.Budget) > 0 THEN 
                ((SUM(COALESCE(s.SaleAmount, 0)) - SUM(c.Budget)) / SUM(c.Budget)) * 100
            ELSE NULL
        END AS NetROI_Percent,
        RANK() OVER (ORDER BY 
            CASE 
                WHEN SUM(c.Budget) > 0 THEN 
                    ((SUM(COALESCE(s.SaleAmount, 0)) - SUM(c.Budget)) / SUM(c.Budget)) * 100
                ELSE -999999
            END DESC
        ) AS ChannelRank
    FROM Campaigns c
    LEFT JOIN Sales s ON c.CampaignID = s.CampaignID
    GROUP BY c.Channel
),
CampaignPerformance AS (
    -- Calculate performance metrics for each campaign
    SELECT
        c.CampaignID,c.CampaignName,c.Channel,c.Budget,c.StartDate,c.EndDate,
        COUNT(DISTINCT s.SaleID) AS CampaignPurchases,
        SUM(COALESCE(s.SaleAmount, 0)) AS CampaignSales,
        CASE 
            WHEN c.Budget > 0 THEN 
                ((SUM(COALESCE(s.SaleAmount, 0)) - c.Budget) / c.Budget) * 100
            ELSE NULL
        END AS CampaignNetROI,
        CASE 
            WHEN COUNT(DISTINCT s.SaleID) > 0 THEN c.Budget / COUNT(DISTINCT s.SaleID)
            ELSE NULL
        END AS CPA,
        RANK() OVER (
            PARTITION BY c.Channel 
            ORDER BY 
                CASE 
                    WHEN c.Budget > 0 THEN 
                        ((SUM(COALESCE(s.SaleAmount, 0)) - c.Budget) / c.Budget) * 100
                    ELSE -999999
                END DESC
        ) AS CampaignRankInChannel
    FROM Campaigns c
    LEFT JOIN Sales s ON c.CampaignID = s.CampaignID
    GROUP BY c.CampaignID, c.CampaignName, c.Channel, c.Budget, c.StartDate, c.EndDate
),
TopChannel AS (
    -- Get the top performing channel
    SELECT *
    FROM ChannelPerformance
    WHERE ChannelRank = 1
)
-- Final result: Most profitable channel and its top campaign
SELECT
    'TOP CHANNEL' AS AnalysisType,
    tc.Channel AS MostProfitableChannel,
    ROUND(tc.NetROI_Percent, 2) AS ChannelNetROI_Percent,
    tc.TotalChannelBudget,
    tc.TotalChannelSales,
    tc.TotalChannelPurchases,
    NULL AS CampaignID,
    NULL AS CampaignName,
    NULL AS CampaignNetROI,
    NULL AS CampaignRank
FROM TopChannel tc

UNION ALL

SELECT
    'TOP CAMPAIGN IN CHANNEL' AS AnalysisType,
    cp.Channel,
    NULL AS ChannelNetROI_Percent,
    NULL AS TotalChannelBudget,
    NULL AS TotalChannelSales,
    NULL AS TotalChannelPurchases,
    cp.CampaignID,
    cp.CampaignName,
    ROUND(cp.CampaignNetROI, 2) AS CampaignNetROI,
    cp.CampaignRankInChannel AS CampaignRank
FROM CampaignPerformance cp
WHERE cp.Channel = (SELECT Channel FROM TopChannel)
  AND cp.CampaignRankInChannel = 1
ORDER BY AnalysisType DESC;