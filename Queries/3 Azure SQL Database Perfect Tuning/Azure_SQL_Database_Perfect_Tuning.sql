DECLARE @StartDate date = DATEADD(day, -30, GETDATE()) -- 30 Days

SELECT
    @@SERVERNAME AS ServerName,
    database_name AS DatabaseName,
    sysso.edition,
    sysso.service_objective,
    (SELECT TOP 1 dtu_limit FROM sys.resource_stats AS rs3 WHERE rs3.database_name = rs1.database_name ORDER BY rs3.start_time DESC)  AS DTU,
    avcon.AVG_Connections_per_Hour,
    CAST(MAX(storage_in_megabytes) / 1024 AS DECIMAL(10, 2)) StorageGB,
    CAST(MAX(allocated_storage_in_megabytes) / 1024 AS DECIMAL(10, 2)) Allocated_StorageGB,
    MIN(end_time) AS StartTime,
    MAX(end_time) AS EndTime,
    CAST(AVG(avg_cpu_percent) AS decimal(4,2)) AS Avg_CPU,
    MAX(avg_cpu_percent) AS Max_CPU,
    (COUNT(database_name) - SUM(CASE WHEN avg_cpu_percent >= 40 THEN 1 ELSE 0 END) * 1.0) / COUNT(database_name) * 100 AS [CPU Fit %],
    CAST(AVG(avg_data_io_percent) AS decimal(4,2)) AS Avg_IO,
    MAX(avg_data_io_percent) AS Max_IO,
    (COUNT(database_name) - SUM(CASE WHEN avg_data_io_percent >= 40 THEN 1 ELSE 0 END) * 1.0) / COUNT(database_name) * 100 AS [Data IO Fit %],
    CAST(AVG(avg_log_write_percent) AS decimal(4,2)) AS Avg_LogWrite,
    MAX(avg_log_write_percent) AS Max_LogWrite,
    (COUNT(database_name) - SUM(CASE WHEN avg_log_write_percent >= 40 THEN 1 ELSE 0 END) * 1.0) / COUNT(database_name) * 100 AS [Log Write Fit %],
    CAST(AVG(max_session_percent) AS decimal(4,2)) AS 'Average % of sessions',
    MAX(max_session_percent) AS 'Maximum % of sessions',
    CAST(AVG(max_worker_percent) AS decimal(4,2)) AS 'Average % of workers',
    MAX(max_worker_percent) AS 'Maximum % of workers'
FROM sys.resource_stats AS rs1
INNER JOIN sys.databases dbs ON rs1.database_name = dbs.name
INNER JOIN sys.database_service_objectives sysso ON sysso.database_id = dbs.database_id
LEFT JOIN (
    SELECT
        name,
        ROUND(AVG(CAST(success_count AS FLOAT)), 2) AS AVG_Connections_per_Hour
    FROM (
        SELECT
            name,
            CONVERT(DATE, start_time) AS Dating,
            DATEPART(HOUR, start_time) AS Houring,
            SUM(CASE WHEN name = database_name THEN success_count ELSE 0 END) AS success_count
        FROM sys.database_connection_stats
        CROSS JOIN sys.databases
        WHERE start_time > @StartDate
          AND database_id != 1
        GROUP BY name, CONVERT(DATE, start_time), DATEPART(HOUR, start_time)
    ) AS t
    GROUP BY name
) avcon ON avcon.name = rs1.database_name
WHERE start_time > @StartDate
  AND rs1.start_time > @StartDate 
  AND rs1.database_name != 'master' -- Exclude the master database explicitly
GROUP BY database_name, sysso.edition, sysso.service_objective, avcon.AVG_Connections_per_Hour
ORDER BY database_name, sysso.edition, sysso.service_objective;
