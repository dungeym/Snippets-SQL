
--=================================================================================================
-- Clean Buffer and Cache.
-- 
-- https://msdn.microsoft.com/en-us/library/ms178529%28v=sql.105%29.aspx
-- https://msdn.microsoft.com/en-us/library/ms187781%28v=sql.105%29.aspx
-- https://msdn.microsoft.com/en-us/library/ms174283%28v=sql.105%29.aspx
-- https://msdn.microsoft.com/en-gb/library/ms187762%28v=sql.105%29.aspx
--=================================================================================================


DBCC FREESYSTEMCACHE('ALL') WITH MARK_IN_USE_FOR_REMOVAL;
GO


DBCC FREESESSIONCACHE;
GO


DBCC FREEPROCCACHE;
GO


CHECKPOINT;
GO


DBCC DROPCLEANBUFFERS;
GO