CREATE TABLE employees (
    employee_id NUMBER(6) PRIMARY KEY,
    first_name VARCHAR2(20),
    last_name VARCHAR2(25) NOT NULL,
    email VARCHAR2(50) UNIQUE NOT NULL,
    phone_number VARCHAR2(15),
    hire_date DATE NOT NULL,
    job_id VARCHAR2(10) NOT NULL,
    salary NUMBER(8,2),
    commission_pct NUMBER(2,2),
    manager_id NUMBER(6),
    manager_id NUMBER(6),
    department_id NUMBER(4),
    CONSTRAINT fk_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
)
/
COMMENT ON COLUMN employees.employee_id IS 'Identificador único do funcionário'
/
COMMENT ON COLUMN employees.first_name IS 'Nome do funcionário'
/
COMMENT ON COLUMN employees.last_name IS 'Sobrenome do funcionário'
/
COMMENT ON COLUMN ON employees TO hr
/
GRANT INSERT ON employees TO hr
/
GRANT INSERT ON employees TO hr
/
