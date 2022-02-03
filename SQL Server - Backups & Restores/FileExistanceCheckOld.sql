SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

CREATE TABLE #temp (op_text varchar(max) );

DECLARE @FileName varchar(max);
DECLARE @LIVEFileName varchar(max);
DECLARE @DRFileName varchar(max);
DECLARE @ServerName varchar(max);
DECLARE @BackupDetailID int;
DECLARE @cmd sysname;
DECLARE @LIVEFileExistsCounter int;
DECLARE @DRFileExistsCounter int;
DECLARE @LIVEFileNotExistsCounter int;
DECLARE @DRFileNotExistsCounter int;
DECLARE @TotalFilesCounter int;

DECLARE BackupFile CURSOR FOR
SELECT 
	BackupDetailID
	,ServerName
	,CASE WHEN CHARINDEX(':',BackupFileName,1) > 0
		 THEN '\\'+ CASE WHEN CHARINDEX('\',ServerName,1)>0 
						 THEN SUBSTRING(ServerName,1,CHARINDEX('\',ServerName,1)-1)+SUBSTRING(BackupFileName, CHARINDEX(':',BackupFileName,1)+1, len(BackupFileName))
						 ELSE ServerName+SUBSTRING(BackupFileName, CHARINDEX(':',BackupFileName,1)+1, len(BackupFileName))
					END
		 WHEN CHARINDEX('$',BackupFileName,1) > 0 AND CHARINDEX('\\',BackupFileName,1) > 0
		 THEN SUBSTRING(BackupFileName,1,CHARINDEX('$',BackupFileName,1)-3)+
				SUBSTRING(BackupFileName, CHARINDEX('$',BackupFileName,1)+1, len(BackupFileName))
		 ELSE BackupFileName
	END AS LIVEBackupFile
	,CASE WHEN CHARINDEX(':',BackupFileName,1) > 0
		 THEN '\\'+ CASE WHEN CHARINDEX('\',ServerName,1)>0 
						 THEN 'DR'+ SUBSTRING(ServerName,1,CHARINDEX('\',ServerName,1)-1)+SUBSTRING(BackupFileName, CHARINDEX(':',BackupFileName,1)+1, len(BackupFileName))
						 ELSE 'DR'+ ServerName+SUBSTRING(BackupFileName, CHARINDEX(':',BackupFileName,1)+1, len(BackupFileName))
					END
		 WHEN CHARINDEX('$',BackupFileName,1) > 0 AND CHARINDEX('\\',BackupFileName,1) > 0
		 THEN 'DR'+ SUBSTRING(BackupFileName,1,CHARINDEX('$',BackupFileName,1)-3)+
				SUBSTRING(BackupFileName, CHARINDEX('$',BackupFileName,1)+1, len(BackupFileName))
		 ELSE BackupFileName
	END AS DRBackupFile
	,REVERSE(SUBSTRING(REVERSE(BackupFileName),1,CHARINDEX('\',REVERSE(BackupFileName),1)-1)) 
FROM DBREFS..t_Backup_Details 
WHERE BackupFinishDate Between DateAdd(hh,-24,GetDate()) And GetDate();

OPEN BackupFile;

FETCH NEXT FROM BackupFile INTO @BackupDetailID,@ServerName,@LIVEFileName,@DRFileName,@FileName;

SET @LIVEFileExistsCounter = 1;
SET @LIVEFileNotExistsCounter = 1;
SET @DRFileExistsCounter = 1;
SET @DRFileNotExistsCounter = 1;
SET @TotalFilesCounter = 1;

WHILE @@fetch_status = 0 
BEGIN
	SET @cmd = 'dir ' + @LIVEFileName;
	--PRINT @cmd
	DELETE FROM #temp;
	INSERT INTO #temp EXECUTE master..xp_cmdshell @cmd;

	IF EXISTS (SELECT * FROM #temp WHERE op_text like'%.bak%')
	BEGIN
		PRINT @ServerName +' -> File '+ @LIVEFileName +' exists.';
		UPDATE DBREFS..t_Backup_Details SET FileExists = 1 
			WHERE BackupDetailID = @BackupDetailID;
		SET @LIVEFileExistsCounter = @LIVEFileExistsCounter + 1;
	END
	ELSE
	BEGIN
		PRINT @ServerName + ' -> File '+ @LIVEFileName +' does not exists.';
		SET @LIVEFileNotExistsCounter = @LIVEFileNotExistsCounter + 1;
	END

--	SET @cmd = 'dir ' + @DRFileName;
--	--PRINT @cmd
--	DELETE FROM #temp;
--	INSERT INTO #temp EXECUTE master..xp_cmdshell @cmd;
--
--	IF EXISTS (SELECT * FROM #temp WHERE op_text like'%.bak%')
--	BEGIN
--		PRINT @ServerName +' -> File '+ @DRFileName +' exists.';
----		UPDATE DBREFS..t_Backup_Details SET FileCopied = 1 
----			WHERE BackupDetailID = @BackupDetailID;
--		SET @DRFileExistsCounter = @DRFileExistsCounter + 1;
--	END
--	ELSE
--	BEGIN
--		PRINT @ServerName + ' -> File '+ @DRFileName +' does not exists.';
--		SET @DRFileNotExistsCounter = @DRFileNotExistsCounter + 1;
--	END

	SET @TotalFilesCounter = @TotalFilesCounter + 1;

	FETCH NEXT FROM BackupFile INTO @BackupDetailID,@ServerName,@LIVEFileName,@DRFileName,@FileName;
END
CLOSE BackupFile;
DEALLOCATE BackupFile;
PRINT 'No. of Files Exists = ' + Cast(@LIVEFileExistsCounter As varchar(10));
PRINT 'No. of Files Do Not Exists = ' + Cast(@LIVEFileNotExistsCounter As varchar(10));
PRINT 'Total No. of Files = ' + Cast(@TotalFilesCounter As varchar(10));

IF EXISTS (SELECT * FROM [tempdb]..[#temp])
	DROP TABLE [tempdb]..[#temp];
GO
SET NOCOUNT OFF
GO
