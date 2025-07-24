Create table Students (
						StudentID int primary key,
						Name char (50) not null,
						Country varchar (50) not null
						);

Create table Courses (
						CourseID int primary key,
						Title varchar (75) not null,
						Category varchar(50) not null,
						Price decimal (10,2) not null check (Price>0)
						);

CREATE TABLE Enrollments (
							EnrollmentID INT PRIMARY KEY,
							StudentID INT NOT NULL,
							CourseID INT NOT NULL,
							EnrollDate DATE NOT NULL DEFAULT GETDATE() CHECK (EnrollDate <= GETDATE()),
							FOREIGN KEY (StudentID) REFERENCES Students(StudentID) ON DELETE CASCADE,
							FOREIGN KEY (CourseID) REFERENCES Courses(CourseID) ON DELETE CASCADE,
							UNIQUE (StudentID, CourseID) 
							);

Create table Progress (
						ProgressID int primary key,
						EnrollmentID int not null,
						CompletionPercent int not null check (CompletionPercent between 0 and 100),
						LastAccessDate Date not null DEFAULT GETDATE() check (LastAccessDate<=GetDate()),
						foreign key (EnrollmentID) references Enrollments(EnrollmentID) ON DELETE CASCADE
						);

Create index Idx_Enrollments_StudentID on Enrollments(StudentID);
Create index Idx_Enrollments_CourseID on Enrollments(CourseID);
Create index Idx_Progress_EnrollmentID on Progress(EnrollmentID);
CREATE INDEX Idx_Students_Country ON Students(Country);
CREATE INDEX Idx_Courses_Category ON Courses(Category);

INSERT INTO Students (StudentID, Name, Country) VALUES
(1, 'Anita', 'India'),
(2, 'Ben', 'USA'),
(3, 'Carlos', 'Brazil'),
(4, 'Diana', 'India'),
(5, 'Eva', 'Germany');

INSERT INTO Courses (CourseID, Title, Category, Price) VALUES
(101, 'SQL for Beginners', 'Data', 49.99),
(102, 'Advanced Python', 'Programming', 79.99),
(103, 'Data Visualization', 'Data', 59.99),
(104, 'Digital Marketing', 'Business', 39.99),
(105, 'Cloud Fundamentals', 'IT', 69.99);

INSERT INTO Enrollments (EnrollmentID, StudentID, CourseID, EnrollDate) VALUES
(201, 1, 101, '2024-06-01'),
(202, 1, 103, '2024-06-05'),
(203, 2, 102, '2024-06-03'),
(204, 3, 104, '2024-06-10'),
(205, 4, 101, '2024-06-15'),
(206, 4, 105, '2024-06-20'),
(207, 5, 102, '2024-06-25');

INSERT INTO Progress (ProgressID, EnrollmentID, CompletionPercent, LastAccessDate) VALUES
(301, 201, 100, '2024-07-01'),
(302, 202, 0, '2024-07-02'),
(303, 203, 75, '2024-07-01'),
(304, 204, 50, '2024-07-03'),
(305, 205, 100, '2024-07-04'),
(306, 206, 20, '2024-07-05'),
(307, 207, 90, '2024-07-06');

Select*from Students 
Select*from Courses 
Select*from Enrollments 
Select*from Progress 
 

--1) List all courses along with their categories and prices.
SELECT 
    Title AS 'Course Title', Category AS 'Category', Price AS 'Price'
FROM 
    Courses
ORDER BY 
    Title;

--2) Show the number of students enrolled in each course.
SELECT
    c.CourseID, c.Title AS 'Course Title', c.Category,
    COUNT(e.StudentID) AS 'Number of Students Enrolled'
FROM 
    Courses c
LEFT JOIN
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY
    c.CourseID, c.Title, c.Category
ORDER BY
    COUNT(e.StudentID) DESC;

--3) Calculate total revenue generated from each course (Price × Enrollments).
SELECT
    c.CourseID,c.Title,c.Category,
    COUNT(e.EnrollmentID) AS [Total Enrollments],
    SUM(c.Price) AS [Total Revenue Generated]
FROM
    Courses c
LEFT JOIN
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY
    c.CourseID, c.Title, c.Category
