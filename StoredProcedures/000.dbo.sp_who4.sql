USE [master]
GO

DECLARE @DatabaseName NVARCHAR(255) = 'CashManager_EU'

-- EXEC sp_who2
-- SELECT * FROM sys.dm_exec_connections
-- SELECT * FROM sys.dm_exec_sessions
-- SELECT * FROM sys.dm_exec_requests
-- SELECT * FROM sys.sysprocesses
-- SELECT * FROM sys.dm_os_waiting_tasks
-- SELECT * FROM sys.dm_exec_sql_text

DECLARE @Data TABLE
(
	[Level]							NVARCHAR(20) NOT NULL,
	SessionId						INT NOT NULL,
	ConnectionCount					INT NOT NULL,
	ServerName						NVARCHAR(255) NOT NULL,
	LoginName						NVARCHAR(255) NULL,
	DatabaseName					NVARCHAR(255) NULL,
	HostName						NVARCHAR(255) NULL,
	ClientAddress					NVARCHAR(255) NULL,
	ClientPort						INT NULL,
	ClientName						NVARCHAR(255) NULL,
	ClientProcessId					INT NULL,
	ClientAuthenticationScheme		NVARCHAR(40) NOT NULL,
	ClientInterface					NVARCHAR(255) NULL,
	ClientUserName					NVARCHAR(255) NULL,
	ClientUser						NVARCHAR(255) NULL,
	ClientEmail						NVARCHAR(255) NULL,
	ConnectedDate					DATETIME NOT NULL,
	ConnectedMinutes				INT NOT NULL,
	[Status]						NVARCHAR(255) NOT NULL,	
	CPUTime							INT NOT NULL,
	MemoryUsage						INT NOT NULL,
	LastRequestStartedDate			DATETIME NOT NULL,
	LastRequestEndedDate			DATETIME NULL,
	MinutesSinceLastRequest			INT,
	RequestLengthSeconds			INT NOT NULL,
	[Reads]							BIGINT NOT NULL,
	[Writes]						BIGINT NOT NULL,
	LogicalReads					BIGINT NOT NULL,
	TransactionIsolationLevel		NVARCHAR(50) NOT NULL,
	LockTimeout						INT NOT NULL,
	DeadlockPriority				INT NOT NULL,
	CommandType						NVARCHAR(255) NULL,
	BlockingSessionId				INT NULL,
	OpenTransactionCount			INT NULL,
	[TSQL]							NVARCHAR(MAX) NULL,
	QueryPlan						NVARCHAR(MAX) NULL
)


INSERT INTO @Data
SELECT
	[Level] = CASE
		WHEN es.[host_name] IS NULL THEN 'Information'
		WHEN LEFT(es.[host_name], 5) = 'LONWS' THEN 'Information'
		WHEN LEFT(es.[host_name], 5) = 'LONWV' THEN 'Information'
		WHEN LEFT(es.[host_name], 5) = 'LONLX' THEN 'Information'
		WHEN LEFT(es.[host_name], 5) = 'LONUX' THEN 'Information'
		WHEN LEFT(es.[host_name], 5) = 'nCore' THEN 'Information'
		WHEN ec.auth_scheme = 'SQL' THEN 'Security'
		WHEN es.[status] = 'RUNNING' AND DATEDIFF(mi, es.last_request_start_time, GETUTCDATE()) > 5 THEN 'Alert'
		WHEN DATEDIFF(mi, es.login_time, GETUTCDATE()) > 5 THEN 'Warning'
		ELSE 'Information' END
	
	-- Session / Connection Information
	,SessionId = es.session_id
	,ConnectionCount = (SELECT COUNT(1) FROM sys.dm_exec_connections WITH (NOLOCK) WHERE sys.dm_exec_connections.session_id = es.session_id)
	,ServerName = UPPER(@@SERVICENAME)
	,LoginName = es.login_name
	,DatabaseName = DB_NAME(COALESCE(st.[dbid], p.[dbid]))
	,HostName = UPPER(es.[host_name])
	,ClientAddress = ec.client_net_address
	,ClientPort = ec.client_tcp_port
	,ClientName = UPPER(es.[host_name])
	,ClientProcessId = es.host_process_id
	,ClientAuthenticationScheme = ec.auth_scheme
	,ClientUserName = NULL
	,ClientUser = NULL
	,ClientEmail = NULL
	,ClientInterface = es.client_interface_name
	,ConnectedDate = es.login_time
	,ConnectedMinutes = DATEDIFF(mi, es.login_time, GETUTCDATE())
	,[Status] = UPPER(es.[status])
	,CPUTime = es.cpu_time
	,MemoryUsage = es.memory_usage
	,LastRequestStartedDate = es.last_request_start_time
	,LastRequestEndedDate = es.last_request_end_time	
	,MinutesSinceLastRequest = DATEDIFF(mi, es.last_request_start_time, GETUTCDATE())
	,RequestLengthSeconds = CASE
		WHEN es.[status] = 'RUNNING' THEN DATEDIFF(s, es.last_request_start_time, GETUTCDATE())
		ELSE DATEDIFF(s, es.last_request_start_time, COALESCE(es.last_request_end_time, GETUTCDATE())) END
	,Reads = es.reads
	,Writes = es.writes
	,LogicalReads = es.logical_reads
	,TransactionIsolationLevel = CASE
		WHEN es.transaction_isolation_level = 0 THEN 'Unspecified'
		WHEN es.transaction_isolation_level = 1 THEN 'ReadUncomitted'
		WHEN es.transaction_isolation_level = 2 THEN 'ReadCommitted'
		WHEN es.transaction_isolation_level = 3 THEN 'Repeatable'
		WHEN es.transaction_isolation_level = 4 THEN 'Serializable'
		WHEN es.transaction_isolation_level = 5 THEN 'Snapshot'
		ELSE 'Unknown' END
	,LockTimeout = es.[lock_timeout]
	,DeadlockPriority = es.[deadlock_priority]

	-- Instance Information (maybe null)
	,CommandType = er.command
	,BlockingSessionId = er.blocking_session_id
	,OpenTransactionCount = er.open_transaction_count
	,[TSQL] = st.[text]
	,QueryPlan = CONVERT(NVARCHAR(MAX),qp.query_plan)
