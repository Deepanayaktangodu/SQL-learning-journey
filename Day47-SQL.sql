Create table Students (
						StudentID int Primary Key,
						Name Varchar(50) Not Null Check(Len(Name)>=2),
						Country Varchar(75) Not Null Check(Len(Country)>=2),
						JoinDate date Not Null Default Getdate() Check(JoinDate<=Getdate())
					);

Create table Courses (
						CourseID int Primary Key,
						CourseName Varchar(75) Not Null Check(Len(CourseName)>=2),
						Category Varchar(50) Not Null Check(Category in ('Data','AI','IT','Programming')),
						Price decimal(6,2) Not Null Check(Price>0),
						LaunchDate date Not Null Default getdate(),
					);

Create table Enrollments (
							EnrollID int Primary key,
							StudentID int Not Null,
							CourseID int Not Null,
							EnrollDate date Not Null Default getdate(),
							Status Varchar(50) Not Null Check(Status in('Completed','In Progress','Dropped')),
							Progress int Not Null Default 0 Check(Progress between 0 and 100),
							Unique(StudentID,CourseID),
							Foreign Key(StudentID) references Students(StudentID) on update cascade on delete no action,
							Foreign Key(CourseID) references Courses(CourseID) on update cascade on delete no action
						);

Create Index Idx_Students_Name on Students(Name);
Create Index Idx_Students_Country on Students(Country);
Create Index Idx_Courses_CourseName on Courses(CourseName);
Create Index Idx_Courses_Category on Courses(Category);
Create Index Idx_Courses_Price on Courses(Price);
Create Index Idx_Enrollments_StudentID on Enrollments(StudentID);
Create Index Idx_Enrollments_CourseID on Enrollments(CourseID);

INSERT INTO Students (StudentID, Name, Country, JoinDate) VALUES
(1, 'Alice', 'USA', '2022-01-01'),
(2, 'Bob', 'India', '2022-02-15'),
(3, 'Charlie', 'UK', '2022-03-20'),
(4, 'David', 'Canada', '2022-04-10'),
(5, 'Emma', 'India', '2022-05-05');

INSERT INTO Courses (CourseID, CourseName, Category, Price, LaunchDate) VALUES
(101, 'SQL Basics', 'Data', 100.00, '2022-01-01'),
(102, 'Advanced SQL', 'Data', 150.00, '2022-03-01'),
(103, 'Python for DataSci', 'Programming', 200.00, '2022-02-01'),
(104, 'Machine Learning', 'AI', 250.00, '2022-05-01'),
(105, 'Cloud Computing', 'IT', 300.00, '2022-06-01');

INSERT INTO Enrollments (EnrollID, StudentID, CourseID, EnrollDate, Status, Progress) VALUES
(1, 1, 101, '2022-01-10', 'Completed', 100),
(2, 1, 102, '2022-03-15', 'In Progress', 60),
(3, 2, 103, '2022-02-20', 'Completed', 100),
(4, 3, 101, '2022-03-25', 'Completed', 100),
(5, 3, 104, '2022-06-01', 'In Progress', 40),
(6, 4, 105, '2022-07-10', 'Completed', 100),
(7, 5, 102, '2022-06-20', 'Dropped', 10),
(8, 5, 104, '2022-07-15', 'In Progress', 70);

Select*from Students 
Select*from Courses 
Select*from Enrollments 

--1)Revenue per Course
--Calculate total revenue generated per course (only Completed enrollments).
Select
	c.CourseID,c.CourseName,c.Category,
	ROUND(SUM(c.Price),2) as [Total Revenue Generated]
from Courses c
join Enrollments e on c.CourseID =e.CourseID 
where e.Status ='Completed'
group by c.CourseID,c.CourseName,c.Category 
order by [Total Revenue Generated] Desc;

--2) Top Performing Students
--Find students who completed more than 1 course.
SELECT
    s.StudentID,s.Name AS "Student Name", s.Country,
    COUNT(DISTINCT e.CourseID) AS "Course Count",
    STRING_AGG(c.CourseName, ', ') AS "Courses Completed"
FROM Students AS s
JOIN Enrollments AS e ON s.StudentID = e.StudentID
JOIN Courses c ON c.CourseID = e.CourseID 
WHERE e.Status = 'Completed'
GROUP BY s.StudentID, s.Name, s.Country
HAVING COUNT(DISTINCT e.CourseID) > 1
ORDER BY "Course Count" DESC, s.Name;

