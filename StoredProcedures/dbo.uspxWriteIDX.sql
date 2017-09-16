
/*
DECLARE @TableSuffix VARCHAR(25)
DECLARE @SuffixLength INT

SET @TableSuffix = 'Audit'
SET @SuffixLength = LEN(@TableSuffix)

SELECT DISTINCT 'EXEC uspxWriteIDX ''' + cte.TableName + ''''
FROM 
(
SELECT 
	t.name AS TableName
	,c.name AS ColumnName
	,i.name AS IndexName
	,CASE
	WHEN RIGHT(t.name, @SuffixLength) = @TableSuffix AND i.name IS NULL THEN 0
	WHEN RIGHT(t.name, @SuffixLength) != @TableSuffix AND i.name IS NOT NULL THEN 0
	ELSE 1000
	END AS IsMissingIndex	
FROM sys.columns c WITH (NOLOCK)
INNER JOIN sys.tables t WITH (NOLOCK) ON c.object_id = t.object_id
LEFT JOIN sys.index_columns ic WITH (NOLOCK) ON ic.object_id = t.object_id AND ic.column_id = c.column_id
LEFT JOIN sys.indexes i WITH (NOLOCK) ON ic.index_id = i.index_id AND ic.column_id = c.column_id AND ic.object_id = i.object_id
WHERE 1=1
AND c.name LIKE '%[_]id'
) AS cte
WHERE cte.IsMissingIndex = 1000
order by 'EXEC uspxWriteIDX ''' + cte.TableName + ''''
*/


IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'uspxWriteIDX')
BEGIN
	DROP PROCEDURE dbo.uspxWriteIDX
	PRINT 'DROP PROCEDURE dbo.uspxWriteIDX'
END
GO

CREATE PROCEDURE dbo.uspxWriteIDX
	@TableName VARCHAR(255)
AS
BEGIN
	
	SET NOCOUNT ON 

	IF OBJECT_ID('tempdb..#Columns') IS NOT NULL
	BEGIN
		DROP TABLE #Columns
	END


	SELECT c.name AS ColumnName
	INTO #Columns
	FROM sys.foreign_key_columns fk WITH (NOLOCK)
	INNER JOIN sys.tables t WITH (NOLOCK) ON fk.parent_object_id = t.object_id
	INNER JOIN sys.columns c WITH (NOLOCK) ON c.column_id = fk.parent_column_id AND fk.parent_object_id = c.object_id
	WHERE t.name = @TableName
	ORDER BY c.name ASC


	WHILE (SELECT COUNT(1) FROM #Columns) > 0
	BEGIN
		
		DECLARE @ColumnName VARCHAR(255)
		DECLARE @IndexName VARCHAR(255)
		
		SET @ColumnName = (SELECT TOP 1 ColumnName FROM #Columns)
		SET @IndexName = 'idx_' + @TableName + '_' + @ColumnName
		
		PRINT '-- Create NONCLUSTERED INDEX [' + @IndexName + ']'
		PRINT 'IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TableName + ''') AND name = ''' + @IndexName + ''')'
		PRINT 'BEGIN'
		PRINT '		DROP INDEX [' + @IndexName + '] ON [dbo].[' + @TableName + '] WITH ( ONLINE = OFF )'
		PRINT '		PRINT ''DROP INDEX [' + @IndexName + '] ON [dbo].[' + @TableName + ']'''
		PRINT 'END'
		PRINT 'GO'
		PRINT ''
		PRINT 'CREATE NONCLUSTERED INDEX [' + @IndexName + '] ON [dbo].[' + @TableName + ']'
		PRINT '('
		PRINT '		[' + @ColumnName + '] ASC'
		PRINT ')'
		PRINT 'WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]'
		PRINT 'GO'
		PRINT ''
		
		DELETE #Columns WHERE ColumnName = @ColumnName
		
	END
	
END
GO