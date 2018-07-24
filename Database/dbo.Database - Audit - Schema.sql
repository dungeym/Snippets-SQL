
--=================================================================================================
-- Output basic schema details.
--=================================================================================================

SELECT
	SchemaName = s.name
	,ObjectName = o.name
	,ObjectType = o.type_desc
	,ColumnName = c.name
	,[Type] = UPPER(t.name)
	,Ordinal = c.column_id
	,[Length] = c.max_length
	,[Precision] = c.[precision]
	,Scale = c.scale
	,IsIdentity = c.is_identity
	,IsNullable = c.is_nullable	
	,IsComputed = c.is_computed
	,Collation = c.collation_name
	,DefaultDefinition = dc.[definition]
	,Relationship = referencedObjects.ReferencedName
FROM sys.columns c 
INNER JOIN sys.objects o ON o.[object_id] = c.[object_id]
INNER JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
INNER JOIN sys.types t ON t.system_type_id = c.system_type_id AND t.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc ON dc.[object_id] = c.default_object_id AND dc.parent_object_id = o.[object_id] AND dc.parent_column_id = c.column_id
LEFT JOIN sys.foreign_key_columns fkc ON fkc.parent_object_id = o.[object_id] AND fkc.parent_column_id = c.column_id
LEFT JOIN 
(
	SELECT 
		o.[object_id]
		, c.column_id
		, ReferencedName = o.name + '.' + c.name
	FROM sys.columns c 
	INNER JOIN sys.objects o ON o.[object_id] = c.[object_id]
) AS referencedObjects ON referencedObjects.[object_id] = fkc.referenced_object_id AND referencedObjects.column_id = fkc.referenced_column_id
WHERE 1=1
AND o.is_ms_shipped = 0
ORDER BY o.name ASC, c.column_id ASC
