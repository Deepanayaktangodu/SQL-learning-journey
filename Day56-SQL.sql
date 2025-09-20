CREATE TABLE Users (
						UserID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2),
						JoinDate DATE NOT NULL DEFAULT GETDATE()
					);

CREATE TABLE Subscriptions (
								SubID INT PRIMARY KEY,
								UserID INT NOT NULL,
								[Plan] VARCHAR(20) NOT NULL CHECK([Plan] in ('Premium','Standard','Basic')),
								StartDate DATE NOT NULL,
								EndDate DATE NOT NULL,
								Status VARCHAR(20) NOT NULL CHECK(Status in ('Expired','Active')),
								FOREIGN KEY (UserID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE CASCADE
							);


CREATE TABLE Movies (
						MovieID INT PRIMARY KEY,
						Title VARCHAR(100) NOT NULL ,
						Genre VARCHAR(50) NOT NULL ,
						ReleaseYear INT NOT NULL CHECK(ReleaseYear>0),
						Duration INT NOT NULL CHECK(Duration>0),
						UNIQUE(Title,ReleaseYear)
					);

CREATE TABLE WatchHistory (
							WatchID INT PRIMARY KEY,
							UserID INT NOT NULL,
							MovieID INT NOT NULL,
							WatchDate DATE NOT NULL CHECK(WatchDate<=GETDATE()),
							WatchDuration INT NOT NULL CHECK(WatchDuration>0),
							UNIQUE(UserID,MovieID,WatchDate),
							FOREIGN KEY (UserID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY (MovieID) REFERENCES Movies(MovieID) ON UPDATE CASCADE ON DELETE CASCADE
							);

CREATE TABLE Ratings (
						RatingID INT PRIMARY KEY,
						UserID INT NOT NULL,
						MovieID INT NOT NULL,
						UNIQUE(UserID,MovieID),
						Rating INT NOT NULL CHECK(Rating BETWEEN 1 AND 5),
						FOREIGN KEY (UserID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE CASCADE,
						FOREIGN KEY (MovieID) REFERENCES Movies(MovieID) ON UPDATE CASCADE ON DELETE CASCADE
					);

Create Index Idx_Users_Name on Users(Name);
Create Index Idx_Users_Country on Users(Country);
Create Index Idx_Subscriptions_Plan on Subscriptions([Plan]);
Create Index Idx_Subscriptions_Status on Subscriptions(Status);
Create Index Idx_Subscriptions_UserID on Subscriptions(UserID);
Create Index Idx_Movies_Title on Movies(Title);
Create Index Idx_Movies_Genre on Movies(Genre);
Create Index Idx_WatchHistory_UserID on WatchHistory(UserID);
Create Index Idx_WatchHistory_MovieID on WatchHistory(MovieID);
Create Index Idx_Ratings_UserID on Ratings(UserID);
Create Index Idx_Ratings_MovieID on Ratings(MovieID);


INSERT INTO Users VALUES
(1, 'Alice', 'USA', '2020-01-15'),
(2, 'Bob', 'UK', '2019-03-22'),
(3, 'Charlie', 'India', '2021-07-19'),
(4, 'David', 'Canada', '2022-11-11'),
(5, 'Eva', 'USA', '2018-05-01');

INSERT INTO Subscriptions VALUES
(101, 1, 'Premium', '2020-01-15', '2021-01-14', 'Expired'),
(102, 1, 'Premium', '2021-01-15', '2022-01-14', 'Expired'),
(103, 1, 'Premium', '2022-01-15', '2023-01-14', 'Active'),
(104, 2, 'Standard', '2019-03-22', '2020-03-21', 'Expired'),
(105, 2, 'Standard', '2020-03-22', '2021-03-21', 'Expired'),
(106, 3, 'Basic', '2021-07-19', '2022-07-18', 'Expired'),
(107, 3, 'Basic', '2022-07-19', '2023-07-18', 'Active'),
(108, 4, 'Premium', '2022-11-11', '2023-11-10', 'Active'),
(109, 5, 'Standard', '2018-05-01', '2019-04-30', 'Expired');

INSERT INTO Movies VALUES
(201, 'Inception', 'Sci-Fi', 2010, 148),
(202, 'Titanic', 'Romance', 1997, 195),
(203, 'The Dark Knight', 'Action', 2008, 152),
(204, 'Interstellar', 'Sci-Fi', 2014, 169),
(205, 'The Godfather', 'Crime', 1972, 175);

INSERT INTO WatchHistory VALUES
(301, 1, 201, '2022-02-15', 120),
(302, 1, 204, '2022-03-10', 169),
(303, 2, 202, '2020-05-12', 100),
(304, 3, 203, '2022-08-20', 150),
(305, 3, 201, '2023-01-05', 140),
(306, 4, 205, '2023-03-11', 175),
(307, 5, 202, '2018-06-01', 195);

INSERT INTO Ratings VALUES
(401, 1, 201, 5),
(402, 1, 204, 4),
(403, 2, 202, 3),
(404, 3, 203, 4),
(405, 3, 201, 5),
(406, 4, 205, 5),
(407, 5, 202, 4);

SELECT* FROM Users;
SELECT * FROM Subscriptions;
SELECT * FROM Movies;
SELECT * FROM WatchHistory;
SELECT * FROM Ratings;

--1) Find the top 3 movies by average rating.
SELECT TOP 3
	m.MovieID,m.Title,m.Genre,
	ROUND(AVG(r.Rating),2) as [Average Rating],
	 COUNT(r.Rating) as [Number of Ratings]
FROM Movies m
JOIN Ratings r ON m.MovieID =r.MovieID 
GROUP BY M.MovieID,M.Title,M.Genre
ORDER BY [Average Rating] DESC;

--2) List users who have watched movies in more than 2 different genres.
SELECT
	u.UserID,u.Name as 'User Name',u.Country,
	COUNT(DISTINCT m.Genre) as [Genre Count],
	COUNT(DISTINCT w.WatchID) as [Movie Count]
FROM Users u
JOIN WatchHistory w ON u.UserID =w.UserID 
JOIN Movies m ON m.MovieID=w.MovieID 
GROUP BY u.UserID,u.Name,u.Country 
HAVING COUNT(DISTINCT m.Genre)>2
ORDER BY u.UserID;

--3) Find the churn rate: number of users whose last subscription status = 'Expired'.
WITH LatestSubscriptions AS (
    SELECT 
        UserID,Status,EndDate,
        ROW_NUMBER() OVER (PARTITION BY UserID ORDER BY EndDate DESC) as rn
    FROM Subscriptions
)
SELECT
    COUNT(UserID) as [Churned Users Count]
