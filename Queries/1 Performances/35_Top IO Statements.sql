-- Adapted from Glenn Berry's Azure SQL Database Diagnostic Information Queries
-- Copyright (C) Glenn Berry. Non-commercial use only. Credit must be given.
-- https://glennsqlperformance.com/resources/

-- Lists the top statements by average input/output usage for the current database  (Query 35) (Top IO Statements)
SELECT TOP (50) OBJECT_NAME(qt.objectid, dbid) AS [SP Name]
	,(qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count AS [Avg IO]
	,qs.execution_count AS [Execution Count]
	,SUBSTRING(qt.[text], qs.statement_start_offset / 2, (
			CASE 
				WHEN qs.statement_end_offset = - 1
					THEN LEN(CONVERT(NVARCHAR(max), qt.[text])) * 2
				ELSE qs.statement_end_offset
				END - qs.statement_start_offset
			) / 2) AS [Query Text]
			,'Helps you find the most expensive statements for I/O by SP' AS Info
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.[dbid] = DB_ID()
ORDER BY [Avg IO] DESC
OPTION (RECOMPILE);
	------
	-- Helps you find the most expensive statements for I/O by SP
