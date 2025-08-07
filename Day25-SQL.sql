Create table Students (
						StudentID int primary key,
						StudentName varchar (50) not null,
						Gender varchar (20) not null check (Gender in ('Male','Female')),
						Major varchar (30) not null
						);

Create table Courses (
						CourseID int primary key,
						CourseName varchar (50) not null,
						Department varchar(30) not null,
						InstructorID int not null,
						foreign key (InstructorID) references Instructors(InstructorID) on update cascade on delete cascade
						);

Create table Instructors (
							InstructorID int primary key,
							InstructorName varchar(75) not null,
							Department varchar(30) not null,
							);

Create table Enrollments (
							EnrollmentID int primary key,
							StudentID int not null,
							CourseID int not null,
							Grade char(5) not null  CHECK (Grade IN ('A', 'B', 'C', 'D', 'F')),
							UNIQUE (StudentID, CourseID),
							foreign key(StudentID) references Students(StudentID) on update cascade on delete cascade,
							foreign key (CourseID) references Courses(CourseID) on update cascade on delete cascade
							);


Create Index Idx_Enrollments_StudentID on Enrollments(StudentID);
Create Index Idx_Enrollments_CourseID on Enrollments(CourseID);
Create Index Idx_Courses_InstructorID on Courses(InstructorID);

INSERT INTO Students VALUES
(1, 'Amit Sharma', 'Male', 'Computer Science'),
(2, 'Priya Verma', 'Female', 'Mathematics'),
(3, 'Raj Mehta', 'Male', 'Physics'),
(4, 'Sneha Kapoor', 'Female', 'Computer Science');

INSERT INTO Courses VALUES
(101, 'Database Systems', 'Computer Science', 9001),
(102, 'Linear Algebra', 'Mathematics', 9002),
(103, 'Quantum Mechanics', 'Physics', 9003),
(104, 'Operating Systems', 'Computer Science', 9001);

INSERT INTO Instructors VALUES
(9001, 'Dr. Ramesh Iyer', 'Computer Science'),
(9002, 'Dr. Anjali Das', 'Mathematics'),
(9003, 'Dr. Vivek Rao', 'Physics');

INSERT INTO Enrollments VALUES
(201, 1, 101, 'A'),
(202, 2, 102, 'B'),
(203, 3, 103, 'A'),
(204, 4, 101, 'B'),
(205, 1, 104, 'A'),
(206, 2, 104, 'C');

Select * from Students 
Select * from Courses 
Select * from Instructors 
Select * from Enrollments 

--1) List all students along with their enrolled courses and corresponding grades.
SELECT
    s.StudentID, s.StudentName,
    c.CourseID, c.CourseName, e.Grade
FROM
    Students s
LEFT JOIN
    (Enrollments e JOIN Courses c ON e.CourseID = c.CourseID)
ON s.StudentID = e.StudentID
ORDER BY
    s.StudentID, c.CourseID;

--2) Display each instructor along with the number of students taught by them.
Select
	i.InstructorID,i.InstructorName,
	count (Distinct e.StudentID) as [Student Count]
from
	Instructors i
left join
	Courses c
on i.InstructorID =c.InstructorID 
left join
	Enrollments e
on e.CourseID =c.CourseID 
Group by
	i.InstructorID,i.InstructorName
Order by
	[Student Count] Desc;

--3) Show the average grade per course (assume A=4, B=3, C=2, D=1).
SELECT
    c.CourseID,c.CourseName,
    ROUND(AVG(CASE e.Grade
        WHEN 'A' THEN 4
        WHEN 'B' THEN 3
        WHEN 'C' THEN 2
        WHEN 'D' THEN 1
        ELSE 0  -- Handles any unexpected grades
    END), 2) AS AverageGradeNumeric,
    COUNT(e.StudentID) AS EnrollmentCount
FROM
    Courses c
LEFT JOIN
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY
    c.CourseID, c.CourseName
ORDER BY
    AverageGradeNumeric DESC;

--4) Find the most popular course based on enrollments.
Select top 1
	c.CourseID,c.CourseName,
	Count(e.StudentID) as [EnrollmentCount]
from
	Courses c
join
	Enrollments e
on c.CourseID =e.CourseID 
Group by
	c.CourseID,c.CourseName
Order by
	[EnrollmentCount] Desc;

--5) List students who have taken more than one course.
Select
	s.StudentID,s.StudentName,
	Count (e.CourseID) as [CourseCount]
from
	Students s
join
	Enrollments e
on s.StudentID =e.StudentID 
Group by
	s.StudentID,s.StudentName
Having
	Count (e.CourseID)>1
Order by
	[CourseCount]Desc;

--Alternative with course Name
SELECT
    s.StudentID,s.StudentName,
    COUNT(e.CourseID) AS CourseCount,
    STRING_AGG(c.CourseName, ', ') AS CoursesTaken
FROM
    Students s
JOIN
    Enrollments e ON s.StudentID = e.StudentID
JOIN
    Courses c ON e.CourseID = c.CourseID
