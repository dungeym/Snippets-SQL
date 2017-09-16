=========================================================================================
SQL Prompt
=========================================================================================
findcolumn: SELECT OBJECT_NAME(object_id) AS ParentName, * FROM sys.columns WHERE [name] LIKE '%$CURSOR$%' ORDER BY OBJECT_NAME(object_id) ASC, [name] ASC
findtext: SELECT OBJECT_NAME(id), * FROM syscomments WHERE [text] LIKE '%$CURSOR$%' ORDER BY OBJECT_NAME(id) ASC
today: DATEADD(DAY, DATEDIFF(DAY,0,GETDATE()), 0)
me: 'dungeym'
mm: 'LONWD030856'
utc: GETUTCDATE()
sti: SELECT TOP 1 * FROM $CURSOR$ WITH (NOLOCK) 
stx: SELECT TOP 10 * FROM $CURSOR$ WITH (NOLOCK)  
stc: SELECT TOP 100 * FROM $CURSOR$ WITH (NOLOCK) 
sbi: SELECT TOP 1 * FROM $CURSOR$ WITH (NOLOCK) ORDER BY 1 DESC
sbx: SELECT TOP 10 * FROM $CURSOR$ WITH (NOLOCK) ORDER BY 1 DESC
sbc: SELECT TOP 100 * FROM $CURSOR$ WITH (NOLOCK) ORDER BY 1 DESC
lk: LIKE '%$CURSOR$%'
wn: WITH (NOLOCK)
isn: IS NULL
isnn: IS NOT NULL
dt#: IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;
toxml: CAST(REPLACE($CURSOR$, 'encoding="utf-8"', 'encoding="utf-16"') AS XML) As MyXml,
for: EXEC sp_msforeachtable 'SELECT TOP 1 * FROM ?'
dataToXml: MyData = CONVERT(XML,'<xml><![CDATA[' + CAST($CURSOR$ AS VARCHAR(MAX)) + ']]></xml>')
info: SELECT @@SERVICENAME AS [Server], DB_NAME() AS [Database], CURRENT_USER AS [User], GETUTCDATE() AS [Timestamp]

=========================================================================================
SQL Management Studio
=========================================================================================
CTRL+F1: SELECT [Name] = df.name, [State] = df.state_desc,  [File Size (MB)] = ( ( df.size * 8 ) / 1024.00 ),  [Space Used (MB)] = CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0, [Free Space (MB)] = ( ( df.size * 8 ) / 1024.00 ) - CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0, [Used (%)] = ( CONVERT(DECIMAL(25, 4), ( CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0 ) / ( ( df.size * 8 ) / 1024.00 )) ) * 100, [Max Size (MB)] = CASE WHEN df.max_size = 0 THEN 'Fixed' WHEN df.max_size = -1 THEN 'Unlimited' ELSE CONVERT(NVARCHAR(25), ( ( df.max_size * 8.00 ) / 1024.00 )) END, [Auto Grow] = CASE WHEN df.growth = 0 THEN 'None' WHEN df.is_percent_growth = 1 THEN CONVERT(NVARCHAR(25), df.growth) + ' %' WHEN df.is_percent_growth = 0 THEN CONVERT(NVARCHAR(25), CONVERT(INT, ( ( df.growth * 8 ) / 1024.00 ))) + ' MB' ELSE NULL END, [Log State] = d.log_reuse_wait_desc, [Recovery Model] = d.recovery_model_desc, [Path] = df.physical_name FROM sys.database_files df WITH ( NOLOCK ) LEFT JOIN sys.databases d WITH ( NOLOCK ) ON d.name COLLATE Latin1_General_CI_AS = df.name COLLATE Latin1_General_CI_AS; SELECT [InstanceName] = SERVERPROPERTY('InstanceName'), [Database] = name, [DatabaseCollation] = collation_name, [Compatibility] = CONVERT(NVARCHAR(25), [compatibility_level]) + ' = ' + CASE WHEN [compatibility_level] = 80 THEN 'SQL Server 2000' WHEN [compatibility_level] = 90 THEN 'SQL Server 2005' WHEN [compatibility_level] = 100 THEN 'SQL Server 2008 (and R2)' WHEN [compatibility_level] = 110 THEN 'SQL Server 2012' WHEN [compatibility_level] = 120 THEN 'SQL Server 2014' WHEN [compatibility_level] = 130 THEN 'SQL Server 2016' ELSE 'Unknown'  END, [State] = state_desc, [RecoveryModel] = recovery_model_desc , [Version] = SERVERPROPERTY('productversion'), [ProductLevel] = SERVERPROPERTY('productlevel'), [Edition] = SERVERPROPERTY('edition'), [Server Collation] = SERVERPROPERTY('Collation'), [Version] = @@VERSION FROM sys.databases WHERE 1=1 AND name = DB_NAME();

