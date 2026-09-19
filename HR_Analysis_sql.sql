SELECT employee_status,termination_date,clean_termination_date
FROM stag_employee_sql
WHERE employee_status = 'Terminated'


-- Data Cleaning Process
-- 1. Date columns cleaning
ALTER TABLE stag_employee_sql
ADD clean_termination_date DATE;

-- Format 1: yyyy-mm-dd (e.g. 2022-02-18)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 23)
WHERE termination_date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]';

-- Format 2: mm/dd/yyyy (e.g. 06/13/2018)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 101)
WHERE termination_date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
  AND clean_termination_date IS NULL;

-- Format 3: dd-mm-yyyy (e.g. 10-04-2021)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 105)
WHERE termination_date LIKE '[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]'
  AND clean_termination_date IS NULL;

-- Format 4: dd-Mon-yyyy (e.g. 26-Apr-2024)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 106)
WHERE termination_date LIKE '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9][0-9][0-9]'
  AND clean_termination_date IS NULL;

-- Format 5: Month dd, yyyy (e.g. February 18, 2022)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 107)
WHERE termination_date LIKE '%,%'
  AND clean_termination_date IS NULL;

-- Format 6: dd/mm/yy (e.g. 14/08/24)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 3)
WHERE termination_date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9]'
  AND clean_termination_date IS NULL;

-- Format 7: dd-Mon-yy, 2-digit year (defensive, uses correct style 6)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 6)
WHERE termination_date LIKE '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9]'
  AND clean_termination_date IS NULL;

-- Format 8: m/dd/yyyy, single-digit month (defensive)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 101)
WHERE termination_date LIKE '[0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
  AND clean_termination_date IS NULL;

-- Format 9: d-Mon-yy, single-digit day (defensive, uses correct style 6)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 6)
WHERE termination_date LIKE '[0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9]'
  AND clean_termination_date IS NULL;

-- Format 10: mm/d/yyyy, single-digit day (defensive)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 101)
WHERE termination_date LIKE '[0-9][0-9]/[0-9]/[0-9][0-9][0-9][0-9]'
  AND clean_termination_date IS NULL;

-- Format 11: m/d/yyyy, single-digit month and day (defensive)
UPDATE stag_employee_sql
SET clean_termination_date = TRY_CONVERT(DATE, termination_date, 101)
WHERE termination_date LIKE '[0-9]/[0-9]/[0-9][0-9][0-9][0-9]'
  AND clean_termination_date IS NULL;

-- 2. Letter standardization
UPDATE stag_employee_sql
SET employee_status = 
	CASE 
		WHEN 
LOWER(TRIM(employee_status)) = 
'on leave' THEN 'On Leave'
		WHEN
LOWER(TRIM(employee_status)) = 
'terminated' THEN 'Terminated'
		WHEN 
LOWER(TRIM(employee_status)) =
'active' THEN 'Active'
--		WHEN 
--LOWER(TRIM(attendance_status)) =
--'leave' THEN 'Leave'
		ELSE TRIM(employee_status)
		END;


-- Clean job title
UPDATE stag_employee_sql
SET job_title = LOWER(TRIM(job_title));

-- standardization of words
CREATE FUNCTION dbo.ProperCase (@input VARCHAR(200))
RETURNS VARCHAR(200)
AS
BEGIN
    DECLARE @result VARCHAR(200) = '';
    DECLARE @i INT = 1;
    DECLARE @char CHAR(1);
    DECLARE @prevChar CHAR(1) = ' ';

    SET @input = LTRIM(RTRIM(@input));

    WHILE @i <= LEN(@input)
    BEGIN
        SET @char = SUBSTRING(@input, @i, 1);

        IF @prevChar = ' '
            SET @result = @result + UPPER(@char);
        ELSE
            SET @result = @result + LOWER(@char);

        SET @prevChar = @char;
        SET @i = @i + 1;
    END

    RETURN @result;
