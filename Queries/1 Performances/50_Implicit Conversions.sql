-- Script to find Queries With Implicit Conversion

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
  eqs.last_execution_time,
  'Implicit conversions prevent index seeks and cause full scans. Fix by aligning data types between columns and query parameters.' AS Info
FROM sys.dm_exec_query_stats AS eqs
     CROSS APPLY sys.dm_exec_text_query_plan(eqs.plan_handle, 
											 eqs.statement_start_offset, 
											 eqs.statement_end_offset) AS pl
     CROSS APPLY sys.dm_exec_sql_text(eqs.sql_handle) AS stx
WHERE pl.query_plan not like '%OBJECT_SCHEMA_NAME (stx.objectid, stx.dbid) %'
and pl.dbid=DB_ID()
and pl.query_plan like '%CONVERT_IMPLICIT%'

-- Finding Implicit Column Conversions in the Plan Cache

/*SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @dbname SYSNAME 
SET @dbname = QUOTENAME(DB_NAME());

WITH XMLNAMESPACES 
   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
SELECT 
   stmt.value('(@StatementText)[1]', 'varchar(max)'), 
   t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)'), 
   t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)'), 
   t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)'), 
   ic.DATA_TYPE AS ConvertFrom, 
   ic.CHARACTER_MAXIMUM_LENGTH AS ConvertFromLength, 
   t.value('(@DataType)[1]', 'varchar(128)') AS ConvertTo, 
   t.value('(@Length)[1]', 'int') AS ConvertToLength, 
   query_plan 
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
CROSS APPLY stmt.nodes('.//Convert[@Implicit="1"]') AS n(t) 
JOIN INFORMATION_SCHEMA.COLUMNS AS ic 
   ON QUOTENAME(ic.TABLE_SCHEMA) = t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)') 
   AND QUOTENAME(ic.TABLE_NAME) = t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)') 
   AND ic.COLUMN_NAME = t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)') 
WHERE t.exist('ScalarOperator/Identifier/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]') = 1*/