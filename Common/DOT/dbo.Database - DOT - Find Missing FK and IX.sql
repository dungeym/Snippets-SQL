
SELECT * 
FROM 
(
	SELECT 
		[Object_id] = c.[object_id]
		,TableName = OBJECT_NAME(c.[object_id])
		,[RowCount] = ps.row_count
		,ColumnName = c.name
		,Column_id = c.column_id
		,ColumnType_id = c.system_type_id
		,IsNullable = c.is_nullable
		,FkName = fk.name
		,IxName = i.name
		,IxType = i.type_desc
	FROM sys.columns c WITH (NOLOCK)
	INNER JOIN sys.tables t WITH (NOLOCK) ON t.[object_id] = c.[object_id] AND t.[type] = 'U' AND t.is_ms_shipped = 0 AND t.name LIKE 'tbl%'
	LEFT JOIN sys.foreign_key_columns fkc WITH (NOLOCK) ON fkc.parent_object_id = c.[object_id] AND fkc.parent_column_id = c.column_id
	LEFT JOIN sys.foreign_keys fk WITH (NOLOCK) ON fk.[object_id] = fkc.constraint_object_id
	LEFT JOIN sys.index_columns ic WITH (NOLOCK) ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id AND ic.is_included_column = 0
	LEFT JOIN sys.indexes i WITH (NOLOCK) ON i.index_id = ic.index_id AND i.[object_id] = c.[object_id]
	LEFT JOIN sys.dm_db_partition_stats ps WITH (NOLOCK) ON ps.[object_id] = c.[object_id] AND ps.index_id < 2 -- 0:Heap, 1:Clustered
	WHERE 1=1
	AND c.system_type_id = 56 -- int
	--AND c.is_identity = 0
	AND c.name != 'id'
) AS cte
WHERE 1=1
AND (cte.FkName IS NULL OR cte.IxName IS NULL)
AND cte.[RowCount] != 0
AND cte.[RowCount] > 100000
AND cte.TableName NOT LIKE '%audit%'
AND cte.TableName NOT LIKE '%history%'
AND cte.ColumnName LIKE '%id'
ORDER BY cte.TableName ASC, cte.Column_id ASC
