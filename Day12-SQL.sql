Create table Genres (
						GenreID int Primary key,
						GenreName varchar (50) not null
					);

Create table Movies (
						MovieID int primary key,
						Title varchar (100) not null,
						GenreID int not null,
						ReleaseYear int not null check (ReleaseYear<=Year(GetDate())),
						foreign key(GenreID) references Genres (GenreID)
					);

Create table Users (
						UserID int primary key,
						Name varchar (50) not null,
						Age int not null CHECK (Age BETWEEN 5 AND 120),
						Country varchar (50) not null
					);

Create table Ratings (
						RatingID int primary key,
						UserID int not null,
						MovieID int not null,
						Rating int not null CHECK (Rating BETWEEN 1 AND 5),
						RatingDate Date not null check (RatingDate BETWEEN '2000-01-01' AND GETDATE()),
						foreign key (UserID) references Users(UserID),
						foreign key (MovieID) references Movies (MovieID)
					);

Create index idx_Movies_GenreID on Movies(GenreID);
Create index idx_Ratings_UserID on Ratings(UserID);
Create index idx_Ratings_MovieID on Ratings(MovieID);

INSERT INTO Genres VALUES
(1, 'Action'),
(2, 'Comedy'),
(3, 'Drama'),
(4, 'Sci-Fi');

INSERT INTO Movies VALUES
(1, 'Sky High', 1, 2012),
(2, 'Laugh Out Loud', 2, 2010),
(3, 'Deep Emotions', 3, 2015),
(4, 'Space Travel', 4, 2020),
(5, 'Classic Adventure', 1, 2005);

INSERT INTO Users VALUES
(1, 'Alice', 25, 'USA'),
(2, 'Bob', 30, 'UK'),
(3, 'Charlie', 28, 'Canada'),
(4, 'Diana', 22, 'USA'),
(5, 'Ethan', 35, 'India');

INSERT INTO Ratings VALUES
(1, 1, 1, 4, '2024-01-01'),
(2, 2, 2, 5, '2024-02-01'),
(3, 3, 1, 3, '2024-03-01'),
(4, 4, 3, 4, '2024-04-01'),
(5, 5, 4, 5, '2024-05-01'),
(6, 1, 4, 2, '2024-06-01'),
(7, 2, 3, 3, '2024-06-15'),
(8, 3, 2, 4, '2024-07-01'),
(9, 5, 2, 3, '2024-07-15');

Select * from Genres 
Select * from Movies 
Select * from Ratings 
Select * from Users 

--1) List all movie titles along with their genres.

SELECT 
    m.Title, g.GenreName
FROM
    Movies m
left JOIN
    Genres g ON m.GenreID = g.GenreID
ORDER BY
    m.Title;

--2) Show the average rating for each movie (include movies with no ratings).

Select
	m.MovieID,m.Title,
	Coalesce (AVG(r.Rating),0) as [Average Rating] 
from 
	Movies m
left join
	Ratings r
on m.MovieID =r.MovieID 
Group by
	m.MovieID,m.Title
Order by
	[Average Rating] Desc;

--3) Find the top 3 movies with the highest average rating (minimum 5 ratings required).

SELECT TOP 3
    m.MovieID, m.Title, 
    AVG(r.Rating) AS [Average Rating], COUNT(r.RatingID) AS [Rating Count]
FROM
    Movies m
JOIN
    Ratings r ON m.MovieID = r.MovieID 
GROUP BY
    m.MovieID, m.Title
HAVING
    COUNT(r.RatingID) >= 5
ORDER BY 
    [Average Rating] DESC;

--4) Count how many movies belong to each genre.

Select
	g.GenreName, Count (m.MovieID) as [Total Movies]
from
	Genres g
left join
	Movies m
on g.GenreID =m.GenreID 
Group by
	g.GenreName
Order by
	[Total Movies] Desc;

--5) List users who have rated more than 10 movies.

