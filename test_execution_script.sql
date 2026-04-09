SET SERVEROUTPUT ON;

DECLARE
    v_new_assmt_id NUMBER;
    v_prev_grade NUMBER;
    v_new_grade NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('1. TESTING ENROLLMENT MANAGEMENT MODULE');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    
    -- Test 1A: Enrolling a student in a class (Success)
    pkg_enrollment.enroll_student_in_class(102, 79);
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Enrolled student 102 in class 79.');
    
    -- Test 1B: Attempting to enroll a student twice in the same class (Error)
    BEGIN
        pkg_enrollment.enroll_student_in_class(102, 79);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (Enroll Twice): ' || SQLERRM);
    END;

    -- Test 1C: Displaying a student's class history (Success)
    DBMS_OUTPUT.PUT_LINE('--- Student 102 Class History ---');
    pkg_enrollment.student_class_list(102, NULL, NULL);

    -- Test 1D: Dropping a student from a class (Success)
    pkg_enrollment.drop_student_from_class(102, 79);
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Dropped student 102 from class 79.');

    -- Test 1E: Attempting to drop a student who is not enrolled in a class (Error)
    BEGIN
        pkg_enrollment.drop_student_from_class(102, 79);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (Drop Not Enrolled): ' || SQLERRM);
    END;


    DBMS_OUTPUT.PUT_LINE(CHR(10) || '====================================================');
    DBMS_OUTPUT.PUT_LINE('2. TESTING ACADEMIC REPORTING MODULE');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    
    -- Test 2A: Generating administrative reports - Missing Grades (Success)
    DBMS_OUTPUT.PUT_LINE('-- Missing Grades Report --');
    pkg_academic_reporting.show_missing_grades(TO_DATE('01-JAN-2000', 'DD-MON-YYYY'), SYSDATE);
    
    -- Test 2B: Generating administrative reports - Class Offerings (Success)
    DBMS_OUTPUT.PUT_LINE('-- Class Offerings Report --');
    pkg_academic_reporting.show_class_offerings(TO_DATE('01-JAN-2000', 'DD-MON-YYYY'), TO_DATE('31-DEC-2027', 'DD-MON-YYYY'));
    

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '====================================================');
    DBMS_OUTPUT.PUT_LINE('3. TESTING ASSESSMENT AND GRADE MANAGEMENT MODULE');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    
    -- Test 3A: Inserting an assignment (Success)
    pkg_assessment_and_grades.create_assignment('Final Database Project');
    SELECT MAX(assessment_id) INTO v_new_assmt_id FROM assessments;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Created new assessment with ID: ' || v_new_assmt_id);

    -- Setup: Ensure a specific student is enrolled so we can grade them
    BEGIN
        INSERT INTO enrollment (student_id, section_id, enroll_date, created_by, created_date, modified_by, modified_date) 
        VALUES (103, 81, SYSDATE, USER, SYSDATE, USER, SYSDATE);
    EXCEPTION WHEN OTHERS THEN NULL; -- Ignore if they are already in the table
    END;

    -- Test 3B: Inserting assignment grades (Success)
    pkg_assessment_and_grades.enter_student_grade(92, 81, 103, v_new_assmt_id);
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Entered grade of 92 for student 103 in class 81.');
    
    -- Test 3C: Attempting to insert a grade for a non-existent assessment (Error)
    BEGIN
        pkg_assessment_and_grades.enter_student_grade(85, 81, 103, 9999);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (Non-existent assessment): ' || SQLERRM);
    END;

    -- Test 3D: Attempting to insert a grade for a non-existent student (Error)
    BEGIN
        pkg_assessment_and_grades.enter_student_grade(85, 81, 9999, v_new_assmt_id);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (Non-existent student): ' || SQLERRM);
    END;
    
    -- Verify convert_grade function
    DBMS_OUTPUT.PUT_LINE('Conversion Test: Numeric 85 converts to Letter Grade: ' || pkg_assessment_and_grades.convert_grade(85));


    DBMS_OUTPUT.PUT_LINE(CHR(10) || '====================================================');
    DBMS_OUTPUT.PUT_LINE('4. TESTING TRIGGER IMPLEMENTATION');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    
    -- Setup baseline final_grade
    UPDATE enrollment SET final_grade = 75, modified_date = SYSDATE WHERE student_id = 104 AND section_id = 81;
    
    -- Clear audit history from the setup phase so we only see the intended update
    DELETE FROM grade_change_history WHERE student_id = 104 AND section_id = 81;
    
    -- Test 4A: Updating a final grade and verifying that the trigger records the change (Success)
    UPDATE enrollment SET final_grade = 95, modified_date = SYSDATE WHERE student_id = 104 AND section_id = 81;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Updated final grade for student 104 in section 81 from 75 to 95.');
    
    -- Query the audit table
    SELECT previous_grade, new_grade INTO v_prev_grade, v_new_grade
    FROM (
        SELECT previous_grade, new_grade
        FROM grade_change_history 
        WHERE student_id = 104 AND section_id = 81 
        ORDER BY change_date DESC
    )
    WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Audit Log Validation -> Previous Grade: ' || v_prev_grade || ', New Grade: ' || v_new_grade);

    -- Test 4B: Attempting to update a final grade for a non-existent enrollment (Error / Edge Case)
    UPDATE enrollment SET final_grade = 100 WHERE student_id = 9999 AND section_id = 9999;
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED RESULT: Update affected 0 rows for non-existent enrollment. Trigger did not fire.');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'ALL TESTS COMPLETED SUCCESSFULLY.');
END;
/