
--=================================================================================================
-- Search every column of types: text, ntext, varchar, char, nvarchar, sysname, nchar
-- in every table for the defined text.
--=================================================================================================

SET NOCOUNT ON 

DECLARE @LikePattern VARCHAR(255) = '%lost_895826%' 
DECLARE @TopCount INT = 0
DECLARE @ExcludeTable TABLE(TableName VARCHAR(255)) 
DECLARE @ExcludeColumn TABLE(ColumnName VARCHAR(255)) 

INSERT INTO @ExcludeColumn (ColumnName) VALUES ('CreatedByUid')
INSERT INTO @ExcludeColumn (ColumnName) VALUES ('UpdatedByUid')


--=================================================================================================
-- Get a list of non-shipped tables.
--=================================================================================================
IF OBJECT_ID('tempdb..#Table') IS NOT NULL BEGIN DROP TABLE #Table END;
CREATE TABLE #Table
(
	id							INT IDENTITY(1,1),
	[Schema]					VARCHAR(255),
	[Name]						VARCHAR(255)
)

INSERT INTO #Table ([Schema], [Name])
SELECT [Schema] = s.[name], [Name] = t.[name]
FROM sys.tables t 
INNER JOIN sys.schemas s ON s.[schema_id] = t.[schema_id]
WHERE 1=1
AND t.is_ms_shipped = 0 
ORDER BY t.[name] ASC


--=================================================================================================
-- Generate the SELECT statements, TOP 10 or not.
--=================================================================================================
IF OBJECT_ID('tempdb..#Statement') IS NOT NULL BEGIN DROP TABLE #Statement END;
CREATE TABLE #Statement
(
	id							INT IDENTITY(1,1),
	[Table.Column]				VARCHAR(500),
	[SystemTypeId]				INT,
	[TSQL]						VARCHAR(4000)
)

DECLARE @Table_id INT = 1
DECLARE @Schema VARCHAR(255) = (SELECT [Schema] FROM #Table WHERE id = @Table_id)
DECLARE @Table VARCHAR(255) = (SELECT [Name] FROM #Table WHERE id = @Table_id)
DECLARE @Top VARCHAR(25) = CASE WHEN @TopCount > 0 THEN ' TOP ' + CONVERT(VARCHAR(10), @TopCount) ELSE '' END

WHILE @Table IS NOT NULL 
BEGIN

	DECLARE @KeyColumn VARCHAR(255) = 
	(
		SELECT TOP 1 COALESCE(cte.[name], c.[name])
		FROM sys.columns c 
		LEFT JOIN 
		(
			-- Restrict to CLUSTERED indexes where there's only one column in the index
			SELECT ic.[object_id], c.[name]
			FROM sys.index_columns ic 
			INNER JOIN sys.indexes i ON i.index_id = ic.index_id AND i.[object_id] = ic.[object_id]
			INNER JOIN sys.columns c ON c.column_id = ic.column_id AND c.[object_id] = i.[object_id]
			AND i.[type] = 1 
			AND i.is_primary_key = 1
			GROUP BY ic.[object_id], c.[name]
			HAVING COUNT(1) = 1
		) AS cte ON cte.[object_id] = c.[object_id]
		WHERE 1=1
		AND c.[object_id] = OBJECT_ID(@Table) 
		AND c.system_type_id IN (56, 127) -- INT, BIGINT
		AND (cte.[object_id] IS NOT NULL OR c.is_identity = 1)
	)


	-- Generate SELECT statement
	INSERT INTO #Statement ([Table.Column], [SystemTypeId], [TSQL])
	SELECT 
		[Table.Column] = QUOTENAME(@Table) + '.' + QUOTENAME(c.[name])
		,[SystemTypeId] = c.system_type_id
		,[TSQL] = 
			'SELECT ' + @Top + '''' + QUOTENAME(@Table) + '.' + QUOTENAME(c.[name]) + 
			CASE 
				WHEN @KeyColumn IS NOT NULL THEN ''', [Key_id] = ' + @KeyColumn 
				ELSE ''', [Key_id] = NULL' 
			END 
			+ 
			CASE 
				WHEN c.system_type_id = 99 THEN ', LEFT(CONVERT(NVARCHAR(MAX), ' + QUOTENAME(c.[name]) + '), 100) FROM '
				WHEN c.system_type_id = 35 THEN ', LEFT(CONVERT(VARCHAR(MAX), ' + QUOTENAME(c.[name]) + '), 100) FROM '
				ELSE ', LEFT(' + QUOTENAME(c.[name]) + ', 100) FROM '
			END 
			+ '' + QUOTENAME(@Table) + ' WHERE ' + QUOTENAME(c.[name]) + ' IS NOT NULL AND ' + QUOTENAME(c.[name]) + ' LIKE ''' + @LikePattern + ''''
	FROM sys.columns c 
	LEFT JOIN @ExcludeTable et ON et.TableName = @Table
	LEFT JOIN @ExcludeColumn ec ON ec.ColumnName = c.[name]
	WHERE 1=1
	AND c.[object_id] = OBJECT_ID(@Table) 
	AND c.system_type_id IN (35, 99, 167, 175, 231, 239) -- text, ntext, varchar, char, nvarchar, sysname, nchar
	AND et.TableName IS NULL 
	AND ec.ColumnName IS NULL 
	ORDER BY c.column_id ASC
	
	-- Next table		
	SET @Table_id = @Table_id + 1
	SET @Schema = (SELECT [Schema] FROM #Table WHERE id = @Table_id)
	SET @Table = (SELECT [Name] FROM #Table WHERE id = @Table_id)

END


--=================================================================================================
-- Populate #Result
--=================================================================================================
IF OBJECT_ID('tempdb..#Result') IS NOT NULL BEGIN DROP TABLE #Result END;
CREATE TABLE #Result
(
	[Table.Column]				VARCHAR(500),
	[Key_id]					SQL_VARIANT NULL,
	[Value]						NVARCHAR(200) NULL
)

DECLARE @SQL_id INT = 1
DECLARE @TableColumn VARCHAR(500) = (SELECT [Table.Column] FROM #Statement WHERE id = @SQL_id)
DECLARE @TSQL VARCHAR(1000) = (SELECT [TSQL] FROM #Statement WHERE id = @SQL_id)

WHILE @TSQL IS NOT NULL 
BEGIN
	RAISERROR (@TableColumn, 0, 0) WITH NOWAIT
	
	INSERT INTO #Result ([Table.Column], [Key_id], Value)
	EXEC (@TSQL)
	
	-- Next TSQL
	SET @SQL_id = @SQL_id + 1
	SET @TableColumn = (SELECT [Table.Column] FROM #Statement WHERE id = @SQL_id)
	SET @TSQL = (SELECT [TSQL] FROM #Statement WHERE id = @SQL_id)
END


--=================================================================================================
-- Output
--=================================================================================================
SELECT * 
FROM #Result
GO