FROM sys.dm_exec_sessions es WITH (NOLOCK)
LEFT JOIN sys.sysprocesses p WITH (NOLOCK) ON p.spid = es.session_id
LEFT JOIN sys.dm_exec_connections ec WITH (NOLOCK) ON ec.session_id = es.session_id
LEFT JOIN sys.dm_exec_requests er WITH (NOLOCK) ON er.session_id = es.session_id AND ec.connection_id = er.connection_id
LEFT JOIN sys.databases d WITH (NOLOCK) ON d.database_id = er.database_id
OUTER APPLY sys.dm_exec_sql_text (er.[sql_handle]) AS st
OUTER APPLY sys.dm_exec_query_plan(er.plan_handle) AS qp
WHERE 1=1
AND es.host_name IS NOT NULL -- NULL indicates internal sessions
AND es.is_user_process = 1
AND es.session_id != @@SPID
ORDER BY es.[status] ASC, CASE WHEN UPPER(es.[host_name]) = HOST_NAME() THEN 0 ELSE 1 END ASC, es.login_name ASC, es.session_id ASC


SELECT
	[Level],
	SessionId,
	[Status],
	ConnectionCount,
	BlockingSessionId,
	OpenTransactionCount,
	ServerName,
	LoginName,
	DatabaseName,
	HostName,
	ClientAddress,
	ClientPort,
	ClientName,
	ClientProcessId,
	ClientAuthenticationScheme,
	ClientInterface,
	ClientUserName,
	ClientUser,
	ClientEmail,
	ConnectedDate,
	ConnectedMinutes,	
	CPUTime,
	MemoryUsage,
	LastRequestStartedDate,
	LastRequestEndedDate,
	MinutesSinceLastRequest,
	RequestLengthSeconds,
	Reads,
	Writes,
	LogicalReads,
	TransactionIsolationLevel,
	LockTimeout,
	DeadlockPriority,
	CommandType,
	[TSQL],
	CAST(REPLACE(QueryPlan, 'encoding="utf-8"', 'encoding="utf-16"') AS XML) As QueryPlan 
FROM @Data d
WHERE 1=1
--AND d.[Level] != 'Information'
--AND (d.ClientName NOT LIKE 'LONWS%' AND ClientName NOT LIKE 'LONWV%' AND ClientName NOT LIKE 'LONLX%' AND ClientName NOT LIKE 'LONUX%' AND ClientName NOT LIKE 'nCore%')
--AND d.LoginName LIKE DatabaseName + '%'
--AND d.ClientAuthenticationScheme = 'SQL'
AND (@DatabaseName IS NULL OR d.DatabaseName = @DatabaseName)
--AND d.HostName != 'LONWD013191'
GO

