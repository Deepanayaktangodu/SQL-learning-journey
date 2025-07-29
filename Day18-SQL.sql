Create table Customers(
						CustomerID int primary key,
						Name varchar (50) not null,
						Email varchar (100) not null unique CHECK (Email LIKE '%@%.%'),
						Country varchar (30) not null
						);

Create table Books (
					BookID int primary key,
					Title varchar (100) not null unique,
					Author varchar (50) not null,
					Genre varchar(30) not null,
					Price decimal (10,2) not null check (Price>0)
					);

Create table Orders (
						OrderID int primary key,
						CustomerID int not null,
						BookID int not null,
						OrderDate date default getdate() check(OrderDate<=Getdate()),
						Quantity int not null check (Quantity>0),
						foreign key (CustomerID) references Customers(CustomerID) on delete cascade,
						foreign key (BookID) references Books(BookID) on delete cascade,
						CONSTRAINT UQ_Order UNIQUE (CustomerID, BookID, OrderDate)
						);

Create table Reviews (
						ReviewID int primary key,
						CustomerID int not null,
						BookID int not null,
						Rating int not null check (Rating between 1 and 5),
						ReviewDate date default getdate() check(ReviewDate<=Getdate()),
						foreign key (CustomerID) references Customers (CustomerID) on delete cascade,
						foreign key (BookID) references Books(BookID) on delete cascade,
						CONSTRAINT UQ_Review UNIQUE (CustomerID, BookID)
						);

Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_Orders_BookID on Orders(BookID);
Create Index Idx_Reviews_CustomerID on Reviews(CustomerID);
Create Index Idx_Reviews_BookID on Reviews(BookID);

INSERT INTO Customers VALUES
(1, 'Alice', 'alice@example.com', 'USA'),
(2, 'Bob', 'bob@example.com', 'UK'),
(3, 'Chitra', 'chitra@example.com', 'India'),
(4, 'Daniel', 'daniel@example.com', 'Canada'),
(5, 'Eva', 'eva@example.com', 'Germany');

INSERT INTO Books VALUES
(101, 'Data Science 101', 'Smith', 'Tech', 25.50),
(102, 'Mystery of AI', 'Jones', 'Thriller', 19.99),
(103, 'The Last Algorithm', 'Ray', 'Sci-Fi', 22.75),
(104, 'Learning SQL', 'Clark', 'Tech', 29.99),
(105, 'Cooking for Coders', 'Lee', 'Cooking', 18.50);

INSERT INTO Orders VALUES
(1001, 1, 101, '2024-06-01', 2),
(1002, 2, 102, '2024-06-03', 1),
(1003, 3, 104, '2024-06-05', 1),
(1004, 4, 105, '2024-06-07', 3),
(1005, 1, 103, '2024-06-09', 1),
(1006, 2, 105, '2024-06-10', 1),
(1007, 5, 101, '2024-06-12', 2);

INSERT INTO Reviews VALUES
(201, 1, 101, 4, '2024-06-05'),
(202, 2, 102, 5, '2024-06-06'),
(203, 3, 104, 3, '2024-06-08'),
(204, 4, 105, 5, '2024-06-10'),
(205, 1, 103, 4, '2024-06-12'),
(206, 5, 101, 5, '2024-06-13'),
(207, 2, 105, 4, '2024-06-14');

Select * from Customers 
Select * from Books 
Select * from Orders 
Select * from Reviews 

--1) List all customers along with the number of books they ordered.
Select
	c.CustomerID,c.Name as 'Customer Name',
	Coalesce(SUM(o.Quantity),0) as [Total Order Quantity]
from
	Customers c
left join
Orders o
on c.CustomerID =o.CustomerID 
Group by
	c.CustomerID,c.Name
Order by
	[Total Order Quantity] Desc;

--2) Show the average rating for each genre.
Select
	b.Genre,ROUND(AVG(R.Rating),2) as [AVG Rating]
from
	Books b
left join
	Reviews r
on b.BookID =r.BookID 
Group by
	b.Genre
Order by
	[AVG Rating] Desc;

--3) Find the top-selling book (based on quantity).
Select Top 1
	b.BooKID,b.Title as ' BOOK NAME',
	Coalesce (SUM (o.Quantity),0) as [Total Order Quantity]
from Books b
left join
	Orders o
