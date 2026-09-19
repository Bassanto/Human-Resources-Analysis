# Data Cleaning Processes
In this page, I will be narrating my data cleaning step by step in accordance with each table. The full data cleaning query can be found in this file!
[View raw file](./HR_Analysis_sql.sql)


- `performance_records`

This the flat file which came as a text file. However, for my analysis in SQL (SMSS), I needed to import it as a .CSV file. I achieved this using excel to convert the .text file to a proper .CSV_UTF8 file. 

## Data Cleaning Process
For the data cleaning, I created the first table for the cleaning which is the staging file. 

1. I started by cleaning the date column (record_date). For a clean analysis, I created a new column for this using this SQL query
```
ALTER TABLE stag_employee_sql
ADD clean_termination_date DATE;
```
After creating the table, I went on to clean up the inconsistent date column. The date column had several inconsistent date column which are : yyyy-mm-dd,	mm/dd/yyyy,dd-mm-yyyy , dd-Mon-yyyy	, Month dd, yyyy ,dd/mm/yy. I cleaned it up using the TRY_CONVERT function so it interpretes the date coulmn well. This is how  I cleaned the first two formats 

```
-- Format 1: yyyy-mm-dd (e.g. 2022-02-18)
UPDATE stag_performance_records
SET clean_record_date = TRY_CONVERT(DATE, record_date, 23)
WHERE record_date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]';

-- Format 2: mm/dd/yyyy (e.g. 06/13/2018)
UPDATE stag_performance_records
SET clean_record_date = TRY_CONVERT(DATE, record_date, 101)
WHERE record_date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
  AND clean_record_date IS NULL;
```
2. The next was the `attendence_status` column in the table. The letter formatting were not consistent. I cleaned this using case statement with Lower(Trim()) function. 
3. For the null value in salary_paid, I replaced them with the base_salary since there is no distinguished measure to get the salary_paid. This is because am required to fill the null values. 
4. The final column in stag_performance_record is the hours_worked. 

I added a new column `clean_hours_worked ` to the table, then the next was to nullify where values are < 0. This essence of nullification is because , its obviously impossible to have work_hour < 0. Here is the query !

```UPDATE stag_performance_records
SET hours_worked_clean = NULL 
WHERE hours_worked_clean < 0;
```
After the nullification, the next is to replace all the null values. I replaced that with the average worked hours based on thier respective department. The reason is that, realistically every departmenting has their opening and closing time which guides every employee in the department. 
```
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
```
- `employee_record`

This file arrived as an Excel file, but I converted it to .csv so I 
could import it into SSMS. I achieved this by first loading it into 
Power Query — this was necessary to avoid corrupting the file, since 
Excel automatically reformats date columns on its own. However, the 
date columns in my raw file were intentionally inconsistent, so I 
needed to protect them by explicitly keeping them in text form before 
conversion.

## Data Cleaning Process
1. `full_name` and `job_title`: These columns contain the employee's 
name and job title, but were not properly formatted. The first step 
was to add new columns for the clean, formatted versions. For the 
formatting, I created a `dbo.ProperCase` function, since `LOWER()` 
alone would only convert everything to lowercase rather than proper 
case. Below is the `dbo.ProperCase` function I created:
```
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
```

2. `hire_date` and `termination_date`: 
The cleaning of these columns has same procedure with `record_date` in `performance_record` table. I added new columns and formatted then to be evenly. The null values in termination date column were left because not all employee had left. 

3. `email` : I cleaned this column by using Lower() function to lower the data formatting and I also trimmed it.
```
UPDATE stag_employee_sql
SET email = LOWER(LTRIM(RTRIM(email)))
WHERE email IS NOT NULL AND email <> '';
  ```
  4. `base_salary`: This is the finally column I cleaned in this project. It had inconsistent currency formatting and also unnecessary spaces which I cleaned.
  ``` UPDATE stag_employee_sql
SET clean_base_salary = TRY_CONVERT(
    DECIMAL(12,2), 
    REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(base_salary)), 'NGN', ''), ',', ''), ' ', '')
);
```
The next was to replace the null values and I did that using the median base_salary based on their respective department. I used median value to avoid the impact of outlier in the distribution.
```UPDATE t
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
```


After data cleaning, my next step was to create a new clean table so I could proceed with my analysis.