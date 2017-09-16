SELECT
	[SessionID] = es.session_id
	,[Status] = es.[status]
	,[LoginName] = es.login_name
	,[HostName] = es.[HOST_NAME]
	,[BlockingSessionID] = er.blocking_session_id
	,[DatabaseName] = DB_NAME(er.database_id)
	,[Command] = er.command
	,[CPUTime] = es.cpu_time
	,[ReadCount] = es.[reads]
	,[WriteCount] = es.writes
	,[LastWrite] = ec.last_write
	,[ProgramName] = es.[program_name]
	,[RequestedMemoryKB] = emg.requested_memory_kb
	,[GrantedMemoryKB] = emg.granted_memory_kb
	,[UsedMemoryKB] = emg.used_memory_kb
	,[WaitType] = er.wait_type
	,[WaitTime] = er.wait_time
	,[LastWaitType] = er.last_wait_type
	,[WaitResource] = er.wait_resource
	,[TransactionIsolation] = CASE es.transaction_isolation_level
		WHEN 0 THEN 'Unspecified'
		WHEN 1 THEN 'ReadUncommitted'
		WHEN 2 THEN 'ReadCommitted'
		WHEN 3 THEN 'Repeatable'
		WHEN 4 THEN 'Serializable'
		WHEN 5 THEN 'Snapshot'
		END
	,[ObjectName] = OBJECT_NAME(est.objectid, er.database_id)
	,[TSQL] = SUBSTRING(est.[text], er.statement_start_offset / 2, (CASE WHEN er.statement_end_offset = -1 THEN DATALENGTH(est.[text]) ELSE er.statement_end_offset END - er.statement_start_offset ) / 2)
	,[FullSQL] = est.text
	,[Query Plan] = eqp.query_plan
FROM sys.dm_exec_sessions es WITH (NOLOCK)
LEFT JOIN sys.dm_exec_requests er WITH (NOLOCK) ON es.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections ec WITH (NOLOCK) ON es.session_id = ec.session_id
LEFT JOIN sys.dm_exec_query_memory_grants emg WITH (NOLOCK) ON es.session_id = emg.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) est
CROSS APPLY sys.dm_exec_query_plan(er.plan_handle) eqp
WHERE 1=1
AND es.session_id <> @@SPID -- Exclude this SPID
ORDER BY DB_NAME(er.database_id) ASC, es.login_name ASC
GO