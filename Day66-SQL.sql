Create Table Users(
					UserID INT PRIMARY KEY,
					Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
					Country VARCHAR(30) NOT NULL CHECK(LEN(Country)>=2),
					JoinDate Date NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE()),
					SubscriptionType VARCHAR(30) NOT NULL CHECK(SubscriptionType IN ('Premium','Basic','Standard'))
					);

Create Table Movies (
						MovieID INT PRIMARY KEY,
						Title VARCHAR(50) UNIQUE NOT NULL,
						Genre VARCHAR(30) NOT NULL,
						Duration INT NOT NULL CHECK(Duration>0),
						ReleaseYear INT NOT NULL CHECK(ReleaseYear>1888)
					);

Create Table WatchHistory (
							WatchID INT PRIMARY KEY,
							UserID INT NOT NULL,
							MovieID INT NOT NULL,
							WatchDate DATE NOT NULL CHECK(WatchDate<=GETDATE()),
							WatchDuration INT NOT NULL DEFAULT 0 CHECK(WatchDuration>0),
							Rating INT NOT NULL DEFAULT 0 CHECK(Rating between 0 AND 10),
							UNIQUE(UserID,MovieID,Rating),
							FOREIGN KEY(UserID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY(MovieID) REFERENCES Movies(MovieID) ON UPDATE CASCADE ON DELETE CASCADE
							);

Create Table Payments (
						PaymentID INT PRIMARY KEY,
						UserID INT NOT NULL,
						Amount DECIMAL(10,2) NOT NULL CHECK(Amount>0),
						PaymentDate DATE NOT NULL CHECK(PaymentDate<=GETDATE()),
						PaymentMode VARCHAR(20) NOT NULL CHECK(PaymentMode in ('Card','UPI','Wallet')),
						FOREIGN KEY(UserID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE CASCADE
					);

Create Index Idx_Users_Name_Country on Users(Name,Country);
Create Index Idx_Users_SubscriptionType on Users(SubscriptionType);
Create Index Idx_Movies_Title_Genre on Movies(Title,Genre);
Create Index Idx_Movies_Duration on Movies(Duration);
Create Index Idx_WatchHistory_UserID on WatchHistory(UserID);
Create Index Idx_WatchHistory_MovieID on WatchHistory(MovieID);
Create Index Idx_Payments_UserID on Payments(UserID);
Create Index Idx_Payments_Amount on Payments(Amount);
Create Index Idx_Payments_PaymentDate_PaymentMode on Payments(PaymentDate,PaymentMode);
CREATE INDEX Idx_WatchHistory_WatchDate ON WatchHistory(WatchDate);
CREATE INDEX Idx_Users_JoinDate ON Users(JoinDate);
CREATE INDEX Idx_Movies_ReleaseYear ON Movies(ReleaseYear);

INSERT INTO Users VALUES
(1, 'Priya Nair', 'India', '2021-01-10', 'Premium'),
(2, 'Arjun Sharma', 'India', '2021-03-15', 'Basic'),
(3, 'Emily Brown', 'USA', '2020-11-25', 'Premium'),
(4, 'Ahmed Khan', 'UAE', '2021-05-30', 'Standard'),
(5, 'Maria Garcia', 'Spain', '2021-07-02', 'Premium');

INSERT INTO Movies VALUES
(101, 'Inception', 'Sci-Fi', 148, 2010),
(102, 'The Batman', 'Action', 176, 2022),
(103, 'Frozen II', 'Animation', 103, 2019),
(104, 'Money Heist Finale', 'Thriller', 110, 2021),
(105, 'Dangal', 'Drama', 161, 2016),
(106, 'Avengers Endgame', 'Action', 181, 2019);

INSERT INTO WatchHistory VALUES
(1, 1, 101, '2022-05-12', 120, 9),
(2, 1, 105, '2022-06-01', 161, 8),
(3, 2, 104, '2022-07-11', 60, 7),
(4, 2, 103, '2022-07-13', 103, 6),
(5, 3, 106, '2022-08-01', 181, 9),
(6, 4, 101, '2022-08-05', 100, 8),
(7, 4, 104, '2022-08-06', 90, 7),
(8, 5, 103, '2022-09-01', 103, 8),
(9, 5, 106, '2022-09-05', 181, 9),
(10, 3, 105, '2022-09-07', 150, 8);

INSERT INTO Payments VALUES
(201, 1, 999.00, '2022-01-01', 'Card'),
(202, 2, 499.00, '2022-01-05', 'UPI'),
(203, 3, 999.00, '2022-02-10', 'Wallet'),
(204, 4, 699.00, '2022-03-01', 'Card'),
(205, 5, 999.00, '2022-04-01', 'Card'),
(206, 1, 999.00, '2022-07-01', 'Wallet'),
(207, 3, 999.00, '2022-08-01', 'Card'),
(208, 5, 999.00, '2022-09-01', 'Card');

SELECT * FROM Users;
SELECT * FROM Movies;
SELECT * FROM WatchHistory;
SELECT * FROM Payments;

--1) Join Practice: Display each user’s name, movie title, and their rating.
SELECT
	u.UserID,u.Name,m.MovieID,m.Title,w.Rating
FROM Users u
JOIN WatchHistory w ON u.UserID =w.UserID 
JOIN Movies m ON m.MovieID =w.MovieID 
ORDER BY u.UserID;

--2) Aggregate Query:Find the total hours watched by each user (convert minutes to hours, round to 2 decimals).
SELECT
    u.UserID,u.Name,
    ROUND(SUM(w.WatchDuration) / 60.0, 2) AS TotalHoursWatched
