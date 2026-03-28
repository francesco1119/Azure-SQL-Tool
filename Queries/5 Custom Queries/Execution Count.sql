-- Pulling out the Problematic Queries
SELECT  
         a.execution_count ,
         OBJECT_NAME(objectid, b.dbid) as object_name,
         query_text = SUBSTRING(b.text, a.statement_start_offset/2, 
									(   CASE WHEN a.statement_end_offset = -1 
										THEN LEN(CONVERT(nvarchar(MAX), b.text)) * 2 
                                        ELSE a.statement_end_offset 
                                        END - a.statement_start_offset
                                      )/2
                                ) ,
                                dbname = DB_NAME(b.dbid),
                                a.creation_time,
                                a.last_execution_time
								,'All these queries have Execution Count = 1' AS Info
FROM            sys.dm_exec_query_stats a 
CROSS APPLY     sys.dm_exec_sql_text(a.sql_handle) AS b 
where execution_count =1

