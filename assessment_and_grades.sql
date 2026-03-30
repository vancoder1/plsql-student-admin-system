CREATE OR REPLACE FUNCTION assessment_exists(
    p_class_id IN NUMBER,
    p_stu_id IN NUMBER,
    p_assessment_id IN NUMBER
)
RETURN BOOLEAN
IS
    v_tmp NUMBER;
BEGIN
    SELECT assessment_id
    INTO v_tmp
    FROM assessments
    WHERE assessment_id = p_assessment_id;

    SELECT class_id
    INTO v_tmp
    FROM classes
    WHERE class_id = p_class_id;

    SELECT stu_id
    INTO v_tmp
    FROM students
    WHERE stu_id = p_stu_id;


    RETURN TRUE;
EXCEPTION
    WHEN no_data_found THEN
        RETURN FALSE;
END;

CREATE OR REPLACE PACKAGE pkg_assessment_and_grades IS
    PROCEDURE create_assignment(
        assignment_description IN TEXT
    );

    PROCEDURE enter_student_grade(
        p_numeric_grade IN NUMBER,
        p_class_id IN NUMBER,
        p_stu_id IN NUMBER,
        p_assessment_id IN NUMBER
    );

    FUNCTION convert_grade(
        p_numeric_grade IN NUMBER
    )
    RETURN VARCHAR2;
END pkg_assessment_and_grades;

CREATE SEQUENCE assessment_id_seq
    MINVALUE 0
    START WITH 0
    INCREMENT BY 1
    CACHE 20;

CREATE OR REPLACE PACKAGE BODY pkg_assessment_and_grades IS
    PROCEDURE create_assignment(
        assignment_description IN VARCHAR2
    )
    IS
    BEGIN
        INSERT INTO assessments (assessment_id, description) VALUES (
            assessment_id_seq.NEXTVAL,
            assignment_description
        );
    END;

    PROCEDURE enter_student_grade(
        p_numeric_grade IN NUMBER,
        p_class_id IN NUMBER,
        p_stu_id IN NUMBER,
        p_assessment_id IN NUMBER
    )
    IS
    BEGIN
        IF assessment_exists(p_class_id, p_stu_id, p_assessment_id) THEN
            INSERT INTO class_assessments (class_id, stu_id, assessment_id, numeric_grade, date_turned_in) VALUES (
                p_class_id,
                p_stu_id,
                p_assignment_id,
                p_numeric_grade,
                SYSDATE
            );
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Missing either student with ID ' || p_stu_id || ', class with ID ' || p_class_id || ', or assessment with ID ' || p_assessment_id || '.');
        END IF;
    END;

    FUNCTION convert_grade(
        p_numeric_grade IN NUMBER
    )
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN CASE
            WHEN p_numeric_grade >= 90 THEN 'A'
            WHEN p_numeric_grade BETWEEN 80 AND 89 THEN 'B'
            WHEN p_numeric_grade BETWEEN 70 AND 79 THEN 'C'
            WHEN p_numeric_grade BETWEEN 60 and 69 THEN 'D'
            ELSE 'F'
        END;
    END;
END pkg_assessment_and_grades;