/*
List Statements with the Highest Execution Counts

Description

Sample script that lists the top 50 statements by execution counts. This script requires Microsoft SQL Server 2005. 

Script Code


*/

SELECT TOP 50
        qs.execution_count,
        SUBSTRING(qt.text,qs.statement_start_offset/2, 
			(case when qs.statement_end_offset = -1 
			then len(convert(nvarchar(max), qt.text)) * 2 
			else qs.statement_end_offset end -qs.statement_start_offset)/2) 
		as query_text,
		qt.dbid, dbname=db_name(qt.dbid),
		qt.objectid 
FROM sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY 
        qs.execution_count DESC

