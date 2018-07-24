
--=================================================================================================
-- Output information about the indexes in the database.
--=================================================================================================

DECLARE @TableName NVARCHAR(255)
--SET @TableName = 'OnlyThisTable'

SELECT
	cte.id
	,cte.TableName
	,cte.IndexName
	,cte.IndexType
	,cte.IndexColumns
	,cte.IncludeColumns 
FROM 
(
	SELECT
		id = i.[object_id]
		,TableName = OBJECT_NAME(i.[object_id])
		,IndexName = i.name 
		,IndexType = CASE
			WHEN i.[type] = 1 AND i.is_unique_constraint = 1 THEN 'Clustered Unique'
			WHEN i.[type] = 2 AND i.is_unique_constraint = 1 THEN 'Non-clustered Unique'
			WHEN i.[type] = 1 THEN 'Clustered'
			WHEN i.[type] = 2 THEN 'Non-clustered'
			ELSE NULL
			END
		,IsPrimaryKey = i.is_primary_key
		,IsDisabled = i.is_disabled
		,IndexColumns = STUFF((
			SELECT ',' + name 
			FROM sys.columns c 
			INNER JOIN sys.index_columns ic ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
			WHERE 1=1
			AND ic.[object_id] = i.[object_id]
			AND ic.index_id = i.index_id
			AND ic.is_included_column = 0
			ORDER BY ic.index_column_id ASC
			FOR XML PATH ('')), 1, 1, '') 
		,IncludeColumns = STUFF((
			SELECT ',' + name 
			FROM sys.columns c 
			INNER JOIN sys.index_columns ic ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
			WHERE 1=1
			AND ic.[object_id] = i.[object_id]
			AND ic.index_id = i.index_id
			AND ic.is_included_column = 1
			ORDER BY ic.index_column_id ASC
			FOR XML PATH ('')), 1, 1, '') 
	FROM sys.indexes i 
	INNER JOIN sys.objects o ON o.[object_id] = i.[object_id]
	WHERE 1=1
	AND o.is_ms_shipped = 0
	AND i.[type] != 0 -- Heap
) AS cte
WHERE 1=1
AND (@TableName IS NULL OR cte.TableName = @TableName)
ORDER BY cte.TableName ASC, cte.IndexColumns ASC