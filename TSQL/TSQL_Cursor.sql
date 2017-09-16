
SET NOCOUNT ON	


-- Declare variables to hold Row.Column values.
DECLARE @PrincipalName NVARCHAR(255) 
DECLARE @SchemaName NVARCHAR(255) 
DECLARE @IsSchemaOwner BIT
DECLARE @TSQL NVARCHAR(MAX)

DECLARE TSQL_Cursor CURSOR FOR 
SELECT 
	PrincipalName = dp.name
	,SchemaName = s.name
	,IsSchemaOwner = CASE WHEN s.principal_id IS NULL  THEN 0 ELSE 1 END
INTO #Data
FROM sys.database_principals dp WITH (NOLOCK)
LEFT JOIN sys.schemas s WITH (NOLOCK) ON s.principal_id = dp.principal_id
WHERE 1=1
AND dp.type_desc IN ('WINDOWS_USER', 'WINDOWS_GROUP')


-- Open cursor, populate variables.
OPEN TSQL_Cursor;
FETCH NEXT FROM TSQL_Cursor INTO @PrincipalName, @SchemaName, @IsSchemaOwner;


-- While we have data...
WHILE @@FETCH_STATUS = 0
BEGIN	
	
	BEGIN TRY
		-- Clear and re-sent @TSQL
		SET @TSQL = NULL
		SET @TSQL = 'DROP USER [' + @PrincipalName + '];'	
		
		EXEC sp_executesql @TSQL
		PRINT @TSQL
	END TRY
	BEGIN CATCH
		PRINT 'FAILED | ' + @TSQL + ' | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()		
	END CATCH	
	
	-- Get next variable values.
	FETCH NEXT FROM TSQL_Cursor INTO @PrincipalName, @SchemaName, @IsSchemaOwner
	
END


-- Clean-up cursor.
CLOSE TSQL_Cursor;
DEALLOCATE TSQL_Cursor;
GO