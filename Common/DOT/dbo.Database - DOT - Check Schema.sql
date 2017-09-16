DECLARE @TriggeredTableSuffix VARCHAR(25)
DECLARE @SuffixLength INT

SET @TriggeredTableSuffix = 'Audit'
SET @SuffixLength = LEN(@TriggeredTableSuffix)

-- ================================================================================================
-- Do all tables contain the standard columns?
-- ================================================================================================
SELECT 
	[Name] = 'Standard Columns'
	,cte.TableName
	,cte.ColumnCount
	,CASE
	WHEN RIGHT(cte.TableName, @SuffixLength) = @TriggeredTableSuffix AND cte.ColumnCount = 6 THEN 0
	WHEN RIGHT(cte.TableName, @SuffixLength) = @TriggeredTableSuffix AND cte.ColumnCount = 7 THEN 0
	WHEN RIGHT(cte.TableName, @SuffixLength) != @TriggeredTableSuffix AND cte.ColumnCount = 7 THEN 0
	ELSE 1000
	END AS IsMissingStandardColumns
FROM
(
	SELECT 
		t.[name] AS TableName
		,(SELECT COUNT(1) AS ColumnCount
			FROM sys.columns c WITH (NOLOCK)
			WHERE c.[name] IN	
			(
			'Id'
			,'DeletedDate'
			,'CreatedDate'
			,'CreatedByUid'
			,'UpdatedDate'
			,'UpdatedByUid'
			,'DbStamp'
			)
			AND c.[object_id] = t.[object_id]
		) AS ColumnCount
	FROM sys.tables t WITH (NOLOCK)
	WHERE 1=1
) AS cte
ORDER BY cte.TableName ASC


-- ================================================================================================
-- Are there any tables where the fact column matches the table name?
-- ================================================================================================
SELECT 
	[Name] = 'Has Invalid Column Name'
	,TableName = t.[name]
	,FactName = SUBSTRING(t.[name], 4, 500)
	,HasInvalidColumnName = CASE 
		WHEN (SELECT COUNT(1) FROM sys.columns c WITH (NOLOCK) WHERE c.[name] = SUBSTRING(t.[name], 4, 500) AND c.[object_id] = t.[object_id]) > 0 THEN 1000
		ELSE 0
		END
FROM sys.tables t WITH (NOLOCK)
WHERE 1=1
ORDER BY t.[name] ASC


-- ================================================================================================
-- Do all '_id' columns have a FK relationship?
-- ================================================================================================
SELECT 
	[Name] = 'Missing FK Relationship'
	,TableName = t.[name]
	,ColumnName = c.[name]
	,ReferenceTable = OBJECT_NAME(fk.referenced_object_id)
	,IsMissingRelationship = CASE 
		WHEN RIGHT(t.[name], @SuffixLength) = @TriggeredTableSuffix AND fk.referenced_object_id IS NULL THEN 0
		WHEN RIGHT(t.[name], @SuffixLength) != @TriggeredTableSuffix AND fk.referenced_object_id IS NOT NULL THEN 0
		ELSE 1000
		END
FROM sys.columns c WITH (NOLOCK)
INNER JOIN sys.tables t WITH (NOLOCK) ON t.[object_id] = c.[object_id]
LEFT JOIN sys.foreign_key_columns fk WITH (NOLOCK) ON fk.parent_object_id = c.[object_id] AND fk.parent_column_id = c.column_id
WHERE 1=1
AND c.[name] LIKE '%[_]id'
ORDER BY t.[name] ASC, c.[name] ASC


-- ================================================================================================
-- Is there an INDEX on all '_id' columns?
-- ================================================================================================
SELECT 
	[Name] = 'Missing INDEX on FK column'
	,TableName = t.[name]
	,ColumnName = c.[name]
	,IndexName = i.[name]
	,IsMissingIndex = CASE
		WHEN RIGHT(t.[name], @SuffixLength) = @TriggeredTableSuffix AND i.[name] IS NULL THEN 0
		WHEN RIGHT(t.[name], @SuffixLength) != @TriggeredTableSuffix AND i.[name] IS NOT NULL THEN 0
		ELSE 1000
		END	
FROM sys.columns c WITH (NOLOCK)
INNER JOIN sys.tables t WITH (NOLOCK) ON c.[object_id] = t.[object_id]
LEFT JOIN sys.index_columns ic WITH (NOLOCK) ON ic.[object_id] = t.[object_id] AND ic.column_id = c.column_id
LEFT JOIN sys.indexes i WITH (NOLOCK) ON ic.index_id = i.index_id AND ic.column_id = c.column_id AND ic.[object_id] = i.[object_id]
WHERE 1=1
AND c.[name] LIKE '%[_]id'
ORDER BY t.[name] ASC, c.[name] ASC


-- ================================================================================================
-- Is there an Audit Table, if so do the columns match?
-- ================================================================================================
SELECT 
	[Name] = 'Out of sync Audit table'
	,TableName = OBJECT_NAME(c.[object_id])
	,ColumnName = c.[name]
	,AuditTableName = OBJECT_NAME(c.[object_id]) + @TriggeredTableSuffix
	,MissingAuditColumnName = audit.[name]
FROM sys.columns c WITH (NOLOCK)
INNER JOIN sys.tables t WITH (NOLOCK) ON c.[object_id] = t.[object_id]
LEFT JOIN sys.columns audit WITH (NOLOCK) ON OBJECT_NAME(audit.[object_id]) = OBJECT_NAME(c.[object_id]) + @TriggeredTableSuffix AND c.[name] = audit.[name]
WHERE 1=1
AND c.[name] != 'DbStamp'
AND t.[name] NOT LIKE '%' + @TriggeredTableSuffix
AND audit.[name] IS NULL 
AND EXISTS (SELECT * FROM sys.tables WHERE [name] = t.[name] + @TriggeredTableSuffix)
GO