--3) Course Popularity Ranking
--Rank courses by the total number of enrollments.
SELECT
    c.CourseID,c.CourseName,c.Category,
    COUNT(e.EnrollID) AS "Total Enrollments",
    RANK() OVER (ORDER BY COUNT(e.EnrollID) DESC) AS "Popularity Rank",
    DENSE_RANK() OVER (ORDER BY COUNT(e.EnrollID) DESC) AS "Dense Rank",
    COUNT(CASE WHEN e.Status = 'Completed' THEN 1 END) AS "Completed Enrollments",
    COUNT(CASE WHEN e.Status = 'In Progress' THEN 1 END) AS "In Progress Enrollments"
FROM Courses c
LEFT JOIN Enrollments e ON c.CourseID = e.CourseID 
GROUP BY c.CourseID, c.CourseName, c.Category
ORDER BY "Total Enrollments" DESC;

--4) Student Engagement
--Find students who have at least one In Progress course with >50% progress.
SELECT
    s.StudentID,s.Name AS 'Student Name', s.Country,
    c.CourseName,e.Progress,e.EnrollDate
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
JOIN Courses c ON e.CourseID = c.CourseID
WHERE e.Status = 'In Progress' AND e.Progress > 50
ORDER BY e.Progress DESC, s.StudentID;

--5) Country-Wise Revenue Contribution
--Show revenue contribution by country and rank them.
SELECT
    s.Country,
    ROUND(SUM(c.Price), 2) AS "Revenue Generated",
    RANK() OVER (ORDER BY SUM(c.Price) DESC) AS "Revenue Rank",
    ROUND(SUM(c.Price) * 100.0 / SUM(SUM(c.Price)) OVER (), 2) AS "Revenue Percentage"
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
JOIN Courses c ON c.CourseID = e.CourseID
WHERE e.Status = 'Completed' 
GROUP BY s.Country
ORDER BY "Revenue Generated" DESC;

--6) Window Function – Enrollment Timeline
--For each student, display their enrollments along with the previous course enrolled (use LAG).
SELECT
    s.StudentID,s.Name AS 'Student Name',s.Country,
    c.CourseName AS 'Course',e.Status,
    e.EnrollDate AS 'Enrollment Date',
    LAG(c.CourseName) OVER (PARTITION BY s.StudentID ORDER BY e.EnrollDate) AS 'Previous Course',
    LAG(e.EnrollDate) OVER (PARTITION BY s.StudentID ORDER BY e.EnrollDate) AS 'Previous Enrollment Date',
    ROW_NUMBER() OVER (PARTITION BY s.StudentID ORDER BY e.EnrollDate) AS 'Enrollment Sequence',
    CASE 
        WHEN LAG(c.CourseName) OVER (PARTITION BY s.StudentID ORDER BY e.EnrollDate) IS NULL 
        THEN 'First Enrollment'
        ELSE CONCAT('After ', DATEDIFF(day, 
            LAG(e.EnrollDate) OVER (PARTITION BY s.StudentID ORDER BY e.EnrollDate), 
            e.EnrollDate
        ), ' days')
    END AS 'Enrollment Pattern'
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
JOIN Courses c ON e.CourseID = c.CourseID
ORDER BY s.StudentID, e.EnrollDate;

--7) Dropout Analysis
--Find percentage of courses that were Dropped vs total enrollments, month-wise.
SELECT
    FORMAT(e.EnrollDate, 'yyyy-MM') AS 'Enrollment Month',
    COUNT(e.EnrollID) AS 'Total Enrollments',
    COUNT(CASE WHEN e.Status = 'Dropped' THEN 1 END) AS 'Dropped Enrollments',
    COUNT(CASE WHEN e.Status = 'Completed' THEN 1 END) AS 'Completed Enrollments',
    COUNT(CASE WHEN e.Status = 'In Progress' THEN 1 END) AS 'In Progress Enrollments',
    ROUND(
        COUNT(CASE WHEN e.Status = 'Dropped' THEN 1 END) * 100.0 / 
        COUNT(e.EnrollID), 
        2
    ) AS 'Dropout Rate (%)'
FROM Enrollments e
GROUP BY FORMAT(e.EnrollDate, 'yyyy-MM')
ORDER BY 'Enrollment Month';

--8) High-Value Students
--Students whose average completed course spend > $200.
Select
	s.StudentID,s.Name as 'Student Name',s.Country,
	ROUND(AVG(c.Price),2) as [Average Spent]
