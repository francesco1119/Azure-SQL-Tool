-- Check compatibility level for the current database
SELECT
    name AS [Database Name],
    compatibility_level AS [Compatibility Level],
    state_desc AS [State],
    user_access_desc AS [User Access],
    'Compatibility level controls which SQL Server features and behaviors are available. 160 = SQL Server 2022 / Azure SQL latest. Lower levels may prevent use of newer query optimizer features.' AS Info
FROM sys.databases
WHERE database_id = DB_ID()
OPTION (RECOMPILE);
