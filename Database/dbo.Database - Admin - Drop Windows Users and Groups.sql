
--=================================================================================================
-- Find and drop Windows Users and Windows Groups.
--=================================================================================================

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;
SELECT 
	PrincipalName = dp.name
	,SchemaName = s.name
	,IsSchemaOwner = CASE 
		WHEN s.principal_id IS NULL THEN 0 
		ELSE 1 
		END
INTO #Data
FROM sys.database_principals dp 
LEFT JOIN sys.schemas s ON s.principal_id = dp.principal_id
WHERE 1=1
AND dp.type_desc IN ('WINDOWS_USER', 'WINDOWS_GROUP')


DECLARE @PrincipalName NVARCHAR(255) 
DECLARE @SchemaName NVARCHAR(255) 
DECLARE @IsSchemaOwner BIT
DECLARE @TSQL NVARCHAR(MAX)


DECLARE Data_Cursor CURSOR DYNAMIC FOR 
SELECT 
	PrincipalName
	, SchemaName
	, IsSchemaOwner 
FROM #Data 
ORDER BY PrincipalName ASC


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @PrincipalName, @SchemaName, @IsSchemaOwner;


WHILE @@FETCH_STATUS = 0
BEGIN
	IF @IsSchemaOwner = 1
	BEGIN		
		BEGIN TRY
			SET @TSQL = NULL
			SET @TSQL = 'ALTER AUTHORIZATION ON SCHEMA::[' + @SchemaName + '] TO dbo;'
			EXEC sp_executesql @TSQL
			PRINT @TSQL
			
		END TRY
		BEGIN CATCH
			PRINT 'FAILED | ' + @TSQL + ' | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()	
			RAISERROR ('Failed to ALTER AUTHORIZATION.', 16, 0)	
			
		END CATCH
	END
	
	
	BEGIN TRY
		SET @TSQL = NULL
		SET @TSQL = 'DROP USER [' + @PrincipalName + '];'	
		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
	END TRY
	BEGIN CATCH
		PRINT 'FAILED | ' + @TSQL + ' | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()
		RAISERROR ('Failed to DROP USER.', 16, 0)
		
	END CATCH	
	
	FETCH NEXT FROM Data_Cursor INTO @PrincipalName, @SchemaName, @IsSchemaOwner
	
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;
GO