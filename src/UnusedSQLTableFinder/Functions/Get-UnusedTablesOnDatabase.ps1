Function Get-UnusedTablesOnDatabase {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ServerInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Database

    )
  
    $query = @"
            
    ;with TableUsage
 as (select     schema_name(o.schema_id) as [Schema]
               ,object_name(i.object_id) [Table]
               ,sum(s.user_seeks) + sum(s.user_scans) + sum(s.user_lookups) as [TotalReads]
               ,sum(s.user_updates) as [TotalWrites]
               ,max(s.last_user_scan) as LastUserScan
               ,max(s.last_user_lookup) as LastUserLookup
               ,max(s.last_user_seek) as LastUserSeek
     from       sys.indexes as i with (nolock)
     join       sys.objects as o
     on         o.object_id = i.object_id

     left join  sys.dm_db_index_usage_stats as s with (nolock)
     on         i.[object_id] = s.[object_id]
     and        i.index_id = s.index_id
     and        s.database_id = db_id()
     where      objectproperty(i.[object_id], 'IsUserTable') = 1
     group by   schema_name(o.schema_id)
               ,object_name(i.object_id))
select      concat(tu.[Schema], '.', tu.[Table]) as SchemaTable
           ,tu.[Schema]
           ,tu.[Table]
from        TableUsage tu
where       tu.TotalReads is null
and         tu.TotalWrites is null
and         tu.LastUserScan is null
and         tu.LastUserLookup is null
and         tu.LastUserSeek is null
order by    tu.[Table] asc;
        
"@

    try {

        $UnusedTables = Invoke-Sqlcmd -ServerInstance $ServerInstance -query $query -QueryTimeout 60 -Database $Database -ErrorAction Stop

        return $UnusedTables
        
    }
    
    catch {
        Write-Error "Failed to retrieve table stats from Server: $ServerInstance"
        Write-Error "Error Message: $_.Exception.Message"
        exit
    }

    
    
}