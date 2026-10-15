-- ============================================================================
-- ORACLE SQL IMPLEMENTATION: LABORATORY CYCLE SHEETS I - VI
-- Database Management Systems (DBMS) Laboratory & Project Report
-- Domain: Enterprise Human Resource & Project Allocation System (Company DB)
-- Compatibility: Oracle Database 11g / 12c / 18c / 19c / 21c / 23c / Live SQL
-- ============================================================================

SET SERVEROUTPUT ON;
SET PAGESIZE 100;
SET LINESIZE 200;

-- ============================================================================
-- PART 0: USER CREATION & CONNECTION SETUP (Run as SYSDBA if local Oracle instance)
-- ============================================================================
-- (Note: If using Oracle Live SQL, skip to PART 1 directly as the schema is auto-provisioned)

/*
CREATE USER dbms_user IDENTIFIED BY OraclePassword123;
GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO dbms_user;
CONNECT dbms_user/OraclePassword123;
*/

-- Cleanup any pre-existing tables to allow clean re-execution
BEGIN
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN 
             ('ASSIGNMENTS', 'PROJECTS', 'EMPLOYEES', 'DEPARTMENTS', 'SALARY_AUDIT', 'TEMP_EMP')) 
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
    
    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN 
             ('EMP_SEQ', 'DEPT_SEQ', 'AUDIT_SEQ')) 
    LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- CYCLE SHEET I: DDL (DATA DEFINITION LANGUAGE) & INTEGRITY CONSTRAINTS
-- ============================================================================
-- Concepts: CREATE TABLE, PRIMARY KEY, FOREIGN KEY (ON DELETE CASCADE),
--           UNIQUE, NOT NULL, CHECK, DEFAULT, ALTER TABLE, DROP, TRUNCATE.

-- 1. Create DEPARTMENTS table with PK, UNIQUE, and CHECK constraints
CREATE TABLE DEPARTMENTS (
    dept_id     NUMBER(4)          CONSTRAINT pk_departments PRIMARY KEY,
    dept_name   VARCHAR2(50)       CONSTRAINT unq_dept_name UNIQUE NOT NULL,
    location    VARCHAR2(50)       CONSTRAINT nn_dept_location NOT NULL,
    budget      NUMBER(12, 2)      CONSTRAINT chk_dept_budget CHECK (budget > 0)
);

-- 2. Create EMPLOYEES table with PK, FK, Self-referential FK, CHECK, and NOT NULL
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

-- 3. Create PROJECTS table
CREATE TABLE PROJECTS (
    project_id      NUMBER(5)      CONSTRAINT pk_projects PRIMARY KEY,
    project_name    VARCHAR2(60)   CONSTRAINT unq_project_name UNIQUE NOT NULL,
    start_date      DATE           CONSTRAINT nn_proj_sdate NOT NULL,
    end_date        DATE,
    dept_id         NUMBER(4)      CONSTRAINT fk_proj_dept REFERENCES DEPARTMENTS(dept_id) ON DELETE CASCADE,
    CONSTRAINT chk_proj_dates CHECK (end_date >= start_date)
);

-- 4. Create ASSIGNMENTS junction table (Resolves M:N with Composite Primary Key)
CREATE TABLE ASSIGNMENTS (
    emp_id          NUMBER(6)      CONSTRAINT fk_asgn_emp REFERENCES EMPLOYEES(emp_id) ON DELETE CASCADE,
    project_id      NUMBER(5)      CONSTRAINT fk_asgn_proj REFERENCES PROJECTS(project_id) ON DELETE CASCADE,
    role            VARCHAR2(30)   DEFAULT 'Contributor' NOT NULL,
    hours_allocated NUMBER(4)      CONSTRAINT chk_asgn_hours CHECK (hours_allocated > 0),
    rating          NUMBER(2, 1)   CONSTRAINT chk_asgn_rating CHECK (rating BETWEEN 1.0 AND 5.0),
    CONSTRAINT pk_assignments PRIMARY KEY (emp_id, project_id)
);

-- 5. ALTER TABLE Operations: ADD, MODIFY, DROP, RENAME
-- A. Add a new column
ALTER TABLE DEPARTMENTS ADD (head_of_dept VARCHAR2(60));

-- B. Modify existing column data type / constraint
ALTER TABLE DEPARTMENTS MODIFY (head_of_dept VARCHAR2(80));

-- C. Rename column
ALTER TABLE DEPARTMENTS RENAME COLUMN head_of_dept TO director_name;

