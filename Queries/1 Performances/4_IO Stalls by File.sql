-- Adapted from Glenn Berry's Azure SQL Database Diagnostic Information Queries
-- Copyright (C) Glenn Berry. Non-commercial use only. Credit must be given.
-- https://glennsqlperformance.com/resources/

-- Calculates average stalls per read, per write, and per total input/output for each database file  (Query 4) (IO Stalls by File)
SELECT 
    DB_NAME(fs.database_id) AS [Database Name],
    CAST(SUM(fs.io_stall_read_ms) / (1.0 + SUM(fs.num_of_reads)) AS NUMERIC(16, 1)) AS [avg_read_stall_ms],
    CAST(SUM(fs.io_stall_write_ms) / (1.0 + SUM(fs.num_of_writes)) AS NUMERIC(16, 1)) AS [avg_write_stall_ms],
    CAST((SUM(fs.io_stall_read_ms) + SUM(fs.io_stall_write_ms)) / (1.0 + SUM(fs.num_of_reads + fs.num_of_writes)) AS NUMERIC(16, 1)) AS [avg_io_stall_ms],
    SUM(fs.io_stall_read_ms) AS io_stall_read_ms,
    SUM(fs.num_of_reads) AS num_of_reads,
    SUM(fs.io_stall_write_ms) AS io_stall_write_ms,
    SUM(fs.num_of_writes) AS num_of_writes,
    SUM(fs.io_stall_read_ms + fs.io_stall_write_ms) AS [io_stalls],
    SUM(fs.num_of_reads + fs.num_of_writes) AS [total_io],
    SUM(io_stall_queued_read_ms) AS [Resource Governor Total Read IO Latency (ms)],
    SUM(io_stall_queued_write_ms) AS [Resource Governor Total Write IO Latency (ms)],
    'Helps determine which database files on the entire instance have the most I/O bottlenecks' AS Info
FROM 
    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
GROUP BY 
    fs.database_id
ORDER BY 
    [avg_io_stall_ms] DESC
OPTION (RECOMPILE);

	------
	-- Helps determine which database files on the entire instance have the most I/O bottlenecks
	-- This can help you decide whether certain LUNs are overloaded and whether you might
	-- want to move some files to a different location or perhaps improve your I/O performance
	-- These latency numbers include all file activity against each database file since SQL Server was last started