3: IF OBJECT_ID('tempdb..#Tables') IS NOT NULL BEGIN DROP TABLE #Tables END;IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL BEGIN DROP TABLE #SpaceUsed END;SET NOCOUNT ON DECLARE @TSQL VARCHAR(255) CREATE TABLE #Tables ( name VARCHAR(255) ) SELECT @TSQL = 'INSERT #Tables SELECT TABLE_NAME FROM ' + DB_NAME() + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = ''BASE TABLE''' EXEC (@TSQL) CREATE TABLE #SpaceUsed ( Name VARCHAR(255) , [Rows] VARCHAR(11) , Reserved VARCHAR(18) , Data VARCHAR(18) , Index_Size VARCHAR(18) , Unused VARCHAR(18) ) DECLARE @Name VARCHAR(255) SELECT @Name = '' WHILE EXISTS ( SELECT * FROM #Tables WHERE Name > @Name ) BEGIN SELECT @Name = MIN(name) FROM #Tables WHERE name > @Name SELECT @TSQL = 'EXEC ' + DB_NAME() + '..sp_executesql N''INSERT #SpaceUsed EXEC sp_spaceused ' + @Name + '''' EXEC (@TSQL) END UPDATE #SpaceUsed SET Reserved = REPLACE(Reserved, 'KB', '') UPDATE #SpaceUsed SET Data = REPLACE(Data, 'KB', '') UPDATE #SpaceUsed SET Index_Size = REPLACE(Index_Size, 'KB', '') UPDATE #SpaceUsed SET Unused = REPLACE(Unused, 'KB', '') SELECT Name , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, [Rows]), 1), '.00', '') AS [Rows] , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Reserved / 1024 )), 1), '.00', ' MB') AS Reserved , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Data / 1024 )), 1), '.00', ' MB') AS Data , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Index_Size / 1024 )), 1), '.00', ' MB') AS Index_Size , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Unused / 1024 )), 1), '.00', ' MB') AS Unused ,CASE WHEN [Rows] = '0' THEN '0 KB' ELSE REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, Data)/CONVERT(MONEY, [Rows]), 1), '.00', '') + ' KB' END AS Row_Size FROM #SpaceUsed ORDER BY [Name] ASC IF OBJECT_ID('tempdb..#Tables') IS NOT NULL BEGIN DROP TABLE #Tables END; IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL BEGIN DROP TABLE #SpaceUsed END;

4: IF OBJECT_ID('tempdb..#Tables') IS NOT NULL BEGIN DROP TABLE #Tables END;IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL BEGIN DROP TABLE #SpaceUsed END;SET NOCOUNT ON DECLARE @TSQL VARCHAR(255) CREATE TABLE #Tables ( name VARCHAR(255) ) SELECT @TSQL = 'INSERT #Tables SELECT TABLE_NAME FROM ' + DB_NAME() + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = ''BASE TABLE''' EXEC (@TSQL) CREATE TABLE #SpaceUsed ( Name VARCHAR(255) , [Rows] VARCHAR(11) , Reserved VARCHAR(18) , Data VARCHAR(18) , Index_Size VARCHAR(18) , Unused VARCHAR(18) ) DECLARE @Name VARCHAR(255) SELECT @Name = '' WHILE EXISTS ( SELECT * FROM #Tables WHERE Name > @Name ) BEGIN SELECT @Name = MIN(name) FROM #Tables WHERE name > @Name SELECT @TSQL = 'EXEC ' + DB_NAME() + '..sp_executesql N''INSERT #SpaceUsed EXEC sp_spaceused ' + @Name + '''' EXEC (@TSQL) END UPDATE #SpaceUsed SET Reserved = REPLACE(Reserved, 'KB', '') UPDATE #SpaceUsed SET Data = REPLACE(Data, 'KB', '') UPDATE #SpaceUsed SET Index_Size = REPLACE(Index_Size, 'KB', '') UPDATE #SpaceUsed SET Unused = REPLACE(Unused, 'KB', '') SELECT Name , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, [Rows]), 1), '.00', '') AS [Rows] , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Reserved / 1024 )), 1), '.00', ' MB') AS Reserved , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Data / 1024 )), 1), '.00', ' MB') AS Data , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Index_Size / 1024 )), 1), '.00', ' MB') AS Index_Size , REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Unused / 1024 )), 1), '.00', ' MB') AS Unused ,CASE WHEN [Rows] = '0' THEN '0 KB' ELSE REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, Data)/CONVERT(MONEY, [Rows]), 1), '.00', '') + ' KB' END AS Row_Size FROM #SpaceUsed ORDER BY CONVERT(MONEY, ( Data / 1024 )) DESC IF OBJECT_ID('tempdb..#Tables') IS NOT NULL BEGIN DROP TABLE #Tables END; IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL BEGIN DROP TABLE #SpaceUsed END;

5: SELECT ':SETVAR SQLCMDPACKETSIZE 512'
6: SELECT [Server] = UPPER(@@SERVERNAME), [Database] = DB_NAME(), [ServerDatabase] = UPPER(@@SERVERNAME) + '.' + DB_NAME(), [Edition] = SERVERPROPERTY('edition'), [Version] = SERVERPROPERTY('productversion'), [Level] = SERVERPROPERTY('productlevel')
7: SELECT * FROM sys.tables ORDER BY name ASC 
8: SELECT * FROM sys.views ORDER BY name ASC 
9: SELECT * FROM sys.procedures ORDER BY name ASC 
0: SELECT * FROM sys.objects WHERE [type_desc] LIKE '%FUNCTION%' ORDER BY [name] ASC


=========================================================================================
Extract Manager
=========================================================================================
:SETVAR ExtractFileName 'NCFA_nettingrec$(@ScheduleStartTime:_yyyyMMdd)$(Environment:_{0}).csv'
SELECT $(ExtractFileName)

-- When the text has spaces
:SETVAR Param_Subject "'($(ENVIRONMENT)) SWIFT suppressed cashflows for Value Date today.'"
SELECT $(Param_Subject)


