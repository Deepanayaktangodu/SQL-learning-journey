Create table Users (
					UserID int primary key,
					Name varchar (30) not null,
					Age int not null check (Age>=13),
					Country varchar(30) not null
					);

Create table Shows (
					ShowID int primary key,
					Title varchar(75) not null,
					Genre varchar(25) not null,
					ReleaseYear bigint not null CHECK (ReleaseYear > 1900 AND ReleaseYear <= YEAR(GETDATE()))
					);

Create table Views (
					ViewID int primary key,
					UserID int not null,
					ShowID int not null,
					WatchDate date not null default getdate() check (WatchDate<=getdate()),
					WatchDuration int not null check (WatchDuration>0),
					foreign key (UserID) references Users(UserID) on delete cascade,
					foreign key (ShowID) references Shows (ShowID)
					);

Create table Ratings (
						RatingID int primary key,
						UserID int not null,
						ShowID int not null,
						Rating int not null check (Rating between 1 and 5),
						foreign key (UserID) references Users(UserID) on delete cascade,
						foreign key (ShowID) references Shows(ShowID) on delete cascade,
						UNIQUE (UserID, ShowID)
						);

Create Index Idx_Views_UserID on Views(UserID);
Create Index Idx_Views_ShowID on Views (ShowID);
Create Index Idx_Ratings_UserID on Ratings(UserID);
Create Index Idx_Ratings_ShowID on Ratings(ShowID);

INSERT INTO Users (UserID, Name, Age, Country) VALUES
(1, 'Alice', 25, 'USA'),
(2, 'Bob', 32, 'UK'),
(3, 'Chitra', 29, 'India'),
(4, 'Diego', 41, 'Mexico'),
(5, 'Eva', 20, 'Germany');

INSERT INTO Shows (ShowID, Title, Genre, ReleaseYear) VALUES
(101, 'Mind Bender', 'Thriller', 2022),
(102, 'Laugh Riot', 'Comedy', 2021),
(103, 'Code Wars', 'Drama', 2020),
(104, 'True Tails', 'Documentary', 2023),
(105, 'Space Race', 'Sci-Fi', 2022);

INSERT INTO Views (ViewID, UserID, ShowID, WatchDate, WatchDuration) VALUES
(1001, 1, 101, '2024-07-01', 60),
(1002, 2, 102, '2024-07-02', 45),
(1003, 3, 101, '2024-07-03', 55),
(1004, 4, 103, '2024-07-04', 30),
(1005, 5, 104, '2024-07-05', 25),
(1006, 1, 105, '2024-07-06', 90),
(1007, 2, 105, '2024-07-07', 60);

INSERT INTO Ratings (RatingID, UserID, ShowID, Rating) VALUES
(201, 1, 101, 4),
(202, 2, 102, 5),
(203, 3, 101, 3),
(204, 4, 103, 2),
(205, 5, 104, 5),
(206, 1, 105, 4),
(207, 2, 105, 5);

Select *from Users 
Select *from Shows 
Select * from Views 
Select *from Ratings

--1) List all users with the total number of shows watched.

Select
	u.UserID,u.Name as 'User Name',
	Count (Distinct V.ShowID) as [Number of Shows Watched]
from
	Users u
left join
	Views v
on u.UserID =v.UserID 
Group by
	u.UserID,u.Name
Order by
	[Number of Shows Watched] Desc;

--1) List all users with the total number of shows watched.
Select
	u.UserID,u.Name as 'User Name',
	Count (V.ShowID) as [Number of Shows Watched]
from
	Users u
left join
	Views v
on u.UserID =v.UserID 
Group by
	u.UserID,u.Name
Order by
	[Number of Shows Watched] Desc;

--2) Show the average watch duration per genre.
Select
	s.Genre, Round(AVG(v.WatchDuration),2) as  [AVG Watch Duration]
from
	Shows s
left join
	Views v
on s.ShowID =v.ShowID
Group by
	s.Genre
Order by
	[AVG Watch Duration] Desc;

--3) Find the most-watched show (based on total duration watched).
SELECT TOP 1
    s.ShowID,s.Title AS 'Show Name',
    SUM(ISNULL(v.WatchDuration, 0)) AS 'Total Watch Duration'
FROM
    Shows s
LEFT JOIN
    Views v ON s.ShowID = v.ShowID
