-- 1. Create the audit table for tracking grade changes
CREATE TABLE grade_change_history (
    student_id     NUMBER(8,0),
    section_id     NUMBER(8,0),
    enroll_date    DATE,
    previous_grade NUMBER(3,0),
    new_grade      NUMBER(3,0),
    change_date    DATE
);

-- 2. Create the row-level trigger
CREATE OR REPLACE TRIGGER audit_grade_change
AFTER UPDATE OF final_grade ON enrollment
FOR EACH ROW
BEGIN
    -- Insert a record into the audit table whenever the final_grade is updated
    INSERT INTO grade_change_history (
        student_id,
        section_id,
        enroll_date,
        previous_grade,
        new_grade,
        change_date
    ) VALUES (
        :OLD.student_id,
        :OLD.section_id,
        :OLD.enroll_date,
        :OLD.final_grade,
        :NEW.final_grade,
        SYSDATE
    );
END;
/