-- TABLE 1: Departments
CREATE TABLE departments (
    departmentid INT PRIMARY KEY,
    departmentname VARCHAR(100) NOT NULL
);

INSERT INTO departments (departmentid, departmentname) VALUES
(1, 'Computer Science'),
(2, 'Mathematics');

-- TABLE 2: Students
CREATE TABLE students (
    studentid INT PRIMARY KEY,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    birthdate DATE,
    enrollmentdate DATE
);


-- TABLE 3: Instructors
CREATE TABLE instructors (
    instructorid INT PRIMARY KEY,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    departmentid INT REFERENCES departments(departmentid),
    salary NUMERIC(10, 2)
);

INSERT INTO instructors
(instructorid, firstname, lastname, email, departmentid, salary)
VALUES
(1, 'Alice', 'Johnson', 'alice.johnson@univ.com', 1, 65000),
(2, 'Bob', 'Lee', 'bob.lee@univ.com', 2, 60000)
ON CONFLICT (instructorid) DO NOTHING;



-- TABLE 4: Courses
CREATE TABLE courses (
    courseid INT PRIMARY KEY,
    coursename VARCHAR(100) NOT NULL,
    departmentid INT REFERENCES departments(departmentid),
    credits INT CHECK (credits > 0)
);


INSERT INTO courses
(courseid, coursename, departmentid, credits)
VALUES
(101, 'Introduction to SQL', 1, 3),
(102, 'Data Structures', 2, 4)
ON CONFLICT (courseid) DO NOTHING;


-- TABLE 5: Enrollments
CREATE TABLE enrollments (
    enrollmentid INT PRIMARY KEY,
    studentid INT REFERENCES students(studentid),
    courseid INT REFERENCES courses(courseid),
    enrollmentdate DATE
);

INSERT INTO enrollments
(enrollmentid, studentid, courseid, enrollmentdate)
VALUES
(1, 1, 101, '2022-08-01'),
(2, 2, 102, '2021-08-01')
ON CONFLICT (enrollmentid) DO NOTHING;


ALTER TABLE public.enrollments 
DROP COLUMN IF EXISTS grade,
DROP COLUMN IF EXISTS semester;

-- 1. Perform CRUD Operations on all tables.
SELECT * FROM students;
SELECT * FROM courses;
SELECT * FROM instructors;
SELECT * FROM enrollments;
SELECT * FROM departments;

--UPDATE example 
UPDATE students
SET firstname = 'Aarav'
where studentid = 1;

--DELETE example (run only when needed)
--DELETE FROM students WHERE studentid = 1;


-- 2. Retrieve students who enrolled after 2022.
SELECT * FROM enrollments 
WHERE enrollmentdate >= DATE '2023-01-01';

-- 3. Retrieve courses offered by the Mathematics department with a limit of 5 courses.
SELECT c.* 
FROM courses c 
JOIN departments d ON c.departmentid = d.departmentid
WHERE d.departmentname = 'Mathematics' 
LIMIT 5;

-- 4. Get the number of students enrolled in each course, filtering for courses with more than 5 students.
SELECT c.courseid, c.coursename, COUNT(e.studentid) AS total_students 
FROM courses c 
JOIN enrollments e ON c.courseid = e.courseid 
GROUP BY c.courseid, c.coursename 
HAVING COUNT(e.studentid) > 5;

-- 5. Find students who are enrolled in both Introduction to SQL and Data Structures.
SELECT e.studentid 
FROM enrollments e
JOIN courses c ON e.courseid = c.courseid
WHERE c.coursename IN ('Introduction to SQL', 'Data Structures') 
GROUP BY e.studentid 
HAVING COUNT(DISTINCT c.courseid) = 2;

-- 6. Find students who are either enrolled in Introduction to SQL or Data Structures.
SELECT DISTINCT e.studentid, s.firstname, s.lastname
FROM enrollments e
JOIN courses c ON e.courseid = c.courseid
JOIN students s ON e.studentid = s.studentid
WHERE c.coursename IN ('Introduction to SQL', 'Data Structures');

-- 7. Calculate the average number of credits for all courses.
SELECT AVG(credits) AS average_credits 
FROM courses;

-- 8. Find the maximum salary of instructors in the Computer Science department.
SELECT MAX(i.salary) AS max_salary 
FROM instructors i
JOIN departments d ON i.departmentid = d.departmentid
WHERE d.departmentname = 'Computer Science';

-- 9. Count the number of students enrolled in each department.
SELECT d.departmentname, COUNT(DISTINCT e.studentid) AS total_students 
FROM departments d
JOIN courses c ON d.departmentid = c.departmentid
JOIN enrollments e ON c.courseid = e.courseid 
GROUP BY d.departmentid, d.departmentname;

-- 10. INNER JOIN: Retrieve students and their corresponding courses.
SELECT s.studentid, s.firstname, s.lastname, c.coursename 
FROM students s 
INNER JOIN enrollments e ON s.studentid = e.studentid 
INNER JOIN courses c ON e.courseid = c.courseid;

-- 11. LEFT JOIN: Retrieve all students and their corresponding courses, if any.
SELECT s.studentid, s.firstname, s.lastname, c.coursename 
FROM students s 
LEFT JOIN enrollments e ON s.studentid = e.studentid 
LEFT JOIN courses c ON e.courseid = c.courseid;

-- 12. Subquery: Find students enrolled in courses that have more than 10 students.
SELECT * FROM students 
WHERE studentid IN (
    SELECT studentid FROM enrollments 
    WHERE courseid IN (
        SELECT courseid FROM enrollments 
        GROUP BY courseid 
        HAVING COUNT(studentid) > 10 
    )
);

-- 13. Extract the year from the EnrollmentDate of students.
SELECT studentid, EXTRACT(YEAR FROM enrollmentdate) AS enrollment_year 
FROM enrollments;

-- 14. Concatenate the instructor's first and last name.
SELECT instructorid, CONCAT(firstname, ' ', lastname) AS instructor_name 
FROM instructors;

-- 15. Calculate the running total of students enrolled in courses.
SELECT enrollmentid, studentid, courseid, COUNT(*) OVER (ORDER BY enrollmentid) AS running_total 
FROM enrollments;

-- 16. Label students as 'Senior' or 'Junior' based on their year of enrollment. (If the enrollment date is more than 4 years from the current date, put the label 'Senior' otherwise 'Junior')
SELECT studentid, enrollmentdate, 
    CASE 
        WHEN enrollmentdate < CURRENT_DATE - INTERVAL '4 years' THEN 'Senior' 
        ELSE 'Junior' 
    END AS student_level 
FROM students;  
