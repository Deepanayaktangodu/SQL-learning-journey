Create table Users (
					UserID Int Primary Key,
					Name Varchar(50) Not Null Check(Len(Name)>=2),
					Country Varchar(50) Not Null Check(Len(Country)>=2),
					JoinDate Date Not Null Default GetDate() Check(JoinDate<=GetDate()),
					SubscriptionType Varchar(50) Not Null Check(SubscriptionType in ('Premium','Standard','Basic'))
					);

Create table Movies(
					MovieID Int Primary Key,
					Title Varchar(75) Not Null Unique,
					Genre Varchar(30) Not Null Check(Len(Genre)>=2),
					ReleaseYear Int Not Null Check(ReleaseYear>1888),
					Duration Int Not Null Check(Duration>0)
					);

Create table WatchHistory(
							WatchID Int Primary Key,
							UserID Int Not Null,
							MovieID Int Not Null,
							WatchDate Date Not Null Default GetDate() Check (WatchDate<=GetDate()),
							WatchDuration Int Not Null Check(WatchDuration>0),
							Rating int Not Null Check(Rating between 1 and 5),
							Foreign Key(UserId) references Users(UserID) on update cascade on delete no action,
							Foreign Key(MovieID) references Movies(MovieID) on update cascade on delete no action
						);

Create Index Idx_Users_Name on Users(Name);
Create Index Idx_Users_Country on Users(Country);
Create Index Idx_Users_SubscriptionType on Users(SubscriptionType);
Create Index Idx_Movies_Title on Movies(Title);
Create Index Idx_Movies_Genre on Movies(Genre);
Create Index Idx_Movies_Duration on Movies(Duration);
Create Index Idx_WatchHistory_UserID on WatchHistory(UserID);
Create Index Idx_WatchHistory_MovieID on WatchHistory(MovieID);

INSERT INTO Users (UserID, Name, Country, JoinDate, SubscriptionType) VALUES
(1, 'Alice', 'USA', '2021-01-01', 'Premium'),
(2, 'Bob', 'India', '2021-03-15', 'Standard'),
(3, 'Charlie', 'UK', '2022-02-10', 'Premium'),
(4, 'David', 'Canada', '2022-05-20', 'Basic'),
(5, 'Emma', 'India', '2023-01-12', 'Premium');

INSERT INTO Movies (MovieID, Title, Genre, ReleaseYear, Duration) VALUES
(101, 'SQL Unlocked', 'Documentary', 2022, 90),
(102, 'Data Science 101', 'Education', 2021, 120),
(103, 'AI Future', 'Sci-Fi', 2023, 150),
(104, 'Cloud Wars', 'Drama', 2022, 100),
(105, 'Python Mastery', 'Education', 2023, 110);

INSERT INTO WatchHistory (WatchID, UserID, MovieID, WatchDate, WatchDuration, Rating) VALUES
(1, 1, 101, '2022-01-10', 90, 5),
(2, 2, 102, '2022-02-15', 100, 4),
(3, 3, 103, '2023-01-05', 150, 5),
(4, 4, 104, '2023-02-20', 80, 3),
(5, 5, 105, '2023-03-01', 110, 4),
(6, 1, 103, '2023-03-10', 140, 5),
(7, 2, 101, '2023-04-01', 85, 4),
(8, 3, 105, '2023-04-15', 100, 5),
(9, 4, 102, '2023-05-01', 110, 3),
(10, 5, 104, '2023-05-20', 90, 4);

Select * from Users 
Select * from Movies 
Select * from WatchHistory 

--1) Most Watched Genre
--Find the genre with the highest total watch duration.
Select Top 1
	m.Genre,
	ROUND(SUM(w.WatchDuration),2) as [Total Watch Duration]
from Movies m
join WatchHistory w on m.MovieID =w.MovieID 
group by m.Genre 
order by SUM(w.WatchDuration) Desc;

--2) Top Rated Movies
--List movies with an average rating above 4.5.
SELECT
    m.MovieID,m.Title as 'Movie Title',m.Genre,
    ROUND(AVG(w.Rating), 2) as [Average Rating],
    COUNT(w.Rating) as [Number of Ratings]
FROM Movies m
JOIN WatchHistory w ON m.MovieID = w.MovieID 
GROUP BY m.MovieID, m.Title, m.Genre
HAVING AVG(w.Rating) > 4.5
ORDER BY [Average Rating] DESC;

--3) User Engagement
--Find users who watched more than 2 movies.
Select
	u.UserID,u.Name as 'User Name',u.Country,
	COUNT(Distinct w.WatchID) as [Watched Movies Count]
from Users u 
join WatchHistory w on u.UserID=w.UserID 
group by u.UserID,u.Name,u.Country 
having COUNT(Distinct w.WatchID)>2
order by [Watched Movies Count] Desc;

--4) Monthly Active Users (MAU)
--Count distinct active users per month.
SELECT
    FORMAT(w.WatchDate, 'yyyy-MM') as [Month],
    DATENAME(MONTH, w.WatchDate) as [Month Name],
    COUNT(DISTINCT w.UserID) as [Monthly Active Users]
FROM WatchHistory w
GROUP BY 
    FORMAT(w.WatchDate, 'yyyy-MM'),
    DATENAME(MONTH, w.WatchDate),
    MONTH(w.WatchDate)  -- Added for proper ordering
ORDER BY 
    FORMAT(w.WatchDate, 'yyyy-MM');  -- Order by year-month string

