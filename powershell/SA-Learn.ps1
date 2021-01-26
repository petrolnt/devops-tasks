#This script was designed for copy email messages in MSG format from windows remote folder, copy it to linux server where Exim are installed, convert this messages to EML format and run sa-learn on it, for learning BAYES
#This script used WinSCPnet.dll library
#REQUIREMENTS: on linux server should be installed msgconvert, see https://github.com/mvz/msgconvert
Param(
    $remoteSpamFolder = "\\remotecomputer\remotefolder",
    $localSpamFolder = "",
    $eximServer = "mx1.mudomain.ru",
    [Parameter(Mandatory=$true)]
    $eximUsername,
    [Parameter(Mandatory=$true)]
    $eximPassword,
    $winscpPath = "",
    $eximSpamFolder = "/tmp/spam/"
)
#create path to winscp
if($winscpPath -eq ""){
    $winscpPath = Join-Path $PSScriptRoot "WinSCPnet.dll"
}
#temp directory on local computer
if ($localSpamFolder -eq ""){
    $localSpamFolder = Join-Path -Path $env:TEMP "spam"
}
#create dir if not exists
if(-not (Test-Path $localSpamFolder)){
    New-Item -ItemType Directory -Path $localSpamFolder | Out-null
}
#list files in the remote folder
$files = Get-ChildItem -Path $remoteSpamFolder -Filter "*.msg"
#if files exixts
if($files.Length -gt 0){
    #moving files from remote folder to local path with renaming
    $count = 1
    foreach($f in $files){
        try{
            $newFilename = $count.ToString() + ".msg"
            Move-Item $f.FullName (Join-Path $localSpamFolder $newFilename)
        }
        catch [Exeception]{
            Write-Host ("Error in moving file: {0}" -f $_.Exception.Message)
        }
        $count++
    }
    $localFiles = Get-ChildItem -Path $localSpamFolder -Filter "*.msg"
    #import winscp library
    Add-Type -Path $winscpPath
    #Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.UserName = $eximUsername
    $sessionOptions.Password = $eximPassword
    $sessionOptions.Protocol = [WinSCP.Protocol]::Sftp
    $sessionOptions.HostName = $eximServer
    $sessionOptions.GiveUpSecurityAndAcceptAnySshHostKey = $True
    $session = New-Object WinSCP.Session
    try{
        # Connect
        $session.Open($sessionOptions)
 
        # Upload files
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
        $transferResult = $session.PutFiles((Join-Path $localSpamFolder "*"), $eximSpamFolder , $False, $transferOptions)
 
        # Throw on any error
        $transferResult.Check()

        #remove the local folder after copying
        Remove-Item -Path $localSpamFolder -Force

        #converting files to eml format on the linux server
        $dirList = $session.ListDirectory($eximSpamFolder)
        foreach($f in $dirList.Files){
            if($f.FileType -eq "-"){
                $filePath = $f.FullName
                $emlFile = $f.FullName.Split(".")[0] + ".eml"
                $command = "/usr/local/bin/msgconvert --mbox $emlFile $filePath"
                $res = $session.ExecuteCommand($command)
                if($res.ExitCode -eq 0){
                    Write-Host "The file $filePath was succesfully converted to EML format and saved as $emlFile"
                }
                else{
                    Write-Host "Error in converting $filePath to EML format:"
                    Write-Host $res.ErrorOutput
                    Write-Host "Failures: "$res.Failures
                }

                #remove msg file
                $res = $session.RemoveFiles($f.FullName)
                if($res.IsSuccess -eq $True){
                    Write-Host "The file $filePath was succesfully removed"
                }
                else{
                    Write-Host "Error in removing $filePath :"
                    Write-Host "Error output: "$res.ErrorOutput
                    Write-Host "Failures: "$res.Failures
                }
            }
        }

        #run sa-learn for learning SpamAssassin
        $sacommand = "/usr/bin/sa-learn --spam $eximSpamFolder"
        $res = $session.ExecuteCommand($sacommand)
        if($res.ExitCode -eq 0){
            Write-Host "The file $filePath was succesfully removed"
        }
        else{
            Write-Host "Error in removing $filePath :"
            Write-Host "Error output: "$res.ErrorOutput
            Write-Host "Failures: "$res.Failures
        }
        $res
    }
    catch [Exception]{
        Write-Host ("Error: {0}" -f $_.Exception.Message)
        exit 1
    }
    finally{
        # Disconnect, clean up
        $session.Dispose()
    }
}