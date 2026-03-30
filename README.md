# Azure SQL Tool

A PowerShell-based diagnostic and analysis tool for Azure SQL databases. It authenticates to Azure, lets you pick a category of SQL queries, filters targets by subscription/server/database, executes the queries, and exports the results to Excel or CSV files.

---

## Prerequisites

- **PowerShell** with the following modules:
  - `Az` (Azure PowerShell)
  - `SqlServer`
  - `ImportExcel`

> **Note:** The script automatically checks for these modules at startup and installs any that are missing. No manual setup required.

- Permissions to read Azure SQL resources in the target subscriptions
- A `Results\` folder in the same directory as the script

---

## How It Works — `Azure SQL Tool.ps1`

### 1. Module Check

On every run, the script verifies that `Az`, `SqlServer`, and `ImportExcel` are installed. If any are missing, they are automatically installed via `Install-Module` before proceeding.

### 2. Authentication

The script calls `Connect-AzAccount`, which prompts for interactive Azure login via browser. If login is cancelled or fails, the script exits immediately. It then retrieves an Azure AD access token scoped to `https://database.windows.net`, used to authenticate all SQL queries without needing SQL credentials.

### 3. Task Selection Menu

You are presented with five categories to choose from:

| # | Category | Description |
|---|----------|-------------|
| 1 | Performances | Performance-related diagnostics (I/O, buffer, indexes, wait stats, query stats, etc.) |
| 2 | Quick Investigation | Blocking detection, lock waits, geo-replication status, resumable index rebuilds, etc. |
| 3 | Perfect Tuning | Evaluates whether Azure SQL databases can be downgraded to a lower service tier |
| 4 | AUTO_SHRINK | Checks if AUTO_SHRINK is enabled on databases |
| 5 | compatibility_level | Queries related to database compatibility level analysis |
| 6 | Custom Queries | Ad hoc queries (plan cache analysis, duplicate indexes, missing indexes, etc.) |

### 4. Target Filtering

After picking a category, you enter filter values that support wildcard (`*`) patterns:

- **Subscription** — matches Azure subscriptions by name
- **Server** — matches Azure SQL servers by name
- **Database** — matches databases by name (not applicable for option 3)

### 5. Query Execution

