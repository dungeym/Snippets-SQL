
--=================================================================================================
-- Output the server roperties.
-- https://msdn.microsoft.com/en-us/library/bb510680.aspx
--=================================================================================================
	
SELECT 
	[InstanceName] = SERVERPROPERTY('InstanceName')
	, [Database] = name
	, [DatabaseCollation] = collation_name
	, [Compatibility] = CONVERT(NVARCHAR(25), [compatibility_level]) + ' = ' + CASE
		WHEN [compatibility_level] = 80 THEN 'SQL Server 2000'
		WHEN [compatibility_level] = 90 THEN 'SQL Server 2005'
		WHEN [compatibility_level] = 100 THEN 'SQL Server 2008 (and R2)'
		WHEN [compatibility_level] = 110 THEN 'SQL Server 2012'
		WHEN [compatibility_level] = 120 THEN 'SQL Server 2014'
		WHEN [compatibility_level] = 130 THEN 'SQL Server 2016'
		ELSE 'Unknown' 
		END
	, [State] = state_desc
	, [RecoveryModel] = recovery_model_desc 
	, [Version] = SERVERPROPERTY('productversion')
	, [ProductLevel] = SERVERPROPERTY('productlevel')
	, [Edition] = SERVERPROPERTY('edition')
	, [Server Collation] = SERVERPROPERTY('Collation')
	, [Version] = @@VERSION
FROM sys.databases
WHERE 1=1
AND name = DB_NAME()