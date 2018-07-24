
--=================================================================================================
-- Output a checksum on the text (content) of the following:
-- C = CHECK constraint
-- FN = SQL scalar function
-- P = SQL Stored Procedure
-- TR = SQL Trigger
--=================================================================================================

SELECT 
	ObjectName = o.name
	,ObjectType = o.type_desc
	,ColumnOrdinal = sc.colid
	,[CheckSum] = BINARY_CHECKSUM(sc.[text])
FROM sys.syscomments sc 
INNER JOIN sys.objects o ON o.[object_id] = sc.id
WHERE 1=1
AND o.[type] IN ('C', 'FN', 'P', 'TR')
ORDER BY o.name ASC, sc.colid ASC

