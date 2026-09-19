-- What is the average performance score by department?
SELECT 
	d.department_name,
	ROUND(AVG(performance_score),2) AS avg_performance
FROM performance_records p
JOIN employees_record e ON p.employee_id = e.employee_id
JOIN department d ON e.department_id = d.department_id
GROUP BY d.department_name

-- Which departments have the highest attrition (terminated employees) rate?
WITH employee_count AS (
	SELECT
		department_id,
		COUNT(*) AS Total_employee,
		COUNT(CASE WHEN employee_status = 'Terminated' THEN employee_id END) AS terminated_employees
	FROM employees_record
	GROUP BY department_id)

SELECT
	d.department_name,
	e.Total_employee,
	e.terminated_employees * 100 / e.Total_employee AS Attrition_rate
FROM employee_count e 
JOIN department d ON e.department_id = d.department_id
ORDER BY Attrition_rate DESC

-- What is the monthly attendance rate (Present vs. Absent vs. Leave vs. Remote) across the company?
WITH attendance_rate AS (
	SELECT
		YEAR (record_date) Yr,
		DATENAME(MONTH,record_date) AS Months,
		MONTH (record_date) Month_num,
		COUNT(*) AS Total_employee,
		COUNT(CASE WHEN attendance_status = 'Present' THEN record_id END) AS present_employees,
		COUNT(CASE WHEN attendance_status = 'Absent' THEN record_id END) AS  absent_employees,
		COUNT(CASE WHEN attendance_status = 'Leave' THEN record_id END) AS leave_employees,
		COUNT(CASE WHEN attendance_status = 'Remote' THEN record_id END) AS remote_employees
	FROM performance_records
	GROUP BY YEAR(record_date),MONTH(record_date), DATENAME(MONTH,record_date)
	)
	SELECT 
	Yr,
	Months,
	ROUND(present_employees * 100 / Total_employee,1) AS present_rate,
	ROUND(absent_employees * 100 / Total_employee,1) AS absent_rate,
	ROUND(leave_employees * 100 / Total_employee,1) AS leave_rate,
	ROUND(remote_employees * 100 / Total_employee,1) AS remote_rate
	FROM attendance_rate
	ORDER BY Yr, Month_num


-- Which employees have the highest total bonus earned over their tenure?
SELECT TOP (5)
	e.full_name,
	ROUND(p.bonus_amount,2) AS bonus_amount
FROM performance_records p
JOIN employees_record e ON p.employee_id = e.employee_id
ORDER BY p.bonus_amount DESC

--   What is the year-over-year headcount trend (hires vs. terminations) per department?
WITH hires AS(SELECT 
	department_id,
	YEAR(hire_date) Yr,
	COUNT(*) AS hired_employees
FROM employees_record e
WHERE hire_date IS NOT NULL
GROUP BY department_id,YEAR(hire_date)  
),

terminated AS
(SELECT 
	department_id,
	YEAR(termination_date) Yr,
	COUNT(*) AS terminated_employees
FROM employees_record e
WHERE termination_date IS NOT NULL
GROUP BY department_id,YEAR(termination_date) 
)
SELECT 
d.department_name,
COALESCE(h.Yr , t.Yr) AS Yr,
ISNULL(h.hired_employees,0) AS hired_employees,
ISNULL(t.terminated_employees,0) AS terminated_employees
FROM hires  h
FULL OUTER JOIN terminated t
ON h.department_id = t.department_id
AND h.Yr = t.Yr
JOIN department d 
ON d.department_id = COALESCE(h.department_id,t.department_id)
ORDER BY department_name,Yr
;

--  What is the average tenure of employees, by department?
WITH tenure_calc AS (
    SELECT 
        employee_id,
        department_id,
        employee_status,
        DATEDIFF(
            MONTH, 
            hire_date, 
            COALESCE(termination_date, '2024-12-31')
        ) AS tenure_months
    FROM employees_record
    WHERE hire_date IS NOT NULL
)
SELECT 
    d.department_name,
    ROUND(AVG(CASE WHEN t.employee_status = 'Active' THEN t.tenure_months END) / 12.0, 1) AS avg_tenure_active_years,
    ROUND(AVG(CASE WHEN t.employee_status = 'Terminated' THEN t.tenure_months END) / 12.0, 1) AS avg_tenure_terminated_years,
    COUNT(CASE WHEN t.employee_status = 'Active' THEN 1 END) AS active_count,
    COUNT(CASE WHEN t.employee_status = 'Terminated' THEN 1 END) AS terminated_count
FROM tenure_calc t
JOIN department d ON t.department_id = d.department_id
GROUP BY d.department_name
ORDER BY d.department_name;

--  Is there a gender pay gap in average base salary, overall ?

		SELECT
			ROUND(AVG(CASE WHEN gender = 'Female' THEN base_salary END),1) AS avg_female_salary,
			ROUND(AVG(CASE WHEN gender = 'Male' THEN base_salary END),1) AS avg_male_salary,
			ROUND(
					AVG(CASE WHEN gender = 'Male' THEN base_salary END) - 
					AVG(CASE WHEN gender = 'FeMale' THEN base_salary END),1
				  ) AS pay_gap,
			ROUND(
					(AVG(CASE WHEN gender = 'Male' THEN base_salary END) - 
					AVG(CASE WHEN gender = 'Female' THEN base_salary END))/
					AVG(CASE WHEN gender = 'Female' THEN base_salary END) * 100 ,
				1 ) AS pay_gap_percent
		FROM employees_record
		WHERE gender IS NOT NULL;

--  Is there a gender pay gap in average base salary by department ?

SELECT 
    d.department_name,
    ROUND(AVG(CASE WHEN e.gender = 'Male' THEN e.base_salary END), 1) AS avg_male_salary,
    ROUND(AVG(CASE WHEN e.gender = 'Female' THEN e.base_salary END), 1) AS avg_female_salary,
    ROUND(
        AVG(CASE WHEN e.gender = 'Male' THEN e.base_salary END) - 
        AVG(CASE WHEN e.gender = 'Female' THEN e.base_salary END), 
    1) AS pay_gap
FROM employees_record e
JOIN department d ON e.department_id = d.department_id
WHERE e.gender IS NOT NULL
GROUP BY d.department_name
ORDER BY pay_gap DESC;


select * from performance_records
select * from employees_record

-- Create views for power bi visualization
CREATE VIEW vw_employees_clean AS
SELECT 
    employee_id, full_name, gender, department_id, job_title,
    hire_date,
    termination_date AS termination_date,
    employee_status, marital_status, email,
    base_salary AS base_salary
FROM employees_record;

CREATE VIEW vw_performance_clean AS
SELECT 
    record_id, employee_id, 
    record_date,
     hours_worked,
    overtime_hours, performance_score, attendance_status,
    bonus_amount, salary_paid AS salary_paid
FROM performance_records;

CREATE VIEW vw_department AS
SELECT * FROM department;