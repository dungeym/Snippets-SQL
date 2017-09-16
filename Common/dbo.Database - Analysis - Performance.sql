--=================================================================================================
-- Gather performance related information from the current database.
--=================================================================================================

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#Setting') IS NOT NULL BEGIN DROP TABLE #Setting END;
CREATE TABLE #Setting
(
	id					INT IDENTITY(1,1) NOT NULL,
	SettingName			VARCHAR(255) NOT NULL,
	IsSettingOn			BIT DEFAULT(0) NOT NULL
)
GO

INSERT INTO #Setting (SettingName, IsSettingOn)
VALUES 
	('Statistics', 1),
	('Missing Indexes', 1),
	('Expensive Queries by Score', 1),
	('Expensive Queries by CPU', 1),
	('Expensive Queries by I/O', 1),
	('Expensive Queries by CLR', 1),
	('Unused Indexes', 1),
	('Procedures by Score', 1)
GO


-- ================================================================================================
-- Statistics Information
-- ================================================================================================
IF EXISTS (SELECT * FROM #Setting WHERE SettingName = 'Statistics' AND IsSettingOn = 1)
BEGIN
	
	SET ROWCOUNT 0
	
	SELECT 
		[Name] = 'Statistics Information'
		,ParentName = o.[name]
		,StatisticName = st.[name]		
		,[Columns] = 
		(
			SELECT 
				c.name + ',' AS [text()]
            FROM sys.columns c WITH (NOLOCK)
            INNER JOIN sys.stats_columns sc WITH (NOLOCK) ON sc.column_id = c.column_id AND sc.[object_id] = c.[object_id] AND sc.stats_id = st.stats_id
            WHERE 1=1
            AND sc.[object_id] = st.[object_id]
            ORDER BY sc.stats_column_id ASC
            FOR XML PATH ('')
		)
		,LastUpdated = STATS_DATE(st.[object_id], st.stats_id)
		,AgeInHours = DATEDIFF(HOUR, STATS_DATE(st.[object_id], st.stats_id), GETDATE())
		,[TSQL] = 'UPDATE STATISTICS ' + o.[name] + ' ' + st.[name] + ';'
	FROM sys.stats st WITH (NOLOCK)
	INNER JOIN sys.objects o WITH (NOLOCK) ON o.[object_id]= st.[object_id]
	LEFT JOIN sys.tables t WITH (NOLOCK) ON st.[object_id] = t.[object_id]
	WHERE 1=1
	AND t.[type] = 'U'
	AND STATS_DATE(st.[object_id], st.stats_id) IS NOT NULL 
	--AND DATEDIFF(MINUTE, STATS_DATE(st.[object_id], stats_id), GETDATE()) > 600
	--AND st.[object_id] = OBJECT_ID('tblScheduleExecutionLog')
	ORDER BY o.[name] ASC, st.[name] ASC--, sc.stats_column_id ASC
	
END
GO


-- ================================================================================================
-- Missing Indexes
-- ================================================================================================
IF EXISTS (SELECT * FROM #Setting WHERE SettingName = 'Missing Indexes' AND IsSettingOn = 1)
BEGIN

	SET ROWCOUNT 0
	
	DECLARE @ServiceStart DATETIME = '1990-JAN-01'
	IF EXISTS(SELECT * FROM fn_my_permissions (NULL, 'DATABASE')WHERE permission_name = 'VIEW SERVER STATE')
	BEGIN
		SET @ServiceStart = (SELECT TOP 1 sqlserver_start_time FROM sys.dm_os_sys_info)
	END	

	SELECT
		[Name] = 'Missing Indexes'		
		,[ServiceStart] = @ServiceStart
		,[ServiceUpTime] = DATEDIFF(MINUTE, @ServiceStart, GETUTCDATE())
		,[DatabaseName] = d.[name]
		,[TableName] = OBJECT_NAME(mid.[object_id])
		,[Cost] = migs.avg_total_user_cost	-- No specific unit, average cost of the user queries that could be reduced by the index in the group
		,[Benefit] = migs.avg_user_impact	-- Average percentage benefit that user queries could experience if this missing index group was implemented. The value means that the query cost would on average drop by this percentage if this missing index group was implemented
		,[UserSeeks] = migs.user_seeks		-- Number of seeks caused by user queries that the recommended index in the group could have been used for.
		,[UserScans] = migs.user_scans		-- Number of scans caused by user queries that the recommended index in the group could have been used for.
		,[Score] = CONVERT (DECIMAL (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans))
		,[Columns] = COALESCE(mid.equality_columns, mid.inequality_columns)
		,[Include] = mid.included_columns
		,[TSQL] = 'CREATE INDEX idx_' + CONVERT (VARCHAR, mig.index_group_handle) + '_' + CONVERT (VARCHAR, mid.index_handle) + ' ON ' + mid.[statement] + ' (' + ISNULL (mid.equality_columns,'') + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '') + ')' + ISNULL (' INCLUDE (' + mid.included_columns + ')', '')
	FROM sys.dm_db_missing_index_groups mig WITH (NOLOCK) 
	INNER JOIN sys.dm_db_missing_index_group_stats migs WITH (NOLOCK) ON migs.group_handle = mig.index_group_handle
	INNER JOIN sys.dm_db_missing_index_details mid WITH (NOLOCK) ON mig.index_handle = mid.index_handle
	INNER JOIN sys.databases d WITH (NOLOCK) ON d.database_id = mid.database_id
	WHERE 1=1
	AND d.[name] = DB_NAME()
	AND CONVERT (DECIMAL (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10 -- Only include inmdexes that have a reasonable measure of improvement
	ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC

	
END
GO


-- ================================================================================================
-- Collate Index Stats information
-- ================================================================================================
SET ROWCOUNT 0
IF OBJECT_ID('tempdb..#QueryData') IS NOT NULL BEGIN DROP TABLE #QueryData END;

DECLARE @ServiceStart DATETIME = '1990-JAN-01'
IF EXISTS(SELECT * FROM fn_my_permissions (NULL, 'DATABASE')WHERE permission_name = 'VIEW SERVER STATE')
BEGIN
	SET @ServiceStart = (SELECT TOP 1 sqlserver_start_time FROM sys.dm_os_sys_info)
END	

;WITH QueryStats (plan_handle, statement_start_offset, statement_end_offset, creation_time, last_execution_time, execution_count, total_rows, total_worker_time, total_physical_reads, total_logical_reads, total_clr_time)
AS
(
	SELECT
		plan_handle = qs.plan_handle
		,statement_start_offset = qs.statement_start_offset
		,statement_end_offset = qs.statement_end_offset
		,creation_time = MAX(qs.creation_time)
		,last_execution_time = MAX(qs.last_execution_time)			
		,execution_count = SUM(qs.execution_count)
		,total_rows = SUM(qs.total_rows)										-- Rows
		,total_worker_time = SUM(qs.total_worker_time)							-- Time
		,total_physical_reads = SUM(qs.total_physical_reads)					-- I/O
		,total_logical_reads = SUM(qs.total_logical_reads)						-- I/O
		,total_clr_time = SUM(qs.total_clr_time)								-- CLR
	FROM sys.dm_exec_query_stats qs WITH (NOLOCK)
	WHERE 1=1
	GROUP BY qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset
) 
SELECT
	id = ROW_NUMBER() OVER(ORDER BY q.plan_handle)
	,ServiceStart = @ServiceStart
	,ServiceUpTime = DATEDIFF(MINUTE, @ServiceStart, GETUTCDATE())
	,DatabaseName = DB_NAME(st.[dbid])
	,ObjectName = CASE WHEN o.name IS NULL THEN 'Ad hoc' ELSE o.name END
	,CreatedTime = q.creation_time	
	,LastExecuted = q.last_execution_time
	,ExecutionCount = q.execution_count
	,AverageCPU = CONVERT(DECIMAL(11,2), (CONVERT(DECIMAL(28,5), q.total_worker_time) / 1000000) / q.execution_count)
	,AverageIO = CONVERT(DECIMAL(11,0), (q.total_physical_reads + q.total_logical_reads) / q.execution_count)
	,AverageCLR = CONVERT(DECIMAL(11,2), (CONVERT(DECIMAL(28,5), q.total_clr_time) / 1000000) / q.execution_count)
	,AverageRowCount = CONVERT(DECIMAL(11,0), (q.total_rows / q.execution_count))
	,[Score] =	
				CONVERT(DECIMAL(28,2),
				(
					CONVERT(DECIMAL(11,2), (CONVERT(DECIMAL(28,5), q.total_worker_time) / 1000000) / q.execution_count)
					+
					CONVERT(DECIMAL(11,2), (q.total_physical_reads + q.total_logical_reads) / q.execution_count)
					+
					CONVERT(DECIMAL(11,2), (CONVERT(DECIMAL(28,5), q.total_clr_time) / 1000000) / q.execution_count)
				) * q.execution_count)
	,[TSQL] = SUBSTRING(st.[text], (q.statement_start_offset/2) +1,
		CASE 
			WHEN q.statement_end_offset = -1 AND (((LEN(CONVERT(NVARCHAR(MAX), st.[text]))/2) - (q.statement_start_offset/2)) - (((LEN(CONVERT(NVARCHAR(MAX), st.[text]))/2) - (q.statement_start_offset/2)) % 2) <0) THEN LEN(CONVERT(NVARCHAR(MAX), st.[text]))/2
			WHEN q.statement_end_offset = -1 THEN ((LEN(CONVERT(NVARCHAR(MAX), st.[text]))/2) - (q.statement_start_offset/2)) - (((LEN(CONVERT(NVARCHAR(MAX), st.[text]))/2) - (q.statement_start_offset/2)) % 2)
			ELSE ((statement_end_offset/2) - (q.statement_start_offset/2)) - (((statement_end_offset/2) - (q.statement_start_offset/2)) % 2)
			END)
	,FullSQL = st.[text]
INTO #QueryData
FROM QueryStats q
CROSS APPLY sys.dm_exec_sql_text(q.plan_handle) AS st
LEFT OUTER JOIN sys.objects o WITH (NOLOCK) ON st.objectid = o.[object_id]
WHERE 1=1
AND st.[dbid] = DB_ID()
GO


-- ================================================================================================
-- TOP n Most Expensive Queries by Score
-- ================================================================================================
IF EXISTS (SELECT * FROM #Setting WHERE SettingName = 'Expensive Queries by Score' AND IsSettingOn = 1)
BEGIN

	SET ROWCOUNT 50
	
	SELECT 
		[Expensive Queries by Score] = 'Expensive Queries by Score'
		,q.ServiceStart
		,q.ServiceUpTime
		,q.DatabaseName
		,q.ObjectName
		,q.CreatedTime
		,q.LastExecuted
		,q.ExecutionCount
		,q.[Score]
		,q.AverageCPU
		,q.AverageIO
		,q.AverageCLR
		,q.AverageRowCount
		,q.[TSQL]
		,q.FullSQL
	FROM #QueryData q
	WHERE 1=1
	AND q.AverageCPU IS NOT NULL 
	AND q.AverageCPU > 0
	ORDER BY q.[Score] DESC
	
END
GO


-- ================================================================================================
-- TOP n Most Expensive Queries by CPU
-- ================================================================================================
IF EXISTS (SELECT * FROM #Setting WHERE SettingName = 'Expensive Queries by CPU' AND IsSettingOn = 1)
BEGIN

	SET ROWCOUNT 50
	
	SELECT 
		[Expensive Queries by CPU] = 'Expensive Queries by CPU'
		,q.ServiceStart
		,q.ServiceUpTime
		,q.DatabaseName
		,q.ObjectName
		,q.CreatedTime
		,q.LastExecuted
		,q.ExecutionCount
		,q.[Score]
		,q.AverageCPU
		,q.AverageRowCount
		,q.[TSQL]
		,q.FullSQL
	FROM #QueryData q
	WHERE 1=1
	AND q.AverageCPU IS NOT NULL 
	AND q.AverageCPU > 0
	ORDER BY q.AverageCPU DESC
	
END
GO


-- ================================================================================================
-- TOP n Most Expensive Queries by I/O
-- ================================================================================================
IF EXISTS (SELECT * FROM #Setting WHERE SettingName = 'Expensive Queries by I/O' AND IsSettingOn = 1)
BEGIN

	SET ROWCOUNT 50
	
	SELECT 
		[Expensive Queries by I/O] = 'Expensive Queries by I/O'
		,q.ServiceStart
		,q.ServiceUpTime
		,q.DatabaseName
		,q.ObjectName
		,q.CreatedTime
		,q.LastExecuted
		,q.ExecutionCount
		,q.[Score]
		,q.AverageIO
		,q.AverageRowCount
		,q.[TSQL]
		,q.FullSQL
	FROM #QueryData q
	WHERE 1=1
	AND q.AverageIO IS NOT NULL 
	AND q.AverageIO > 0
	ORDER BY q.AverageIO DESC
	
END
GO


-- ================================================================================================
-- TOP n Most Expensive Queries by CLR
-- ================================================================================================
IF EXISTS (SELECT * FROM #Setting WHERE SettingName = 'Expensive Queries by CLR' AND IsSettingOn = 1)
BEGIN

	SET ROWCOUNT 50
	
	SELECT 
		[Expensive Queries by CLR] = 'Expensive Queries by CLR'
		,q.ServiceStart
		,q.ServiceUpTime
		,q.DatabaseName
		,q.ObjectName
		,q.CreatedTime
		,q.LastExecuted
		,q.ExecutionCount
		,q.[Score]
		,q.AverageCLR
		,q.AverageRowCount
		,q.[TSQL]
		,q.FullSQL
	FROM #QueryData q
	WHERE 1=1
	AND q.AverageCLR IS NOT NULL 
	AND q.AverageCLR > 0
	ORDER BY q.AverageCLR DESC
	
END
GO


-- ================================================================================================
-- Unused Indexes
-- ================================================================================================
IF EXISTS (SELECT * FROM #Setting WHERE SettingName = 'Unused Indexes' AND IsSettingOn = 1)
BEGIN
/*
The user_updates counter indicates the level of maintenance on the index caused by insert, update, 
or delete operations on the underlying table or view. You can use this view to determine which 
indexes are used only lightly by your applications. You can also use the view to determine which 
indexes are incurring maintenance overhead. You may want to consider dropping indexes that incur 
maintenance overhead, but are not used for queries, or are only infrequently used for queries.

The counters are initialized to empty whenever the SQL Server (MSSQLSERVER) service is started. 
In addition, whenever a database is detached or is shut down (for example, because AUTO_CLOSE is set to ON), 
all rows associated with the database are removed.
*/

	SET ROWCOUNT 0
	
	DECLARE @ServiceStart DATETIME = (SELECT TOP 1 sqlserver_start_time FROM sys.dm_os_sys_info)
	
	SELECT 
		[Name] = 'Unused Indexes'
		,[ServiceStart] = @ServiceStart
		,[ServiceUpTime] = DATEDIFF(MINUTE, @ServiceStart, GETUTCDATE())
		,[SchemaName] = SCHEMA_NAME(o.[schema_id])
		,[DatabaseName] = d.name
		,[TableName] = OBJECT_NAME(s.[object_id])	
		,[IndexName] = i.name
		,[IsPrimaryIndex] = i.is_primary_key						-- Is this part of the Primary Key
		,[IsUniqueIndex] = i.is_unique_constraint					-- Is this part of a Unique Constraint
		,[IndexUpdateCount] = s.user_updates						-- The number of updates to this Index
		,[IndexSizeMB] = ((st.used_page_count * 8) / 1024)
	FROM sys.dm_db_index_usage_stats s 
	INNER JOIN sys.objects o  WITH (NOLOCK) ON s.[object_id] = o.[object_id] 
	INNER JOIN sys.indexes i WITH (NOLOCK) ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id 
	INNER JOIN sys.dm_db_partition_stats st WITH (NOLOCK) ON st.[object_id] = i.[object_id] AND st.index_id = i.index_id
	INNER JOIN sys.databases d WITH (NOLOCK) ON d.database_id = s.database_id
	WHERE 1=1
	AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 
	AND s.user_seeks = 0
	AND s.user_scans = 0 
	AND s.user_lookups = 0
	AND i.name IS NOT NULL -- Ignore HEAP indexes.
	AND d.name = DB_NAME()
	ORDER BY OBJECT_NAME(s.[object_id]) ASC, i.name ASC, (s.user_seeks + s.user_scans + s.user_lookups) DESC
	
END
GO


-- ================================================================================================
-- Procedures by Score
-- ================================================================================================
IF EXISTS (SELECT * FROM #Setting WHERE SettingName = 'Procedures by Score' AND IsSettingOn = 1)
BEGIN

	SET ROWCOUNT 0
	
	DECLARE @ServiceStart DATETIME = '1990-JAN-01'
	IF EXISTS(SELECT * FROM fn_my_permissions (NULL, 'DATABASE') WHERE permission_name = 'VIEW SERVER STATE')
	BEGIN
		SET @ServiceStart = (SELECT TOP 1 sqlserver_start_time FROM sys.dm_os_sys_info)
	END	
	
	SELECT
		[Name] = 'Procedures by Score'
		,ProcedureName = p.name
		,LastExecuted = ps.last_execution_time
		,[ServiceStart] = @ServiceStart

		,MinDuration = ps.min_elapsed_time
		,AvgDuration = ps.total_elapsed_time / ps.execution_count
		,MaxDuration = ps.max_elapsed_time
		,ExecutionCount = ps.execution_count
		
		,AvgLogicalReads = ps.total_logical_reads / ps.execution_count
		,AvgLogicalWrites = ps.total_logical_writes / ps.execution_count
		
		,AvgPhysicalReads = ps.total_physical_reads / ps.execution_count
		
		-- AvgDuration * ExecutionCount * AvgLogicalReads * (AvgLogicalWrites * 3) * (AvgPhysicalReads * 2)
		,[Score] =	(
						((CONVERT (DECIMAL (28,1), ps.total_elapsed_time) / 1000000) / ps.execution_count) * 
						CONVERT (DECIMAL (28,1), ps.execution_count) * 
						(CASE WHEN ps.total_logical_reads = 0 THEN 1 ELSE (CONVERT (DECIMAL (28,1), ps.total_logical_reads) / ps.execution_count) END) *
						(CASE WHEN ps.total_logical_writes = 0 THEN 1 ELSE (CONVERT (DECIMAL (28,1), ps.total_logical_writes) / ps.execution_count) END) *
						(CASE WHEN ps.total_physical_reads = 0 THEN 1 ELSE (CONVERT (DECIMAL (28,1), ps.total_physical_reads) / ps.execution_count) END)
					)
	FROM sys.procedures p WITH (NOLOCK)
	LEFT JOIN sys.dm_exec_procedure_stats ps WITH (NOLOCK) ON ps.[object_id] = p.[object_id]
	WHERE 1=1
	AND p.is_ms_shipped = 0
	AND (p.name LIKE 'sp%' OR p.name LIKE 'usp%')
	ORDER BY 10 DESC, p.name ASC
	
END
GO
