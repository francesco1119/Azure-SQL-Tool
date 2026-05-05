-- Get active requests with CPU time, elapsed time, and wait info (Query 57) (Active Requests)
SELECT DB_NAME(st.dbid) AS [Database Name]
	,r.session_id
	,s.login_name
	,s.host_name
	,s.program_name
	,r.[status] AS [Request Status]
	,r.command
	,r.wait_type
	,r.wait_time
	,r.cpu_time
	,r.total_elapsed_time
	,r.start_time
	,SUBSTRING(st.[text], r.statement_start_offset / 2, (
			CASE
				WHEN r.statement_end_offset = -1
					THEN LEN(CONVERT(NVARCHAR(MAX), st.[text])) * 2
				ELSE r.statement_end_offset
				END - r.statement_start_offset
			) / 2) AS [Statement Text]
	,'Shows active requests with CPU time, elapsed time, and wait info. Useful for identifying what sessions are doing during an incident.' AS Info
FROM sys.dm_exec_requests AS r WITH (NOLOCK)
INNER JOIN sys.dm_exec_sessions AS s WITH (NOLOCK) ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE s.is_user_process = 1
	AND r.session_id <> @@SPID
ORDER BY r.cpu_time DESC
OPTION (RECOMPILE);
	------
	-- Shows currently active user requests with CPU time, elapsed time, wait type, and statement text
	-- Run multiple times during an incident to see what sessions are actively working on
	-- Complements 9_Detect Blocking (which focuses on lock chains) and 52_Input Buffer (which shows query text via input buffer)