-- D. Drop column
ALTER TABLE DEPARTMENTS DROP COLUMN director_name;

-- 6. Temporary table for TRUNCATE demonstration
CREATE TABLE TEMP_EMP AS SELECT * FROM EMPLOYEES WHERE 1 = 0;
TRUNCATE TABLE TEMP_EMP;
DROP TABLE TEMP_EMP;


-- ============================================================================
-- CYCLE SHEET II: DATA POPULATION, DML STATEMENTS & BASIC QUERIES
-- ============================================================================
-- Concepts: INSERT, UPDATE, DELETE, Arithmetic/Relational/Logical Operators,
--           BETWEEN, LIKE, IN, IS NULL, ORDER BY, DISTINCT.

-- 1. Populate DEPARTMENTS
INSERT INTO DEPARTMENTS (dept_id, dept_name, location, budget) 
VALUES (10, 'Information Technology', 'Bangalore', 5000000.00);

INSERT INTO DEPARTMENTS (dept_id, dept_name, location, budget) 
VALUES (20, 'Human Resources', 'Mumbai', 1200000.00);

INSERT INTO DEPARTMENTS (dept_id, dept_name, location, budget) 
VALUES (30, 'Finance & Accounting', 'New Delhi', 3500000.00);

INSERT INTO DEPARTMENTS (dept_id, dept_name, location, budget) 
VALUES (40, 'Sales & Marketing', 'Hyderabad', 2800000.00);

INSERT INTO DEPARTMENTS (dept_id, dept_name, location, budget) 
VALUES (50, 'Research & Development', 'Pune', 4200000.00);

-- 2. Populate EMPLOYEES (First insert top executives with NULL manager_id)
INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (101, 'Rajesh', 'Sharma', 'rajesh.sharma@corp.com', '9876543210', TO_DATE('2018-03-15', 'YYYY-MM-DD'), 'Chief Technology Officer', 125000.00, 0.15, NULL, 10);

INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (102, 'Priya', 'Nair', 'priya.nair@corp.com', '9876543211', TO_DATE('2019-06-01', 'YYYY-MM-DD'), 'VP Human Resources', 95000.00, NULL, NULL, 20);

INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (103, 'Amit', 'Verma', 'amit.verma@corp.com', '9876543212', TO_DATE('2019-09-12', 'YYYY-MM-DD'), 'Finance Director', 105000.00, NULL, NULL, 30);

-- Insert Managers and Staff reporting to Executives
INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (104, 'Vikram', 'Singh', 'vikram.singh@corp.com', '9876543213', TO_DATE('2020-01-20', 'YYYY-MM-DD'), 'Lead Software Architect', 82000.00, 0.10, 101, 10);

INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (105, 'Ananya', 'Iyer', 'ananya.iyer@corp.com', '9876543214', TO_DATE('2021-04-10', 'YYYY-MM-DD'), 'Senior Database Administrator', 75000.00, 0.05, 104, 10);

INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (106, 'Rohan', 'Mehta', 'rohan.mehta@corp.com', '9876543215', TO_DATE('2021-08-18', 'YYYY-MM-DD'), 'Full Stack Developer', 58000.00, NULL, 104, 10);

INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (107, 'Sneha', 'Patil', 'sneha.patil@corp.com', '9876543216', TO_DATE('2022-02-01', 'YYYY-MM-DD'), 'HR Business Partner', 48000.00, NULL, 102, 20);

INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (108, 'Karthik', 'Reddy', 'karthik.reddy@corp.com', '9876543217', TO_DATE('2020-11-05', 'YYYY-MM-DD'), 'Senior Financial Analyst', 64000.00, 0.08, 103, 30);

INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (109, 'Pooja', 'Chopra', 'pooja.chopra@corp.com', '9876543218', TO_DATE('2022-07-22', 'YYYY-MM-DD'), 'Marketing Manager', 69000.00, 0.20, NULL, 40);

INSERT INTO EMPLOYEES (emp_id, first_name, last_name, email, phone_number, hire_date, job_title, salary, commission_pct, manager_id, dept_id)
VALUES (110, 'Arjun', 'Sen', 'arjun.sen@corp.com', '9876543219', TO_DATE('2023-01-10', 'YYYY-MM-DD'), 'Junior Cloud Engineer', 35000.00, NULL, 104, 10);

