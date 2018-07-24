
--=================================================================================================
-- Find constraints that were created without a specific name (named by SQL Server)
-- and rename them 'DF_<TableName>_<ColumnName>'
--=================================================================================================

SET NOCOUNT ON

DECLARE @TSQL NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(255)
DECLARE @ColumnName NVARCHAR(255)
DECLARE @OldName NVARCHAR(255)
DECLARE @NewName NVARCHAR(255)

DECLARE Data_Cursor CURSOR FOR 
SELECT 
	[TSQL] = 'EXEC sp_rename ''' + name + ''', ''DF_' + OBJECT_NAME(parent_object_id) + '_' + COL_NAME(parent_object_id, parent_column_id) + ''''
	,TableName = OBJECT_NAME(parent_object_id)
	,ColumnName = COL_NAME(parent_object_id, parent_column_id)
	,OldName = [name]
	,[NewName] = 'DF_' + OBJECT_NAME(parent_object_id) + '_' + COL_NAME(parent_object_id, parent_column_id) + ''
FROM sys.default_constraints 
WHERE 1=1
AND name LIKE 'DF__%__%__[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]'


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TSQL,@TableName, @ColumnName, @OldName, @NewName;


WHILE @@FETCH_STATUS = 0
BEGIN
	
	BEGIN TRY
		PRINT 'Table:[' + @TableName + '], Column;[' + @ColumnName + '] re-name ' + @OldName + ' to ' + @NewName
		EXEC sp_executesql @TSQL
		
	END TRY
	BEGIN CATCH
		PRINT SPACE(5) + 'FAILED | ' + @TSQL + ' | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()		
	END CATCH
	
	PRINT 'Table:[' + @TableName + '], Column;[' + @ColumnName + '] re-name ' + @OldName + ' to ' + @NewName
	EXEC sp_executesql @TSQL
	
	FETCH NEXT FROM Data_Cursor INTO @TSQL,@TableName, @ColumnName, @OldName, @NewName;

END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;
GO