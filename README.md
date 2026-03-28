# Azure SQL Tool

A PowerShell-based diagnostic and analysis tool for Azure SQL databases. It authenticates to Azure, lets you pick a category of SQL queries, filters targets by subscription/server/database, executes the queries, and exports the results to Excel or CSV files.

---

## Prerequisites

- **PowerShell** with the following modules installed:
  - `Az` (Azure PowerShell) — `Install-Module Az`
  - `SqlServer` — `Install-Module SqlServer`
  - `ImportExcel` — `Install-Module ImportExcel`
- Permissions to read Azure SQL resources in the target subscriptions
- A `Results\` folder in the same directory as the script (created automatically for the AUTO_SHRINK sub-tool)

---

## How It Works — `Azure SQL Tool.ps1`

### 1. Authentication

The script starts by calling `Connect-AzAccount`, which prompts you for interactive Azure login. It then retrieves an Azure AD access token scoped to `https://database.windows.net`, used to authenticate all SQL queries without needing SQL credentials.

### 2. Task Selection Menu

You are presented with five categories to choose from:

| # | Category | Description |
|---|----------|-------------|
| 1 | Performances | Performance-related diagnostics (I/O, buffer, indexes, wait stats, query stats, etc.) |
| 2 | Quick Investigation | Blocking detection, lock waits, geo-replication status, resumable index rebuilds, etc. |
| 3 | DB Tier Down | Evaluates whether Azure SQL databases can be downgraded to a lower service tier |
| 4 | AUTO_SHRINK | Checks if AUTO_SHRINK is enabled on databases |
| 5 | Custom Queries | Ad hoc queries (plan cache analysis, duplicate indexes, missing indexes, etc.) |

### 3. Target Filtering

After picking a category, you enter three filter values that support wildcard (`*`) patterns:

- **Subscription** — matches Azure subscriptions by name
- **Server** — matches Azure SQL servers by name
- **Database** — matches databases by name (not applicable for option 3)

### 4. Query Execution

The script iterates through all subscriptions → servers → databases that match the filters and runs every `.sql` file found in the corresponding `Queries\<category>\` folder.

- Files are executed in **natural sort order** (numeric prefix of the filename).
- Queries run using `Invoke-Sqlcmd` with the Azure AD token — no passwords required.

### 5. Output

| Category | Output format | File location |
|----------|--------------|---------------|
| 1, 2, 4, 5 | Excel (`.xlsx`), one worksheet per query | `.\Results\<Category>_<DatabaseName>_<Date>.xlsx` |
| 3 (DB Tier Down) | CSV (`.csv`), appended across all servers | `.\Results\DB_Tier_Down.csv` |

- Excel files use `Export-Excel` with `AutoSize` columns.
- Each worksheet is named after the query file.
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

### 3 - DB Tier Down
Runs against the `master` database and queries `sys.resource_stats` to show average/max CPU, I/O, log write, session, and worker percentages over the last 30 days — helping identify databases that could be moved to a lower service tier.

### 4 - AUTO_SHRINK
Checks whether `AUTO_SHRINK` is enabled on databases (via `sys.databases`).

### 5 - Custom Queries
Plan cache profiling, single-use plans, duplicate/overlapping indexes, missing indexes, indexes not in use, tables without primary keys, queries using a specific index, and implicit conversions.

---

## Usage Example

```powershell
# Run from the root of the project
.\Azure SQL Tool.ps1
```

```
Welcome to AzureSQLTool
What do you want to do? Choose a number
1 Performances
2 Quick Investigation
3 DB Tier Down
4 AUTO_SHRINK
5 Custom Queries
Enter your choice (1-5): 1
Choose a Subscription (you can use wildcard *): Production*
Choose a Server (you can use wildcard *): sql-prod-*
Choose a Database (you can use wildcard *): *
```

Results will be saved to the `Results\` folder.
