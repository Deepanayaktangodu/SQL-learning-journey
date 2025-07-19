Create table Courses (
						CourseId int Primary key,
						CourseName varchar (75) not null unique,
						InstructorID int not null,
						Price decimal (10,2) check (Price>0),
						foreign key (InstructorID) references Instructors (InstructorID)
					);

Create table Instructors (
							InstructorID int Primary key,
							InstructorName varchar (50) not null
						);

Create table Enrollments (
							EnrollmentID int Primary key,
							CourseID int not null,
							StudentID int not null ,
							foreign key (CourseID) references Courses (CourseID)
							);

Create index idx_Courses_InstructorID on Courses(InstructorID);
Create index idx_Enrollments_CourseID on Enrollments(CourseID);

Insert into Courses (CourseId,CourseName,InstructorID,Price)
Values
	(101,'SQL Fundamentals',1,50),
	(102,'Advanced Python',2,75),
	(103,'Excel for Data Analysis',1,40),
	(104,'Data Visualization',3,60),
	(105,'Machine Learning Basics',2,80);

Insert into Instructors (InstructorID,InstructorName)
Values
	(1,'Alice'),
	(2,'Bob'),
	(3,'Carol');

Insert into Enrollments (EnrollmentID,CourseID,StudentID)
Values
	(1001,101,501),
	(1002,102,502),
	(1003,101,503),
	(1004,103,504),
	(1005,104,505),
	(1006,105,506),
	(1007,105,507),
	(1008,104,508),
	(1009,103,509),
	(1010,102,510);

Select * from Courses 
Select * from Instructors
Select * from Enrollments 
 
--1) List all courses with their instructor names.

Select
	c.CourseID,c.CourseName,i.InstructorName
from
	Courses c
join
	Instructors i
on c.InstructorID =i.InstructorID;

--2) Show total number of enrollments per course.

Select
	c.CourseID, c.CourseName, Count (e.EnrollmentID) as [Total Enrollments]
from
	Courses c
left join
	Enrollments e
on c.CourseId =e.CourseID 
Group by
	c.CourseID, c.CourseName
Order by
	[Total Enrollments] Desc;

--3) Display total revenue generated per course (Price × Enrollments).

Select
	c.CourseID,c.CourseName, c.Price* COUNT (e.EnrollmentID) as [Total Revenue]
from
	Courses c
left join
	Enrollments e
on c.CourseId =e.CourseID 
Group by
	c.CourseID,c.CourseName,c.Price 
Order by
	[Total Revenue] Desc;

--4) Show total revenue generated per instructor.

SELECT
    i.InstructorID, i.InstructorName,
    SUM(c.Price * enrollment_counts.EnrollmentCount) AS [Total Revenue]
FROM
    Instructors i
LEFT JOIN
    Courses c ON i.InstructorID = c.InstructorID
LEFT JOIN
    (SELECT CourseID, COUNT(*) AS EnrollmentCount
     FROM Enrollments
     GROUP BY CourseID) enrollment_counts
ON c.CourseID = enrollment_counts.CourseID
GROUP BY
    i.InstructorID, i.InstructorName
ORDER BY
    [Total Revenue] DESC;

--5) Find instructors with no courses listed.

SELECT
    i.InstructorID, i.InstructorName
FROM
    Instructors i
LEFT JOIN
    Courses c ON i.InstructorID = c.InstructorID
WHERE
    c.CourseID IS NULL;

--6) Identify courses that have no enrollments. 
	
Select
	c.CourseID,c.CourseName
from
	Courses c
left join
	Enrollments e 
on c.CourseId =e.CourseID 
where
	e.EnrollmentID  is null;

--7) Display average number of enrollments per course for each instructor.

SELECT 
    i.InstructorID, i.InstructorName,
    COUNT(e.EnrollmentID) * 1.0 / COUNT(DISTINCT c.CourseID) AS [Avg Enrollments Per Course]
FROM 
    Instructors i
LEFT JOIN 
    Courses c ON i.InstructorID = c.InstructorID
LEFT JOIN 
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY 
    i.InstructorID, i.InstructorName
ORDER BY 
    [Avg Enrollments Per Course] DESC;

--8) Rank courses based on total enrollments (highest to lowest).

Select
	c.CourseID,c.CourseName, count (e.EnrollmentID) as [Total Enrollments],
	Rank () over (Order by count (e.EnrollmentID) Desc) as [Rank]
from
	Courses c
left join
	Enrollments e 
on c.CourseId =e.CourseID 
Group by
	c.CourseID,c.CourseName
Order by
	[Total Enrollments] Desc;

--9) List instructors whose courses have an average price above $60.

SELECT
    i.InstructorID, i.InstructorName,
    AVG(c.Price) AS [Average Price]
FROM
    Courses c
JOIN
    Instructors i ON c.InstructorID = i.InstructorID
GROUP BY
    i.InstructorID, i.InstructorName
HAVING
    AVG(c.Price) > 60
ORDER BY
    [Average Price] DESC;

--10) Find the most enrolled course for each instructor.

SELECT 
    i.InstructorID, i.InstructorName,c.CourseID,c.CourseName,
    COUNT(e.EnrollmentID) AS EnrollmentCount
FROM 
    Instructors i
JOIN 
    Courses c ON i.InstructorID = c.InstructorID
JOIN 
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY 
    i.InstructorID, i.InstructorName, c.CourseID, c.CourseName
HAVING 
    COUNT(e.EnrollmentID) = (
        SELECT MAX(subcount)
        FROM (
            SELECT COUNT(e2.EnrollmentID) AS subcount
            FROM Courses c2
            JOIN Enrollments e2 ON c2.CourseID = e2.CourseID
            WHERE c2.InstructorID = i.InstructorID
            GROUP BY c2.CourseID
        ) counts
    )
ORDER BY 
    i.InstructorName;

--Bonus Challenge
--Write a query to list the top 2 revenue-generating courses for each instructor using DENSE_RANK.

WITH CourseRevenue AS (
    SELECT
        i.InstructorID,i.InstructorName,
        c.CourseID,c.CourseName,
        c.Price * COUNT(e.EnrollmentID) AS Revenue,
        DENSE_RANK() OVER (
            PARTITION BY i.InstructorID 
            ORDER BY c.Price * COUNT(e.EnrollmentID) DESC
        ) AS RevenueRank
    FROM
        Instructors i
    JOIN
        Courses c ON i.InstructorID = c.InstructorID
    LEFT JOIN
        Enrollments e ON c.CourseID = e.CourseID
    GROUP BY
        i.InstructorID, i.InstructorName, c.CourseID, c.CourseName, c.Price
)
SELECT
    InstructorID, InstructorName,
    CourseID,CourseName,Revenue
FROM
    CourseRevenue
WHERE
    RevenueRank <= 2
ORDER BY
    InstructorName,
    RevenueRank;
			