ORDER BY
    [Total Revenue Generated] DESC;

--4) Find the top 3 courses with the highest number of enrollments.

SELECT TOP 3
    c.CourseID,c.Title AS 'Course Title',c.Category,
    COUNT(e.EnrollmentID) AS 'Enrollment Count'
FROM 
    Courses c
INNER JOIN
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY
    c.CourseID, c.Title, c.Category
ORDER BY
    COUNT(e.EnrollmentID) DESC;

--5) List student names along with the total number of courses they’ve enrolled in.
SELECT
    s.StudentID,s.Name AS 'Student Name',
    COUNT(DISTINCT e.CourseID) AS 'Courses Enrolled'
FROM
    Students s
LEFT JOIN
    Enrollments e ON s.StudentID = e.StudentID
GROUP BY
    s.StudentID, s.Name
ORDER BY
    COUNT(DISTINCT e.CourseID) DESC;

--6) Identify the course category with the highest average course price.
Select Top 1
	Category, ROUND(AVG(Price),2) as [Average Course Price]
from
	Courses c
Group by
	Category
Order by
	[Average Course Price] Desc;	

--7) Show the total number of enrollments for students from India.

SELECT
    'India' AS Country,
    COUNT(e.EnrollmentID) AS 'Total Enrollments'
FROM
    Students s
INNER JOIN
    Enrollments e ON s.StudentID = e.StudentID
WHERE
    s.Country = 'India';

--8) Display the average completion percentage per course.
SELECT
    c.CourseID,c.Title AS 'Course Title',c.Category,
    ROUND(AVG(ISNULL(p.CompletionPercent, 0)), 2) AS 'Avg Completion %'
FROM
    Courses c
LEFT JOIN
    Enrollments e ON c.CourseID = e.CourseID
LEFT JOIN
    Progress p ON e.EnrollmentID = p.EnrollmentID
GROUP BY
    c.CourseID, c.Title, c.Category
ORDER BY
    AVG(ISNULL(p.CompletionPercent, 0)) DESC;

--9) List students who have not completed any course (i.e., 0% completion in all enrolled courses).
SELECT 
    s.StudentID, s.Name AS 'Student Name',
    COUNT(e.EnrollmentID) AS 'Courses Enrolled'
FROM
    Students s
LEFT JOIN
    Enrollments e ON s.StudentID = e.StudentID
LEFT JOIN
    Progress p ON e.EnrollmentID = p.EnrollmentID
WHERE
    p.CompletionPercent IS NULL 
    OR p.CompletionPercent = 0
GROUP BY
    s.StudentID, s.Name
HAVING
    MAX(ISNULL(p.CompletionPercent, 0)) = 0
ORDER BY
    COUNT(e.EnrollmentID) DESC;

--10) For each category, find the course that generated the highest revenue.

With CourseRevenue as (
		Select
				c.CourseID,c.Category,c.Title,
				SUM (c.Price) as TotalRevenue,
				RANK () over (Partition by c.Category Order by SUM (c.Price) Desc) as RevenueRank
			from
				Courses c
			inner join
				Enrollments e
				on e.CourseID =c.CourseID 
				Group by
					c.CourseID,c.Category,c.Title
				)
		Select	
			CourseID,Category,Title,TotalRevenue 
		From
			CourseRevenue 
		Where
			RevenueRank =1
		Order by	
			Category;

--Bonus Challenge
-- Identify the student with the highest average completion percentage across all their courses.
WITH StudentCompletion AS (
    SELECT
        s.StudentID,s.Name AS 'Student Name',
        COUNT(p.EnrollmentID) AS 'Courses Enrolled',
        ROUND(AVG(p.CompletionPercent), 2) AS 'Avg Completion %'
    FROM
        Students s
    JOIN
        Enrollments e ON s.StudentID = e.StudentID
    JOIN
        Progress p ON e.EnrollmentID = p.EnrollmentID
    GROUP BY
        s.StudentID, s.Name)
SELECT TOP 1
    StudentID,[Student Name],[Courses Enrolled],[Avg Completion %]
FROM
    StudentCompletion
ORDER BY
    [Avg Completion %] DESC;