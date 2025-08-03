CREATE table Students (
						StudentID INT primary key,
						Name varchar(30) not null,
						Gender VARCHAR(20) not null CHECK (Gender IN ('Male', 'Female', 'Other')),
						Age INT NOT NULL CHECK (Age > 0),
						City VARCHAR(30) NOT NULL,
						JoinDate DATE NOT NULL DEFAULT getdate() CHECK (JoinDate <= getdate())
						);

Create table Courses (
						CourseID int primary key,
						CourseName varchar(30) not null,
						Department varchar(30) not null
						);

Create table Enrollments (
							EnrollmentID int primary key,
							StudentID int not null,
							CourseID int not null,
							EnrollmentDate date not null default getdate() check (EnrollmentDate<=getdate()),
							foreign key (StudentID) references Students(StudentID) 
							on update cascade
							on delete cascade,
							foreign key (CourseID) references Courses(CourseID) 
							on update cascade
							on delete cascade,
							);

Create table Performance (
							PerformanceID int primary key,
							EnrollmentID int not null,
							Marks int not null check (Marks>=0 and Marks<=100),
							ExamDate date not null default getdate() check (ExamDate<=getdate()),
							foreign key (EnrollmentID) references Enrollments(EnrollmentID) 
							on update cascade
							on delete cascade,
							UNIQUE (EnrollmentID, ExamDate)
							);

Create Index Idx_Enrollemnts_StudentID on Enrollments(StudentID);
Create Index Idx_Enrollments_CourseID on Enrollments(CourseID);
Create Index Idx_Performance_EnrollmentID on Performance(EnrollmentID);
CREATE INDEX Idx_Students_JoinDate ON Students(JoinDate);
CREATE INDEX Idx_Courses_Department ON Courses(Department);

INSERT INTO Students VALUES
(1, 'Aryan', 'Male', 16, 'Delhi', '2022-06-01'),
(2, 'Riya', 'Female', 17, 'Mumbai', '2021-07-15'),
(3, 'Kabir', 'Male', 16, 'Chennai', '2022-06-10'),
(4, 'Neha', 'Female', 15, 'Kolkata', '2022-01-20'),
(5, 'Ishaan', 'Male', 17, 'Delhi', '2021-05-25');

INSERT INTO Courses VALUES
(101, 'Mathematics', 'Science'),
(102, 'English', 'Arts'),
(103, 'Physics', 'Science'),
(104, 'History', 'Arts'),
(105, 'Computer Science', 'Technology');

INSERT INTO Enrollments VALUES
(1, 1, 101, '2022-06-05'),
(2, 1, 103, '2022-06-06'),
(3, 2, 102, '2021-07-20'),
(4, 3, 101, '2022-06-11'),
(5, 3, 105, '2022-06-12'),
(6, 4, 104, '2022-01-25'),
(7, 5, 105, '2021-05-30');

INSERT INTO Performance VALUES
(1, 1, 85, '2022-09-10'),
(2, 2, 90, '2022-09-12'),
(3, 3, 75, '2021-12-10'),
(4, 4, 88, '2022-10-15'),
(5, 5, 92, '2022-10-20'),
(6, 6, 68, '2022-02-10'),
(7, 7, 79, '2021-08-30');

Select * from Students 
Select * from Courses 
Select * from Enrollments 
Select * from Performance 

--1) List all students along with the courses they are enrolled in and the department.
SELECT
    s.StudentID,s.Name AS StudentName,s.City,
    c.CourseID,c.CourseName,c.Department,
    e.EnrollmentDate
FROM
    Students s
INNER JOIN
    Enrollments e ON s.StudentID = e.StudentID
INNER JOIN
    Courses c ON e.CourseID = c.CourseID
ORDER BY
    s.Name, c.CourseName;

--2) Display average marks scored by each student across all subjects.
SELECT
    s.StudentID,s.Name AS [Student Name],
    ROUND(AVG(p.Marks), 2) AS [Average Marks],
    COUNT(e.CourseID) AS [Number of Courses]
FROM
    Students s
JOIN
    Enrollments e ON s.StudentID = e.StudentID
JOIN
    Performance p ON e.EnrollmentID = p.EnrollmentID
GROUP BY
    s.StudentID,s.Name
ORDER BY
    [Average Marks] DESC;

--3)  Find top 2 scoring students in each department based on average marks.
WITH DepartmentAverages AS (
    SELECT
        s.StudentID,s.Name AS [Student Name],c.Department,
        ROUND(AVG(p.Marks), 2) AS [Average Marks],
        RANK() OVER (PARTITION BY c.Department ORDER BY AVG(p.Marks) DESC) AS DepartmentRank
    FROM
        Students s
    JOIN
        Enrollments e ON s.StudentID = e.StudentID
    JOIN
        Performance p ON e.EnrollmentID = p.EnrollmentID
    JOIN
        Courses c ON e.CourseID = c.CourseID
    GROUP BY
        s.StudentID, s.Name, c.DepartmenT)
SELECT
    StudentID,[Student Name],Department,[Average Marks]
FROM
    DepartmentAverages
WHERE
    DepartmentRank <= 2
ORDER BY
    Department, [Average Marks] DESC;

--4) Identify students who have not scored above 75 in any subject
SELECT
    s.StudentID, s.Name AS [Student Name]
FROM
    Students s
WHERE
    NOT EXISTS (
        SELECT 1
        FROM Enrollments e
        JOIN Performance p ON e.EnrollmentID = p.EnrollmentID
        WHERE e.StudentID = s.StudentID
        AND p.Marks > 75
    )
    AND EXISTS (
        SELECT 1
        FROM Enrollments e
        JOIN Performance p ON e.EnrollmentID = p.EnrollmentID
        WHERE e.StudentID = s.StudentID
    )