SELECT
    u.UserID,u.Name, 
    COUNT(*) AS [Movies Rated]
FROM
    Users u
JOIN
    Ratings r ON u.UserID = r.UserID
GROUP BY
    u.UserID, u.Name
HAVING 
    COUNT(*) > 10
ORDER BY 
    [Movies Rated] DESC;

--6) Show the most recently rated movie and its rating details.

SELECT TOP 1
    m.MovieID,m.Title,
    r.RatingID,r.UserID,u.Name AS [User Name],
    r.Rating,r.RatingDate
FROM
    Ratings r
JOIN
    Movies m ON r.MovieID = m.MovieID
JOIN
    Users u ON r.UserID = u.UserID
ORDER BY
    r.RatingDate DESC; 

--7) Find the average rating given by users from each country.

SELECT
    u.Country,
    ROUND(AVG(r.Rating), 2) AS [Average Rating],
    COUNT(r.RatingID) AS [Total Ratings]
FROM
    Users u
JOIN
    Ratings r ON u.UserID = r.UserID
GROUP BY
    u.Country
ORDER BY
    [Average Rating] DESC;

--8) List the top-rated movie (by average rating) in each genre.

WITH GenreMovieRatings AS (
    SELECT
        g.GenreID,g.GenreName,
        m.MovieID,m.Title,
        AVG(r.Rating) AS AvgRating,
        COUNT(r.RatingID) AS RatingCount,
        ROW_NUMBER() OVER (PARTITION BY g.GenreID ORDER BY AVG(r.Rating) DESC) AS Rank
    FROM
        Genres g
    JOIN
        Movies m ON g.GenreID = m.GenreID
    JOIN
        Ratings r ON m.MovieID = r.MovieID
    GROUP BY
        g.GenreID, g.GenreName, m.MovieID, m.Title
    HAVING
        COUNT(r.RatingID) >= 1  -- Minimum 1 rating requirement
)
SELECT
    GenreName,
    Title AS [Top Rated Movie],
    ROUND(AvgRating, 2) AS [Average Rating],
    RatingCount AS [Number of Ratings]
FROM
    GenreMovieRatings
WHERE
    Rank = 1
ORDER BY
    GenreName;

--9) Identify movies that have never been rated.

SELECT
    m.MovieID,m.Title
FROM
    Movies m
LEFT JOIN
    Ratings r 
ON m.MovieID = r.MovieID
WHERE
    r.RatingID IS NULL
ORDER BY
    m.Title;

--10) For each user, show their highest-rated movie.

WITH UserHighestRatings AS (
    SELECT
        r.UserID, MAX(r.Rating) AS MaxRating
    FROM
        Ratings r
    GROUP BY
        r.UserID
)
SELECT
    u.UserID,u.Name,
    m.MovieID,m.Title,
    uhr.MaxRating AS [Highest Rating],
    r.RatingDate AS [When Rated]
FROM
    Users u
JOIN
    UserHighestRatings uhr ON u.UserID = uhr.UserID
JOIN
    Ratings r ON u.UserID = r.UserID AND uhr.MaxRating = r.Rating
JOIN
    Movies m ON r.MovieID = m.MovieID
ORDER BY
    u.UserID;

--Bonus Challenge
-- Calculate the overall average rating for movies released after 2010, grouped by genre.

SELECT
    g.GenreID,g.GenreName,
    ROUND(AVG(r.Rating), 2) AS [Overall Average Rating],
    COUNT(DISTINCT m.MovieID) AS [Movie Count],
    COUNT(r.RatingID) AS [Rating Count]
FROM
    Genres g
LEFT JOIN
    Movies m ON g.GenreID = m.GenreID AND m.ReleaseYear > 2010
LEFT JOIN
    Ratings r ON m.MovieID = r.MovieID
GROUP BY
    g.GenreID, g.GenreName
HAVING
    COUNT(r.RatingID) > 0  -- Only include genres with ratings
ORDER BY
    [Overall Average Rating] DESC;

