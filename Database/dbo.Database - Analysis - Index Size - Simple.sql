
-- ================================================================================================
-- Output basic information about the size of the indexes.
-- ================================================================================================

SELECT
	TableName = o.name
	,src.IndexName 
	,src.[IndexSize (Mb)]
FROM sys.objects o 
INNER JOIN 
(
	SELECT 
		i.[object_id]
		,IndexName = i.[name]
		,[IndexSize (Mb)] = (SUM(s.[used_page_count]) * 8) / 1024.0
	FROM sys.dm_db_partition_stats AS s
	INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id] AND s.[index_id] = i.[index_id]
	WHERE 1=1
	GROUP BY i.[name], i.[object_id]
) AS src ON src.[object_id] = o.[object_id]
WHERE 1=1
AND o.is_ms_shipped = 0
--AND o.name = 'OnlyThisTable'
ORDER BY 1 ASC, 3 ASC
GO