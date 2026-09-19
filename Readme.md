# Human Resources Analysis 

[View raw file](./HR_Analysis.pbix)
## Introduction

This is a synthetic dataset built around a deep dive into Human 
Resources analysis. It reviews different job roles alongside their 
respective attrition rates and other relevant categories.

It's also a great way for me to showcase my data analytics skills 
especially the full workflow across different tools.

Note that this dataset is strictly synthetic , meaning its findings 
are not statistically representative of any real organization. The 
aim of this project is to demonstrate my data analytical skills, not 
to draw real-world conclusions.

Here is the data dictionary which contains the project instructions and problem I tackled.[View raw file](./HR_dictionary_sql.docx)

## Dataset Overview

This project comprises three separate, messy tables that I cleaned 
before analysis. The full cleaning process is documented in 
[Data_cleaning.md](Data_cleaning.md).

### 1. Department Table
[View raw file](./departments.json)

Contains each department's `department_id`, `department_name`, and 
`location`. This table was clean by design, with no data quality 
issues.

![Department Table](/0_Resources/Images/department_table.png)

### 2. Employee Table
[View raw file](./employees.csv)

Contains every employee's individual information — including hire 
date, job title, department, salary, marital status, and contact 
details. This was the messiest of the three tables, with inconsistent 
date formats, missing values, and inconsistent text casing.

![Employee Table](/0_Resources/Images/employee_table.png)

### 3. Performance Table
[View raw file](./performance_records.txt)

The main flat file for this project — one row per employee per month, 
recording attendance, hours worked, overtime, performance score, 
bonuses, and salary paid. At over 13,000 rows, this is the largest 
table and the primary fact table joined against the other two.

![Performance Table](/0_Resources/Images/performance_table.png)

## Tools Used

I used several tools throughout this project:

- **Excel:** Used initially to convert files from their original 
  format into CSV. This had to be done carefully to avoid corrupting 
  the data ; the tables were messy (inconsistent date formats, 
  inconsistent text formatting, etc.) and needed meticulous handling. 
  The `employees.xlsx` file specifically was converted using Power 
  Query, keeping the date columns as Text type to prevent Excel from 
  silently corrupting the dates on save.

- **SQL:** The bedrock of this project . All data cleaning and 
  analysis were done in SQL.

- **Power BI:** Used to build and visualize the final dashboard.

- **VS Code:** Used for documentation and managing the project's 
  files.

- **GitHub:** Used for version control and to host the project 
  publicly.

  ## Analysis 
1. Attrition Rate : Information Technology department has the highest attrition rate with 38% rate irrespective of the fact it also has one of the highest employees (88).
  
  On the other hand, Human Resources department has the lowest attrition with 20% rate. This mean that attrition is lowest with respect to total employed people in the department. 

2. Base Salary : Generally, the average male salary is 3% higher than the female salary with 16020.60 Naira gap.

The number of employee based on gender is a contributory factor to this. There is 422 male and 404 female.

In the department level, male keep dominating except in Information Technology department,Procurement department,Marketing department where female average base salary is higher. 

Worth noting, the salary band seems counterintuitive because the attrition increases as the salary band increases. However, this is a real-life scenerio since most employees tend to leave there job when they get to the peak of the possible expected salary from a job. This is to try other  opportunity elsewhere with potential higher salary.

3. Employee Tenure : 

**Insight:** Every department shows active employees with longer 
average tenure than terminated ones which is a  expected pattern 
where early attrition is more common than late-career departure. 
**Information Technology stands out** with the widest gap (5.9 years 
active vs. 2.5 years terminated) and the highest terminated count 
(34) relative to its active headcount (40), signaling a pronounced 
early-attrition problem specific to that department. **Human 
Resources shows the smallest gap** (4.8 vs. 3.3 years), suggesting 
its attrition is more evenly spread across tenure rather than 
concentrated early on.

## Recommendations
- **Prioritize retention efforts in Information Technology**  
It has 
  both the highest departmental attrition rate (38.64%) and the 
  widest gap between active and terminated employee tenure, pointing 
  to an early-career retention issue specific to this department.

- **Focus onboarding and early-tenure support company-wide:**  
Every 
  department shows employees leaving well before the average tenure 
  of those who stay, suggesting the first 2–3 years are the highest 
  attrition risk window across the business, not just in one team.

- Finally , treat these findings as illustrative, not conclusive. This project 
uses synthetic data, with categories like salary, job titles, and 
other values generated independently of one another. The patterns 
observed here should be read as hypotheses to test against a real 
dataset, not as validated business conclusions.

## Conclusion

In conclusion, this project strengthened my workflow of effectively 
combining different analytical skills into a complete analysis — 
starting with Excel, progressing to SQL for data cleaning and 
analysis, and finally visualizing the results in Power BI.