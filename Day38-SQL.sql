CREATE TABLE Members (
						MemberID INT PRIMARY KEY,
						Name VARCHAR(100) NOT NULL CHECK(LEN(Name)>=2),
						JoinDate DATE NOT NULL,
						Status VARCHAR(20) NOT NULL CHECK(Status IN ('Active','Inactive'))
					);


CREATE TABLE Books (
						BookID INT PRIMARY KEY,
						Title VARCHAR(150) NOT NULL CHECK(LEN(Title)>=2),
						Author VARCHAR(100) NOT NULL CHECK(LEN(Author)>=2),
						Genre VARCHAR(50) NOT NULL CHECK (LEN(Genre)>=2),
						PublishedYear INT NOT NULL CHECK(PublishedYear>0)
					);


CREATE TABLE Loans (
						LoanID INT PRIMARY KEY,
						MemberID INT NOT NULL,
						BookID INT NOT NULL,
						LoanDate DATE NOT NULL DEFAULT getdate() CHECK(LoanDate<=getdate()),
						ReturnDate DATE  NULL,
						FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON UPDATE CASCADE ON DELETE NO ACTION,
						FOREIGN KEY (BookID) REFERENCES Books(BookID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

Create Index Idx_Members_Name on Members(Name);
Create Index Idx_Books_Title on Books(Title);
Create Index Idx_Books_Author on Books(Author);
Create Index Idx_Books_Genre on Books(Genre);
Create Index Idx_Loans_MemberID on Loans(MemberID);
Create Index Idx_Loans_BookID on Loans(BookID);

INSERT INTO Members VALUES
(1, 'Alice Johnson', '2022-01-10', 'Active'),
(2, 'Bob Smith', '2021-12-05', 'Inactive'),
(3, 'Charlie Brown', '2022-03-15', 'Active'),
(4, 'Diana Prince', '2023-01-20', 'Active'),
(5, 'Ethan Hunt', '2021-09-12', 'Active');

INSERT INTO Books VALUES
(1, 'The Great Gatsby', 'F. Scott Fitzgerald', 'Fiction', 1925),
(2, '1984', 'George Orwell', 'Dystopian', 1949),
(3, 'To Kill a Mockingbird', 'Harper Lee', 'Fiction', 1960),
(4, 'Sapiens', 'Yuval Noah Harari', 'History', 2011),
(5, 'Educated', 'Tara Westover', 'Memoir', 2018),
(6, 'The Alchemist', 'Paulo Coelho', 'Fiction', 1988);

INSERT INTO Loans VALUES
(1, 1, 1, '2023-07-01', '2023-07-15'),
(2, 2, 3, '2023-06-10', NULL),
(3, 3, 2, '2023-07-05', '2023-07-20'),
(4, 4, 4, '2023-07-12', NULL),
(5, 5, 5, '2023-06-25', '2023-07-05'),
(6, 1, 6, '2023-07-18', NULL);

Select * from Members 
Select * from Books 
Select * from Loans 

--1) List all members who joined in 2022.
Select
	MemberID,Name as 'Member Name',JoinDate
from Members 
where JoinDate between '2022-01-01' and '2022-12-31';

--2) Find the number of books per genre.
Select
	Genre,
	Count(BookID) as [Book Count]
from Books 
Group by Genre
Order by [Book Count] Desc;

--3) Get the list of books currently on loan (not yet returned).
SELECT
    b.BookID,b.Title
FROM Books b
JOIN Loans l ON b.BookID = l.BookID
WHERE l.ReturnDate IS NULL;

--4) Show members who have borrowed more than 1 book.
Select
	m.MemberID,m.Name as 'Member Name',
	Count(l.LoanID) as [Book Count]
from Members m
join Loans l on m.MemberID =l.MemberID 
group by m.MemberID,m.Name
having Count(l.LoanID)>1
order by [Book Count] Desc;

--5) Find the most borrowed book.
SELECT TOP 1 WITH TIES
    b.BookID,b.Title AS 'Book Name',b.Author,
    COUNT(l.LoanID) AS [Borrow Count]
FROM Books b
JOIN Loans l ON b.BookID = l.BookID
GROUP BY b.BookID,b.Title,b.Author
ORDER BY [Borrow Count] DESC;

--6) Display members with no loans.
Select
	m.MemberID,m.Name as 'Member Name'
from Members m
left join Loans l on m.MemberID =l.MemberID 
where l.LoanID is null;

--7) Find average published year of borrowed books.
Select
	ROUND(AVG(b.PublishedYear),2) as [AVG Prblished Year]
from Books b
join Loans l on b.BookID =l.BookID;

--8) List top 2 recently borrowed books (by LoanDate).
SELECT TOP 2 WITH TIES
    b.BookID,b.Title AS 'Book Name',
    l.LoanDate AS 'Recent Borrow Date'
FROM Loans l
JOIN Books b ON l.BookID = b.BookID
ORDER BY l.LoanDate DESC;

--9) Show loan details where the return date is missing (overdue check).
Select * from Loans l
where l.ReturnDate is null;

--10) Find members who borrowed books in July 2023.
SELECT
    m.MemberID,m.Name AS 'Member Name',l.LoanDate
FROM Members m
JOIN Loans l ON m.MemberID = l.MemberID
WHERE YEAR(l.LoanDate) = 2023 AND MONTH(l.LoanDate) = 7
order by m.MemberID;

--Bonus Challenge
--Find the member who borrowed the oldest published book and display their name along with the book title.
SELECT TOP 1
    m.MemberID,m.Name AS 'Member Name',
    b.BookID,b.Title AS 'Book Title',b.PublishedYear
FROM Members m
JOIN Loans l ON m.MemberID = l.MemberID
JOIN Books b ON l.BookID = b.BookID
ORDER BY
    b.PublishedYear ASC;