FROM LatestSubscriptions
WHERE rn = 1 AND Status = 'Expired';

--4) For each country, show the total watch hours contributed by users.
SELECT
    u.Country,
    ROUND(SUM(w.WatchDuration), 2) as [Total Watch Hours],
    ROUND(SUM(w.WatchDuration) * 100.0 / (SELECT SUM(WatchDuration) FROM WatchHistory), 2) as [% Contribution]
FROM Users u
JOIN WatchHistory w ON u.UserID = w.UserID 
GROUP BY u.Country 
ORDER BY [% Contribution] DESC;

--5) Identify binge-watchers: users who watched more than 300 minutes in a single day.
SELECT
    u.UserID,u.Name as [User Name],u.Country,
    CAST(w.WatchDate as DATE) as [Watch Date],
    SUM(w.WatchDuration) as [Total Minutes Watched],
    COUNT(w.WatchID) as [Number of Sessions]
FROM Users u
JOIN WatchHistory w ON u.UserID = w.UserID 
GROUP BY u.UserID, u.Name, u.Country, CAST(w.WatchDate as DATE)
HAVING SUM(w.WatchDuration) > 300
ORDER BY [Total Minutes Watched] DESC;

--6) Find the most-watched genre based on total watch duration.
SELECT TOP 1
	m.Genre,
	SUM(w.WatchDuration) as [Total Watch Duration]
FROM Movies m
JOIN WatchHistory w ON m.MovieID =w.MovieID 
GROUP BY m.Genre 
ORDER BY [Total Watch Duration] DESC;

--7) Show users who downgraded their subscription (e.g., Premium to Standard/Basic).
WITH SubscriptionHistory AS (
    SELECT 
        UserID,[Plan],
        StartDate,EndDate,Status,
        LAG([Plan]) OVER (PARTITION BY UserID ORDER BY StartDate) as PreviousPlan,
        ROW_NUMBER() OVER (PARTITION BY UserID ORDER BY StartDate DESC) as rn
    FROM Subscriptions
),
Downgrades AS (
    SELECT 
        UserID,PreviousPlan as [From Plan],
        [Plan] as [To Plan],StartDate as [Downgrade Date],Status
    FROM SubscriptionHistory
    WHERE rn = 1 -- Most recent subscription
    AND PreviousPlan IS NOT NULL -- Ensure there was a previous subscription
    AND (
        (PreviousPlan = 'Premium' AND [Plan] IN ('Standard', 'Basic')) OR
        (PreviousPlan = 'Standard' AND [Plan] = 'Basic')
    )
)
SELECT 
    u.UserID,u.Name as [User Name],u.Country,
    d.[From Plan],d.[To Plan],d.[Downgrade Date],d.Status