--5) Genre Popularity Ranking
--Rank genres by total number of unique viewers.
Select
	m.Genre,
	COUNT(DISTINCT w.UserID) as [Unique Users],
	RANK() OVER (Order by COUNT(DISTINCT w.UserID) Desc) as PopularityRank
from Movies m
join WatchHistory w on m.MovieID =w.MovieID 
group by m.Genre 
order by [Unique Users] Desc;

--6) Repeat Watchers
--Identify users who watched the same movie more than once.
SELECT
    u.UserID,u.Name as 'User Name',u.Country,
    m.MovieID,m.Title as 'Movie Title',
    COUNT(w.WatchID) as [Times Watched],
    MIN(w.WatchDate) as [First Watch],
    MAX(w.WatchDate) as [Last Watch]
FROM Users u
JOIN WatchHistory w ON u.UserID = w.UserID
JOIN Movies m ON w.MovieID = m.MovieID
GROUP BY u.UserID, u.Name, u.Country, m.MovieID, m.Title
HAVING COUNT(w.WatchID) > 1
ORDER BY [Times Watched] DESC, u.Name;

--7) Subscription Value Analysis
--Find the average watch duration for each subscription type.
Select
	u.SubscriptionType,
	ROUND(AVG(w.WatchDuration),2) as [Average Watch Duration]
from Users u
join WatchHistory w on u.UserID =w.UserID 
group by u.SubscriptionType 
order by [Average Watch Duration] Desc;

--8)Window Function – User Timeline
--For each user, show their watch history with previous movie watched (LAG).
SELECT
    u.UserID,u.Name as 'User Name',
    w.WatchID,w.WatchDate,
    m.MovieID,m.Title as 'Current Movie',m.Genre as 'Current Genre',
    LAG(m.Title) OVER (PARTITION BY w.UserID ORDER BY w.WatchDate) as 'Previous Movie',
    LAG(m.Genre) OVER (PARTITION BY w.UserID ORDER BY w.WatchDate) as 'Previous Genre',
    LAG(w.WatchDate) OVER (PARTITION BY w.UserID ORDER BY w.WatchDate) as 'Previous Watch Date'
FROM WatchHistory w
JOIN Users u ON w.UserID = u.UserID
JOIN Movies m ON w.MovieID = m.MovieID
ORDER BY u.UserID, w.WatchDate;

--9) Churn Prediction
--Find users who have not watched anything in the last 90 days from max watch date.
SELECT
    u.UserID,u.Name as 'User Name',u.Country,u.JoinDate,
    MIN(w.WatchDate) as [First Watch Date],
    MAX(w.WatchDate) as [Latest Watch Date],
    COUNT(w.WatchID) as [Total Watches],
    DATEDIFF(DAY, MAX(w.WatchDate), GETDATE()) as [Days Since Last Watch],
    CASE 
        WHEN DATEDIFF(DAY, MAX(w.WatchDate), GETDATE()) > 90 THEN 'Churned'
        ELSE 'Active'
    END as [User Status]
FROM Users u
LEFT JOIN WatchHistory w ON u.UserID = w.UserID
GROUP BY u.UserID, u.Name, u.Country, u.JoinDate
HAVING MAX(w.WatchDate) IS NULL OR DATEDIFF(DAY, MAX(w.WatchDate), GETDATE()) > 90
ORDER BY [Days Since Last Watch] DESC;

--10) Country-Wise Viewing Habits
--Show total viewing hours and average rating per country.
Select
	u.Country,
	ROUND(SUM(w.WatchDuration),2) as [Total Viewing Duration],
	ROUND(AVG(w.Rating),2) as [Average Rating]
from Users u
join WatchHistory w on u.UserID =w.UserID 
group by u.Country
order by [Total Viewing Duration],[Average Rating] Desc;

--Bonus Challenge (Advanced)
--11)Binge-Watching Detection: A binge session = Watching more than 2 movies within 7 days.
--Write a query to detect which users engaged in binge-watching.
WITH BingeWindows AS (
    SELECT
        w1.UserID,u.Name as UserName,u.Country,w1.WatchDate as StartDate,
        DATEADD(DAY, 7, w1.WatchDate) as EndDate,
        COUNT(DISTINCT w2.MovieID) as MoviesInWindow,
        ROUND(SUM(w2.WatchDuration), 2) as TotalDuration,
        MIN(w2.WatchDate) as FirstWatchInWindow,
        MAX(w2.WatchDate) as LastWatchInWindow
    FROM WatchHistory w1
    JOIN Users u ON w1.UserID = u.UserID
    JOIN WatchHistory w2 ON w1.UserID = w2.UserID
        AND w2.WatchDate BETWEEN w1.WatchDate AND DATEADD(DAY, 7, w1.WatchDate)
    GROUP BY w1.UserID, u.Name, u.Country, w1.WatchDate
    HAVING COUNT(DISTINCT w2.MovieID) > 2
)
SELECT
    UserID,UserName,Country,
    StartDate as BingeStartDate,EndDate as BingeEndDate,
    MoviesInWindow as [Movies Watched],TotalDuration as [Total Binge Hours],
    DATEDIFF(DAY, StartDate, EndDate) as [Binge Duration Days],
    CASE 
        WHEN MoviesInWindow >= 5 THEN 'Heavy Binger'
        WHEN MoviesInWindow >= 3 THEN 'Moderate Binger'
        ELSE 'Light Binger'
    END as BingeIntensity
FROM BingeWindows
ORDER BY MoviesInWindow DESC, TotalDuration DESC;