
--=================================================================================================
-- Full database search, using either EQUALS or LIKE and TOP 1.
--=================================================================================================

SET NOCOUNT ON

DECLARE @Clause NVARCHAR(255)
SET @Clause = ' = ''Mark'''
--SET @Clause = ' LIKE ''%Mark%'''


DECLARE Data_Cursor CURSOR FOR
SELECT 
	TableName = QUOTENAME(t.name)
	,ColumnName = QUOTENAME(c.name)
FROM sys.columns c 
INNER JOIN sys.tables t ON t.[object_id] = c.[object_id]
INNER JOIN sys.types ty ON ty.system_type_id = c.system_type_id AND ty.user_type_id = c.user_type_id
WHERE 1=1
AND t.is_ms_shipped = 0
AND c.system_type_id IN (35, 99, 167, 175, 231, 239) -- text, ntext, varchar, char, nvarchar, sysname, nchar
--AND c.name NOT LIKE '%Uid'
ORDER BY t.name ASC, c.column_id ASC

DECLARE @TableName NVARCHAR(255)
DECLARE @PreviousTableName NVARCHAR(255)
DECLARE @ColumnName NVARCHAR(255) 
DECLARE @TSQL NVARCHAR(MAX)


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TableName, @ColumnName;


WHILE @@FETCH_STATUS = 0
BEGIN
	
	IF @PreviousTableName IS NULL OR @PreviousTableName != @TableName
	BEGIN
		-- The table has changed or is being set for the first time.
		IF @TSQL IS NOT NULL
		BEGIN
			-- IF we have TSQL then execute it.
			RAISERROR ('%s', 0, 0, @TSQL) WITH NOWAIT
			EXEC sp_executesql @TSQL
		END
	
		SET @TSQL = 'SELECT TOP 1 [' + @TableName + '] = NULL, * FROM ' + @TableName + ' WHERE ' + @ColumnName + @Clause
		SET @PreviousTableName = @TableName
	END
	ELSE 
	BEGIN
		SET @TSQL = @TSQL + ' OR ' + @ColumnName + @Clause
	END

	FETCH NEXT FROM Data_Cursor INTO @TableName, @ColumnName
	
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;
GO


