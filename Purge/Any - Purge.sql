
IF EXISTS (SELECT * FROM sys.procedures WHERE [name] = 'uspPurge')
BEGIN
	EXEC sp_executesql N'EXEC uspPurge'
END	
GO

IF EXISTS (SELECT * FROM sys.procedures WHERE [name] = 'uspxPurgeRTU')
BEGIN
	EXEC sp_executesql N'EXEC uspxPurgeRTU'
END	
GO
