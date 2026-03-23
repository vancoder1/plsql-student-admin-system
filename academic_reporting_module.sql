-- package specification
CREATE OR REPLACE PACKAGE pkg_academic_reporting IS
    -- show enrollments missing a final grade
    PROCEDURE show_missing_grades(
        p_start_date IN DATE DEFAULT NULL,
        p_end_date IN DATE DEFAULT NULL
    );

    -- show class offerings in a date range
    PROCEDURE show_class_offerings(
        p_start_date IN DATE,
        p_end_date IN DATE
    );

    -- count total classes for a course
    FUNCTION count_classes_per_course(
        p_course_no IN NUMBER
    ) RETURN NUMBER;
END pkg_academic_reporting;
/

-- package body
CREATE OR REPLACE PACKAGE BODY pkg_academic_reporting IS

    -- compute average grade for a section
    FUNCTION compute_average_grade(p_section_id IN NUMBER) RETURN NUMBER IS
        v_avg NUMBER;
    BEGIN
        SELECT AVG(numeric_grade)
        INTO v_avg
        FROM grade
        WHERE section_id = p_section_id;

        RETURN NVL(v_avg, 0);
    END compute_average_grade;

    -- show enrollments that have no final grade
    PROCEDURE show_missing_grades(
        p_start_date IN DATE DEFAULT NULL,
        p_end_date IN DATE DEFAULT NULL
    ) IS
        v_start DATE := NVL(p_start_date, SYSDATE - 365);
        v_end DATE := NVL(p_end_date, SYSDATE);

        CURSOR c_missing IS
            SELECT section_id, student_id, enroll_date
            FROM enrollment
            WHERE final_grade IS NULL
            AND enroll_date BETWEEN v_start AND v_end
            ORDER BY enroll_date DESC;
    BEGIN
        FOR rec IN c_missing LOOP
            DBMS_OUTPUT.PUT_LINE('class id (section): ' || rec.section_id || 
                                 ', student id: ' || rec.student_id ||
                                 ', enroll date: ' || rec.enroll_date);
        END LOOP;
    END show_missing_grades;

    -- show class offerings with instructor and avg grade
    PROCEDURE show_class_offerings(
        p_start_date IN DATE,
        p_end_date IN DATE
    ) IS
        CURSOR c_offerings IS
            SELECT DISTINCT 
                   s.section_id, 
                   s.start_date_time, 
                   c.description AS course_title,
                   s.section_no, 
                   i.first_name || ' ' || i.last_name AS instructor_name
            FROM section s
            JOIN course c ON s.course_no = c.course_no
            JOIN instructor i ON s.instructor_id = i.instructor_id
            JOIN enrollment e ON s.section_id = e.section_id
            WHERE s.start_date_time BETWEEN p_start_date AND p_end_date;

        v_avg_grade NUMBER;
    BEGIN
        FOR rec IN c_offerings LOOP
            v_avg_grade := compute_average_grade(rec.section_id);

            DBMS_OUTPUT.PUT_LINE('class id: ' || rec.section_id || 
                                 ', start date: ' || rec.start_date_time ||
                                 ', course: ' || rec.course_title || 
                                 ', section code: ' || rec.section_no ||
                                 ', instructor: ' || rec.instructor_name || 
                                 ', avg grade: ' || ROUND(v_avg_grade, 2));
        END LOOP;
    END show_class_offerings;

    -- count classes per course
    FUNCTION count_classes_per_course(p_course_no IN NUMBER) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM section
        WHERE course_no = p_course_no;

        RETURN v_count;
    END count_classes_per_course;

END pkg_academic_reporting;
/