-- 3. Populate PROJECTS
INSERT INTO PROJECTS (project_id, project_name, start_date, end_date, dept_id)
VALUES (501, 'NextGen Cloud Migration', TO_DATE('2024-01-01', 'YYYY-MM-DD'), TO_DATE('2024-12-31', 'YYYY-MM-DD'), 10);

INSERT INTO PROJECTS (project_id, project_name, start_date, end_date, dept_id)
VALUES (502, 'ERP HR Modernization', TO_DATE('2024-03-01', 'YYYY-MM-DD'), TO_DATE('2024-10-31', 'YYYY-MM-DD'), 20);

INSERT INTO PROJECTS (project_id, project_name, start_date, end_date, dept_id)
VALUES (503, 'Automated Audit & Compliance', TO_DATE('2024-02-15', 'YYYY-MM-DD'), TO_DATE('2024-09-30', 'YYYY-MM-DD'), 30);

INSERT INTO PROJECTS (project_id, project_name, start_date, end_date, dept_id)
VALUES (504, 'AI Customer Analytics', TO_DATE('2024-04-01', 'YYYY-MM-DD'), TO_DATE('2025-03-31', 'YYYY-MM-DD'), 50);

-- 4. Populate ASSIGNMENTS
INSERT INTO ASSIGNMENTS (emp_id, project_id, role, hours_allocated, rating) VALUES (104, 501, 'Project Lead', 160, 4.8);
INSERT INTO ASSIGNMENTS (emp_id, project_id, role, hours_allocated, rating) VALUES (105, 501, 'Lead DBA', 120, 4.9);
INSERT INTO ASSIGNMENTS (emp_id, project_id, role, hours_allocated, rating) VALUES (106, 501, 'Backend Developer', 180, 4.5);
INSERT INTO ASSIGNMENTS (emp_id, project_id, role, hours_allocated, rating) VALUES (110, 501, 'Cloud Associate', 140, 4.0);
INSERT INTO ASSIGNMENTS (emp_id, project_id, role, hours_allocated, rating) VALUES (107, 502, 'Change Management Lead', 100, 4.6);
INSERT INTO ASSIGNMENTS (emp_id, project_id, role, hours_allocated, rating) VALUES (108, 503, 'Financial Auditor', 110, 4.7);
INSERT INTO ASSIGNMENTS (emp_id, project_id, role, hours_allocated, rating) VALUES (105, 504, 'Data Architect', 80, 4.8);
INSERT INTO ASSIGNMENTS (emp_id, project_id, role, hours_allocated, rating) VALUES (106, 504, 'ML Integrator', 90, 4.3);

COMMIT;

-- 5. DML Operations: UPDATE & DELETE
-- Increase salary of employees in IT department (dept_id = 10) by 5%
UPDATE EMPLOYEES 
SET salary = salary * 1.05 
WHERE dept_id = 10 AND job_title != 'Chief Technology Officer';

-- 6. Basic SELECT queries demonstrating clauses
-- A. Arithmetic and Relational operators with Column Aliases
SELECT emp_id, first_name || ' ' || last_name AS full_name,
       salary AS current_monthly_salary,
       salary * 12 AS annual_package,
       (salary * 12) + NVL(salary * 12 * commission_pct, 0) AS total_ctc
FROM EMPLOYEES
WHERE salary > 60000;

-- B. Logical Operators (AND, OR, NOT)
SELECT emp_id, first_name, job_title, salary, dept_id
FROM EMPLOYEES
WHERE (dept_id = 10 OR dept_id = 30) AND NOT (salary < 60000);

-- C. Range Condition (BETWEEN ... AND ...)
SELECT emp_id, first_name, last_name, hire_date, salary
FROM EMPLOYEES
WHERE salary BETWEEN 50000 AND 90000;

-- D. Pattern Matching (LIKE with % and _)
SELECT emp_id, first_name, email, job_title
FROM EMPLOYEES
WHERE first_name LIKE 'A%' OR last_name LIKE '%a%';

-- E. Membership Condition (IN, NOT IN)
SELECT emp_id, first_name, job_title, dept_id
FROM EMPLOYEES
WHERE dept_id IN (10, 20, 50);

-- F. NULL Check (IS NULL, IS NOT NULL)
SELECT emp_id, first_name, job_title, commission_pct
FROM EMPLOYEES
WHERE commission_pct IS NOT NULL;

-- G. DISTINCT & ORDER BY (Multi-column with NULLS LAST)
SELECT DISTINCT dept_id, job_title
FROM EMPLOYEES
ORDER BY dept_id ASC, job_title DESC;


