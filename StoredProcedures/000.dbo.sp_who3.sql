
SET NOCOUNT ON 

DECLARE @Login			NVARCHAR(255)
DECLARE @IgnoreLogin	NVARCHAR(255)
DECLARE @DbName			NVARCHAR(255)

SET @Login = 'CoreLog_user'
SET @IgnoreLogin = 'EUROPE\dungeym'
SET @DbName = 'CoreLog'


IF OBJECT_ID('tempdb..#Who') IS NOT NULL
BEGIN
	DROP TABLE #Who
END

CREATE TABLE #Who 
(
	SPID			NVARCHAR(255), 
	[Status]		NVARCHAR(255), 
	[Login]			NVARCHAR(255), 
	HostName		NVARCHAR(255), 
	BlkBy			NVARCHAR(255), 
	DBName			NVARCHAR(255), 
	Command			NVARCHAR(255), 
	CPUTime			NVARCHAR(255), 
	DiskIO			NVARCHAR(255), 
	LastBatch		NVARCHAR(255), 
	ProgramName		NVARCHAR(255), 
	SPID_2			NVARCHAR(255), 
	REQUESTID		NVARCHAR(255)
) 

INSERT INTO #Who(SPID, [Status], [Login], HostName, BlkBy, DBName, Command, CPUTime, DiskIO, LastBatch, ProgramName, SPID_2, REQUESTID) EXEC sp_who2

SELECT w.* 
FROM #Who w
WHERE 1=1 
AND (@IgnoreLogin IS NULL OR w.[Login] != @IgnoreLogin)
AND (@Login IS NOT NULL AND w.[Login] = @Login)
AND (@DbName IS NULL OR w.DBName != @DbName)

SELECT 
	s.session_id
	,s.login_time
	,s.login_name
	,s.host_name
	,s.program_name
	,s.last_request_end_time
	,r.start_time
	,r.command
	,r.open_transaction_count
	,statement_text = SUBSTRING(st.text, (r.statement_start_offset/2)+1, ((CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(st.text) ELSE r.statement_end_offset END - r.statement_start_offset)/2) + 1)
	,command_text = COALESCE(QUOTENAME(DB_NAME(st.dbid)) + N'.' + QUOTENAME(OBJECT_SCHEMA_NAME(st.objectid, st.dbid)) + N'.' + QUOTENAME(OBJECT_NAME(st.objectid, st.dbid)), '<Adhoc Batch>')
FROM sys.dm_exec_sessions AS s
JOIN sys.dm_exec_requests AS r
ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE 1=1
AND (@IgnoreLogin IS NULL OR s.login_name != @IgnoreLogin)
ORDER BY s.last_request_end_time;