FROM Users u
JOIN WatchHistory w ON u.UserID = w.UserID
GROUP BY u.UserID, u.Name
ORDER BY TotalHoursWatched DESC;

--3) Subquery + Filtering: List movies that have been watched by more than 2 users.
SELECT 
    m.MovieID,m.Title,m.Genre,m.ReleaseYear,UserCount
FROM Movies m
JOIN (
    SELECT 
        MovieID,
        COUNT(DISTINCT UserID) AS UserCount
    FROM WatchHistory
    GROUP BY MovieID
    HAVING COUNT(DISTINCT UserID) > 2
) AS PopularMovies ON m.MovieID = PopularMovies.MovieID
ORDER BY UserCount DESC, m.Title;

--4) CASE + Aggregation: Categorize each user as:
--“Binge Watcher” → avg watch duration > 120
--“Casual Viewer” → avg watch duration 60–120
--“Light Viewer” → avg watch duration < 60
SELECT
    u.UserID,u.Name,u.Country,
    ROUND(AVG(w.WatchDuration), 2) as [Average Watch Duration],
    CASE 
        WHEN AVG(w.WatchDuration) > 120 THEN 'Binge Watcher'
        WHEN AVG(w.WatchDuration) BETWEEN 60 AND 120 THEN 'Casual Viewer'
        ELSE 'Light Viewer'
    END as DurationCategory
FROM Users u
JOIN WatchHistory w ON u.UserID = w.UserID
GROUP BY u.UserID, u.Name, u.Country
ORDER BY [Average Watch Duration] DESC;

--5)CTE + Ranking: Using a CTE, rank users within each country by total watch duration.
WITH CountryWatchStatistics AS (
    SELECT
        u.UserID,u.Name,u.Country,
        ROUND(SUM(w.WatchDuration) / 60.0, 2) AS [Total Watch Hours],
        RANK() OVER (PARTITION BY u.Country ORDER BY SUM(w.WatchDuration) DESC) AS WatchDurationRank
    FROM Users u
    JOIN WatchHistory w ON u.UserID = w.UserID
    GROUP BY u.UserID, u.Name, u.Country)
SELECT
    UserID,Name,Country,[Total Watch Hours],WatchDurationRank
FROM CountryWatchStatistics
ORDER BY Country, WatchDurationRank;

--6) Window Function (LAG): For each user, show the time gap (in days) between consecutive payments.
WITH PaymentGaps AS (
    SELECT
        p.UserID,u.Name,p.PaymentID,p.Amount,p.PaymentDate,p.PaymentMode,
        LAG(p.PaymentDate) OVER (PARTITION BY p.UserID ORDER BY p.PaymentDate) AS PreviousPaymentDate,
        LAG(p.Amount) OVER (PARTITION BY p.UserID ORDER BY p.PaymentDate) AS PreviousAmount
    FROM Payments p
    JOIN Users u ON p.UserID = u.UserID)
SELECT
    UserID,Name,PaymentID,Amount,
    PaymentDate,PaymentMode,PreviousPaymentDate,PreviousAmount,
    DATEDIFF(day, PreviousPaymentDate, PaymentDate) AS DaysBetweenPayments,
    Amount - PreviousAmount AS AmountChange
FROM PaymentGaps
WHERE PreviousPaymentDate IS NOT NULL
ORDER BY UserID, PaymentDate;

--7) Correlated Subquery: Find users who rated above their own average rating for any movie.
WITH UserAverageRatings AS (
    SELECT
        UserID,
        ROUND(AVG(Rating * 1.0), 2) AS AvgRating
    FROM WatchHistory
    GROUP BY UserID)
SELECT 
    u.UserID,u.Name,m.Title,wh.Rating,
    uar.AvgRating AS UserAverageRating,
    (wh.Rating - uar.AvgRating) AS RatingAboveAverage
