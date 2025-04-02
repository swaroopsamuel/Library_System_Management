SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM members;


-- Project Task

--*EASY/INTERMEDIATE LEVEL*--

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"



INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES (
		'978-1-60129-456-2', 
		'To Kill a Mockingbird', 
		'Classic', 
		6.00, 
		'yes', 
		'Harper Lee', 
		'J.B. Lippincott & Co.');
		


-- Task 2: Update an Existing Member's Address



UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;



-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.



DELETE FROM issued_status
WHERE issued_id = 'IS121'



-- Task 4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';



--Task 5: List Members Who Have Issued More Than One Book



SELECT issued_emp_id,
		COUNT(issued_id) as total_book_issued
FROM issued_status
GROUP BY (issued_emp_id)
HAVING COUNT(issued_id)>1;



-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_count**
-- CTAS (Create Table As Select)



CREATE TABLE books_count 
AS
		SELECT 
			b.isbn, 
			b.book_title,
			COUNT(ist.issued_id) as no_of_issued
		FROM books b
		JOIN issued_status as ist
		ON 
			ist.issued_book_isbn = b.isbn
		GROUP BY 1, 2
		
SELECT * FROM books_count;



-- Task 7. Retrieve All Books in a Specific Category
-- 4. Data Analysis & Findings
-- The following SQL queries were used to address specific questions:



SELECT * FROM books
WHERE category = 'Fiction';



-- Task 8: Find Total Rental Income by Category



SELECT
	b.category,
	SUM(b.rental_price) AS total_rental_income,
	COUNT(*) AS total_count
FROM books AS b
JOIN issued_status AS ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1;



-- Task 9: List Members Who Registered in the Last 180 Days



INSERT INTO members(member_id, member_name, member_address, reg_date)
VALUES ('C120', 'chris', '130 Beth St', '2025-01-01'),
		('C121', 'david', '250 Avenue St', '2025-04-01');


SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days'



-- Task 10: List Employees with Their Branch Manager's Name and their branch details



SELECT em.emp_id, 
	   em.emp_name,  
	   em.position,
	   em.salary,
	   b.branch_id,
	   b.manager_id,
	   em1.emp_name AS manager
FROM employees AS em
JOIN branch AS b
ON em.branch_id = b.branch_id
JOIN employees AS em1
ON em1.emp_id = b.manager_id



-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold



CREATE TABLE books_above_threshold
AS
	SELECT * FROM books
	WHERE rental_price > 7.00;

SELECT * FROM books_above_threshold;



-- Task 12. Retrieve the List of Books Not Yet Returned


SELECT ist.issued_book_name 
FROM issued_status AS ist
LEFT JOIN return_status AS rts
		ON rts.issued_id = ist.issued_id 
WHERE rts.return_id is NULL;



--*ADVANCED LEVEL*--



-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

/*
issued_status = members == books == return_status
filter books which are returned
*/


SELECT 
    ist.issued_member_id,
    m.member_name,
    b.book_title,
    ist.issued_date,
    (CURRENT_DATE - ist.issued_date) AS overdue_days
	
FROM issued_status ist
JOIN 
members m 
ON m.member_id = ist.issued_member_id
JOIN 
books b 
ON b.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status rts 
ON rts.issued_id = ist.issued_id
WHERE 
    (CURRENT_DATE - ist.issued_date) > 30 
    AND rts.return_Date IS NULL
ORDER BY 1;



-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table)

 
-- Stored procedure
CREATE OR REPLACE PROCEDURE add_return_records(
    p_return_id VARCHAR(10), 
    p_issued_id VARCHAR(10), 
    p_book_quality VARCHAR(15)
)
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);

BEGIN
    -- Inserting into return_status table
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality) 
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    -- Fetching issued book ISBN and book name
    SELECT issued_book_isbn, 
		   issued_book_name
    INTO 
			v_isbn, 
			v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Updating books status
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;  -- Use dynamic ISBN instead of hardcoded value

    -- Display return message
    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$;


CALL add_return_records();


-- Testing FUNCTION add_return_records

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