FROM Downgrades d
JOIN Users u ON d.UserID = u.UserID
ORDER BY d.[Downgrade Date] DESC;

--8) Using a window function, calculate the running total of minutes watched per user ordered by WatchDate.
SELECT
    u.UserID,u.Name as [User Name],
    CAST(w.WatchDate as DATE) as [Watch Date],
    SUM(w.WatchDuration) as [Daily Minutes],
    SUM(SUM(w.WatchDuration)) OVER (PARTITION BY u.UserID ORDER BY CAST(w.WatchDate as DATE)) as [Running Total Minutes],
    ROUND(SUM(SUM(w.WatchDuration)) OVER (PARTITION BY u.UserID ORDER BY CAST(w.WatchDate as DATE)) / 60.0, 2) as [Running Total Hours]
FROM Users u
JOIN WatchHistory w ON u.UserID = w.UserID
GROUP BY u.UserID, u.Name, CAST(w.WatchDate as DATE)
ORDER BY u.UserID, [Watch Date];

--9) Find movies that are watched but never rated.
SELECT
    m.MovieID,m.Title,m.Genre
FROM Movies m
JOIN WatchHistory w ON m.MovieID = w.MovieID  -- Ensure movie was watched
LEFT JOIN Ratings r ON m.MovieID = r.MovieID 
WHERE r.Rating IS NULL
GROUP BY m.MovieID, m.Title, m.Genre
ORDER BY m.Title;

--10) List users who re-subscribed within 30 days after their subscription expired.
WITH SubscriptionHistory AS (
    SELECT 
        UserID,StartDate,EndDate,Status,
        LEAD(StartDate) OVER (PARTITION BY UserID ORDER BY StartDate) as NextStartDate,
        DATEDIFF(DAY, EndDate, LEAD(StartDate) OVER (PARTITION BY UserID ORDER BY StartDate)) as DaysToResubscribe
    FROM Subscriptions
)
SELECT 
    u.UserID,u.Name as [User Name],u.Country,
    sh.StartDate as [Previous End Date],
    sh.EndDate as [Previous End Date],
    sh.NextStartDate as [Resubscription Date],
    sh.DaysToResubscribe as [Days Between]
FROM SubscriptionHistory sh
JOIN Users u ON sh.UserID = u.UserID
WHERE sh.Status = 'Expired'
AND sh.NextStartDate IS NOT NULL
AND sh.DaysToResubscribe BETWEEN 0 AND 30
ORDER BY sh.DaysToResubscribe;

--11) Build a query to calculate the Customer Lifetime Value (CLV) for each user:
--CLV = SUM(TotalAmountPaid) / Number of Years as Customer
--Assume Premium = $15/month, Standard = $10/month, Basic = $5/month.
WITH UserSubscriptionRevenue AS (
    SELECT 
        s.UserID,
        SUM(CASE 
            WHEN s.[Plan]  = 'Premium' THEN DATEDIFF(MONTH, s.StartDate, s.EndDate) * 15
            WHEN s.[Plan]  = 'Standard' THEN DATEDIFF(MONTH, s.StartDate, s.EndDate) * 10
            WHEN s.[Plan]  = 'Basic' THEN DATEDIFF(MONTH, s.StartDate, s.EndDate) * 5
        END) as TotalAmountPaid,
        DATEDIFF(DAY, MIN(s.StartDate), MAX(s.EndDate)) / 365.0 as YearsAsCustomer
    FROM Subscriptions s
    GROUP BY s.UserID
)
SELECT 
    u.UserID,u.Name as [User Name],u.Country,
    COALESCE(usr.TotalAmountPaid, 0) as [Total Amount Paid],
    ROUND(COALESCE(usr.YearsAsCustomer, 0), 2) as [Years as Customer],
    CASE 
        WHEN COALESCE(usr.YearsAsCustomer, 0) > 0 
        THEN ROUND(COALESCE(usr.TotalAmountPaid, 0) / usr.YearsAsCustomer, 2)
        ELSE 0 
    END as [CLV]
FROM Users u
LEFT JOIN UserSubscriptionRevenue usr ON u.UserID = usr.UserID
ORDER BY [CLV] DESC;