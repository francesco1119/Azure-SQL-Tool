-- Status of last VLF for current database  (Query 18) (Last VLF Status)
SELECT TOP(1) 
    DB_NAME(li.database_id) AS [Database Name], 
    li.[file_id],
    li.vlf_size_mb, 
    li.vlf_sequence_number, 
    li.vlf_active, 
    li.vlf_status,
    CASE 
        WHEN li.vlf_status = 0 THEN 'vlf_status is 0, this means you cannot shrink the transaction log file'
		WHEN li.vlf_status = 1 THEN 'vlf_status is 1, this means the transaction log file is initialized but unused '
		WHEN li.vlf_status = 2 THEN 'vlf_status is 2, this means can shrink the transaction log file'
        ELSE ''
    END AS Comment
FROM sys.dm_db_log_info(DB_ID()) AS li 
ORDER BY vlf_sequence_number DESC
OPTION (RECOMPILE);
