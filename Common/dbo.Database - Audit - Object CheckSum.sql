--=================================================================================================
-- Database CheckSum.
--=================================================================================================
SELECT 
	ObjectName = o.name
	,ObjectType = o.type_desc
	,ColumnOrdinal = sc.colid
	,[CheckSum] = BINARY_CHECKSUM(text)
FROM sys.syscomments sc WITH (NOLOCK)
INNER JOIN sys.objects o WITH (NOLOCK) ON o.object_id = sc.id
WHERE 1=1
AND o.type IN ('C', 'FN', 'P', 'TR', 'P')
ORDER BY o.name ASC, sc.colid ASC
