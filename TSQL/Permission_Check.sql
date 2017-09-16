EXECUTE AS USER = 'eMatch_EU_user';
SELECT * FROM fn_my_permissions('uspPhoenixMasterConfirmationAgreementExchangeGroupProduct', 'OBJECT') ORDER BY subentity_name, permission_name ;  
REVERT;