FROM WatchHistory wh
JOIN Users u ON wh.UserID = u.UserID
JOIN Movies m ON wh.MovieID = m.MovieID
JOIN UserAverageRatings uar ON wh.UserID = uar.UserID
WHERE wh.Rating > uar.AvgRating
ORDER BY u.UserID, RatingAboveAverage DESC;

--8) Analytical Query (NTILE): Divide all users into 3 engagement tiers based on their total watch time.
SELECT
    u.UserID,u.Name,u.Country,
    ROUND(SUM(w.WatchDuration) / 60.0, 2) as [Total Watch Hours],
    NTILE(3) OVER (ORDER BY SUM(w.WatchDuration) DESC) AS EngagementTier
FROM Users u
JOIN WatchHistory w ON u.UserID = w.UserID  -- Fixed: was u.UserID = u.UserID
GROUP BY u.UserID, u.Name, u.Country
ORDER BY EngagementTier, [Total Watch Hours] DESC;

--9) Nested CTE + JOIN: Use nested CTEs to find the most watched genre by each subscription type.
WITH GenreWatchCounts AS (
    SELECT
        u.SubscriptionType,m.Genre,
        COUNT(w.WatchID) AS WatchCount
    FROM Users u
    JOIN WatchHistory w ON u.UserID = w.UserID
    JOIN Movies m ON w.MovieID = m.MovieID
    GROUP BY u.SubscriptionType, m.Genre
),
-- Second CTE: Rank genres within each subscription type
RankedGenres AS (
    SELECT
        SubscriptionType,Genre,WatchCount,
        RANK() OVER (PARTITION BY SubscriptionType ORDER BY WatchCount DESC) AS GenreRank
    FROM GenreWatchCounts
)
-- Final selection: Only the top genre per subscription type
SELECT
    SubscriptionType,Genre AS MostWatchedGenre,WatchCount
FROM RankedGenres
WHERE GenreRank = 1
ORDER BY SubscriptionType, WatchCount DESC;

--10) Real-World Analytical Question (Interview Simulation)
--For each country, find the top movie based on average rating 
--and display how much higher it is compared to the country’s average movie rating (in %).
WITH CountryStats AS (
    SELECT
        u.Country,m.MovieID,m.Title,
        ROUND(AVG(w.Rating * 1.0), 2) AS MovieRating,
        ROUND(AVG(AVG(w.Rating * 1.0)) OVER (PARTITION BY u.Country), 2) AS CountryAvgRating
    FROM Users u
    JOIN WatchHistory w ON u.UserID = w.UserID
    JOIN Movies m ON w.MovieID = m.MovieID
    GROUP BY u.Country, m.MovieID, m.Title
),
RankedMovies AS (
    SELECT
        *,
        ROUND(((MovieRating - CountryAvgRating) / CountryAvgRating) * 100, 2) AS PctAboveAvg,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY MovieRating DESC) AS Rank
    FROM CountryStats
)
SELECT
    Country,Title AS TopMovie,MovieRating,CountryAvgRating,PctAboveAvg
FROM RankedMovies
WHERE Rank = 1
ORDER BY PctAboveAvg DESC;

--11) Bonus Challenge (Complex Analytical Logic): Write a query to find the most loyal Premium user —
--i.e., the user who has maximum months of continuous payment activity without a gap of more than 60 days between payments.
WITH PaymentSegments AS (
    SELECT
        p.UserID,u.Name,p.PaymentDate,
        LAG(p.PaymentDate) OVER (PARTITION BY p.UserID ORDER BY p.PaymentDate) AS PrevDate,
        CASE 
            WHEN DATEDIFF(day, LAG(p.PaymentDate) OVER (PARTITION BY p.UserID ORDER BY p.PaymentDate), p.PaymentDate) <= 60 
            THEN 0 ELSE 1 END AS SegmentStart
    FROM Payments p
    JOIN Users u ON p.UserID = u.UserID
    WHERE u.SubscriptionType = 'Premium'
),
SegmentGroups AS (
    SELECT
        *,
        SUM(SegmentStart) OVER (PARTITION BY UserID ORDER BY PaymentDate) AS SegmentID
    FROM PaymentSegments
),
SegmentStats AS (
    SELECT
        UserID,Name,SegmentID,
        MIN(PaymentDate) AS StartDate,
        MAX(PaymentDate) AS EndDate,
        DATEDIFF(month, MIN(PaymentDate), MAX(PaymentDate)) + 1 AS ContinuousMonths
    FROM SegmentGroups
    GROUP BY UserID, Name, SegmentID
)
SELECT TOP 1
    UserID,Name AS MostLoyalUser,StartDate,EndDate,ContinuousMonths
FROM SegmentStats
ORDER BY ContinuousMonths DESC, DATEDIFF(day, StartDate, EndDate) DESC;


	