on b.BookID =o.BookID 
Group by
	b.BooKID,b.Title
Order by
	[Total Order Quantity] Desc;

--4) Display books ordered by customers who never left a review.
SELECT
    b.BookID,b.Title AS [Book Name],
    COUNT(o.OrderID) AS [Order Count]
FROM
    Books b
JOIN
    Orders o ON b.BookID = o.BookID
LEFT JOIN
    Reviews r ON o.CustomerID = r.CustomerID
WHERE
    r.CustomerID IS NULL
GROUP BY
    b.BookID, b.Title
ORDER BY
    [Order Count] DESC;

--5) List all books with an average rating of 4 or higher and total orders above 2.
SELECT
    b.BookID,b.Title AS [Book Name],
    ROUND(AVG(r.Rating), 2) AS [AVG Rating],
    COUNT(DISTINCT o.OrderID) AS [Total Orders]
FROM
    Books b
JOIN
    Orders o ON b.BookID = o.BookID
JOIN
    Reviews r ON b.BookID = r.BookID
GROUP BY
    b.BookID, b.Title
HAVING
    AVG(r.Rating) >= 4 AND COUNT(DISTINCT o.OrderID) > 2
ORDER BY
    [AVG Rating] DESC;

--6) Show the best-rated book per genre (based on average rating).
WITH RankedBooks AS (
    SELECT
        b.BookID,b.Title AS [Book Name],b.Genre,
        ROUND(AVG(r.Rating), 2) AS [AVG Rating],
        RANK() OVER (PARTITION BY b.Genre ORDER BY AVG(r.Rating) DESC) AS GenreRank
    FROM
        Books b
    JOIN
        Reviews r ON b.BookID = r.BookID
    GROUP BY
        b.BookID, b.Title, b.Genre )
SELECT
    BookID,[Book Name],Genre,[AVG Rating]
FROM
    RankedBooks
WHERE
    GenreRank = 1
ORDER BY
    [AVG Rating] DESC;

--7) Identify customers who purchased books from at least 3 different genres.
Select
	c.CustomerID,c.Name, 
	Count (Distinct b.Genre) as [Number of Genres]
from
	Customers c
join
	Orders o
on c.CustomerID =o.CustomerID 
join
	Books b
on b.BookID =o.BookID 
Group by
	c.CustomerID,c.Name
Having 
	Count (Distinct b.Genre) >=3
Order by
	[Number of Genres] Desc;

--8) Find the books not ordered by anyone.
SELECT
    b.BookID,b.Title AS [Book Name],
    b.Author,b.Genre
FROM
    Books b
LEFT JOIN
    Orders o ON b.BookID = o.BookID
WHERE
    o.BookID IS NULL
ORDER BY
    b.Title;

--9) Show the most popular genre in terms of total orders.
Select Top 1
	b.Genre, Coalesce(SUM(o.Quantity),0) as [Total Orders]
from
	Books b
left join
	Orders o
on b.BookID =o.BookID 
Group by
	b.Genre
Order by
	[Total Orders] Desc;

--10) List top 2 customers who spent the most money (price × quantity).
Select top 2
	c.CustomerID,c.Name,
	Coalesce(sum(b.Price*o.Quantity),0) as [Total Money Spent]
from
	Customers c
left join
	Orders o
on c.CustomerID =o.CustomerID 
left join
	Books b
on b.BookID =o.BookID 
Group by
	c.CustomerID,c.Name
Order by
	[Total Money Spent] Desc;

--Bonus Challenge
--Identify books that were ordered at least twice and received only ratings 4 or above.
SELECT
    b.BookID,b.Title,
    COUNT(DISTINCT o.OrderID) AS [Number of Orders],
    MIN(r.Rating) AS [Minimum Rating],
    AVG(r.Rating) AS [Average Rating]
FROM
    Books b
JOIN
    Orders o ON b.BookID = o.BookID
JOIN
    Reviews r ON b.BookID = r.BookID
WHERE
    r.Rating >= 4
GROUP BY
    b.BookID, b.Title
HAVING
    COUNT(DISTINCT o.OrderID) >= 2
    AND NOT EXISTS (
        SELECT 1
        FROM Reviews r2
        WHERE r2.BookID = b.BookID
        AND r2.Rating < 4)
ORDER BY
    [Number of Orders] DESC;

