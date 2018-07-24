
-- ================================================================================================
-- Create and map and Active Directory group as a user.
-- create the user.
-- add the user to the role needed...db_datareader
-- output.
-- ================================================================================================

IF NOT EXISTS (SELECT * FROM dbo.sysusers WHERE [name] = 'MCCOLE\MyGroupName')
BEGIN
	CREATE USER [MCCOLE\MyGroupName]
	PRINT 'Created: MCCOLE\MyGroupName'
END
GO


IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE [name] = 'MCCOLE\MyGroupName')
BEGIN
	EXEC sp_addrolemember db_datareader, [MCCOLE\MyGroupName]
	PRINT 'Added: MCCOLE\MyGroupName'
END
GO


SELECT * FROM dbo.sysusers WHERE [name] IN 
(
	'MCCOLE\MyGroupName'
)

SELECT * FROM sys.database_principals WHERE [name] IN 
(
	'MCCOLE\MyGroupName'
)
GO