END;

UPDATE stag_employee_sql
SET full_name = dbo.ProperCase(full_name);

UPDATE stag_employee_sql
SET job_title = dbo.ProperCase(job_title);

-- clean email
UPDATE stag_employee_sql
SET email = LOWER(LTRIM(RTRIM(email)))
WHERE email IS NOT NULL AND email <> '';

-- clean marital status
UPDATE stag_employee_sql
SET marital_status = 'Unidentified'
WHERE marital_status IS NULL ;

--  clean attendance_status
UPDATE performance_records
SET attendance_status = 'Present'
WHERE attendance_status = 'Parent'

-- clean base salary 
ALTER TABLE stag_employee_sql
ADD clean_base_salary DECIMAL(12,2);

-- transfer cleaned base salary

UPDATE stag_employee_sql
SET clean_base_salary = TRY_CONVERT(
    DECIMAL(12,2), 
    REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(base_salary)), 'NGN', ''), ',', ''), ' ', '')
);

-- Replace blank salary with their respective median salary
UPDATE t
SET t.clean_base_salary = dept_median.median_salary
FROM stag_employee_sql t
JOIN (
SELECT DISTINCT 
    department_id,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_base_salary)
        OVER (PARTITION BY department_id) AS median_salary
    FROM stag_employee_sql
    WHERE clean_base_salary IS NOT NULL) dept_median 
    ON t.department_id = dept_median.department_id
    WHERE t.clean_base_salary IS NULL;



-- Add new column for clean salary paid
ALTER TABLE stag_performance_records
ADD salary_paid_clean DECIMAL(12,2);

UPDATE stag_performance_records
SET salary_paid_clean = TRY_CONVERT(DECIMAL(12,2), salary_paid);

-- filling null value in salary pain with their base salary
UPDATE P 
SET p.salary_paid_clean = e.clean_base_salary
FROM stag_performance_records p
JOIN stag_employee_sql e ON p.employee_id = e.employee_id
WHERE salary_paid IS NULL

-- clean hours worked

-- Step 1: Add the new column
ALTER TABLE stag_performance_records
ADD hours_worked_clean DECIMAL(6,1);

-- Step 2: Populate it from the original hours_worked column
UPDATE stag_performance_records
SET hours_worked_clean = TRY_CONVERT(DECIMAL(6,1), hours_worked);

-- nullify worked hour < 0
UPDATE stag_performance_records
SET hours_worked_clean = NULL 
WHERE hours_worked_clean < 0;


-- input department hour avg to the null 
UPDATE p
SET p.hours_worked_clean = dept_avg.avg_hours
FROM stag_performance_records p
JOIN stag_employee_sql e ON p.employee_id = e.employee_id
JOIN (
          SELECT 
                e2.department_id,
                AVG(hours_worked_clean) AS avg_hours
          FROM stag_performance_records p2
            JOIN stag_employee_sql e2 ON p2.employee_id = e2.employee_id
           WHERE hours_worked_clean IS NOT NULL
           GROUP BY department_id
       ) dept_avg 
  ON e.department_id = dept_avg.department_id
WHERE p.hours_worked_clean IS  NULL ;

-- Importing into new main table
SELECT
    record_id,
    employee_id,
    overtime_hours,
    performance_score,
    attendance_status,
    bonus_amount,
    clean_record_date AS record_date,
    salary_paid_clean AS salary_paid,
    hours_worked_clean AS hours_worked
INTO performance_records
FROM stag_performance_records;

SELECT
    employee_id,
    full_name,
    gender,
    department_id,
    job_title,
    employee_status,
    marital_status,
    email,
    clean_base_salary AS base_salary,
    clean_hire_date AS hire_date,
    clean_termination_date AS termination_date
INTO employees_record
FROM stag_employee_sql








select * 
from stag_performance_records;

select * 
from performance_records;

select * 
from stag_employee_sql;

select * 
from employees_record