ORDER BY
    s.StudentID;
				
--5) Show department-wise average performance of students.
SELECT
    c.Department,
    COUNT(DISTINCT s.StudentID) AS [Number of Students],
    COUNT(p.PerformanceID) AS [Number of Exams],
    ROUND(AVG(p.Marks), 2) AS [Department Average],
    MIN(p.Marks) AS [Minimum Score],
    MAX(p.Marks) AS [Maximum Score]
FROM
    Courses c
JOIN
    Enrollments e ON c.CourseID = e.CourseID
JOIN
    Performance p ON e.EnrollmentID = p.EnrollmentID
JOIN
    Students s ON e.StudentID = s.StudentID
GROUP BY
    c.Department
ORDER BY
    [Department Average] DESC;

--6) List students enrolled in more than one course.
SELECT
    s.StudentID,s.Name AS [Student Name],s.City,s.JoinDate,
    COUNT(DISTINCT e.CourseID) AS [Number of Courses],
    STRING_AGG(c.CourseName, ', ') WITHIN GROUP (ORDER BY c.CourseName) AS [Courses Enrolled]
FROM
    Students s
JOIN
    Enrollments e ON s.StudentID = e.StudentID
JOIN
    Courses c ON e.CourseID = c.CourseID
GROUP BY
    s.StudentID,s.Name,s.City,s.JoinDate
HAVING
    COUNT(DISTINCT e.CourseID) > 1
ORDER BY
    [Number of Courses] DESC,
    s.Name;

--7) Find students who joined in 2022 and scored above 85 in any subject.
SELECT DISTINCT
    s.StudentID,s.Name AS [Student Name],s.City,s.JoinDate,
    c.CourseName,p.Marks AS [Score]
FROM
    Students s
JOIN
    Enrollments e ON s.StudentID = e.StudentID
JOIN
    Performance p ON e.EnrollmentID = p.EnrollmentID
JOIN
    Courses c ON e.CourseID = c.CourseID
WHERE
    YEAR(s.JoinDate) = 2022
    AND p.Marks > 85
ORDER BY
    p.Marks DESC,s.Name;

--8) Display the most recent exam score of each student.
WITH RecentExams AS (
    SELECT
        s.StudentID,s.Name AS [Student Name],
        c.CourseName,p.Marks,p.ExamDate,
        ROW_NUMBER() OVER (PARTITION BY s.StudentID ORDER BY p.ExamDate DESC) AS ExamRank
    FROM
        Students s
    JOIN
        Enrollments e ON s.StudentID = e.StudentID
    JOIN
        Performance p ON e.EnrollmentID = p.EnrollmentID
    JOIN
        Courses c ON e.CourseID = c.CourseID)
SELECT
    StudentID,[Student Name],
    CourseName,Marks AS [Most Recent Score],
    ExamDate AS [Most Recent Exam Date]
FROM
    RecentExams
WHERE
    ExamRank = 1
ORDER BY
    StudentID;

--9) Find the course with the highest average marks.
WITH CourseAverages AS (
    SELECT
        c.CourseID,c.CourseName,c.Department,
        ROUND(AVG(p.Marks), 2) AS [Average Marks],
        COUNT(p.PerformanceID) AS [Number of Exams]
    FROM
        Courses c
    JOIN
        Enrollments e ON c.CourseID = e.CourseID
    JOIN
        Performance p ON e.EnrollmentID = p.EnrollmentID
    GROUP BY
        c.CourseID, c.CourseName, c.Department
)
SELECT TOP 1
    CourseName,Department,
	[Average Marks],[Number of Exams]
FROM
    CourseAverages
ORDER BY
    [Average Marks] DESC;

--10) Count how many students scored above the average of their course.
-- 10) Count how many students scored above the average of their course
WITH CourseAverages AS (
    SELECT
        e.CourseID,
        AVG(p.Marks) AS CourseAverageMark
    FROM
        Enrollments e
    JOIN
        Performance p ON e.EnrollmentID = p.EnrollmentID
    GROUP BY
        e.CourseID),
AboveAverageStudents AS (
    SELECT DISTINCT
        e.StudentID
    FROM
        Enrollments e
    JOIN
        Performance p ON e.EnrollmentID = p.EnrollmentID
    JOIN
        CourseAverages ca ON e.CourseID = ca.CourseID
    WHERE
        p.Marks > ca.CourseAverageMark
)
SELECT
    COUNT(*) AS [Number of Students Above Course Average]
FROM
    AboveAverageStudents;

-- Bonus Challenge
--Rank students within each department based on their average marks, and show only the top student per department.
WITH DepartmentStudentAverages AS (
    SELECT
        c.Department,s.StudentID,s.Name AS [Student Name],
        ROUND(AVG(p.Marks), 2) AS [Average Marks],
        COUNT(e.CourseID) AS [Courses Taken],
        RANK() OVER (PARTITION BY c.Department ORDER BY AVG(p.Marks) DESC) AS DepartmentRank
    FROM
        Students s
    JOIN
        Enrollments e ON s.StudentID = e.StudentID
    JOIN
        Performance p ON e.EnrollmentID = p.EnrollmentID
    JOIN
        Courses c ON e.CourseID = c.CourseID
    GROUP BY
        c.Department, s.StudentID, s.Name)
SELECT
    Department,[Student Name],[Average Marks],[Courses Taken]
FROM
    DepartmentStudentAverages
WHERE
    DepartmentRank = 1
ORDER BY
    [Average Marks] DESC;