-- ============================================================================
-- CYCLE SHEET III: AGGREGATE FUNCTIONS, GROUP BY, HAVING, SCALAR FUNCTIONS & SET OPS
-- ============================================================================

-- 1. Built-in Aggregate Functions
SELECT COUNT(*) AS total_employees,
       COUNT(commission_pct) AS employees_with_commission,
       MIN(salary) AS min_salary,
       MAX(salary) AS max_salary,
       ROUND(AVG(salary), 2) AS avg_salary,
       SUM(salary) AS total_payroll
FROM EMPLOYEES;

-- 2. GROUP BY and HAVING Clause
SELECT d.dept_id, d.dept_name,
       COUNT(e.emp_id) AS total_staff,
       ROUND(AVG(e.salary), 2) AS avg_salary,
       MAX(e.salary) AS peak_salary
FROM DEPARTMENTS d
JOIN EMPLOYEES e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING COUNT(e.emp_id) >= 2
ORDER BY avg_salary DESC;

-- 3. Oracle Built-in Scalar Functions
-- A. String Functions
SELECT emp_id,
       UPPER(last_name) AS upper_last,
       LOWER(first_name) AS lower_first,
       INITCAP(job_title) AS formatted_job,
       LENGTH(first_name) AS fname_len,
       SUBSTR(email, 1, INSTR(email, '@') - 1) AS username,
       LPAD(TO_CHAR(salary), 10, '*') AS padded_salary
FROM EMPLOYEES
WHERE emp_id <= 105;

-- B. Numeric Functions
SELECT salary,
       ROUND(salary / 30, 2) AS daily_rounded,
       TRUNC(salary / 30, 2) AS daily_truncated,
       MOD(emp_id, 2) AS is_even_odd,
       CEIL(salary / 1000) * 1000 AS rounded_up_thousand,
       FLOOR(salary / 1000) * 1000 AS rounded_down_thousand
FROM EMPLOYEES
WHERE emp_id IN (104, 105, 106);

-- C. Date Functions
SELECT emp_id, first_name, hire_date,
       ROUND(MONTHS_BETWEEN(SYSDATE, hire_date), 1) AS months_with_company,
       ADD_MONTHS(hire_date, 6) AS probation_end_date,
       LAST_DAY(hire_date) AS hire_month_last_day,
       TO_CHAR(hire_date, 'Day, DD Month YYYY') AS formatted_hire_date
FROM EMPLOYEES
WHERE emp_id <= 104;

-- 4. Set Operators (UNION, UNION ALL, INTERSECT, MINUS)
-- A. UNION (Unique department IDs from EMPLOYEES and PROJECTS)
SELECT dept_id FROM EMPLOYEES
UNION
SELECT dept_id FROM PROJECTS;

-- B. UNION ALL (Preserves duplicates)
SELECT dept_id FROM EMPLOYEES WHERE dept_id IN (10, 20)
UNION ALL
SELECT dept_id FROM PROJECTS;

-- C. INTERSECT (Departments that have both employees and active projects)
SELECT dept_id FROM EMPLOYEES
INTERSECT
SELECT dept_id FROM PROJECTS;

-- D. MINUS (Departments that have employees but no projects allocated)
SELECT dept_id FROM EMPLOYEES
MINUS
SELECT dept_id FROM PROJECTS;


-- ============================================================================
-- CYCLE SHEET IV: JOINS & SUBQUERIES (COMPLEX / NESTED / CORRELATED)
-- ============================================================================

-- 1. Inner Join with ON condition
SELECT e.emp_id, e.first_name || ' ' || e.last_name AS employee,
       e.job_title, e.salary, d.dept_name, d.location
FROM EMPLOYEES e
INNER JOIN DEPARTMENTS d ON e.dept_id = d.dept_id;

-- 2. Left Outer Join (Displays departments even if they have no employees)
SELECT d.dept_id, d.dept_name, COUNT(e.emp_id) AS employee_count
FROM DEPARTMENTS d
LEFT OUTER JOIN EMPLOYEES e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY d.dept_id;

-- 3. Right Outer Join
SELECT e.emp_id, e.first_name, p.project_id, p.project_name
FROM ASSIGNMENTS a
RIGHT OUTER JOIN PROJECTS p ON a.project_id = p.project_id
LEFT OUTER JOIN EMPLOYEES e ON a.emp_id = e.emp_id;

