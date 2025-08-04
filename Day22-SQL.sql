Create table Users (
					UserID int primary key,
					Name varchar (30) not null,
					Email varchar (50) not null UNIQUE CHECK (Email LIKE '%@%.%'),
					JoinDate date default getdate() check (JoinDate<=getdate()),
					Country varchar(30) not null,
					LastModified datetime2 DEFAULT SYSDATETIME()
					);

Create table Courses (
						CourseID int primary key,
						Title varchar(75) not null,
						Instructor varchar (50) not null,
						Category varchar (50) not null,
						CreatedDate date default getdate() check (CreatedDate<=getdate()),
						LastModified datetime2 DEFAULT SYSDATETIME()
						);

CREATE TABLE Enrollments (
							EnrollmentID int PRIMARY KEY,
							UserID int NOT NULL,
							CourseID int NOT NULL,
							EnrollDate date DEFAULT GETDATE() CHECK (EnrollDate <= GETDATE()),
							CompletionStatus varchar(25) NOT NULL CHECK (CompletionStatus IN ('Completed', 'In Progress')),
							LastModified datetime2 DEFAULT SYSDATETIME(),
							FOREIGN KEY (UserID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY (CourseID) REFERENCES Courses(CourseID) ON UPDATE CASCADE ON DELETE CASCADE
						);

GO

CREATE TRIGGER trg_Enrollments_CheckEnrollDate
ON Enrollments
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Users u ON i.UserID = u.UserID
        WHERE i.EnrollDate < u.JoinDate
    )
    BEGIN
        RAISERROR('Enrollment date cannot be before user join date', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE TABLE Reviews (
						ReviewID int PRIMARY KEY,
						EnrollmentID int NOT NULL,
						Rating int NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
						ReviewDate date NULL,
						LastModified datetime2 DEFAULT SYSDATETIME(),
						FOREIGN KEY (EnrollmentID) REFERENCES Enrollments(EnrollmentID) 
						ON UPDATE CASCADE ON DELETE CASCADE
						);

GO

CREATE TRIGGER trg_Reviews_ValidateReviewDate
ON Reviews
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Enrollments e ON i.EnrollmentID = e.EnrollmentID
        WHERE i.ReviewDate IS NOT NULL 
          AND i.ReviewDate < e.EnrollDate
    )
    BEGIN
        RAISERROR('Review date cannot be before enrollment date', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

Create Index Idx_Enrollments_UserID on Enrollments(UserID);
Create Index Idx_Enrollments_CourseID on Enrollments(CourseID);
Create Index Idx_Reviews_EnrollmentID on Reviews(EnrollmentID);

CREATE TRIGGER trg_Users_UpdateLastModified ON Users AFTER UPDATE AS
BEGIN
    UPDATE Users SET LastModified = SYSDATETIME()
    FROM Users u INNER JOIN inserted i ON u.UserID = i.UserID
END;
GO

INSERT INTO Users (UserID, Name, Email, JoinDate, Country)
VALUES
(1, 'Aarav', 'aarav@example.com', '2022-01-10', 'India'),
(2, 'Maya', 'maya@example.com', '2021-09-15', 'USA'),
(3, 'Zoya', 'zoya@example.com', '2021-12-01', 'India'),
(4, 'Dev', 'dev@example.com', '2022-06-20', 'UK'),
(5, 'Emma', 'emma@example.com', '2023-02-14', 'Canada');

INSERT INTO Courses (CourseID, Title, Instructor, Category, CreatedDate)
VALUES
(101, 'SQL for Beginners', 'John Smith', 'Data', '2021-05-01'),
(102, 'Python Basics', 'Alice Green', 'Programming', '2021-06-15'),
(103, 'Advanced Excel', 'John Smith', 'Business', '2022-01-20'),
(104, 'Data Visualization', 'Chris Lee', 'Data', '2022-08-10'),
(105, 'Machine Learning', 'Alice Green', 'AI', '2023-01-05');

INSERT INTO Enrollments (EnrollmentID, UserID, CourseID, EnrollDate, CompletionStatus)
VALUES
(1, 1, 101, '2022-01-15', 'Completed'),
(2, 1, 103, '2022-03-10', 'In Progress'),
(3, 2, 102, '2021-09-20', 'Completed'),
(4, 3, 104, '2022-08-15', 'Completed'),
(5, 4, 105, '2023-03-01', 'In Progress'),
(6, 5, 105, '2023-03-05', 'Completed');

INSERT INTO Reviews (ReviewID, EnrollmentID, Rating, ReviewDate)
VALUES
(1, 1, 4, '2022-02-01'),
(2, 3, 5, '2021-10-01'),
(3, 4, 5, '2022-08-20'),
(4, 6, 4, '2023-03-20');

Select *from Users 
Select * from Courses 
Select * from Enrollments 
Select * from Reviews 

--1) List all users along with the courses they are enrolled in, course category, and instructor.
SELECT
    u.UserID,u.Name AS 'User Name',u.Email,
    c.CourseID,c.Title AS 'Course Title',c.Category AS 'Course Category',c.Instructor,
    e.EnrollDate,e.CompletionStatus
