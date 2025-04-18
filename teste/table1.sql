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
    department_id NUMBER(4),
    supervisor_id NUMBER(6),
    address VARCHAR2(100),
    date_of_birth DATE,
    status CHAR(1) CHECK (status IN ('A', 'I')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_supervisor
        FOREIGN KEY (supervisor_id) REFERENCES employees(employee_id),
    CONSTRAINT chk_salary CHECK (salary >= 0),
    CONSTRAINT uq_email UNIQUE (email)
)
/
COMMENT ON COLUMN employees.employee_id IS 'Identificador único do funcionário'
/
COMMENT ON COLUMN employees.first_name IS 'Nome do funcionário'
/
COMMENT ON COLUMN employees.last_name IS 'Sobrenome do funcionário'
/
COMMENT ON COLUMN employees.email IS 'Email do funcionário'
/
COMMENT ON COLUMN employees.phone_number IS 'Número de telefone do funcionário'
/
COMMENT ON COLUMN employees.hire_date IS 'Data de contratação do funcionário'
/
COMMENT ON COLUMN employees.job_id IS 'Cargo do funcionário'
/
COMMENT ON COLUMN employees.salary IS 'Salário do funcionário'
/
COMMENT ON COLUMN employees.commission_pct IS 'Percentual de comissão do funcionário'
/
COMMENT ON COLUMN employees.manager_id IS 'ID do gerente do funcionário'
/
COMMENT ON COLUMN employees.department_id IS 'ID do departamento do funcionário'
/
COMMENT ON COLUMN employees.supervisor_id IS 'ID do supervisor do funcionário'
/
COMMENT ON COLUMN employees.address IS 'Endereço do funcionário'
/
COMMENT ON COLUMN employees.date_of_birth IS 'Data de nascimento do funcionário'
/
COMMENT ON COLUMN employees.status IS 'Status do funcionário (A - Ativo, I - Inativo)'
/
GRANT SELECT, INSERT, UPDATE, DELETE ON employees TO hr
/
GRANT SELECT ON employees TO admin
/
CREATE INDEX idx_employee_email ON employees (email)
/
CREATE INDEX idx_employee_last_name ON employees (last_name)
/
CREATE SEQUENCE employee_seq
    START WITH 1
    INCREMENT BY 1
    CACHE 20
/
CREATE SEQUENCE employee_seq2
    START WITH 1
    INCREMENT BY 1
    CACHE 20
/
CREATE OR REPLACE PUBLIC SYNONYM emp_synonym FOR employees
/
CREATE OR REPLACE PUBLIC SYNONYM emp_synonym2 FOR employees
/

-- Alter Table Statements
ALTER TABLE employees
    ADD CONSTRAINT chk_phone_number
    CHECK (phone_number IS NOT NULL);

ALTER TABLE employees
    ADD CONSTRAINT fk_manager
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

ALTER TABLE employees
    ADD CONSTRAINT uq_phone_number
    UNIQUE (phone_number);

ALTER TABLE employees
    ADD CONSTRAINT chk_date_of_birth
    CHECK (date_of_birth <= SYSDATE);
