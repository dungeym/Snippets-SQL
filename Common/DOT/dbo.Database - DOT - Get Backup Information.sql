USE msdb
GO

SELECT 
	b.backup_start_date
	, b.backup_finish_date
	, b.server_name
	, b.database_name
	, b.backup_size
	, b.compressed_backup_size
	, b.[user_name]
FROM dbo.backupset b WITH (NOLOCK)
WHERE 1=1
AND b.database_name NOT IN ('dbadb', 'msdb', 'model', 'master')
AND b.backup_finish_date > CONVERT(DATE, GETUTCDATE())
ORDER BY b.backup_finish_date DESC
GO