FROM
    Users u
JOIN
    Enrollments e ON u.UserID = e.UserID
JOIN
    Courses c ON e.CourseID = c.CourseID
ORDER BY
    u.Name, c.Title;

--2) Find the average rating of each course with at least one review.
SELECT
    c.CourseID,c.Title AS [Course Title],c.Instructor,
    COUNT(r.ReviewID) AS [Review Count],
    ROUND(AVG(CAST(r.Rating AS DECIMAL(3,1))), 1) AS [Average Rating]
FROM
    Courses c
JOIN
    Enrollments e ON c.CourseID = e.CourseID
JOIN
    Reviews r ON e.EnrollmentID = r.EnrollmentID
GROUP BY
    c.CourseID,c.Title,c.Instructor
HAVING
    COUNT(r.ReviewID) >= 1
ORDER BY
    [Average Rating] DESC;

--3) Display the number of enrollments and completions per course.
SELECT
    c.CourseID,c.Title AS 'Course Name',
    COUNT(e.EnrollmentID) AS 'Total Enrollments',
    SUM(CASE WHEN e.CompletionStatus = 'Completed' THEN 1 ELSE 0 END) AS 'Completed Count',
    CONVERT(DECIMAL(5,2), 
           SUM(CASE WHEN e.CompletionStatus = 'Completed' THEN 1 ELSE 0 END) * 100.0 / 
           COUNT(e.EnrollmentID)) AS 'Completion Rate (%)'
FROM
    Courses c
LEFT JOIN
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY
    c.CourseID,c.Title
ORDER BY
    'Total Enrollments' DESC;

--4) Show the top 2 rated courses per category based on average rating.
WITH CourseRatings AS (
    SELECT
        c.CourseID,c.Title AS 'Course Name',c.Category,c.Instructor,
        ROUND(AVG(CAST(r.Rating AS DECIMAL(3,1))), 1) AS 'Average Rating',
        COUNT(r.ReviewID) AS 'Review Count',
        RANK() OVER (PARTITION BY c.Category ORDER BY AVG(CAST(r.Rating AS DECIMAL(3,1))) DESC) AS 'RatingRank'
    FROM
        Courses c
    JOIN
        Enrollments e ON c.CourseID = e.CourseID
    JOIN
        Reviews r ON e.EnrollmentID = r.EnrollmentID
    GROUP BY
        c.CourseID,c.Title,c.Category,c.Instructor)
SELECT
    CourseID,[Course Name],Category,Instructor,
    [Average Rating],[Review Count]
FROM
    CourseRatings
WHERE
    RatingRank <= 2
ORDER BY
    Category,
    [Average Rating] DESC;

