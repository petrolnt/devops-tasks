#This script was designed for sync a Windows folder with remote a Linux folder by using WinSCP Automation
#It monitored $folder for creating new files and copy files that created in $folder to remote $linuxFolder
#For autorun this script you need add this script in TaskScheduler with "At system startup" trigger, specify a start account as System
#String for Action: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -File C:\test\script\WinSCPSync.ps1"
Param(
        $folder = "c:\test\winscp\",
        $linuxFolder = "/home/testuser/winscp/",
        $filter = "*.*",
        $archiveFolder = "c:\test\archive\",
        $username = "testuser",
        $password = "1q2w3e4r",
        $hostname = "alfresco",
        $winscpPath = "C:\test\script\WinSCP-5.9.3-Automation\WinSCPnet.dll",
        $fingerprint = "ssh-ed25519 256 50:ad:ce:db:e8:62:72:cf:10:6b:00:e1:bb:cd:96:11"
)
#Register FileSystemWatcher
$fsw = New-Object IO.FileSystemWatcher #$folder, $filter -Property @{IncludeSubdirectories = $false;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 
$fsw.Path = $folder
$fsw.Filter = $filter
$fsw.EnableRaisingEvents = $true
$fsw.IncludeSubdirectories = $false
Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {
     try{
       # Load WinSCP .NET assembly
        Add-Type -Path $winscpPath
        #Setup session options
        $sessionOptions = New-Object WinSCP.SessionOptions
        #$sessionOptions.ParseUrl($sessionURL)
        $sessionOptions.UserName = $username
        $sessionOptions.Password = $password
        $sessionOptions.Protocol = [WinSCP.Protocol]::Sftp
        $sessionOptions.HostName = $hostname
        #Highly recommend use SshHostKeyFingerprint for safety from MITM-attack
#       $sessionOptions.SshHostKeyFingerprint = $fingerprint

        #No secure connection, use for example only
        $sessionOptions.GiveUpSecurityAndAcceptAnySshHostKey = $True

        $session = New-Object WinSCP.Session
 
        try{
            # Connect
            $session.Open($sessionOptions)
 
            # Upload files
            $transferOptions = New-Object WinSCP.TransferOptions
            $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
 
            $transferResult = $session.PutFiles(($folder + "*"), $linuxFolder, $False, $transferOptions)
 
            # Throw on any error
            $transferResult.Check()
 
            # Print results
            #foreach ($transfer in $transferResult.Transfers)
            #{
            #    Write-Host ("Upload of {0} succeeded" -f $transfer.FileName)
            #}
        }
        finally
        {
            # Disconnect, clean up
            $session.Dispose()
        }

        Move-Item ($folder + $filter) $archiveFolder -Force
        exit 0
        
    }
    catch [Exception]
    {
        #Write-Host ("Error: {0}" -f $_.Exception.Message)
    
        exit 1
    }
}

#for unregister FileSystemWatcher
#Unregister-Event FileCreated

