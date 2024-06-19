create or replace trigger ab.trg_update_last_updated       
BEFORE UPDATE ON employees
FOR EACH ROW

DECLARE
    -- Variable declarations
    v_old_salary employees.salary%TYPE;
    v_new_salary employees.salary%TYPE;

BEGIN
    -- Check if the salary has changed
    IF :OLD.salary != :NEW.salary THEN
        -- Save the old and new salaries for logging purposes
        v_old_salary := :OLD.salary;
        v_new_salary := :NEW.salary;

        -- Update the last_updated column to the current timestamp
        :NEW.last_updated := SYSDATE;

        -- Log the salary change
        INSERT INTO salary_log (employee_id, old_salary, new_salary, change_date)
        VALUES (:NEW.employee_id, v_old_salary, v_new_salary, SYSDATE);
    END IF;

    -- Additional business logic can be added here
    -- For example, send a notification if / the salary increase exceeds a threshold
    IF v_new_salary > v_old_salary * 1.10 THEN
        INSERT INTO notifications (employee_id, message, notification_date)
        VALUES (:NEW.employee_id, 'Salary increased by more than 10%', SYSDATE);
    END IF;

    -- Check other columns and apply additional rules as needed
    -- Example: ensure the email format is correct
    IF NOT REGEXP_LIKE(:NEW.email, '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$', 'i') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid email format');
    END IF;

EXCEPTION
    -- Exception handling section
    WHEN OTHERS THEN
        -- Log the error in an error log table
        INSERT INTO error_log (error_message, error_date)
        VALUES (SQLERRM, SYSDATE);
        -- Re-raise the exception
        RAISE;

END;
/
