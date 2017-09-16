
SELECT 
	IndexName = i.[name]
	,ColumnName = cte.name
FROM sys.indexes i WITH (NOLOCK)
LEFT JOIN 
(	
	SELECT i.object_id, c.name, c.column_id
	FROM sys.columns c WITH (NOLOCK)
	LEFT JOIN sys.index_columns ic WITH (NOLOCK) ON ic.object_id = c.object_id AND ic.column_id = c.column_id
	LEFT JOIN sys.indexes i WITH (NOLOCK) ON i.object_id = ic.object_id AND ic.is_included_column = 0
	WHERE 1=1
	AND c.[name] = 'DeletedDate'
	AND i.is_unique_constraint = 1
) AS cte ON cte.object_id = i.object_id
WHERE 1=1
AND i.is_unique_constraint = 1
ORDER BY i.[name] ASC
GO
