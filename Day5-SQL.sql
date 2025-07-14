Create table Students(
						StudentID bigint Primary Key,
						StudentName char (100) not null,
						Gender char (10) not null,
						City varchar (75) not null
					);

Create table Courses (
						CourseID bigint Primary key,
						CourseName varchar (100) not null,
						Category varchar(75) not null,
						Fee Bigint not null check (Fee >0)
					);

Create table Enrollments (
							EnrollID bigint Primary key,
							StudentID bigint,
							CourseID bigint,
							EnrollDate Date,
							Score int not null check (Score between 0 and 100),
							Foreign key (StudentID) references Students(StudentID),
							Foreign key (CourseID) references Courses (CourseID)
							);

Insert into Students (StudentID,StudentName,Gender,City)
Values 
	(1,'Riya Sen','F','Mumbai'),
	(2,'Amit Patel','M','Ahmedabad'),
	(3,'Neha Sharma','F','Delhi'),
	(4,'Rahul Verma','M','Bangalore'),
	(5,'Anjali Rao','F','Hyderabad');

Insert into Courses (CourseID,CourseName,Category,Fee)
Values
	(101,'SQL Basics','Database',5000),
	(102,'EXCEL for Beginners','Productivity',3000),
	(103,'Advanced Python','Programming',8000),
	(104,'Data Visualization','Analytics',7000);

Insert into Enrollments (EnrollID,StudentID,CourseID,EnrollDate,Score)
Values
	(1001,1,101,'2022-01-10',85),
	(1002,2,103,'2022-01-15',72),
	(1003,3,102,'2022-01-20',78),
	(1004,4,104,'2022-01-22',90),
	(1005,1,103,'2022-01-25',82),
	(1006,5,101,'2022-01-28',88);

Select * from Students 
Select * from Courses 
Select * from Enrollments 

-- 1) List all students along with the courses they are enrolled in.

Select
	s.StudentName, c.CourseName
from
	Students s
join
	Enrollments e on s.StudentID=e.StudentID 
join
	Courses c on e.CourseID=c.CourseID;

-- 2) Show average score per course.

Select
	c.CourseName,AVG (E.Score) as [Average Score]
from
	Courses c
join
	Enrollments e on c.CourseID =e.CourseID 
Group by
	c.CourseName
Order by 
	[Average Score] Desc;

--3) List students who enrolled in more than one course.

SELECT 
    s.StudentID, s.StudentName, COUNT(DISTINCT e.CourseID) AS [CoursesEnrolled]
FROM 
    Students s
JOIN 
    Enrollments e ON s.StudentID = e.StudentID
GROUP BY 
    s.StudentID, s.StudentName
HAVING 
    COUNT(DISTINCT e.CourseID) > 1;

--4) Find the highest score obtained in each category of courses.

Select
	c.Category, Max (e.Score) as [Highest Score]
from
	Courses c
join
	Enrollments e
on c.CourseID =e.CourseID 
Group by
	c.Category 
Order by
	[Highest Score] Desc;

--5)  Show students who scored more than 80 in any course.

Select
	s.StudentName, c.CourseName,e.Score
from
	Students S
join
	Enrollments e on s.StudentID =e.StudentID 
join
	Courses c on e.CourseID =c.CourseID 
where
	e.Score >80
ORDER BY
    e.Score DESC;

--6) Display total revenue collected per course category.

SELECT
    c.Category, SUM(c.Fee) AS [Total Revenue]
FROM 
	Courses c
JOIN 
	Enrollments e ON c.CourseID = e.CourseID
GROUP BY 
	c.Category
ORDER BY
	[Total Revenue] DESC;

-- 7) List students and the number of days since their enrollment (from today).

SELECT
    s.StudentID,s.StudentName,c.CourseName, e.EnrollDate,
    DATEDIFF(day, e.EnrollDate, GETDATE()) AS [DaysSinceEnrollment]
FROM
    Students s
JOIN
    Enrollments e ON s.StudentID = e.StudentID
JOIN
    Courses c ON e.CourseID = c.CourseID
ORDER BY
    [DaysSinceEnrollment] DESC;

-- 8) Identify any course not yet taken by any student.

SELECT
    c.CourseID,c.CourseName,c.Category
FROM
    Courses c
LEFT JOIN
    Enrollments e ON c.CourseID = e.CourseID
WHERE
    e.EnrollID IS NULL;

-- 9) Rank students by score within each course (use RANK or DENSE_RANK).

Select
	s.StudentName, s.City,c.Coursename, 
	RANK () over (Partition by c.CourseID Order By e.Score Desc) as [Rank],
	DENSE_RANK() over (PARTITION BY c.CourseID ORDER BY e.Score DESC) AS [DenseRank]
from 
	Courses c
join
	Enrollments e on c.CourseID =e.CourseID 
Join
	Students s on e.StudentID =s.StudentID 
ORDER BY
    c.CourseName,e.Score DESC;

-- 10) Show total enrollments and average score by city.

SELECT
    s.City,
    COUNT(e.EnrollID) AS [Total Enrollments],
    AVG(e.Score) AS [Average Score]
FROM
    Students s
JOIN
    Enrollments e ON s.StudentID = e.StudentID
GROUP BY
    s.City
ORDER BY
    [Average Score] DESC;

-- Bonus Challenge
-- Write a query to find top 2 scorers in each course category.

WITH RankedScores AS (
    SELECT
        c.Category,s.StudentName,e.Score,
        DENSE_RANK() OVER (PARTITION BY c.Category ORDER BY e.Score DESC) AS ScoreRank
    FROM
        Students s
    JOIN
        Enrollments e ON s.StudentID = e.StudentID
    JOIN
        Courses c ON e.CourseID = c.CourseID
)
SELECT
    Category,StudentName,Score
FROM
    RankedScores
WHERE
    ScoreRank <= 2
ORDER BY
    Category,Score DESC;