-- 4. Full Outer Join
SELECT NVL(d.dept_name, 'No Department') AS department,
       NVL(p.project_name, 'No Project') AS project
FROM DEPARTMENTS d
FULL OUTER JOIN PROJECTS p ON d.dept_id = p.dept_id;

-- 5. Self Join (Finding Employee and their respective Manager's name)
SELECT e.emp_id,
       e.first_name || ' ' || e.last_name AS employee_name,
       e.job_title AS employee_designation,
       NVL(m.first_name || ' ' || m.last_name, 'None (Top Executive)') AS manager_name,
       NVL(m.job_title, 'N/A') AS manager_designation
FROM EMPLOYEES e
LEFT OUTER JOIN EMPLOYEES m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;

-- 6. Multi-table Join (3+ tables: Employees -> Assignments -> Projects -> Departments)
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       p.project_name,
       a.role,
       a.hours_allocated,
       d.dept_name AS project_owner_dept
FROM EMPLOYEES e
JOIN ASSIGNMENTS a ON e.emp_id = a.emp_id
JOIN PROJECTS p ON a.project_id = p.project_id
JOIN DEPARTMENTS d ON p.dept_id = d.dept_id;

-- 7. Subqueries:
-- A. Single-row Subquery (Employees earning more than the company average salary)
SELECT emp_id, first_name, last_name, salary, job_title
FROM EMPLOYEES
WHERE salary > (SELECT AVG(salary) FROM EMPLOYEES)
ORDER BY salary DESC;

-- B. Multi-row Subquery with IN (Employees working in Bangalore or Hyderabad)
SELECT emp_id, first_name, last_name, dept_id
FROM EMPLOYEES
WHERE dept_id IN (
    SELECT dept_id FROM DEPARTMENTS WHERE location IN ('Bangalore', 'Hyderabad')
);

-- C. Multi-row Subquery with ALL (Employees whose salary exceeds ALL salaries in Finance)
SELECT emp_id, first_name, job_title, salary
FROM EMPLOYEES
WHERE salary > ALL (
    SELECT salary FROM EMPLOYEES WHERE dept_id = 30
);

-- D. Correlated Subquery (Employees earning more than the average salary of their OWN department)
SELECT e.emp_id, e.first_name, e.dept_id, e.salary,
       ROUND((SELECT AVG(salary) FROM EMPLOYEES WHERE dept_id = e.dept_id), 2) AS dept_avg
FROM EMPLOYEES e
WHERE e.salary > (
    SELECT AVG(salary) FROM EMPLOYEES WHERE dept_id = e.dept_id
);

-- E. EXISTS and NOT EXISTS (Departments that have at least one assigned project)
SELECT d.dept_id, d.dept_name, d.location
FROM DEPARTMENTS d
WHERE EXISTS (
    SELECT 1 FROM PROJECTS p WHERE p.dept_id = d.dept_id
);

-- F. Inline View (Subquery in FROM clause with Row Ranking / Aggregates)
SELECT dept_name, max_sal, min_sal, (max_sal - min_sal) AS sal_spread
FROM (
    SELECT d.dept_name, MAX(e.salary) AS max_sal, MIN(e.salary) AS min_sal
    FROM DEPARTMENTS d
    JOIN EMPLOYEES e ON d.dept_id = e.dept_id
    GROUP BY d.dept_name
) dept_summary
ORDER BY sal_spread DESC;


-- ============================================================================
-- CYCLE SHEET V: VIEWS, SEQUENCES, INDEXES, SYNONYMS & TCL (TRANSACTIONS)
-- ============================================================================

-- 1. Create View (Simple View)
CREATE OR REPLACE VIEW V_IT_STAFF AS
SELECT emp_id, first_name, last_name, email, job_title, salary
FROM EMPLOYEES
WHERE dept_id = 10
WITH CHECK OPTION CONSTRAINT chk_v_it_staff;

-- 2. Create Complex View with Calculated Metrics & Read Only constraint
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

-- Test Query from View
SELECT * FROM V_PROJECT_EXECUTIVE_SUMMARY;

-- 3. Sequences (Auto-increment surrogate keys in Oracle)
CREATE SEQUENCE EMP_SEQ
    START WITH 201
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE AUDIT_SEQ
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Verify Sequence Generation
SELECT EMP_SEQ.NEXTVAL AS generated_emp_id FROM DUAL;

-- 4. Indexes (B-Tree and Unique Index for Query Optimization)
CREATE INDEX idx_emp_salary ON EMPLOYEES(salary);
CREATE INDEX idx_emp_dept_job ON EMPLOYEES(dept_id, job_title);

-- 5. Synonyms
CREATE SYNONYM EMP FOR EMPLOYEES;
SELECT COUNT(*) FROM EMP;
DROP SYNONYM EMP;

-- 6. TCL Statements (COMMIT, SAVEPOINT, ROLLBACK TO, ROLLBACK)
-- Demonstration of transactional integrity
SAVEPOINT before_mass_update;

UPDATE EMPLOYEES 
SET salary = salary + 5000 
WHERE dept_id = 20;

SAVEPOINT bonus_applied;

-- Unintended change
DELETE FROM EMPLOYEES WHERE dept_id = 40;

-- Undo the unintended deletion by rolling back to second savepoint
ROLLBACK TO SAVEPOINT bonus_applied;

-- Verify department 40 employees are preserved, but bonus is still active
SELECT emp_id, first_name, dept_id, salary FROM EMPLOYEES WHERE dept_id IN (20, 40);

-- Commit the verified transaction
COMMIT;


-- ============================================================================
-- CYCLE SHEET VI: PL/SQL, TRIGGERS, DCL & CONSTRAINTS AUDITING
-- ============================================================================

-- 1. Create Audit Table for Triggers
CREATE TABLE SALARY_AUDIT (
    audit_id        NUMBER          PRIMARY KEY,
    emp_id          NUMBER(6),
    old_salary      NUMBER(8, 2),
    new_salary      NUMBER(8, 2),
    difference      NUMBER(8, 2),
    changed_by      VARCHAR2(30),
    changed_on      DATE
);

-- 2. Database Trigger: Automatically logs salary modifications to SALARY_AUDIT
CREATE OR REPLACE TRIGGER trg_salary_audit
AFTER UPDATE OF salary ON EMPLOYEES
FOR EACH ROW
WHEN (NEW.salary <> OLD.salary)
BEGIN
    INSERT INTO SALARY_AUDIT (
        audit_id, emp_id, old_salary, new_salary, difference, changed_by, changed_on
    ) VALUES (
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

-- Test Trigger Execution
UPDATE EMPLOYEES SET salary = 85000.00 WHERE emp_id = 105;
COMMIT;

SELECT * FROM SALARY_AUDIT;

-- 3. PL/SQL Function: Calculate Annual Bonus based on Performance Rating
CREATE OR REPLACE FUNCTION fn_calculate_bonus(p_emp_id IN NUMBER)
RETURN NUMBER
IS
    v_salary        EMPLOYEES.salary%TYPE;
    v_avg_rating    NUMBER(3, 2);
    v_bonus         NUMBER(10, 2) := 0;
BEGIN
    SELECT salary INTO v_salary FROM EMPLOYEES WHERE emp_id = p_emp_id;
    
    SELECT NVL(AVG(rating), 3.0) INTO v_avg_rating 
    FROM ASSIGNMENTS WHERE emp_id = p_emp_id;
    
    IF v_avg_rating >= 4.5 THEN
        v_bonus := v_salary * 0.20; -- 20% bonus for top tier
    ELSIF v_avg_rating >= 4.0 THEN
        v_bonus := v_salary * 0.10; -- 10% bonus for good tier
    ELSE
        v_bonus := v_salary * 0.05; -- 5% baseline
    END IF;
    
    RETURN ROUND(v_bonus, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/

-- Execute PL/SQL Function in SQL
SELECT emp_id, first_name, last_name, salary,
       fn_calculate_bonus(emp_id) AS computed_annual_bonus
FROM EMPLOYEES
WHERE emp_id IN (104, 105, 106, 110);

-- 4. PL/SQL Stored Procedure: Department Headcount & Expenditure Reporting
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
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Department ID ' || p_dept_id || ' does not exist.');
END;
/

-- Execute PL/SQL Procedure
BEGIN
    sp_dept_expenditure_report(10);
END;
/

-- 5. DCL (Data Control Language) Statements
-- (Representative commands for security administration)
/*
GRANT SELECT, INSERT, UPDATE ON EMPLOYEES TO hr_analyst;
GRANT SELECT ON V_PROJECT_EXECUTIVE_SUMMARY TO project_manager;
REVOKE INSERT, UPDATE ON EMPLOYEES FROM hr_analyst;
*/

-- ============================================================================
-- END OF SCRIPT: LABORATORY CYCLE SHEETS I - VI COMPLETE
-- ============================================================================