from Students s
join Enrollments e on s.StudentID =e.StudentID 
join Courses c  on c.CourseID =e.CourseID 
where e.Status ='Completed'
group by s.StudentID,s.Name,s.Country 
having AVG(c.Price)>200
order by [Average Spent] Desc;

--9) Learning Path
--Using a recursive CTE, build a path showing students who completed SQL Basics (101) then took Advanced SQL (102).
WITH LearningPath AS (
    -- Anchor: Students who completed SQL Basics (101)
    SELECT 
        s.StudentID,s.Name AS 'Student Name',s.Country,
        c.CourseID,c.CourseName,e.EnrollDate,
        CAST(c.CourseName AS VARCHAR(500)) AS 'Learning Path',
        1 AS 'Path Level'
    FROM Students s
    JOIN Enrollments e ON s.StudentID = e.StudentID
    JOIN Courses c ON e.CourseID = c.CourseID
    WHERE c.CourseID = 101 
      AND e.Status = 'Completed'
    
    UNION ALL
    
    -- Recursive: Find their next course (Advanced SQL - 102)
    SELECT 
        s.StudentID,s.Name,s.Country,
        c.CourseID,c.CourseName,e.EnrollDate,
        CAST(lp.[Learning Path] + ' → ' + c.CourseName AS VARCHAR(500)),
        lp.[Path Level] + 1
    FROM LearningPath lp
    JOIN Students s ON lp.StudentID = s.StudentID
    JOIN Enrollments e ON s.StudentID = e.StudentID
    JOIN Courses c ON e.CourseID = c.CourseID
    WHERE c.CourseID = 102 
      AND e.EnrollDate > lp.EnrollDate  -- Ensure it's after the first course
      AND e.Status IN ('Completed', 'In Progress')  -- Include both statuses
)
SELECT 
    StudentID,'Student Name',Country,
    CourseID,CourseName,EnrollDate,
    'Learning Path',
    'Path Level'
FROM LearningPath
WHERE [Path Level] = 2  -- Only show students who took both courses
ORDER BY StudentID, [Path Level];

--10) Category-Wise Insights
--Find the average price, total enrollments, and completion rate for each course category.
SELECT
    c.Category,
    ROUND(AVG(c.Price), 2) AS "Average Price",
    COUNT(e.EnrollID) AS "Total Enrollments",
    SUM(CASE WHEN e.Status = 'Completed' THEN 1 ELSE 0 END) AS "Completed Enrollments",
    ROUND(
        SUM(CASE WHEN e.Status = 'Completed' THEN 1.0 ELSE 0 END) * 100.0 / 
        COUNT(e.EnrollID), 
        2
    ) AS "Completion Rate (%)",
    SUM(CASE WHEN e.Status = 'In Progress' THEN 1 ELSE 0 END) AS "In Progress Enrollments",
    SUM(CASE WHEN e.Status = 'Dropped' THEN 1 ELSE 0 END) AS "Dropped Enrollments"
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.Category
ORDER BY "Completion Rate (%)" DESC, "Total Enrollments" DESC;

--Bonus Challenge (Advanced)
--11) Course Completion Funnel Analysis
--Build a query to show a funnel for each course:
--Total Enrollments,% In Progress,% Completed,% Dropped
Select
	c.CourseID,c.CourseName,c.Category,c.Price,
--Funnel Metrics
	COUNT(e.EnrollID) as "Total",
	SUM(CASE WHEN e.Status='In Progress' THEN 1 ELSE 0 END) AS "Stage1_InProgress",
	SUM(CASE WHEN e.Status='Completed' THEN 1 ELSE 0 END) AS "Stage2_Completed",
	SUM(CASE WHEN e.Status='Dropped' THEN 1 ELSE 0 END) AS "Stage3_Dropped",
-- Conversion rates between stages
ROUND(
	SUM(CASE WHEN e.Status='Completed' THEN 1 ELSE 0 END) *100.0/
	NULLIF(SUM(CASE WHEN e.Status IN ('In Progress', 'Completed') THEN 1 ELSE 0 END), 0), 
        2
    ) AS "ProgressToCompletionRate",
ROUND(
        SUM(CASE WHEN e.Status = 'Dropped' THEN 1.0 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN e.Status IN ('In Progress', 'Dropped') THEN 1 ELSE 0 END), 0), 
        2
    ) AS "ProgressToDropoutRate"
FROM Courses c
LEFT JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.CourseName, c.Category, c.Price
HAVING COUNT(e.EnrollID) > 0
ORDER BY "ProgressToCompletionRate" DESC, "Total" DESC;



 