GROUP BY
    s.ShowID, s.Title
ORDER BY
    'Total Watch Duration' DESC;

--4) Display users who watched a show but didn't rate it.
SELECT DISTINCT
    u.UserID,u.Name AS 'User Name'
FROM
    Users u
JOIN
    Views v ON u.UserID = v.UserID
LEFT JOIN
    Ratings r ON u.UserID = r.UserID AND v.ShowID = r.ShowID
WHERE
    r.RatingID IS NULL;

--5) List all shows that were watched by at least 3 different users.
SELECT
    s.ShowID,s.Title AS 'Show Name',
    COUNT(DISTINCT v.UserID) AS 'Users Watched'
FROM
    Shows s
JOIN
    Views v ON s.ShowID = v.ShowID
GROUP BY
    s.ShowID, s.Title
HAVING
    COUNT(DISTINCT v.UserID) >3; 

--6)  Show the top-rated show (average rating) per genre.
WITH GenreShowRatings AS (
    SELECT 
        s.Genre,s.ShowID,s.Title AS 'Show Name',
        AVG(r.Rating * 1.0) AS 'Average Rating',
        COUNT(r.RatingID) AS 'RatingCount',
        RANK() OVER (PARTITION BY s.Genre ORDER BY AVG(r.Rating * 1.0) DESC) AS 'GenreRank'
    FROM 
        Shows s
    LEFT JOIN 
        Ratings r ON s.ShowID = r.ShowID
    GROUP BY 
        s.Genre, s.ShowID, s.Title)
SELECT 
    Genre,ShowID,'Show Name',
    'Average Rating',RatingCount
FROM 
    GenreShowRatings
WHERE 
    GenreRank = 1
    AND RatingCount > 0 
ORDER BY 
    Genre;

--7) List users who watched shows from more than 2 different genres.

SELECT 
    u.UserID,u.Name AS 'User Name',
    COUNT(DISTINCT s.Genre) AS 'Distinct Genres Watched'
FROM 
    Users u
JOIN 
    Views v ON u.UserID = v.UserID
JOIN 
    Shows s ON v.ShowID = s.ShowID
GROUP BY 
    u.UserID, u.Name
HAVING 
    COUNT(DISTINCT s.Genre) > 2
ORDER BY 
    'Distinct Genres Watched' DESC;

-- 8) Display all shows not watched by anyone.
SELECT
    s.ShowID,s.Title AS 'Show Name',
    s.Genre,s.ReleaseYear
FROM
    Shows s
LEFT JOIN
    Views v ON s.ShowID = v.ShowID
WHERE 
    v.ViewID IS NULL
ORDER BY
    s.Title;

--9) For each country, show the average watch duration by users.
SELECT
    u.Country,
    ROUND(AVG(ISNULL(v.WatchDuration, 0)), 2) AS 'Average Watch Duration (mins)',
    COUNT(DISTINCT u.UserID) AS 'Number of Users',
    COUNT(v.ViewID) AS 'Total Views'
FROM
    Users u
LEFT JOIN
    Views v ON u.UserID = v.UserID
GROUP BY
    u.Country
ORDER BY
    'Average Watch Duration (mins)' DESC;

--10) Find the top 2 users who gave the most number of 5-star ratings.
SELECT TOP 2
    u.UserID,u.Name AS 'User Name',
    COUNT(r.RatingID) AS 'Number of 5-Star Ratings'
FROM
    Users u
JOIN
    Ratings r ON u.UserID = r.UserID
WHERE
    r.Rating = 5
GROUP BY
    u.UserID, u.Name
ORDER BY
    'Number of 5-Star Ratings' DESC;

--Bonus Challenge:
--Identify shows released after 2021 that received only ratings 4 or above from at least 3 different users.
SELECT 
    s.ShowID,s.Title AS 'Show Name',s.ReleaseYear,
    MIN(r.Rating) AS 'MinRating',
    COUNT(DISTINCT r.UserID) AS 'Number of Users Rated'
FROM
    Shows s
JOIN
    Ratings r ON s.ShowID = r.ShowID
WHERE
    s.ReleaseYear > 2021
GROUP BY
    s.ShowID, s.Title, s.ReleaseYear
HAVING
    COUNT(DISTINCT r.UserID) >= 3
    AND MIN(r.Rating) >= 4  
ORDER BY
    'Number of Users Rated' DESC;