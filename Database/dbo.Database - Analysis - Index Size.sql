
-- ================================================================================================
-- Output detailed information about the indexes.
-- ================================================================================================

SET ROWCOUNT 0

SELECT 
	src.DatabaseName
	,src.ObjectId
	,src.ObjectName
	,src.IndexId
	,src.IndexDescription
	,[IndexSize(MB)] = CONVERT(DECIMAL(16, 1), (SUM(src.AvgRecondSizeInBytes * src.RecordCount) / (1024.0 * 1024)))
	,src.LastUpdated
	,src.AvgFragmentationInPercent
FROM 
(
	SELECT DISTINCT 
		DatabaseName = DB_NAME(stat.Database_id)
		,ObjectId = stat.[object_id]
		,ObjectName = OBJECT_NAME(stat.[object_id])
		,IndexId = stat.index_id
		,IndexDescription = stat.index_type_desc
		,AvgRecondSizeInBytes = stat.avg_record_size_in_bytes
		,RecordCount = stat.record_count
		,LastUpdated = STATS_DATE(stat.[object_id], stat.index_id)
		,AvgFragmentationInPercent = CONVERT(VARCHAR(512), ROUND(stat.avg_fragmentation_in_percent, 3))
	FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'Detailed') stat
	WHERE 1=1
	AND stat.[object_id] IS NOT NULL
	AND stat.avg_fragmentation_in_percent != 0
	--AND OBJECT_NAME(stat.[object_id]) = 'OnlyThisTable'
) AS src
GROUP BY DatabaseName, ObjectId, ObjectName, IndexId, IndexDescription, LastUpdated, AvgFragmentationInPercent
ORDER BY DatabaseName ASC, ObjectName ASC, IndexId ASC
GO
