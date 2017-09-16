
/*
Deadlock testing.

1. Create the required objects.
2. Call [uspxDeadlockCreate] to lock data in [tblDeadlockTesting].
3. Call [uspxDeadlockThrow] from the target script to throw a deadlock exception in your application.
4. Manually stop [uspxDeadlockCreate] when testing is complete and Rollback any open transactions.
5. Manually drop the required objects.
*/

-- EXEC dbo.uspxDeadlockCreate
-- IF @@TRANCOUNT > 0 ROLLBACK
--=================================================================================================
-- DROP TABLE dbo.tblDeadlockTesting
--=================================================================================================
IF EXISTS (SELECT * FROM sys.tables WHERE [name ] = 'tblDeadlockTesting')
BEGIN
	DROP TABLE dbo.tblDeadlockTesting
	PRINT 'DROP TABLE dbo.tblDeadlockTesting'
END
GO


--=================================================================================================
-- DROP PROCEDURE dbo.uspxDeadlockCreate
--=================================================================================================
IF EXISTS(SELECT * FROM sys.procedures WHERE name = 'uspxDeadlockCreate')
BEGIN
	DROP PROCEDURE dbo.uspxDeadlockCreate
	PRINT 'DROP PROCEDURE dbo.uspxDeadlockCreate'
END
GO


--=================================================================================================
-- DROP PROCEDURE dbo.uspxDeadlockThrow
--=================================================================================================
IF EXISTS(SELECT * FROM sys.procedures WHERE name = 'uspxDeadlockThrow')
BEGIN
	DROP PROCEDURE dbo.uspxDeadlockThrow
	PRINT 'DROP PROCEDURE dbo.uspxDeadlockThrow'
END
GO


--=================================================================================================
-- CREATE TABLE dbo.tblDeadlockTesting
--=================================================================================================
CREATE TABLE dbo.tblDeadlockTesting
(
	DeadlockKey		INT PRIMARY KEY CLUSTERED,
	DeadlockCount	INT
)
GO

-- Test data
SET NOCOUNT ON
INSERT INTO dbo.tblDeadlockTesting(DeadlockKey, DeadlockCount)
SELECT 1, 0
UNION SELECT 2, 0
GO

--=================================================================================================
-- CREATE PROCEDURE dbo.uspxDeadlockThrow
--=================================================================================================
CREATE PROCEDURE dbo.uspxDeadlockThrow
	@MaxDeadlocks		INT = -1,		-- Specify the number of deadlocks you want; -1 = constant deadlocking
	@TraceEvent			BIT = 0			-- 1 if information should be written to Trace
AS
BEGIN
/*
Used in conjunction with other objects to create a deadlock scenario

300414	dungeym		initial scripting
*/

	SET NOCOUNT ON

	IF OBJECT_ID('tblDeadlockTesting') IS NULL
	BEGIN
		RAISERROR ('[uspxDeadlockThrow] depends on the missing object [tblDeadlockTesting].', 0, 0) WITH NOWAIT
		RETURN
	END

	/*
	Specifies that the current session will be the deadlock victim if it is involved in a deadlock and 
	other sessions involved in the deadlock chain have deadlock priority set to either NORMAL or HIGH or 
	to an integer value greater than -5. The current session will not be the deadlock victim if the 
	other sessions have deadlock priority set to an integer value less than -5. It also specifies that 
	the current session is eligible to be the deadlock victim if another session has set deadlock priority 
	set to LOW or to an integer value equal to -5.
	*/
	SET DEADLOCK_PRIORITY LOW

	DECLARE @DeadlockCount INT = (SELECT DeadlockCount FROM dbo.tblDeadlockTesting WHERE DeadlockKey = 2)

	/*
	Use SQL Server Profiler to listen to tracing.
	Listen to the event class [UserConfigurable:0]
	User will need ALTER TRACE permissions.
	*/
	DECLARE @Trace NVARCHAR(128)

	IF @MaxDeadlocks > 0 AND @DeadlockCount > @MaxDeadlocks
	BEGIN

		SET @Trace = N'Deadlock Test @MaxDeadlocks: ' + CAST(@MaxDeadlocks AS NVARCHAR) + N' @DeadlockCount: ' + CAST(@DeadlockCount AS NVARCHAR) + N' Resetting deadlock count. Will not cause deadlock.'
		IF @TraceEvent = 1 EXEC sp_trace_generateevent @eventid = 82, @userinfo = @Trace
		IF @TraceEvent = 0 PRINT @Trace

		-- Reset the number of deadlocks.
		-- Hopefully if there is an outer transaction, it will complete and persist this change.
		UPDATE dbo.tblDeadlockTesting SET 
			DeadlockCount = 0
		WHERE DeadlockKey = 2

		RETURN
	END

	SET @Trace = N'Deadlock Test @MaxDeadlocks: ' + CAST(@MaxDeadlocks AS NVARCHAR) + N' @DeadlockCount: ' + CAST(@DeadlockCount AS NVARCHAR) + N' Simulating deadlock.'
	IF @TraceEvent = 1 EXEC sp_trace_generateevent @eventid = 82, @userinfo = @Trace
	IF @TraceEvent = 0 PRINT @Trace
	
	DECLARE @StartedTransaction BIT = 0
	IF @@TRANCOUNT = 0
	BEGIN
		SET @StartedTransaction = 1
		BEGIN TRANSACTION
	END

		-- Lock 2nd record
		UPDATE dbo.tblDeadlockTesting SET 
			DeadlockCount = DeadlockCount
		FROM dbo.tblDeadlockTesting
		WHERE DeadlockKey = 2

		-- Lock 1st record to cause deadlock
		UPDATE dbo.tblDeadlockTesting SET 
			DeadlockCount = DeadlockCount
		FROM dbo.tblDeadlockTesting
		WHERE DeadlockKey = 1

	IF @StartedTransaction = 1
	BEGIN
		ROLLBACK 
	END

END
GO

--=================================================================================================
-- CREATE PROCEDURE dbo.uspxDeadlockCreate
--=================================================================================================
CREATE PROCEDURE dbo.uspxDeadlockCreate
AS
BEGIN
/*
Used in conjunction with other objects to create a deadlock scenario

300414	dungeym		initial scripting
*/

	SET NOCOUNT ON
	
	/* 
	Specifies that the current session will be the deadlock victim if other sessions involved in the
	deadlock chain have deadlock priority set to an integer value greater than 5, or is eligible to be
	the deadlock victim if another session has also set deadlock priority to HIGH or to an integer value equal to 5
	*/
	SET DEADLOCK_PRIORITY HIGH

	BEGIN TRANSACTION

	WHILE 1 = 1
	BEGIN
		BEGIN TRY

			BEGIN TRANSACTION

			-- Lock 1st record
			UPDATE dbo.tblDeadlockTesting SET 
				DeadlockCount = DeadlockCount
			FROM dbo.tblDeadlockTesting
			WHERE DeadlockKey = 1

			WAITFOR DELAY '00:00:10'

			-- Lock 2nd record (which will be locked when [uspxDeadlockThrow] is called)
			UPDATE dbo.tblDeadlockTesting SET 
				DeadlockCount = DeadlockCount
			FROM dbo.tblDeadlockTesting
			WHERE DeadlockKey = 2

			ROLLBACK

		END TRY
		BEGIN CATCH
			PRINT 'Error ' + CONVERT(VARCHAR(20), ERROR_NUMBER()) + ': ' + ERROR_MESSAGE()
			GOTO cleanup
		END CATCH
	END

	cleanup:
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK
		END
	
END
GO
