WITH ConnectionStats AS (
    SELECT
        database_name,
        ROUND(AVG(CAST(hourly_connections AS FLOAT)), 2) AS AVG_Connections_per_Hour
    FROM (
        SELECT
            database_name,
            CONVERT(DATE, start_time)  AS day_bucket,
            DATEPART(HOUR, start_time) AS hour_bucket,
            SUM(success_count)         AS hourly_connections
        FROM sys.database_connection_stats
        WHERE database_name != 'master'
        GROUP BY
            database_name,
            CONVERT(DATE, start_time),
            DATEPART(HOUR, start_time)
    ) AS hourly
    GROUP BY database_name
),

LatestDTU AS (
    SELECT
        database_name,
        dtu_limit,
        ROW_NUMBER() OVER (PARTITION BY database_name ORDER BY start_time DESC) AS rn
    FROM sys.resource_stats
)

SELECT
    @@SERVERNAME                                                         AS ServerName,
    rs.database_name                                                     AS DatabaseName,
    sysso.edition,
    sysso.service_objective,
    dtu.dtu_limit                                                        AS DTU,
    con.AVG_Connections_per_Hour,
    CAST(MAX(rs.storage_in_megabytes)           / 1024 AS DECIMAL(10,2)) AS StorageGB,
    CAST(MAX(rs.allocated_storage_in_megabytes) / 1024 AS DECIMAL(10,2)) AS Allocated_StorageGB,
    MIN(rs.end_time)                                                     AS StartTime,
    MAX(rs.end_time)                                                     AS EndTime,
    CAST(AVG(rs.avg_cpu_percent)     AS DECIMAL(4,2))                   AS Avg_CPU,
    MAX(rs.avg_cpu_percent)                                              AS Max_CPU,
    CAST((COUNT(*) - SUM(CASE WHEN rs.avg_cpu_percent      >= 40 THEN 1 ELSE 0 END)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [CPU Fit %],
    CAST(AVG(rs.avg_data_io_percent) AS DECIMAL(4,2))                   AS Avg_IO,
    MAX(rs.avg_data_io_percent)                                          AS Max_IO,
    CAST((COUNT(*) - SUM(CASE WHEN rs.avg_data_io_percent  >= 40 THEN 1 ELSE 0 END)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [Data IO Fit %],
    CAST(AVG(rs.avg_log_write_percent) AS DECIMAL(4,2))                 AS Avg_LogWrite,
    MAX(rs.avg_log_write_percent)                                        AS Max_LogWrite,
    CAST((COUNT(*) - SUM(CASE WHEN rs.avg_log_write_percent >= 40 THEN 1 ELSE 0 END)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [Log Write Fit %],
    CAST(AVG(rs.max_session_percent) AS DECIMAL(4,2))                   AS [Avg % Sessions],
    MAX(rs.max_session_percent)                                          AS [Max % Sessions],
    CAST(AVG(rs.max_worker_percent)  AS DECIMAL(4,2))                   AS [Avg % Workers],
    MAX(rs.max_worker_percent)                                           AS [Max % Workers]

FROM sys.resource_stats AS rs
INNER JOIN sys.databases                   dbs   ON dbs.name           = rs.database_name
INNER JOIN sys.database_service_objectives sysso ON sysso.database_id  = dbs.database_id
INNER JOIN LatestDTU                       dtu   ON dtu.database_name  = rs.database_name AND dtu.rn = 1
LEFT  JOIN ConnectionStats                 con   ON con.database_name  = rs.database_name

WHERE rs.database_name != 'master'

GROUP BY
    rs.database_name,
    sysso.edition,
    sysso.service_objective,
    con.AVG_Connections_per_Hour,
    dtu.dtu_limit

ORDER BY
    rs.database_name,
    sysso.edition,
    sysso.service_objective;