The script iterates through all subscriptions → servers → databases that match the filters and runs every `.sql` file found in the corresponding `Queries\<category>\` folder.

- Files are executed in **natural sort order** (numeric prefix of the filename).
- Queries run using `Invoke-Sqlcmd` with the Azure AD token — no passwords required.
- **Serverless database support:** If a database is in Azure SQL Serverless mode and is paused, the script automatically detects the wake-up timeout and retries up to 3 times with a 30-second wait between attempts. The connection timeout is set to 120 seconds to accommodate the typical 30–90 second resume time.

### 6. Output

| Category | Output format | File location |
|----------|--------------|---------------|
| 1, 2, 4, 5 | Excel (`.xlsx`), one worksheet per query | `.\Results\<Category>_<DatabaseName>_<Date>.xlsx` |
| 3 (Perfect Tuning) | CSV (`.csv`), appended across all servers | `.\Results\Perfect_Tuning.csv` |

- Excel files use `Export-Excel` with `AutoSize` columns.
- Each worksheet is named after the query file (truncated to 31 characters to comply with Excel's tab name limit).
- The date in the filename uses the `yyyy-MM-dd` format.

---

## How It Works — `AUTO_SHRINK\AUTO_SHRINK.ps1`

This is a standalone, parameterized version of the AUTO_SHRINK check.

### Parameters

```powershell
.\AUTO_SHRINK\AUTO_SHRINK.ps1 -subscription "My Sub" -server "my-server*" -database "*"
```

| Parameter | Description |
|-----------|-------------|
| `subscription` | Azure subscription name (supports wildcards) |
| `server` | SQL server name (supports wildcards) |
| `database` | Database name (supports wildcards) |

### Behavior

1. Authenticates to Azure via `Connect-AzAccount`.
2. Iterates through matching subscriptions → servers → databases (skips `master`).
3. Runs each `.sql` file found in `.\AUTO_SHRINK\Queries\` against every matching database.
4. Exports results to individual CSV files in `.\AUTO_SHRINK\Results\`, one file per query, named after the `.sql` file.

---

## Query Categories

### 1 - Performances

| Query | Description |
|-------|-------------|
| `4_IO Stalls by File` | Average IO stall latency (read/write/total) per database — identifies I/O bottlenecks across the instance |
| `5_IO Usage By Database` | I/O usage breakdown by database showing total, read, and write MB with percentages |
| `6_Buffer by Database` | Buffer pool memory usage and cached size per database |
| `12_Memory Clerk Usage` | Top 10 memory clerks by usage — identifies sources of memory pressure |
| `13_Ad hoc Queries` | Single-use ad-hoc and prepared queries bloating the plan cache |
| `18_Last VLF Status` | Status of the last VLF in the transaction log — determines whether the log can be shrunk |
| `21_IO Stats By File` | Detailed I/O statistics per file for the current database (size, reads, writes, stall %) |
| `25_Query Execution Counts` | Top 50 most frequently executed queries for the current database |
| `26_Top Worker Time Queries` | Top 50 queries by total CPU (worker) time — identifies highest CPU consumers |
| `27_Top Logical Reads Queries` | Top 50 queries by total logical reads — identifies highest memory consumers |
| `28_Top Avg Elapsed Time Queries` | Top 50 queries by average elapsed time — identifies slowest queries |
| `29_SP Execution Counts` | Cached stored procedures ranked by execution count |
| `30_SP Avg Elapsed Time` | Cached stored procedures ranked by average elapsed time |
| `31_SP Worker Time` | Cached stored procedures ranked by total CPU time |
| `32_SP Logical Reads` | Cached stored procedures ranked by total logical reads |
| `33_SP Physical Reads` | Cached stored procedures ranked by total physical reads |
| `34_SP Logical Writes` | Cached stored procedures ranked by total logical writes |
| `35_Top IO Statements` | Top 50 statements by average I/O, grouped by stored procedure |
| `36_Bad NC Indexes` | Nonclustered indexes where writes exceed reads — candidates for removal |
| `37_Missing Indexes` | Missing indexes ranked by impact with a ready-to-run `CREATE INDEX` statement (Brent Ozar) |
| `38_Missing Index Warnings` | Cached execution plans that contain missing index warnings |
| `39_Buffer Usage` | Buffer pool usage broken down by table and index — candidates for data compression |
| `40_Table Sizes` | Table sizes in GB with row count and bytes per row |
| `41_Table Properties` | Key table properties (compression, CDC, temporal, memory-optimized) ordered by row count |
| `42_Statistics Update` | Statistics update dates and sample rates for all indexes |
| `43_Volatile Indexes` | Indexes and statistics with the highest modification counts |
| `44_Index Fragmentation` | Fragmentation level for indexes larger than 2500 pages |
| `45_Overall Index Usage - Reads` | All index read/write stats ordered by total reads |
| `46_Overall Index Usage - Writes` | All index read/write stats ordered by total writes |
| `47_Columnstore Index Stat` | Physical health of columnstore row groups including fragmentation and compression state |
| `49_UDF Statistics` | Scalar UDF execution statistics — identifies expensive user-defined functions |
| `50_Implicit Conversions` | Queries with implicit type conversions that prevent index seeks and cause full scans |
| `51_High Aggregate Duration` | Query Store historical analysis of highest aggregate duration queries over the last hour |
| `53_Resumable Index Rebuild` | Status of any in-progress resumable index rebuild operations with completion percentage |
| `Find Indexes Not In Use` | Nonclustered indexes with low reads relative to writes, with a ready-to-run `DROP INDEX` statement |
| `Find Tables Without Primary Keys` | Heap tables (no clustered index) with read/write stats and row counts |
| `Finding and Eliminating Duplicate or Overlapping Indexes` | Identifies duplicate or overlapping indexes by comparing key column lists |
| `Queries in the Plan Cache That Are Missing an Index` | Cached plans with missing index warnings, ranked by total impact score |
| `Top 50 CPU Consuming Queries` | Top 50 queries by total CPU time across the entire instance (complements `26_Top Worker Time Queries` which is DB-scoped) |

### 2 - Quick Investigation

| Query | Description |
|-------|-------------|
| `7_Connection by IP` | Connection counts grouped by client IP address, program name, host, and login |
| `8_Avg Task Counts` | Average scheduler task counts per metric — run multiple times to detect active CPU and disk pressure |
| `9_Detect Blocking` | Current blocking chains showing blocker and waiter SQL text |
| `22_Recent Resource Usage` | CPU, IO, memory, and session metrics every 15 seconds for the last 64 minutes |
| `24_Top DB Waits` | Cumulative wait statistics for the current database since last restart or failover |
| `48_Lock Waits` | Row and page lock wait counts and durations by table and index |
| `52_Input Buffer` | Current query text for all active non-system sessions |
| `55_Geo-Replication Link Status` | Geo-replication link status and replication lag for all secondary databases |
| `56_Index_Hint` | Queries in the plan cache using forced index hints (`ForcedIndex="1"`) |
| `57_Active Requests` | Active user requests with CPU time, elapsed time, wait type, and statement text — run multiple times during an incident to track what sessions are doing |

### 3 - Perfect Tuning

| Query | Description |
|-------|-------------|
| `Perfect_Tuning` | Queries `sys.resource_stats` over the last 30 days to show avg/max CPU, IO, log write, sessions, and workers per database — identifies candidates for service tier downgrade. Runs against `master`. |

### 4 - AUTO_SHRINK

| Query | Description |
|-------|-------------|
| `AUTO_SHRINK_Check` | Reports whether `AUTO_SHRINK` is enabled for each database on the server |
| `AUTO_SHRINK_Enable` | Enables `AUTO_SHRINK` on all databases where it is currently disabled |

### 5 - compatibility_level

| Query | Description |
|-------|-------------|
| `1_Check_Compatibility_Level` | Reports the current compatibility level, state, and user access mode for the database |
| `2_Update_Compatibility_Level_160` | Updates the database compatibility level to 160 (SQL Server 2022 / Azure SQL latest) and confirms the change |

### 6 - Custom Queries

| Query | Description |
|-------|-------------|
| `Plan Cache Profiler` | Plan cache breakdown by object type (Adhoc, Proc, Prepared, etc.) as % of total entries |
| `Single Used Plan` | Ratio of single-use vs reused plans — high single-use % indicates plan cache bloat |
| `Execution Count` | All queries with execution count = 1 — potential contributors to plan cache bloat |

---

## Query Attribution

The majority of queries in categories 1 and 2 are based on **Glenn Berry's Azure SQL Database Diagnostic Information Queries** ([glennsqlperformance.com](https://glennsqlperformance.com/resources/)), adapted and extended with:

- An **`Info` column** added to every result set, providing inline context about what the query measures and how to interpret results — useful when results are shared as Excel files.
- **Extended text truncation** — `[Short Query Text]` columns use 100 characters instead of 50.
- **Enhanced CASE statements** — e.g. `vlf_status` decoded to human-readable descriptions, memory clerk types explained inline.
- **Custom rewrites** — notably Query 37 (Missing Indexes) dynamically generates a ready-to-run `CREATE INDEX` statement, and Query 40 (Table Sizes) adds `ObjectType`, `IndexType`, and `Bytes/Row`.
- **Custom queries** not present in Glenn Berry's script: implicit conversions (Query 50), index hints (Query 56), and everything in the Custom Queries category.

---

## Usage Example

```powershell
# Run from the root of the project
& '.\Azure SQL Tool.ps1'
```

```
Welcome to AzureSQLTool
What do you want to do? Choose a number
1 Performances
2 Quick Investigation
3 Perfect Tuning
4 AUTO_SHRINK
5 Custom Queries
Enter your choice (1-5): 1
Choose a Subscription (you can use wildcard *): Production*
Choose a Server (you can use wildcard *): sql-prod-*
Choose a Database (you can use wildcard *): *
```

Results will be saved to the `Results\` folder.
