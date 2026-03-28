DECLARE @DBName NVARCHAR(128);

-- Declare a cursor to iterate through databases that need AUTO_SHRINK enabled
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE name <> 'master' AND is_auto_shrink_on = 0;

-- Open the cursor
OPEN db_cursor;

-- Fetch the first database name
FETCH NEXT FROM db_cursor INTO @DBName;

-- Loop through all fetched database names
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Construct and execute the ALTER DATABASE statement
    EXEC('ALTER DATABASE [' + @DBName + '] SET AUTO_SHRINK ON;');

    -- Fetch the next database name
    FETCH NEXT FROM db_cursor INTO @DBName;
END

-- Close and deallocate the cursor
CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Select the updated status of the databases
SELECT 
    @@SERVERNAME AS ServerName,
    name,
    is_auto_shrink_on
FROM 
    sys.databases
WHERE 
    name <> 'master' AND is_auto_shrink_on = 1;
