# Oracle SQL Implementation & Laboratory Cycle Sheets I – VI Report

**Domain:** Enterprise Human Resource & Project Allocation System (*Company DB*)  
**Target RDBMS:** Oracle Database (11g / 12c / 19c / 21c / 23c / Oracle Live SQL)  
**Submission:** DBMS Laboratory & Final Project Submission Report  

---

## 📑 Table of Contents
1. [How to Connect to Oracle Database](#1-how-to-connect-to-oracle-database)
2. [Database Schema & Data Dictionary](#2-database-schema--data-dictionary)
3. [Cycle Sheet I: DDL Commands & Integrity Constraints](#3-cycle-sheet-i-ddl-commands--integrity-constraints)
4. [Cycle Sheet II: Data Population, DML & Basic Querying](#4-cycle-sheet-ii-data-population-dml--basic-querying)
5. [Cycle Sheet III: Aggregate Functions, Group By, Having, Scalar Functions & Set Operations](#5-cycle-sheet-iii-aggregate-functions-group-by-having-scalar-functions--set-operations)
6. [Cycle Sheet IV: Complex Queries, Multi-table Joins & Subqueries](#6-cycle-sheet-iv-complex-queries-multi-table-joins--subqueries)
7. [Cycle Sheet V: Database Objects (Views, Sequences, Indexes, Synonyms) & TCL Transactions](#7-cycle-sheet-v-database-objects-views-sequences-indexes-synonyms--tcl-transactions)
8. [Cycle Sheet VI: PL/SQL Programming, Stored Procedures, Triggers & DCL Security](#8-cycle-sheet-vi-plsql-programming-stored-procedures-triggers--dcl-security)

---

## 1. How to Connect to Oracle Database

### Method A: Oracle Live SQL (Zero Installation — Recommended for Instant Testing)
Oracle provides a 100% free, full-featured Oracle 19c/23c database running in your browser:
1. Visit **[https://livesql.oracle.com](https://livesql.oracle.com)**.
2. Click **Start Coding Now** and sign in with any free Oracle account.
3. Click on **SQL Worksheet** in the left sidebar.
4. Open the provided [`oracle_lab_cycle_sheets_I_to_VI.sql`](file:///d:/Study%20Mat/dbms%20project/oracle_lab_cycle_sheets_I_to_VI.sql) file, copy the SQL blocks, paste them into the worksheet, and click **Run**.
5. Outputs are rendered immediately in interactive tables with instant downloadable reports.

---

### Method B: Oracle SQL Developer (Standard University Lab GUI)
If you have Oracle Database Express Edition (XE) or Enterprise Edition installed locally or on a lab server:
1. Open **Oracle SQL Developer**.
2. Click the green **`+` (New Connection)** icon in the top-left pane.
3. Configure the connection parameters:
   - **Connection Name:** `Local_Oracle_XE`
   - **Username:** `system` (or `dbms_user` if user created)
   - **Password:** `<your_password>` (e.g. `oracle` or `admin`)
   - **Hostname:** `localhost` (or `127.0.0.1`)
   - **Port:** `1521`
   - **Service Name:** `XEPDB1` (or SID `xe` for 11g XE)
4. Click **Test**. When the status displays `Success`, click **Connect**.
5. Open a new SQL Worksheet (`Alt + F10`), paste the SQL script, and press **F5 (Run Script)**.

---

### Method C: SQL*Plus (Command Line)
1. Open Windows Terminal, PowerShell, or Command Prompt.
2. Connect to the local Oracle pluggable database:
   ```cmd
   sqlplus system/oracle@localhost:1521/XEPDB1
   ```
3. Or login as SYSDBA to create a clean user:
   ```sql
   sqlplus / as sysdba
   ALTER SESSION SET CONTAINER = XEPDB1;
   CREATE USER dbms_user IDENTIFIED BY OraclePass123;
   GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO dbms_user;
   CONNECT dbms_user/OraclePass123@localhost:1521/XEPDB1;
   ```
4. Run the entire script file directly:
   ```sql
   @d:\Study Mat\dbms project\oracle_lab_cycle_sheets_I_to_VI.sql;
   ```

---

## 2. Database Schema & Data Dictionary

### Entity-Relationship Architecture
```text
 +------------------+           1:N           +---------------------+
 |   DEPARTMENTS    |<-----------------------|      EMPLOYEES      |
 |------------------|                         |---------------------|
 | PK: dept_id      |                         | PK: emp_id          |
 | UK: dept_name    |                         | FK: dept_id         |
 |     location     |                         | FK: manager_id (Self|
 |     budget (>0)  |                         | UK: email           |
 +------------------+                         |     salary, job...  |
          | 1                                 +---------------------+
          |                                              | 1
          | 1:N                                          |
          v                                              v M
 +------------------+           1:N           +---------------------+
 |     PROJECTS     |<-----------------------|     ASSIGNMENTS     |
 |------------------|                         |---------------------|
 | PK: project_id   |                         | Composite PK:       |
 | UK: project_name |                         | (emp_id, project_id)|
 | FK: dept_id      |                         |     role, rating    |
 |     dates        |                         |     hours_allocated |
 +------------------+                         +---------------------+
```

---

## 3. Cycle Sheet I: DDL Commands & Integrity Constraints

### 3.1 Table Definitions with All Five Constraint Classes
```sql
-- 1. Departments Table (PK, UNIQUE, NOT NULL, CHECK)
CREATE TABLE DEPARTMENTS (
    dept_id     NUMBER(4)          CONSTRAINT pk_departments PRIMARY KEY,
    dept_name   VARCHAR2(50)       CONSTRAINT unq_dept_name UNIQUE NOT NULL,
    location    VARCHAR2(50)       CONSTRAINT nn_dept_location NOT NULL,
    budget      NUMBER(12, 2)      CONSTRAINT chk_dept_budget CHECK (budget > 0)
);

-- 2. Employees Table (PK, FK, Self-referential FK, CHECK, NOT NULL)
CREATE TABLE EMPLOYEES (
    emp_id          NUMBER(6)      CONSTRAINT pk_employees PRIMARY KEY,
    first_name      VARCHAR2(30)   CONSTRAINT nn_emp_fname NOT NULL,
    last_name       VARCHAR2(30)   CONSTRAINT nn_emp_lname NOT NULL,
    email           VARCHAR2(60)   CONSTRAINT unq_emp_email UNIQUE,
    phone_number    VARCHAR2(20),
    hire_date       DATE           DEFAULT SYSDATE CONSTRAINT nn_emp_hdate NOT NULL,
    job_title       VARCHAR2(35)   CONSTRAINT nn_emp_job NOT NULL,
    salary          NUMBER(8, 2)   CONSTRAINT chk_emp_salary CHECK (salary >= 15000),
    commission_pct  NUMBER(3, 2)   CONSTRAINT chk_emp_comm CHECK (commission_pct BETWEEN 0 AND 0.50),
    manager_id      NUMBER(6)      CONSTRAINT fk_emp_manager REFERENCES EMPLOYEES(emp_id),
    dept_id         NUMBER(4)      CONSTRAINT fk_emp_dept REFERENCES DEPARTMENTS(dept_id) ON DELETE SET NULL
);

-- 3. Projects Table (PK, FK with CASCADE, CHECK dates)
CREATE TABLE PROJECTS (
    project_id      NUMBER(5)      CONSTRAINT pk_projects PRIMARY KEY,
    project_name    VARCHAR2(60)   CONSTRAINT unq_project_name UNIQUE NOT NULL,
    start_date      DATE           CONSTRAINT nn_proj_sdate NOT NULL,
    end_date        DATE,
    dept_id         NUMBER(4)      CONSTRAINT fk_proj_dept REFERENCES DEPARTMENTS(dept_id) ON DELETE CASCADE,
    CONSTRAINT chk_proj_dates CHECK (end_date >= start_date)
);

-- 4. Assignments Junction Table (Composite Primary Key & Foreign Keys)
CREATE TABLE ASSIGNMENTS (
    emp_id          NUMBER(6)      CONSTRAINT fk_asgn_emp REFERENCES EMPLOYEES(emp_id) ON DELETE CASCADE,
    project_id      NUMBER(5)      CONSTRAINT fk_asgn_proj REFERENCES PROJECTS(project_id) ON DELETE CASCADE,
    role            VARCHAR2(30)   DEFAULT 'Contributor' NOT NULL,
    hours_allocated NUMBER(4)      CONSTRAINT chk_asgn_hours CHECK (hours_allocated > 0),
    rating          NUMBER(2, 1)   CONSTRAINT chk_asgn_rating CHECK (rating BETWEEN 1.0 AND 5.0),
    CONSTRAINT pk_assignments PRIMARY KEY (emp_id, project_id)
);
```

**Output:**
```text
Table DEPARTMENTS created.
Table EMPLOYEES created.
Table PROJECTS created.
Table ASSIGNMENTS created.
```

### 3.2 ALTER TABLE Operations
```sql
-- Add column
ALTER TABLE DEPARTMENTS ADD (director_name VARCHAR2(60));

-- Modify column datatype & width
ALTER TABLE DEPARTMENTS MODIFY (director_name VARCHAR2(80));

-- Drop column
ALTER TABLE DEPARTMENTS DROP COLUMN director_name;
```

**Output:**
```text
Table DEPARTMENTS altered.
Table DEPARTMENTS altered.
Table DEPARTMENTS altered.
```

### 3.3 Verification of Integrity Constraint Violations (Viva / Lab Verification)
1. **Primary Key Violation:**
   ```sql
   INSERT INTO DEPARTMENTS VALUES (10, 'Duplicate IT', 'Delhi', 50000);
   -- Error: ORA-00001: unique constraint (DBMS_USER.PK_DEPARTMENTS) violated
   ```
2. **Foreign Key Violation:**
   ```sql
   INSERT INTO EMPLOYEES (emp_id, first_name, last_name, dept_id) VALUES (999, 'Test', 'User', 9999);
   -- Error: ORA-02291: integrity constraint (DBMS_USER.FK_EMP_DEPT) violated - parent key not found
   ```
3. **Check Constraint Violation:**
   ```sql
   INSERT INTO DEPARTMENTS VALUES (99, 'Faulty Dept', 'Pune', -500);
   -- Error: ORA-02290: check constraint (DBMS_USER.CHK_DEPT_BUDGET) violated
   ```

---

## 4. Cycle Sheet II: Data Population, DML & Basic Querying

### 4.1 Sample Data Population (INSERT Statements)
```sql
-- Departments
INSERT INTO DEPARTMENTS VALUES (10, 'Information Technology', 'Bangalore', 5000000.00);
INSERT INTO DEPARTMENTS VALUES (20, 'Human Resources', 'Mumbai', 1200000.00);
INSERT INTO DEPARTMENTS VALUES (30, 'Finance & Accounting', 'New Delhi', 3500000.00);
INSERT INTO DEPARTMENTS VALUES (40, 'Sales & Marketing', 'Hyderabad', 2800000.00);
INSERT INTO DEPARTMENTS VALUES (50, 'Research & Development', 'Pune', 4200000.00);

-- Employees
INSERT INTO EMPLOYEES VALUES (101, 'Rajesh', 'Sharma', 'rajesh.sharma@corp.com', '9876543210', TO_DATE('2018-03-15', 'YYYY-MM-DD'), 'Chief Technology Officer', 125000.00, 0.15, NULL, 10);
INSERT INTO EMPLOYEES VALUES (102, 'Priya', 'Nair', 'priya.nair@corp.com', '9876543211', TO_DATE('2019-06-01', 'YYYY-MM-DD'), 'VP Human Resources', 95000.00, NULL, NULL, 20);
INSERT INTO EMPLOYEES VALUES (103, 'Amit', 'Verma', 'amit.verma@corp.com', '9876543212', TO_DATE('2019-09-12', 'YYYY-MM-DD'), 'Finance Director', 105000.00, NULL, NULL, 30);
INSERT INTO EMPLOYEES VALUES (104, 'Vikram', 'Singh', 'vikram.singh@corp.com', '9876543213', TO_DATE('2020-01-20', 'YYYY-MM-DD'), 'Lead Software Architect', 82000.00, 0.10, 101, 10);
INSERT INTO EMPLOYEES VALUES (105, 'Ananya', 'Iyer', 'ananya.iyer@corp.com', '9876543214', TO_DATE('2021-04-10', 'YYYY-MM-DD'), 'Senior Database Administrator', 75000.00, 0.05, 104, 10);
INSERT INTO EMPLOYEES VALUES (106, 'Rohan', 'Mehta', 'rohan.mehta@corp.com', '9876543215', TO_DATE('2021-08-18', 'YYYY-MM-DD'), 'Full Stack Developer', 58000.00, NULL, 104, 10);
INSERT INTO EMPLOYEES VALUES (107, 'Sneha', 'Patil', 'sneha.patil@corp.com', '9876543216', TO_DATE('2022-02-01', 'YYYY-MM-DD'), 'HR Business Partner', 48000.00, NULL, 102, 20);
INSERT INTO EMPLOYEES VALUES (108, 'Karthik', 'Reddy', 'karthik.reddy@corp.com', '9876543217', TO_DATE('2020-11-05', 'YYYY-MM-DD'), 'Senior Financial Analyst', 64000.00, 0.08, 103, 30);
INSERT INTO EMPLOYEES VALUES (109, 'Pooja', 'Chopra', 'pooja.chopra@corp.com', '9876543218', TO_DATE('2022-07-22', 'YYYY-MM-DD'), 'Marketing Manager', 69000.00, 0.20, NULL, 40);
INSERT INTO EMPLOYEES VALUES (110, 'Arjun', 'Sen', 'arjun.sen@corp.com', '9876543219', TO_DATE('2023-01-10', 'YYYY-MM-DD'), 'Junior Cloud Engineer', 35000.00, NULL, 104, 10);

-- Projects
INSERT INTO PROJECTS VALUES (501, 'NextGen Cloud Migration', TO_DATE('2024-01-01', 'YYYY-MM-DD'), TO_DATE('2024-12-31', 'YYYY-MM-DD'), 10);
INSERT INTO PROJECTS VALUES (502, 'ERP HR Modernization', TO_DATE('2024-03-01', 'YYYY-MM-DD'), TO_DATE('2024-10-31', 'YYYY-MM-DD'), 20);
INSERT INTO PROJECTS VALUES (503, 'Automated Audit & Compliance', TO_DATE('2024-02-15', 'YYYY-MM-DD'), TO_DATE('2024-09-30', 'YYYY-MM-DD'), 30);
INSERT INTO PROJECTS VALUES (504, 'AI Customer Analytics', TO_DATE('2024-04-01', 'YYYY-MM-DD'), TO_DATE('2025-03-31', 'YYYY-MM-DD'), 50);

-- Assignments
INSERT INTO ASSIGNMENTS VALUES (104, 501, 'Project Lead', 160, 4.8);
INSERT INTO ASSIGNMENTS VALUES (105, 501, 'Lead DBA', 120, 4.9);
INSERT INTO ASSIGNMENTS VALUES (106, 501, 'Backend Developer', 180, 4.5);
INSERT INTO ASSIGNMENTS VALUES (110, 501, 'Cloud Associate', 140, 4.0);
INSERT INTO ASSIGNMENTS VALUES (107, 502, 'Change Management Lead', 100, 4.6);
INSERT INTO ASSIGNMENTS VALUES (108, 503, 'Financial Auditor', 110, 4.7);
INSERT INTO ASSIGNMENTS VALUES (105, 504, 'Data Architect', 80, 4.8);
INSERT INTO ASSIGNMENTS VALUES (106, 504, 'ML Integrator', 90, 4.3);

COMMIT;
```

### 4.2 Query Execution: Arithmetic & Relational Operators
```sql
SELECT emp_id, first_name || ' ' || last_name AS full_name,
       salary AS monthly_salary,
       salary * 12 AS annual_salary,
       (salary * 12) + NVL(salary * 12 * commission_pct, 0) AS total_ctc
FROM EMPLOYEES
WHERE salary > 65000;
```

**Output:**
```text
EMP_ID | FULL_NAME      | MONTHLY_SALARY | ANNUAL_SALARY | TOTAL_CTC
-------+----------------+----------------+---------------+----------
   101 | Rajesh Sharma  |      125000.00 |    1500000.00 | 1725000.00
   102 | Priya Nair     |       95000.00 |    1140000.00 | 1140000.00
   103 | Amit Verma     |      105000.00 |    1260000.00 | 1260000.00
   104 | Vikram Singh   |       86100.00 |    1033200.00 | 1136520.00
   105 | Ananya Iyer    |       78750.00 |     945000.00 |  992250.00
   109 | Pooja Chopra   |       69000.00 |     828000.00 |  993600.00
```

### 4.3 Query Execution: Pattern Matching & Range Searching
```sql
-- Pattern matching (First name starts with 'A' or Last name contains 'a')
SELECT emp_id, first_name, last_name, job_title
FROM EMPLOYEES
WHERE first_name LIKE 'A%' OR last_name LIKE '%a%';
```

**Output:**
```text
EMP_ID | FIRST_NAME | LAST_NAME | JOB_TITLE
-------+------------+-----------+------------------------------
   101 | Rajesh     | Sharma    | Chief Technology Officer
   102 | Priya      | Nair      | VP Human Resources
   103 | Amit       | Verma     | Finance Director
   105 | Ananya     | Iyer      | Senior Database Administrator
   106 | Rohan      | Mehta     | Full Stack Developer
   107 | Sneha      | Patil     | HR Business Partner
   109 | Pooja      | Chopra    | Marketing Manager
   110 | Arjun      | Sen       | Junior Cloud Engineer
```

---

## 5. Cycle Sheet III: Aggregate Functions, Group By, Having, Scalar Functions & Set Operations

### 5.1 Aggregate Functions & Group By with HAVING
```sql
SELECT d.dept_id, d.dept_name,
       COUNT(e.emp_id) AS total_staff,
       MIN(e.salary) AS lowest_salary,
       MAX(e.salary) AS highest_salary,
       ROUND(AVG(e.salary), 2) AS average_salary,
       SUM(e.salary) AS total_monthly_payroll
FROM DEPARTMENTS d
JOIN EMPLOYEES e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING COUNT(e.emp_id) >= 2
ORDER BY average_salary DESC;
```

**Output:**
```text
DEPT_ID | DEPT_NAME              | TOTAL_STAFF | LOWEST_SALARY | HIGHEST_SALARY | AVERAGE_SALARY | TOTAL_MONTHLY_PAYROLL
--------+------------------------+-------------+---------------+----------------+----------------+----------------------
     30 | Finance & Accounting   |           2 |      64000.00 |      105000.00 |       84500.00 |             169000.00
     10 | Information Technology |           5 |      36750.00 |      125000.00 |       77500.00 |             387500.00
     20 | Human Resources        |           2 |      48000.00 |       95000.00 |       71500.00 |             143000.00
```

### 5.2 Built-in Scalar Functions (String, Numeric, Date)
```sql
SELECT emp_id,
       UPPER(last_name) AS upper_name,
       INITCAP(job_title) AS proper_job,
       LENGTH(first_name) AS name_len,
       SUBSTR(email, 1, INSTR(email, '@') - 1) AS login_username,
       ROUND(MONTHS_BETWEEN(SYSDATE, hire_date), 1) AS service_months
FROM EMPLOYEES
WHERE emp_id IN (101, 102, 104);
```

**Output:**
```text
EMP_ID | UPPER_NAME | PROPER_JOB               | NAME_LEN | LOGIN_USERNAME | SERVICE_MONTHS
-------+------------+--------------------------+----------+----------------+---------------
   101 | SHARMA     | Chief Technology Officer |        6 | rajesh.sharma  |          103.0
   102 | NAIR       | Vp Human Resources       |        5 | priya.nair     |           88.5
   104 | SINGH      | Lead Software Architect  |        6 | vikram.singh   |           80.8
```

### 5.3 Set Operators (UNION, INTERSECT, MINUS)
```sql
-- INTERSECT: Departments with both Employees and Projects
SELECT dept_id FROM EMPLOYEES
INTERSECT
SELECT dept_id FROM PROJECTS;

-- MINUS: Departments that have employees but no allocated project
SELECT dept_id FROM EMPLOYEES
MINUS
SELECT dept_id FROM PROJECTS;
```

**Output:**
```text
DEPT_ID (INTERSECT)
-------------------
                 10
                 20
                 30

DEPT_ID (MINUS)
---------------
                 40
```

---

## 6. Cycle Sheet IV: Complex Queries, Multi-table Joins & Subqueries

### 6.1 Multi-table Inner Join (3 Tables)
```sql
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       p.project_name,
       a.role,
       a.hours_allocated,
       a.rating
FROM EMPLOYEES e
JOIN ASSIGNMENTS a ON e.emp_id = a.emp_id
JOIN PROJECTS p ON a.project_id = p.project_id
ORDER BY p.project_id, a.hours_allocated DESC;
```

**Output:**
```text
EMPLOYEE_NAME | PROJECT_NAME                 | ROLE                   | HOURS_ALLOCATED | RATING
--------------+------------------------------+------------------------+-----------------+-------
Rohan Mehta   | NextGen Cloud Migration      | Backend Developer      |             180 |    4.5
Vikram Singh  | NextGen Cloud Migration      | Project Lead           |             160 |    4.8
Arjun Sen     | NextGen Cloud Migration      | Cloud Associate        |             140 |    4.0
Ananya Iyer   | NextGen Cloud Migration      | Lead DBA               |             120 |    4.9
Sneha Patil   | ERP HR Modernization         | Change Management Lead |             100 |    4.6
Karthik Reddy | Automated Audit & Compliance | Financial Auditor      |             110 |    4.7
Rohan Mehta   | AI Customer Analytics        | ML Integrator          |              90 |    4.3
Ananya Iyer   | AI Customer Analytics        | Data Architect         |              80 |    4.8
```

### 6.2 Self Join (Employee-to-Manager Hierarchy)
```sql
SELECT e.emp_id,
       e.first_name || ' ' || e.last_name AS employee_name,
       e.job_title AS designation,
       NVL(m.first_name || ' ' || m.last_name, 'Board of Directors') AS reports_to
FROM EMPLOYEES e
LEFT OUTER JOIN EMPLOYEES m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;
```

**Output:**
```text
EMP_ID | EMPLOYEE_NAME | DESIGNATION                   | REPORTS_TO
-------+---------------+-------------------------------+-------------------
   101 | Rajesh Sharma | Chief Technology Officer      | Board of Directors
   102 | Priya Nair    | VP Human Resources            | Board of Directors
   103 | Amit Verma    | Finance Director              | Board of Directors
   104 | Vikram Singh  | Lead Software Architect       | Rajesh Sharma
   105 | Ananya Iyer   | Senior Database Administrator | Vikram Singh
   106 | Rohan Mehta   | Full Stack Developer          | Vikram Singh
   107 | Sneha Patil   | HR Business Partner           | Priya Nair
   108 | Karthik Reddy | Senior Financial Analyst      | Amit Verma
   109 | Pooja Chopra  | Marketing Manager             | Board of Directors
   110 | Arjun Sen     | Junior Cloud Engineer         | Vikram Singh
```

### 6.3 Correlated Subquery & Subqueries with ALL
```sql
-- Correlated: Employees earning more than their department's average
SELECT e.emp_id, e.first_name, e.dept_id, e.salary,
       ROUND((SELECT AVG(salary) FROM EMPLOYEES WHERE dept_id = e.dept_id), 2) AS dept_avg_sal
FROM EMPLOYEES e
WHERE e.salary > (
    SELECT AVG(salary) FROM EMPLOYEES WHERE dept_id = e.dept_id
);
```

**Output:**
```text
EMP_ID | FIRST_NAME | DEPT_ID | SALARY    | DEPT_AVG_SAL
-------+------------+---------+-----------+-------------
   101 | Rajesh     |      10 | 125000.00 |     77500.00
   104 | Vikram     |      10 |  86100.00 |     77500.00
   105 | Ananya     |      10 |  78750.00 |     77500.00
   102 | Priya      |      20 |  95000.00 |     71500.00
   103 | Amit       |      30 | 105000.00 |     84500.00
```

---

## 7. Cycle Sheet V: Database Objects (Views, Sequences, Indexes, Synonyms) & TCL Transactions

### 7.1 Views (Simple, Complex, WITH CHECK OPTION, WITH READ ONLY)
```sql
-- 1. Complex Analytical View
CREATE OR REPLACE VIEW V_PROJECT_EXECUTIVE_SUMMARY AS
SELECT p.project_id, p.project_name, d.dept_name,
       COUNT(a.emp_id) AS total_headcount,
       SUM(a.hours_allocated) AS total_hours,
       ROUND(AVG(a.rating), 2) AS avg_team_rating
FROM PROJECTS p
JOIN DEPARTMENTS d ON p.dept_id = d.dept_id
LEFT JOIN ASSIGNMENTS a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name, d.dept_name
WITH READ ONLY;

SELECT * FROM V_PROJECT_EXECUTIVE_SUMMARY;
```

**Output:**
```text
PROJECT_ID | PROJECT_NAME                 | DEPT_NAME              | TOTAL_HEADCOUNT | TOTAL_HOURS | AVG_TEAM_RATING
-----------+------------------------------+------------------------+-----------------+-------------+----------------
       501 | NextGen Cloud Migration      | Information Technology |               4 |         600 |            4.55
       502 | ERP HR Modernization         | Human Resources        |               1 |         100 |            4.60
       503 | Automated Audit & Compliance | Finance & Accounting   |               1 |         110 |            4.70
       504 | AI Customer Analytics        | Research & Development |               2 |         170 |            4.55
```

### 7.2 Sequences & Performance Indexes
```sql
-- Auto-increment Sequence
CREATE SEQUENCE EMP_SEQ START WITH 201 INCREMENT BY 1 NOCACHE;

-- Secondary Indexes for B-Tree Index Scan Optimization
CREATE INDEX idx_emp_salary ON EMPLOYEES(salary);
CREATE INDEX idx_emp_dept_job ON EMPLOYEES(dept_id, job_title);
```

**Output:**
```text
Sequence EMP_SEQ created.
Index IDX_EMP_SALARY created.
Index IDX_EMP_DEPT_JOB created.
```

### 7.3 Transaction Control Language (TCL: SAVEPOINT & ROLLBACK TO)
```sql
SAVEPOINT sp_before_salary_revision;

UPDATE EMPLOYEES SET salary = salary + 10000 WHERE dept_id = 20;

SAVEPOINT sp_salary_revised;

-- Erroneous operation:
DELETE FROM EMPLOYEES WHERE dept_id = 10;

-- Recover only from the erroneous deletion while retaining salary revision:
ROLLBACK TO SAVEPOINT sp_salary_revised;

COMMIT;
```

**Output:**
```text
Savepoint created.
2 rows updated.
Savepoint created.
5 rows deleted.
Rollback complete.
Commit complete.
```

---

## 8. Cycle Sheet VI: PL/SQL Programming, Stored Procedures, Triggers & DCL Security

### 8.1 Database Audit Trigger
```sql
CREATE TABLE SALARY_AUDIT (
    audit_id    NUMBER PRIMARY KEY,
    emp_id      NUMBER(6),
    old_salary  NUMBER(8, 2),
    new_salary  NUMBER(8, 2),
    difference  NUMBER(8, 2),
    changed_by  VARCHAR2(30),
    changed_on  DATE
);

CREATE OR REPLACE TRIGGER trg_salary_audit
AFTER UPDATE OF salary ON EMPLOYEES
FOR EACH ROW
WHEN (NEW.salary <> OLD.salary)
BEGIN
    INSERT INTO SALARY_AUDIT VALUES (
        AUDIT_SEQ.NEXTVAL,
        :OLD.emp_id,
        :OLD.salary,
        :NEW.salary,
        :NEW.salary - :OLD.salary,
        USER,
        SYSDATE
    );
END;
/
```

### 8.2 PL/SQL Stored Procedure with DBMS_OUTPUT
```sql
CREATE OR REPLACE PROCEDURE sp_dept_expenditure_report(p_dept_id IN NUMBER)
IS
    v_dept_name     DEPARTMENTS.dept_name%TYPE;
    v_total_sal     NUMBER(12, 2);
    v_emp_count     NUMBER;
BEGIN
    SELECT dept_name INTO v_dept_name FROM DEPARTMENTS WHERE dept_id = p_dept_id;
    
    SELECT COUNT(*), NVL(SUM(salary), 0)
    INTO v_emp_count, v_total_sal
    FROM EMPLOYEES
    WHERE dept_id = p_dept_id;
    
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('DEPARTMENT EXPENDITURE AUDIT REPORT');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('Department ID   : ' || p_dept_id);
    DBMS_OUTPUT.PUT_LINE('Department Name : ' || v_dept_name);
    DBMS_OUTPUT.PUT_LINE('Total Employees : ' || v_emp_count);
    DBMS_OUTPUT.PUT_LINE('Monthly Payroll : Rs. ' || TO_CHAR(v_total_sal, '99,99,999.00'));
    DBMS_OUTPUT.PUT_LINE('Annual Outflow  : Rs. ' || TO_CHAR(v_total_sal * 12, '99,99,999.00'));
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/
```

**Execution:**
```sql
SET SERVEROUTPUT ON;
EXEC sp_dept_expenditure_report(10);
```

**Output:**
```text
====================================================
DEPARTMENT EXPENDITURE AUDIT REPORT
====================================================
Department ID   : 10
Department Name : Information Technology
Total Employees : 5
Monthly Payroll : Rs.   3,87,500.00
Annual Outflow  : Rs.  46,50,000.00
====================================================
```

### 8.3 Representative DCL Security Statements
```sql
GRANT SELECT, INSERT, UPDATE ON EMPLOYEES TO hr_analyst;
GRANT SELECT ON V_PROJECT_EXECUTIVE_SUMMARY TO project_manager;
REVOKE INSERT, UPDATE ON EMPLOYEES FROM hr_analyst;
```
