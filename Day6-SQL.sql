Create Table Books(
					BookID int Primary key,
					Title varchar (150) not null,
					AuthorID bigint not null,
					Genre varchar (75) not null,
					Price bigint not null check (Price>0),
					foreign key (AuthorID) references Authors(AuthorID)
					);

CREATE INDEX idx_books_authorid ON Books(AuthorID);

Create Table Authors(
						AuthorID bigint Primary key,
						AuthorName varchar (100) not null,
						Country char (75) not null
						);

Create Table Sales(
					SaleID bigint Primary key,
					BookID int not null,
					SaleDate date not null check(SaleDate<= GETDATE()),
					Quantity bigint not null check (Quantity>0),
					foreign key (BookID) references Books(BookID)
					);

CREATE INDEX idx_sales_bookid ON Sales(BookID);

Insert into Books (BookID, Title, AuthorID, Genre, Price)
Values
	(1,'Data Science 101',101,'Technology',600),
	(2,'AI for All',101,'Technology',800),
	(3,'Python Tricks',102,'Programming',500),
	(4,'Modern History',103,'History',400),
	(5,'The World of Plants',104,'Biology',350),
	(6,'Big Data Basics',101,'Technology',750)

Insert into Authors(AuthorID,AuthorName,Country)
Values
	(101,'Ravi Mehra','India'),
	(102,'Sara James','USA'),
	(103,'Vikram Joshi','India'),
	(104,'Lena Gupta','UK')

Insert into Sales(SaleID, BookID, SaleDate, Quantity)
Values 
	(201,1,'2023-01-10',5),
	(202,2,'2023-01-11',3),
	(203,3,'2023-01-13',7),
	(204,1,'2023-01-14',2),
	(205,5,'2023-01-16',4),
	(206,6,'2023-01-17',6)

Select * from Authors 
Select * from Books 
Select * from Sales 

-- 1) List all book titles along with their author names and country.

Select
	b.Title,a.AuthorName,a.Country
from
	Authors a
join
	Books b
on a.AuthorID =b.AuthorID;

-- 2) Show total sales (revenue) per book.

Select 
	b.BookID, b.Title,sum (b.Price*s.Quantity) as [Total Sales]
from
	Books b
join
	Sales s
on b.BookID = s.BookID 
Group by
	b.Title,b.BookID 
Order by
	[Total Sales] Desc;

-- 3) Find the total quantity sold per genre.

Select 
	b.BookID,b.Genre, sum(s.Quantity ) as [Total Quantity]
from
	Books b
join
	Sales s
on b.BookID =s.BookID 
Group by
	b.Genre,b.BookID 
Order by
	[Total Quantity] Desc;

-- 4) List authors who have more than one book listed.

-- 4) List authors who have more than one book listed

SELECT
	a.AuthorID, a.AuthorName,COUNT(b.BookID) AS BookCount
FROM
    Authors a
JOIN
    Books b ON a.AuthorID = b.AuthorID
GROUP BY
    a.AuthorID, a.AuthorName
HAVING
    COUNT(b.BookID) > 1;

-- 5) Identify the highest selling book by quantity.

SELECT TOP 1
	b.BookID, b.Title,SUM(s.Quantity) AS TotalQuantitySold
FROM
    Books b
JOIN
    Sales s ON b.BookID = s.BookID
GROUP BY
    b.BookID, b.Title
ORDER BY
    TotalQuantitySold DESC;

-- 6) Display author-wise total sales revenue.

SELECT
    a.AuthorName, COALESCE(SUM(b.Price * s.Quantity), 0) AS [Total Sales Revenue]
FROM
    Authors a
LEFT JOIN
    Books b ON a.AuthorID = b.AuthorID
LEFT JOIN
    Sales s ON b.BookID = s.BookID
GROUP BY
    a.AuthorName
ORDER BY
    [Total Sales Revenue] DESC;

-- 7) Find books that have never been sold.

Select
	b.BookID,b.Title, 'Never Sold' AS Status
from
	Books b
left join
	Sales s
on b.BookID =s.BookID 
where
	s.SaleID is null;

-- 8) List books priced above the average price of their genre.

-- 8) Books priced above their genre's average price

SELECT 
    b.BookID,b.Title,b.Genre,b.Price, genre_avg.AvgGenrePrice
FROM 
    Books b
JOIN (
    SELECT 
        Genre,
        AVG(Price) AS AvgGenrePrice
    FROM 
        Books
    GROUP BY 
        Genre
) genre_avg ON b.Genre = genre_avg.Genre
WHERE 
    b.Price > genre_avg.AvgGenrePrice
ORDER BY 
    b.Genre, b.Price DESC;

--Simple alternative answer
SELECT 
	b.BookID, b.Title, b.Genre, b.Price
FROM 
	Books b
WHERE b.Price > (
    SELECT AVG(Price) 
    FROM Books 
    WHERE Genre = b.Genre
)
ORDER BY b.Genre, b.Price DESC;

-- 9)  Show rank of books within each genre by price.

Select
	BookId,Title,Genre,Price,
	Rank()over(partition by Genre Order by Price Desc) as pricerank
FROM
    Books
ORDER BY
    Genre, Price DESC;

-- 10)  Show total quantity and revenue earned per author (include books with zero sales).

SELECT 
    a.AuthorID, a.AuthorName,
    COALESCE(SUM(s.Quantity), 0) AS [Total Quantity],
    COALESCE(SUM(b.Price * s.Quantity), 0) AS [Total Revenue]
FROM
    Authors a
LEFT JOIN
    Books b ON a.AuthorID = b.AuthorID
LEFT JOIN
    Sales s ON b.BookID = s.BookID
GROUP BY
    a.AuthorID, a.AuthorName
ORDER BY
    [Total Revenue] DESC;

--Bonus Challenge
--Write a query to find the top 2 bestselling books per genre using window functions.

WITH RankedBooks AS (
    SELECT
        b.BookID,b.Title,b.Genre,
        SUM(COALESCE(s.Quantity, 0)) AS TotalSold,
        RANK() OVER (PARTITION BY b.Genre ORDER BY SUM(COALESCE(s.Quantity, 0)) DESC) AS SalesRank
    FROM
        Books b
    LEFT JOIN
        Sales s ON b.BookID = s.BookID
    GROUP BY
        b.BookID, b.Title, b.Genre
)
SELECT
    BookID,Title,Genre,TotalSold
FROM
    RankedBooks
WHERE
    SalesRank <= 2
ORDER BY
    Genre, SalesRank;

