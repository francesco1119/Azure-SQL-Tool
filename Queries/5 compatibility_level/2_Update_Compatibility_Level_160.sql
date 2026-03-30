-- Update compatibility level to 160 (SQL Server 2022 / Azure SQL latest) for the current database
DECLARE @sql NVARCHAR(MAX) = 'ALTER DATABASE [' + DB_NAME() + '] SET COMPATIBILITY_LEVEL = 160;';
EXEC sp_executesql @sql;

-- Confirm the change
SELECT
    name AS [Database Name],
    compatibility_level AS [Compatibility Level],
    'Compatibility level has been updated to 160. Test your workload after this change as the query optimizer behavior may differ.' AS Info
FROM sys.databases
WHERE database_id = DB_ID()
OPTION (RECOMPILE);
