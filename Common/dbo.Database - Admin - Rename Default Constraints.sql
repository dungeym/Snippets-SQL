--=================================================================================================
-- Find and rename the Default Constraints.
--=================================================================================================

SET NOCOUNT ON

SELECT 
	'EXEC sp_rename ''' + name + ''', ''DF_' + OBJECT_NAME(parent_object_id) + '_' + COL_NAME(parent_object_id, parent_column_id) + '''' AS TSQL
	,OBJECT_NAME(parent_object_id) AS TableName
	,COL_NAME(parent_object_id, parent_column_id) AS ColumnName
	,[name] AS OldName
	,'DF_' + OBJECT_NAME(parent_object_id) + '_' + COL_NAME(parent_object_id, parent_column_id) + '' AS [NewName]
	INTO #TSQL 
FROM sys.default_constraints WHERE name LIKE 'DF__%__%__[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]'

DECLARE @TSQL NVARCHAR(500)
DECLARE @TableName NVARCHAR(255)
DECLARE @ColumnName NVARCHAR(255)
DECLARE @OldName NVARCHAR(255)
DECLARE @NewName NVARCHAR(255)

SET @TSQL = (SELECT TOP 1 [TSQL] FROM #TSQL ORDER BY TableName ASC, ColumnName ASC)
SET @TableName = (SELECT TOP 1 TableName FROM #TSQL WHERE TSQL = @TSQL)
SET @ColumnName = (SELECT TOP 1 ColumnName FROM #TSQL WHERE TSQL = @TSQL)
SET @OldName = (SELECT TOP 1 OldName FROM #TSQL WHERE TSQL = @TSQL)
SET @NewName = (SELECT TOP 1 [NewName] FROM #TSQL WHERE TSQL = @TSQL)

WHILE NOT @TSQL IS NULL
BEGIN
	
	PRINT 'Table:[' + @TableName + '], Column;[' + @ColumnName + '] re-name ' + @OldName + ' to ' + @NewName
	EXEC sp_executesql @TSQL
	
	DELETE #TSQL WHERE [TSQL] = @TSQL
	
	SET @TSQL = (SELECT TOP 1 [TSQL] FROM #TSQL ORDER BY TableName ASC, ColumnName ASC)
	SET @TableName = (SELECT TOP 1 TableName FROM #TSQL WHERE TSQL = @TSQL)
	SET @ColumnName = (SELECT TOP 1 ColumnName FROM #TSQL WHERE TSQL = @TSQL)
	SET @OldName = (SELECT TOP 1 OldName FROM #TSQL WHERE TSQL = @TSQL)
	SET @NewName = (SELECT TOP 1 [NewName] FROM #TSQL WHERE TSQL = @TSQL)

END

DROP TABLE #TSQL
GO