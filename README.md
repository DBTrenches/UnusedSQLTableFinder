# UnusedSQLTableFinder
Run analysis against a SQL Server database and its replicas to find unused tables. Queries sys.dm_db_index_usage_stats to get usage stats. The tool also filters out any tables that is a parent in a foreign key relationship. Outputs to csv.

## Example Usage

```powershell
Import-Module .\src\UnusedSQLTableFinder -Force

$PrimaryServerInstance = "myprimaryserver.prod"
$ReplicasToCheck = @("replica1.prod","replica2.prod")
$Database = "MyDB1"
$OutputFolderPath = 'C:\UnusedTables'

Get-AllUnusedTables -PrimaryServerInstance $PrimaryServerInstance `
                        -Database $Database `
                        -ReplicaServerInstanceList $ReplicasToCheck `
                        -OutputFolderPath $OutputFolderPath

```

