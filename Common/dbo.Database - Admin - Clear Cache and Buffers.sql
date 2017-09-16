-- ================================================================================================
-- Database - Clear Cache and Buffers.
-- ================================================================================================

-- https://msdn.microsoft.com/en-us/library/ms178529%28v=sql.105%29.aspx
DBCC FREESYSTEMCACHE('ALL') WITH MARK_IN_USE_FOR_REMOVAL;
GO


-- https://msdn.microsoft.com/en-us/library/ms187781%28v=sql.105%29.aspx
DBCC FREESESSIONCACHE;
GO


-- https://msdn.microsoft.com/en-us/library/ms174283%28v=sql.105%29.aspx
DBCC FREEPROCCACHE;
GO


CHECKPOINT;
GO


-- https://msdn.microsoft.com/en-gb/library/ms187762%28v=sql.105%29.aspx
DBCC DROPCLEANBUFFERS;
GO