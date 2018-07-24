
-- ================================================================================================
-- Returns a list of the permissions effectively granted to the principal on a securable.
-- https://msdn.microsoft.com/en-us/library/ms176097.aspx
-- ================================================================================================

SELECT [Server] = 'securable_class', * FROM fn_my_permissions(NULL, 'SERVER')
SELECT [Application Role] = 'securable_class', * FROM fn_my_permissions(NULL, 'APPLICATION ROLE')
SELECT [Assembly] = 'securable_class', * FROM fn_my_permissions(NULL, 'ASSEMBLY')
SELECT [Asymmetric Key] = 'securable_class', * FROM fn_my_permissions(NULL, 'ASYMMETRIC KEY')
SELECT [Certificate] = 'securable_class', * FROM fn_my_permissions(NULL, 'CERTIFICATE')
SELECT [Contract] = 'securable_class', * FROM fn_my_permissions(NULL, 'CONTRACT')
SELECT [Database] = 'securable_class', * FROM fn_my_permissions(NULL, 'DATABASE')
SELECT [Endpoint] = 'securable_class', * FROM fn_my_permissions(NULL, 'ENDPOINT')
SELECT [Fulltext Catalog] = 'securable_class', * FROM fn_my_permissions(NULL, 'FULLTEXT CATALOG')
SELECT [Login] = 'securable_class', * FROM fn_my_permissions(NULL, 'LOGIN')
SELECT [Message Type] = 'securable_class', * FROM fn_my_permissions(NULL, 'MESSAGE TYPE')
SELECT [Object] = 'securable_class', * FROM fn_my_permissions(NULL, 'OBJECT')
SELECT [Remote Binding Service] = 'securable_class', * FROM fn_my_permissions(NULL, 'REMOTE SERVICE BINDING')
SELECT [Role] = 'securable_class', * FROM fn_my_permissions(NULL, 'ROLE')
SELECT [Route] = 'securable_class', * FROM fn_my_permissions(NULL, 'ROUTE') 
SELECT [Schema] = 'securable_class', * FROM fn_my_permissions(NULL, 'SCHEMA') 
SELECT [Server] = 'securable_class', * FROM fn_my_permissions(NULL, 'SERVER')
SELECT [Service] = 'securable_class', * FROM fn_my_permissions(NULL, 'SERVICE') 
SELECT [Symmetric Key] = 'securable_class', * FROM fn_my_permissions(NULL, 'SYMMETRIC KEY')
SELECT [Type] = 'securable_class', * FROM fn_my_permissions(NULL, 'TYPE')
SELECT [User] = 'securable_class', * FROM fn_my_permissions(NULL, 'USER')
SELECT [XML Schema Collection] = 'securable_class', * FROM fn_my_permissions(NULL, 'XML SCHEMA COLLECTION')
GO
