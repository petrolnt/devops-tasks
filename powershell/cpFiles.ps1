#This script well copy files from local folders to remote folders
#Start that: cpFiles.ps1 "connectionString" "query" "rootLocalFolder" "remoteFolder"
#Or just replace default values bellow and start: cpFiles.ps1
param(
    [string]$connectionString = "Server = WIN10-DEVEL; Database = testdb; Integrated Security = True;",
    [string]$query = "SELECT computer_name FROM computers;",
    [string]$rootLocalFolder = "c:\testFolder",
    [string]$remoteFolder = "c$\remoteFolder"
)
#get computers names from database
function getComputerNames {
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection 
    $connection.ConnectionString = $connectionString
    $adapter = new-object system.data.sqlclient.sqldataadapter ($query, $connection)
    $table = new-object system.data.datatable 
    $adapter.Fill($table) | out-null
    return $table
}
#get last folder name
function getLastFolder {
#for get last folder by name
    $dirs = Get-ChildItem $rootLocalFolder | where {$_.Attributes -eq 'Directory'}
    $dirs[$dirs.lenght-1]
#or for get last modified folder
    #Get-ChildItem -Path $rootLocalFolder | Where-Object {$_.PSIsContainer} |Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

#write error log
function writeErrorLog($message){
    $logFileName = (Resolve-Path .\).Path + "\" + "ErrorLog-" + (Get-Date -Format dd_MM_yy) + ".txt"
    if(-Not(test-path $logFileName)){
       New-Item $logFileName
        }
    $message | Out-File $logFileName -Append
}
#get Array with computer names
$compArray = @(getComputerNames | select -ExpandProperty computer_name)
#get full path to local folder
$localFolder = $rootLocalFolder + "\" + (getLastFolder) + "\*"
#for each computer perform copying files
ForEach($item in $compArray){
    $remotePath = "\\" + $item + "\" + $remoteFolder
    if(-Not(test-path $remotePath)){
        Try{
            New-Item $remotePath -type directory
        }Catch{
            $msg = "Cannot create folder on remote path " + $remotePath + ".`r`n" + $_.Exception.Message + $_.Exception.ItemName + "`r`n"
            writeErrorLog $msg
        }
        
    }
   
    #Trying copy and replace files and write log if get exception
    Try{
        Copy-Item -Path $localFolder -Destination $remotePath -Recurse -Force
    }Catch{
        $msg += "Cannot copy or replace files.`r`n"  + $_.Exception.Message + $_.Exception.ItemName + "`r`n"
        writeErrorLog $msg
        }
    }

