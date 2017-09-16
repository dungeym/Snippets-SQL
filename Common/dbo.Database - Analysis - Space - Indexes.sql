--=================================================================================================
-- Database Space - Indexes.
--=================================================================================================
SET ROWCOUNT 0
SET NOCOUNT ON

DECLARE @ServiceStart DATETIME = (SELECT TOP 1 sqlserver_start_time FROM sys.dm_os_sys_info)

SELECT * 
FROM 
(
	SELECT 
		ParentName = OBJECT_NAME(i.object_id)
		,IndexName = i.[name]
		,[Type] = i.type_desc
		,[RowCount] = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, SUM(p.[rows])), 1), '.00', '')
		,[PageCount] = SUM(a.total_pages)
		,PagesUsed = SUM(a.used_pages)
		,[FillFactor] = AVG(i.fill_factor)
		,TotalMB = CONVERT(DECIMAL(11, 2), (CONVERT(DECIMAL(11, 2), (SUM(a.total_pages) * 8)) / CONVERT(DECIMAL(11, 2), 1024)))
		,UsedMB = CONVERT(DECIMAL(11, 2), (CONVERT(DECIMAL(11, 2), (SUM(a.used_pages) * 8)) / CONVERT(DECIMAL(11, 2), 1024)))
		,FreeMB = CONVERT(DECIMAL(11, 2), (CONVERT(DECIMAL(11, 2), (SUM(a.total_pages) * 8)) / CONVERT(DECIMAL(11, 2), 1024))) - CONVERT(DECIMAL(11, 2), (CONVERT(DECIMAL(11, 2), (SUM(a.used_pages) * 8)) / CONVERT(DECIMAL(11, 2), 1024)))
		,UserSeeks = SUM(CASE WHEN ius.user_seeks IS NULL THEN 0 ELSE ius.user_seeks END)
		,UserScans = SUM(CASE WHEN ius.user_scans IS NULL THEN 0 ELSE ius.user_scans END)
		,UserLookups = SUM(CASE WHEN ius.user_lookups IS NULL THEN 0 ELSE ius.user_lookups END)
		,[ServiceUpTime] = DATEDIFF(MINUTE, @ServiceStart, GETUTCDATE())
		,[ServiceStart] = @ServiceStart		
	FROM sys.indexes i WITH (NOLOCK)
	LEFT JOIN sys.tables t WITH (NOLOCK) ON t.[object_id] = i.[object_id]
	LEFT JOIN sys.partitions p WITH (NOLOCK) ON i.[object_id] = p.[object_id] AND i.index_id = p.index_id
	LEFT JOIN sys.allocation_units a WITH (NOLOCK) ON p.partition_id = a.container_id
	LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON ius.database_id = DB_ID() AND i.[object_id] = ius.[object_id] AND i.index_id = ius.index_id
	INNER JOIN sys.objects o WITH (NOLOCK) ON o.[object_id] = i.[object_id]
	WHERE 1=1
	AND (o.is_ms_shipped IS NULL OR o.is_ms_shipped = 0)
	AND o.type_desc NOT IN ('SQL_TABLE_VALUED_FUNCTION')
	GROUP BY t.[name], i.[object_id], i.index_id, i.[name], i.type_desc
) cte
WHERE 1=1
AND (cte.UserSeeks = 0 AND cte.UserScans = 0 AND cte.UserLookups = 0)
ORDER BY cte.ParentName ASC, CASE WHEN cte.[Type] = 'HEAP' THEN 0 WHEN cte.[Type] = 'CLUSTERED' THEN 1 ELSE 2 END ASC, cte.IndexName ASC
GO