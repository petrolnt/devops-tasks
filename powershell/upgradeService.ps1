#This script designed for upgrade Windows Service from .7z archive.
#This will be start upgradeService.ps1 "serviceName" "serviceHomeFolder" "pathToArchive"
Param(
          [Parameter(Mandatory=$true)]
          [string]$serviceName,
          [Parameter(Mandatory=$true)]
          [string] $serviceHomeFolder,
          [Parameter(Mandatory=$true)]
          [string] $pathToArch
)
$tempfolder = 'c:\7ztmp\'
$maiMessage = ""

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
#if 7zip not found
if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {
    $mailMessage = "7Zip not found on this computer. Please install 7zip or specify custom path to 7zip.exe and try again.`r`n"
    sendEmail $mailMessage
    }
    else{
        set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"  
    }
#get service by name and try to stop it
$service = Get-Service | Where-Object{$_.Name -eq $serviceName}
if($service.status -eq "Running"){
    Try{
        $service.Stop();
        $service.WaitForStatus("Stopped", "00:00:30")
    }
#If service not replyed in timeout 30 seconds
    Catch{
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $mailMessage = "Error during stop the service. Service not respond in timeout 30 seconds.`r`n" + $_.Exception.Message + $_.Exception.ItemName + "`r`n"
        sendEmail $mailMessage
    }
}
#if the service was not running during start-up script 
else{
    $mailMessage = "The service " + $serviceName + " not running, try to update and start it...`r`n"
    Write-Host "Service status: " $service.Status
    }
#Trying create temporary folder for extracting files from archive
Try{
    if(Test-Path $tempfolder){Remove-Item $tempfolder}
    New-Item $tempfolder -ItemType Directory
    }Catch{
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $mailMessage += "Cannot create folder " + $tempfolder + "`r`n" + $_.Exception.Message + $_.Exception.ItemName + "`r`n"
    }
if(Test-Path $pathToArch){
    sz x $pathToArch ('-o' + $tempfolder)
    }
else{
    $mailMessage += "Archive with upgrading files not found"
    sendEmail $mailMessage
}
#Trying copy and replace service files and send email if get exception
Try{
    Copy-Item -Path ($tempfolder + '*') -Destination $serviceHomeFolder -Recurse -Force
    If($mailMessage.Length -gt 0){
        $mailMessage += "Files of service has been updated.`r`n"
        }
    }
    #If can not update files you first start the service and then send a message
Catch{
     $mailMessage += "Cannot copy or replace the service files.`r`n"  + $_.Exception.Message + $_.Exception.ItemName + "`r`n"
    }

#remove temporary folder
Remove-Item -Path $tempfolder -Recurse -Force

#Trying start the service and waiting 30 seconds, if service not started in this timeout we get exception and we send message
Try{
    $service.Start()
    $service.WaitForStatus("Running", "00:00:30")
    If($mailMessage.Length -gt 0){
        $mailMessage += "Service " + $serviceName + " has been started."
        }
}
Catch{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $mailMessage += "Error during start the service. Service not respond in time out.`r`n" + $_.Exception.Message + $_.Exception.ItemName + "`r`n"
    sendEmail $mailMessage
}

#If, during the execution of the script there are non critical errors, the operation will continue until the end of the script, but the error message will be sent.
if($mailMessage.Length -gt 0){
    sendEmail $mailMessage
    }


