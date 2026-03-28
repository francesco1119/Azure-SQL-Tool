-- http://www.dharmendrakeshari.com/queries-using-particular-index-table/#respond

SELECT OBJECT_SCHEMA_NAME (stx.objectid, stx.dbid) +'.'+OBJECT_NAME(stx.objectid, stx.dbid) AS object_name,
  SUBSTRING	(stx.[text],(eqs.statement_start_offset / 2) + 1,
				(CASE WHEN eqs.statement_end_offset =-1 
					THEN DATALENGTH(stx.text) 
					ELSE eqs.statement_end_offset 
					END - eqs.statement_start_offset
				 )/ 2 + 1) AS QueryText,
  CAST(pl.query_plan AS XML) AS sqlplan,
  stx.[text] as complete_text,
  eqs.execution_count,
  eqs.creation_time [compilation time],
  eqs.total_worker_time/execution_count AS avg_cpu_time,
  eqs.total_worker_time AS total_cpu_time,
  eqs.total_logical_reads/execution_count AS avg_logical_reads,
  eqs.total_logical_reads,
  eqs.last_execution_time
FROM sys.dm_exec_query_stats AS eqs
     CROSS APPLY sys.dm_exec_text_query_plan(eqs.plan_handle, 
											 eqs.statement_start_offset, 
											 eqs.statement_end_offset) AS pl
     CROSS APPLY sys.dm_exec_sql_text(eqs.sql_handle) AS stx
WHERE pl.query_plan not like '%OBJECT_SCHEMA_NAME (stx.objectid, stx.dbid) %'
and pl.query_plan like '%bqm%' ----Replace the "XXXXXXXXX" with index or table name
and pl.dbid=DB_ID()