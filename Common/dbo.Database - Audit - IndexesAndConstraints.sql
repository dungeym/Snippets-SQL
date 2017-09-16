--=================================================================================================
-- Database Indexes and Constraints.
--=================================================================================================
SELECT
	SchemaName = s.name
	,ObjectName = o.name
	,ObjectType = o.type_desc 
	,IndexName = i.name
	,IsPrimary = i.is_primary_key
	,IsUnique = i.is_unique
	,IsUniqueConstraint = i.is_unique_constraint
	,ColumnName = c.name
	,IsIncluded = ic.is_included_column
FROM sys.index_columns ic WITH (NOLOCK)
INNER JOIN sys.indexes i WITH (NOLOCK) ON i.[object_id] = ic.[object_id] AND i.index_id = ic.index_id
INNER JOIN sys.objects o WITH (NOLOCK) ON o.[object_id] = i.[object_id]
INNER JOIN sys.schemas s WITH (NOLOCK) ON s.[schema_id] = o.[schema_id]
INNER JOIN sys.columns c WITH (NOLOCK) ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
WHERE 1=1
AND i.name IS NOT NULL 
AND o.is_ms_shipped = 0
ORDER BY o.name ASC, i.index_id ASC, ic.index_column_id ASC