GROUP BY
    s.StudentID, s.StudentName
HAVING
    COUNT(e.CourseID) > 1
ORDER BY
    CourseCount DESC;

--6) Identify courses with no enrolled students.
SELECT
    c.CourseID,c.CourseName,
    COUNT(e.StudentID) AS [EnrollmentCount]
FROM
    Courses c
LEFT JOIN
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY
    c.CourseID, c.CourseName
HAVING
    COUNT(e.StudentID) = 0
ORDER BY
    c.CourseID;

--7) Show the distribution of grades for each department.
SELECT
    Department,
    SUM(CASE WHEN Grade = 'A' THEN 1 ELSE 0 END) AS A_Count,
    SUM(CASE WHEN Grade = 'B' THEN 1 ELSE 0 END) AS B_Count,
    SUM(CASE WHEN Grade = 'C' THEN 1 ELSE 0 END) AS C_Count,
    SUM(CASE WHEN Grade = 'D' THEN 1 ELSE 0 END) AS D_Count,
    SUM(CASE WHEN Grade = 'F' THEN 1 ELSE 0 END) AS F_Count,
    COUNT(*) AS TotalEnrollments
FROM
    Courses c
JOIN
    Enrollments e ON c.CourseID = e.CourseID
GROUP BY
    Department
ORDER BY
    Department;
	
--8) Rank courses by student performance (average grade).
WITH CourseGrades AS (
    SELECT
        c.CourseID,c.CourseName,c.Department,
        AVG(CASE e.Grade
            WHEN 'A' THEN 4.0
            WHEN 'B' THEN 3.0
            WHEN 'C' THEN 2.0
            WHEN 'D' THEN 1.0
            ELSE 0.0
        END) AS AvgGradePoints,
        COUNT(e.StudentID) AS EnrollmentCount
    FROM
        Courses c
    LEFT JOIN
        Enrollments e ON c.CourseID = e.CourseID
    GROUP BY
        c.CourseID, c.CourseName, c.Department
    HAVING
        COUNT(e.StudentID) > 0  -- Only include courses with enrollments
)
SELECT
    CourseID,CourseName,
    Department,
    ROUND(AvgGradePoints, 2) AS AvgGradePoints,
    EnrollmentCount,
    DENSE_RANK() OVER (ORDER BY AvgGradePoints DESC) AS PerformanceRank
FROM
    CourseGrades
ORDER BY
    PerformanceRank;

--9) Display students who scored an A in all their courses.
SELECT
    s.StudentID,s.StudentName
FROM
    Students s
WHERE
    NOT EXISTS (
        -- Find any enrollments where the student didn't get an A
        SELECT 1
        FROM Enrollments e
        WHERE e.StudentID = s.StudentID
        AND e.Grade <> 'A'
    )
    AND EXISTS (
        -- Ensure the student has at least one enrollment
        SELECT 1
        FROM Enrollments e
        WHERE e.StudentID = s.StudentID
    );

--10) List departments along with their total enrollments and average grade.
SELECT
    c.Department,
    COUNT(e.StudentID) AS [TotalEnrollments],
    ROUND(ISNULL(AVG(CASE e.Grade
        WHEN 'A' THEN 4.0
        WHEN 'B' THEN 3.0
        WHEN 'C' THEN 2.0
        WHEN 'D' THEN 1.0
        ELSE 0.0
    END), 0), 2) AS AvgGradePoints
FROM Courses c
LEFT JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.Department
ORDER BY [TotalEnrollments] DESC;

-- Bonus Challenge
-- Find the top 2 students with the highest average grades across all enrolled courses.
WITH StudentGrades AS (
    SELECT
        s.StudentID,s.StudentName,
        AVG(CASE e.Grade
            WHEN 'A' THEN 4.0
            WHEN 'B' THEN 3.0
            WHEN 'C' THEN 2.0
            WHEN 'D' THEN 1.0
            ELSE 0.0
        END) AS NumericAvg,
        COUNT(*) AS CoursesTaken
    FROM Students s
    JOIN Enrollments e ON s.StudentID = e.StudentID
    GROUP BY s.StudentID, s.StudentName)
SELECT TOP 2
    StudentID,StudentName,
    ROUND(NumericAvg, 2) AS AvgGradePoints,
    CASE
        WHEN NumericAvg >= 3.7 THEN 'A'
        WHEN NumericAvg >= 3.3 THEN 'A-'
        WHEN NumericAvg >= 3.0 THEN 'B+'
        WHEN NumericAvg >= 2.7 THEN 'B'
        WHEN NumericAvg >= 2.3 THEN 'B-'
        WHEN NumericAvg >= 2.0 THEN 'C+'
        WHEN NumericAvg >= 1.7 THEN 'C'
        WHEN NumericAvg >= 1.3 THEN 'C-'
        WHEN NumericAvg >= 1.0 THEN 'D+'
        ELSE 'F'
    END AS LetterGrade,
    CoursesTaken
FROM StudentGrades
ORDER BY NumericAvg DESC;