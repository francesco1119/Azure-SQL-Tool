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
| 3 | Azure SQL Database Perfect Tuning | Evaluates whether Azure SQL databases can be downgraded to a lower service tier |
| 4 | AUTO_SHRINK | Checks if AUTO_SHRINK is enabled on databases |
| 5 | Custom Queries | Ad hoc queries (plan cache analysis, duplicate indexes, missing indexes, etc.) |

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
| 3 (Azure SQL Database Perfect Tuning) | CSV (`.csv`), appended across all servers | `.\Results\Azure_SQL_Database_Perfect_Tuning.csv` |

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
IO stalls, buffer usage, connection stats, wait stats, index fragmentation, missing indexes, query execution stats, stored procedure stats, columnstore indexes, volatile indexes, implicit conversions, and more.

### 2 - Quick Investigation
Blocking detection, lock waits, top DB waits, high aggregate duration queries, geo-replication link status, resumable index rebuilds, index hints.

### 3 - Azure SQL Database Perfect Tuning
Runs against the `master` database and queries `sys.resource_stats` to show average/max CPU, I/O, log write, session, and worker percentages over the last 30 days — helping identify databases that could be moved to a lower service tier.

### 4 - AUTO_SHRINK
Checks whether `AUTO_SHRINK` is enabled on databases (via `sys.databases`).

### 5 - Custom Queries
Plan cache profiling, single-use plans, duplicate/overlapping indexes, missing indexes, indexes not in use, tables without primary keys, queries using a specific index, and implicit conversions.

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
3 Azure SQL Database Perfect Tuning
4 AUTO_SHRINK
5 Custom Queries
Enter your choice (1-5): 1
Choose a Subscription (you can use wildcard *): Production*
Choose a Server (you can use wildcard *): sql-prod-*
Choose a Database (you can use wildcard *): *
```

Results will be saved to the `Results\` folder.
