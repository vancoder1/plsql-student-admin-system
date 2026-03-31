-- Note: should probably make this private
CREATE OR REPLACE FUNCTION student_inside_class(
    p_stu_id IN NUMBER,
    p_class_id IN NUMBER
)
RETURN BOOLEAN
IS
    -- Dummy variable
    v_tmp NUMBER;
BEGIN
    -- Mapped strictly to schema columns
    SELECT section_id
    INTO v_tmp
    FROM enrollment
    WHERE student_id = p_stu_id
    AND section_id = p_class_id;

    RETURN TRUE;
EXCEPTION
    WHEN no_data_found THEN
        RETURN FALSE;
END;
/

CREATE OR REPLACE PACKAGE pkg_enrollment IS
    PROCEDURE enroll_student_in_class(
        p_stu_id IN NUMBER,
        p_class_id IN NUMBER
    );

    PROCEDURE drop_student_from_class(
        p_stu_id IN NUMBER,
        p_class_id IN NUMBER
    );

    PROCEDURE student_class_list(
        p_stu_id IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    );

    PROCEDURE student_class_list(
        p_start_date IN DATE,
        p_end_date IN DATE
    );
END pkg_enrollment;
/

CREATE OR REPLACE PACKAGE BODY pkg_enrollment IS
    PROCEDURE enroll_student_in_class(
        p_stu_id IN NUMBER,
        p_class_id IN NUMBER
    )
    IS
    BEGIN
        -- Validate student is not in class
        IF student_inside_class(p_stu_id, p_class_id) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Student with ID ' || p_stu_id || ' is already enrolled in class with ID ' || p_class_id || '.');
        ELSE
            -- Mapped to schema constraints (Requires audit columns, omitted STATUS)
            INSERT INTO enrollment (student_id, section_id, enroll_date, created_by, created_date, modified_by, modified_date) VALUES (
                p_stu_id,
                p_class_id,
                SYSDATE,
                USER,
                SYSDATE,
                USER,
                SYSDATE
            );
        END IF;
    END;

    PROCEDURE drop_student_from_class(
        p_stu_id IN NUMBER,
        p_class_id IN NUMBER
    )
    IS
        e_student_not_in_class EXCEPTION;
    BEGIN
        IF student_inside_class(p_stu_id, p_class_id) THEN
            DELETE FROM enrollment
            WHERE student_id = p_stu_id
            AND section_id = p_class_id;
        ELSE
            RAISE_APPLICATION_ERROR(-20002, 'Attempted to drop student with ID ' || p_stu_id || ' from class with ID ' || p_class_id || ', but they were not already enrolled in this class.');
        END IF;
    END;

    PROCEDURE student_class_list(
        p_stu_id IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    )
    IS
        CURSOR c_students
        IS
            -- Hardcoded 'Enrolled' since if they are in the table, they are enrolled
            SELECT section_id AS class_id, enroll_date AS enrollment_date, 'Enrolled' AS status
            FROM enrollment
            WHERE student_id = p_stu_id
            AND (p_start_date IS NULL OR enroll_date >= p_start_date)
            AND (p_end_date IS NULL OR enroll_date <= p_end_date)
            ORDER BY enroll_date;
    BEGIN
        FOR rec IN c_students LOOP
            DBMS_OUTPUT.PUT_LINE('Class ID: ' || rec.class_id || ', Enrollment Date: ' || rec.enrollment_date || ', Status: ' || rec.status);
        END LOOP;
    END;

    PROCEDURE student_class_list(
        p_start_date IN DATE,
        p_end_date IN DATE
    )
    IS
        CURSOR c_students
        IS
            SELECT student_id AS stu_id, section_id AS class_id, enroll_date AS enrollment_date, 'Enrolled' AS status
            FROM enrollment
            WHERE (p_start_date IS NULL OR enroll_date >= p_start_date)
            AND (p_end_date IS NULL OR enroll_date <= p_end_date)
            ORDER BY enroll_date;
    BEGIN
        FOR rec IN c_students LOOP
            DBMS_OUTPUT.PUT_LINE('Student ID: ' || rec.stu_id || ', Class ID: ' || rec.class_id || ', Enrollment Date: ' || rec.enrollment_date || ', Status: ' || rec.status);
        END LOOP;
    END;
END pkg_enrollment;
/
