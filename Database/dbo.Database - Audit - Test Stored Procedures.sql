
--=================================================================================================
-- Hmmm...using the parameters found for a stored procedure create a string to execute
-- using NULL for every value, then execute it inside of a transacton.
--=================================================================================================
DECLARE @ProcedureName NVARCHAR(255) = 'uspDatabaseMaintenance'


SET NOCOUNT ON	
DECLARE @TSQL NVARCHAR(MAX) = 'EXEC ' + @ProcedureName
DECLARE @Name NVARCHAR(255)
DECLARE @Type NVARCHAR(255)
DECLARE @Position INT 


-- Find the parameters.
DECLARE Data_Cursor CURSOR DYNAMIC FOR 
SELECT p.PARAMETER_NAME, p.DATA_TYPE, p.ORDINAL_POSITION
FROM information_schema.parameters p 
WHERE 1=1
AND specific_name = @ProcedureName
ORDER BY ORDINAL_POSITION ASC


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @Name, @Type, @Position;


WHILE @@FETCH_STATUS = 0
BEGIN

	IF @Position = 1
	BEGIN
		SET @TSQL = @TSQL + ' ' + @Name + ' = NULL'
	END
	ELSE
	BEGIN
		SET @TSQL = @TSQL + ', ' + @Name + ' = NULL'
	END
	
	FETCH NEXT FROM Data_Cursor INTO @Name, @Type, @Position
	
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;



BEGIN TRANSACTION

	SET ROWCOUNT 5
	RAISERROR ('%s', 0, 0, @TSQL) WITH NOWAIT
	EXEC sp_executesql @TSQL
	SET ROWCOUNT 0
	
ROLLBACK TRANSACTION
GO
