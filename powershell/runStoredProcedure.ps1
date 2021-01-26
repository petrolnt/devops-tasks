#This script   was designed for cleaning table in MS SQL database for VMWare Vcenter. It run the stored procedure in database for this goal.

function getDBAvailSize{
    $sqlCmd.CommandText = "SELECT size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB FROM sys.database_files where name = 'VIM_VCDB_dat';"
    $dbAvailSpace = $SqlCmd.ExecuteScalar()
    return $dbAvailSpace
}

function cleanUpEvents{
    $SqlCmd.CommandText = "cleanup_events_tasks_proc"
    
    $SqlCmd.CommandType = [System.Data.CommandType]'StoredProcedure'
    
    $result = $SqlCmd.ExecuteNonQuery()
    if($result -eq -1){
        $newAvailSize = getDBAvailSize
        $message += "Procedure 'cleanup_events_tasks_proc' succesfully completed new available size is " + $newAvailSize + "`n"
        }
    }
#Function for send email
function sendEmail($message){
    ###Credentials#################
    $username = "Your_email@sendgrid.com"
    $password = "Your_password"
    ###############################
    $EmailTo = "Mail_To_Address"
    $EmailFrom = "Mail_From_Address"
    $Subject = "Upgrade service " + $serviceName
    $Body = $message
    $SMTPServer = "aspmx.l.google.com" 
    $SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom,$EmailTo,$Subject,$Body)
    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
    $SMTPClient.EnableSsl = $true 
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password); 
    $SMTPClient.Send($SMTPMessage)
    Exit-PSSession
}

#Max size for express database in megabytes
$dbMaxSize = 10260
#Max size for transaction log
$logMaxSize = 1024
#connection parameters
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = VCENTER\VIM_SQLEXP; Database = VIM_VCDB; Integrated Security = True;"
$SqlConnection.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.Connection = $SqlConnection
$sqlCmd.CommandTimeout = 0

$message = ""
if((getDBAvailSize)/$dbMaxSize -le 0.1){
    $message += "The database vmvare have less than 10% free space, it will start the stored procedure 'cleanup_events_tasks_proc'...`n"
    cleanUpEvents

}

#Select transaction log available free space
$sqlCmd.CommandText = "SELECT size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB FROM sys.database_files where name = 'VIM_VCDB_log';"
$logAvailSpace = $SqlCmd.ExecuteScalar()

if($logAvailSpace/$logMaxSize -le 0.1){
    $message += "Tranzaction log available space is less then 10% from max size. Require administrator involvement`n"
}

#If, during the execution of the script there are non critical errors, the operation will continue until the end of the script, but the error message will be sent.
if($message.Length -gt 0){
    sendEmail $message
    }

$SqlConnection.Close()
