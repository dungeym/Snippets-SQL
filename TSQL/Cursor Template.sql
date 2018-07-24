
-- ================================================================================================
-- Cursor template.
-- Declare the variables required to hold the data from each column.
-- Declare the CURSOR, should be followed by the SELECT statement that only returns the columns that match the variables.
-- Open the cursor and fetch the first row into the variables.
-- While the @@FETCH_STATUS is 0 do something, then fetch the next row.
-- Close and deallocate the cursor.
-- ================================================================================================

SET NOCOUNT ON	


DECLARE @Column1 INT
DECLARE @Column2 BIT 

DECLARE Data_Cursor CURSOR FOR 
SELECT Column1, Column2
FROM MyTableOrViewOrSomething
WHERE Column2 = 0
ORDER BY Column1 ASC


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @Column1, @Column2;


WHILE @@FETCH_STATUS = 0
BEGIN
		
	BEGIN TRY
		-- Do something
	END TRY
	BEGIN CATCH
		PRINT 'FAILED | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()
	END CATCH	
	
	FETCH NEXT FROM Data_Cursor INTO @Column1, @Column2;
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;
GO

-- @@FETCH_STATUS values.
-- 0 	The FETCH statement was successful.
-- -1 	The FETCH statement failed or the row was beyond the result set.
-- -2 	The row fetched is missing.
-- -9 	The cursor is not performing a fetch operation.
