
-- ================================================================================================
-- Output the permissions for a specific object for a specific user.
-- ================================================================================================

-- Change the user this following will run as.
EXECUTE AS USER = 'CoreRelease_user';
GO

-- Execute
SELECT * 
FROM fn_my_permissions('uspDatabaseMaintenance', 'OBJECT') 
ORDER BY subentity_name, permission_name ;  

-- Revert to the permisions user.
REVERT;
GO
