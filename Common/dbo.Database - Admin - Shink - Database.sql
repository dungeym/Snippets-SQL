--=================================================================================================
-- Shrink the Database.
-- Change the name of the database in the script.
--=================================================================================================
USE CoreLog
GO


SELECT @@SERVICENAME AS [Server], DB_NAME() AS [Database], GETUTCDATE() AS [Timestamp]
GO


SELECT [Name] = df.name, [State] = df.state_desc, [File Size (MB)] = ((df.size * 8) / 1024.00), [Space Used (MB)] = CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0, [Free Space (MB)] = ((df.size * 8) / 1024.00) - CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0, [Used (%)] = (CONVERT(DECIMAL(25, 4), (CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0) / ((df.size * 8) / 1024.00))) * 100, [Max Size (MB)] = CASE WHEN df.max_size = 0 THEN 'Fixed' WHEN df.max_size = -1 THEN 'Unlimited' ELSE CONVERT(NVARCHAR(25), ((df.max_size * 8.00) / 1024.00)) END, [Auto Grow] = CASE WHEN df.growth = 0 THEN 'None' WHEN df.is_percent_growth = 1 THEN CONVERT(NVARCHAR(25), df.growth) + ' %' WHEN df.is_percent_growth = 0 THEN CONVERT(NVARCHAR(25), CONVERT(INT, ((df.growth * 8) / 1024.00))) + ' MB' ELSE NULL END, [Log State] = d.log_reuse_wait_desc, [Recovery Model] = d.recovery_model_desc, [Path] = df.physical_name FROM sys.database_files df WITH (NOLOCK) LEFT JOIN sys.databases d WITH (NOLOCK) ON d.name COLLATE Latin1_General_CI_AS = df.name COLLATE Latin1_General_CI_AS;
GO


DBCC SHRINKDATABASE (CoreLog);
GO


SELECT [Name] = df.name, [State] = df.state_desc, [File Size (MB)] = ((df.size * 8) / 1024.00), [Space Used (MB)] = CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0, [Free Space (MB)] = ((df.size * 8) / 1024.00) - CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0, [Used (%)] = (CONVERT(DECIMAL(25, 4), (CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS INT) / 128.0) / ((df.size * 8) / 1024.00))) * 100, [Max Size (MB)] = CASE WHEN df.max_size = 0 THEN 'Fixed' WHEN df.max_size = -1 THEN 'Unlimited' ELSE CONVERT(NVARCHAR(25), ((df.max_size * 8.00) / 1024.00)) END, [Auto Grow] = CASE WHEN df.growth = 0 THEN 'None' WHEN df.is_percent_growth = 1 THEN CONVERT(NVARCHAR(25), df.growth) + ' %' WHEN df.is_percent_growth = 0 THEN CONVERT(NVARCHAR(25), CONVERT(INT, ((df.growth * 8) / 1024.00))) + ' MB' ELSE NULL END, [Log State] = d.log_reuse_wait_desc, [Recovery Model] = d.recovery_model_desc, [Path] = df.physical_name FROM sys.database_files df WITH (NOLOCK) LEFT JOIN sys.databases d WITH (NOLOCK) ON d.name COLLATE Latin1_General_CI_AS = df.name COLLATE Latin1_General_CI_AS;
GO

/*
USE master;
ALTER DATABASE CoreLog SET RECOVERY SIMPLE;
*/