--5) Identify users who joined in 2022 and haven’t completed any course.
SELECT
    u.UserID,u.Name AS 'User Name',u.JoinDate
FROM
    Users u
WHERE
    YEAR(u.JoinDate) = 2022
    AND NOT EXISTS (
        SELECT 1 
        FROM Enrollments e 
        WHERE e.UserID = u.UserID 
        AND e.CompletionStatus = 'Completed')
ORDER BY
    u.JoinDate;

--6) Show instructor-wise average course rating (only include courses with reviews).
SELECT
    c.Instructor,
    ROUND(AVG(r.Rating), 2) AS 'Average Rating',
    COUNT(r.ReviewID) AS 'Review Count'
FROM
    Courses c
JOIN
    Enrollments e ON c.CourseID = e.CourseID
JOIN
    Reviews r ON e.EnrollmentID = r.EnrollmentID
GROUP BY
    c.Instructor
ORDER BY
    'Average Rating' DESC;

--7) List the most recent course enrolled by each user.
WITH LatestEnrollment AS (
    SELECT
        UserID,
        MAX(EnrollDate) AS LatestEnrollDate
    FROM
        Enrollments
    GROUP BY
        UserID)
SELECT
    u.UserID,u.Name AS 'User Name',
    c.CourseID,c.Title AS 'Course Name',
    e.EnrollDate AS 'Enrollment Date',
    e.CompletionStatus
FROM
    Users u
JOIN
    LatestEnrollment le ON u.UserID = le.UserID
JOIN
    Enrollments e ON u.UserID = e.UserID AND le.LatestEnrollDate = e.EnrollDate
JOIN
    Courses c ON e.CourseID = c.CourseID
ORDER BY
    u.Name;

--8) Find courses with more than 1 review and average rating greater than 4.
Select
	c.CourseID,c.Title as 'Course Name',
	count (r.ReviewID) as 'Review Count',
	ROUND(AVG(r.Rating),2) as[AVG Rating]
from 
	Courses c
join
	Enrollments e
on c.CourseID =e.CourseID 
join
	Reviews r
on r.EnrollmentID =e.EnrollmentID 
GROUP BY
    c.CourseID,c.Title
HAVING
    COUNT(r.ReviewID) > 1
    AND AVG(r.Rating) > 4
ORDER BY
    'AVG Rating' DESC;

--9) Count number of courses completed by users from each country.
SELECT
    u.Country,
    COUNT(DISTINCT e.CourseID) AS 'Completed Courses Count'
FROM 
    Users u
JOIN
    Enrollments e ON u.UserID = e.UserID
WHERE
    e.CompletionStatus = 'Completed'
GROUP BY
    u.Country
ORDER BY
    'Completed Courses Count' DESC;

--10) Identify courses with no enrollments.
SELECT
    c.CourseID,c.Title AS 'Course Name',
    c.Instructor,c.Category
FROM
    Courses c
LEFT JOIN
    Enrollments e ON c.CourseID = e.CourseID
WHERE
    e.EnrollmentID IS NULL
ORDER BY
    c.Title;

--Bonus Challenge
--Rank courses by popularity (number of enrollments) and show only top course per category.
WITH PopularCourses AS (
    SELECT
        c.CourseID,c.Title AS 'Course Name',c.Instructor,c.Category,
        COUNT(e.EnrollmentID) AS 'EnrollmentCount',
        RANK() OVER (PARTITION BY c.Category ORDER BY COUNT(e.EnrollmentID) DESC) AS 'PopularityRank'
    FROM
        Courses c
    LEFT JOIN
        Enrollments e ON c.CourseID = e.CourseID
    GROUP BY
        c.CourseID,c.Title,c.Instructor,c.Category)
SELECT
    CourseID,[Course Name],Instructor,Category,EnrollmentCount
FROM
    PopularCourses
WHERE
    PopularityRank = 1
ORDER BY
    EnrollmentCount DESC;