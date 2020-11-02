Function Get-IsParentFKTable {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ServerInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Schema,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Table

    )
  
    $query = @"
            
    select top 1 
        @@ServerName as ServerName
        ,'$Schema'+'.'+'$Table' as SchemaTable
        ,'$Schema' as [Schema]
        ,'$Table' as [Table]
        ,case
            when SO_R.name = '$Table' and schema_name(SO_R.schema_id) = '$Schema' then 'Parent'
            else 'Child'
        end as 'Relationship'
        ,schema_name(SO_P.schema_id) as [ChildSchema]
        ,SO_P.name as [ChildTable]
        ,schema_name(SO_R.schema_id) as [ReferencedSchema]
        ,SO_R.name as [ReferencedTable]
        ,SC_R.name as [ReferencedColumn]
        ,OBJECT_NAME(FKC.constraint_object_id) AS [ConstraintObject]
        from sys.foreign_key_columns FKC
        inner join sys.objects SO_P on SO_P.object_id = FKC.parent_object_id
        inner join sys.columns SC_P on (SC_P.object_id = FKC.parent_object_id) AND (SC_P.column_id = FKC.parent_column_id)
        inner join sys.objects SO_R on SO_R.object_id = FKC.referenced_object_id
        inner join sys.columns SC_R on (SC_R.object_id = FKC.referenced_object_id) AND (SC_R.column_id = FKC.referenced_column_id)
        where
            (
            ((SO_P.name = '$Table') and (schema_name(SO_P.schema_id) = '$Schema') AND (SO_P.type = 'U'))
            OR
            ((SO_R.name = '$Table') and (schema_name(SO_R.schema_id) = '$Schema') AND (SO_R.type = 'U'))
            )
            AND
            SO_R.name = '$Table' and schema_name(SO_R.schema_id) = '$Schema' --Return only if this table is a parent
        
"@

    try {

        $TableFK = Invoke-Sqlcmd -ServerInstance $ServerInstance -query $query -QueryTimeout 60 -Database $Database -ErrorAction Stop

        return $TableFK
        
    }
    
    catch {
        Write-Error "Failed to retrieve FK tables from Server: $ServerInstance for [$Schema - $Table]"
        Write-Error "Error Message: $_.Exception.Message"
        exit
    }

    
    
}