CALL add_return_records('RS138', 'IS135', 'Good');


-- Calling FUNCTION 

SELECT * FROM books
WHERE isbn = '978-0-330-25864-8'

UPDATE books
SET status = 'yes'
WHERE isbn = '978-0-330-25864-8'


SELECT * FROM issued_status
WHERE issued_id = 'IS140'

SELECT * FROM return_status

CALL add_return_records('RS148', 'IS140', 'Good');



/* Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/


CREATE TABLE branch_reports AS
SELECT 
    br.branch_id,
    br.manager_id,
    COUNT(ist.issued_id) AS no_of_books_issued,
    COUNT(rts.return_id) AS no_of_books_returned,
    SUM(b.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employees AS e 
    ON e.emp_id = ist.issued_emp_id
JOIN branch AS br 
    ON e.branch_id = br.branch_id
LEFT JOIN return_status AS rts 
    ON rts.issued_id = ist.issued_id
JOIN books AS b 
    ON ist.issued_book_isbn = b.isbn
GROUP BY br.branch_id, br.manager_id;

SELECT * FROM branch_reports;



/* Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
*/

CREATE TABLE active_members
AS
	SELECT * 
	FROM members
	WHERE member_id IN (SELECT 
				        DISTINCT (issued_member_id)		
					 FROM issued_status
					 WHERE issued_date >= CURRENT_DATE - INTERVAL '6 MONTHS')




/* Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
*/



SELECT e.emp_name,
 	   br.*,
	   COUNT(ist.issued_id) AS no_of_books	  
FROM issued_status AS ist
JOIN employees AS e
	ON e.emp_id = ist.issued_emp_id
JOIN branch AS br
	ON br.branch_id = e.branch_id
GROUP BY 1, 2
ORDER BY no_of_books DESC
LIMIT 3;




/* Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.
*/

SELECT 
    m.member_name,
    ist.issued_book_name,
    COUNT(ist.issued_id) AS times_issued_damaged
FROM issued_status AS ist
JOIN members AS m 
    ON m.member_id = ist.issued_member_id
JOIN return_status AS rts 
    ON rts.issued_id = ist.issued_id
WHERE rts.book_quality LIKE 'damaged'  
GROUP BY m.member_name, ist.issued_book_name
HAVING COUNT(ist.issued_id) > 2;




/* Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 

-- Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 

-- The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 

-- The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 

-- If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

*/
 

CREATE OR REPLACE PROCEDURE issued_book (
    p_issue_id VARCHAR(10),
    p_issued_member_id VARCHAR(30),
    p_issued_book_isbn VARCHAR(50), 
    p_issued_emp_id VARCHAR(10)
)
LANGUAGE plpgsql
AS $$

DECLARE
    v_status VARCHAR(10);  -- Variable to check book availability

BEGIN
    -- Checking if the book is available
    SELECT status 
    INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    -- If the book is available, issue it
	
    IF v_status = 'yes' THEN  
        -- Insert issue record
        INSERT INTO issued_status (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issue_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        -- Update book status to "no" (not available)
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        -- Success message
        RAISE NOTICE 'Book record added successfully for ISBN: %', p_issued_book_isbn;
    
    ELSE  
        -- Failure message if book is not available
        RAISE NOTICE 'Sorry, the requested book is unavailable: %', p_issued_book_isbn;
    END IF;

END;
$$;

CALL issued_book('IS155', 'C108', '978-0-553-29698-2', 'E104');




/* Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

-- Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days.

-- The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. 

-- The resulting table should show: Member ID, Number of overdue books, Total fines.

*/


CREATE TABLE fined_members

AS

SELECT 
	ist.issued_member_id,
	COUNT(ist.issued_id) AS overdue_books,
	SUM((CURRENT_DATE - ist.issued_date - 30) * 0.50) AS total_fines
FROM issued_status AS ist
LEFT JOIN return_status AS rts
		ON ist.issued_id  = rts.issued_id 
WHERE (CURRENT_DATE - ist.issued_date) > 30
AND rts.return_id is NULL
GROUP BY 1;


SELECT * FROM fined_members





