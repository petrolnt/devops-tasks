#This script was designed for silently and remote/local installation of MongoDB
#You can start it with parameters: ./installMongo.ps1 -serverName mongoServer -pathToMSI c:\path\to\package -pathToDB c:\path\to\db and etc.
#Or you can replace parameters in "param" block below and start it without parameters,
#If serverName not defined then script run installation to the local computer

param(
    [string]$serverName = "",
    [string]$pathToMSI = "C:\distr\mongodb-win32-x86_64-2008plus-ssl-3.2.10-signed.msi",
    [string]$pathToDB = "c:\data\",
    [string]$installocation = 'C:\Program Files\MongoDB\Server\3.2\',
    [string]$addlocal = '"all"', #ADDLOCAL may be: Server, Router, Client, MonitoringTools, ImportExportTools, MiscellaneousTools
    [string]$sharedFolder = "e:\test"
)

#function implemented all instalation process
function installMongo($msiPackage){
  try{  

    #start process of instalation
    Write-Host "Start process of instalation"
    $instResult = Invoke-WmiMethod -Class Win32_Process -ComputerName $serverName -Name `
    Create -ArgumentList ("msiexec.exe /q /i  " + $msiPackage + " " + $instalationKeys)

    #Wait 30 seconds until the program is installed
    Write-Host "Wait 30 seconds until the program is installed..."
    Start-Sleep 30

    #create folders for database and logs
    Write-Host "Creating folders for database and logs..."
    $remoteDataFolder = "\\" + $serverName + "\" + $pathToDB.Replace(":", "$") + "\"
    if(!(Test-Path $remoteDataFolder)){
        New-Item $remoteDataFolder -ItemType Directory  -ErrorAction Stop | Out-Null
        New-Item ($remoteDataFolder + "\log") -ItemType Directory  -ErrorAction Stop | Out-Null
        New-Item ($remoteDataFolder + "\db") -ItemType Directory  -ErrorAction Stop | Out-Null
        }

    #create config file with content
    Write-Host "Create config file with default content"
    $configFile = "\\" + $serverName + "\" + $installocation.Replace(":","$") + "mongod.cfg"
    $content = "systemLog:`r`n    destination: file`r`n    path: " + $pathToDB + "log\mongod.log`r`nstorage:`r`n    dbPath: " + $pathToDB + "db`r`n"
    Set-Content  $configFile $content -Force -ErrorAction Stop
    Write-Host "Instalation MongoDB as service"
    $instService = Invoke-WmiMethod -Class Win32_Process -ComputerName $serverName -Name Create `
-ArgumentList ('"' + $installocation + 'bin\mongod.exe" --config "' + $installocation + 'mongod.cfg" --install')

    #wait until service is installed
    Write-Host "Wait 10 seconds until service is started..."
    Start-Sleep 10

    #add rule in to firewall
    Write-Host "Add rule to firewall" 
    $addRuleRes = Invoke-WmiMethod -Class Win32_Process -ComputerName $serverName -Name Create `
-ArgumentList ('C:\Windows\System32\cmd.exe /C netsh advfirewall firewall add rule name="Allow MongoDB" dir=in action=allow protocol=TCP localport=27017')

    #start service
    Write-Host "Starting service"
    $startResult = Invoke-WmiMethod -Class Win32_Process -ComputerName $serverName -Name `
Create -ArgumentList ("C:\Windows\System32\cmd.exe /C net start MongoDB")

     Write-Host "Creating share folder"
    $remSharedFolder = "\\" + $serverName + "\" + $sharedFolder.Replace(":", "$")
    If(!(Test-Path $remSharedFolder)){
           New-Item $remSharedFolder -ItemType Directory -ErrorAction Stop | Out-Null
        }
    $sharedFolderRes = Invoke-WmiMethod -Class Win32_Process -ComputerName $serverName -Name Create `
-ArgumentList ('C:\Windows\System32\cmd.exe /C net share ' + ($sharedFolder.Split("\")[-1]) + '=' + $sharedFolder + ' /GRANT:"EVERYONE",FULL')
  }
  Catch{
    Write-Host "Exception in installMongo function: `r`n" + $_.Exception.Message + "`r`n"
    Exit -1
  }
  Finally{
  #remove temp local folder from server MongoDB
  Write-Host "Removing temporary local folder"
  Remove-Item -Recurse ("\\" + $serverName + "\" + (Split-Path($msiPackage.Replace(":","$"))))
  }
}

#function implemented copying instalation package to local folder with random name
function copyMSIPackage($package){
    try{
        Write-Host "Copying files"

        #get random folder name for copy distributive
        $randomFolderName = [System.IO.Path]::GetRandomFileName().Split(‘.’)[0]

        #create folder on remote MongoDB server
        $remoteFolder = "\\" + $serverName + "\c$\" + $randomFolderName
        New-Item ($remoteFolder) -ItemType Directory -ErrorAction Stop  | Out-Null
        Copy-Item $package $remoteFolder -ErrorAction Stop | Out-Null

        #return local path to msi package on remote MongoDB server
        $path = "c:\" + $randomFolderName + "\" + ($pathToMSI.Split("\")[-1])
        return $path
    } Catch{
        Write-Host "Exception in copyMSIPackage function: `r`n" $_.Exception.Message "`r`n"
        #remove temp local folder from server MongoDB
        Write-Host "Removing temporary local folder"
        if(Test-Path $remoteFolder){
            Remove-Item -Recurse $remoteFolder
            }
        Exit -1
    }
   
}

function localInstallMongo{
  try{  

    #start process of instalation
    Write-Host "Start process of instalation"
    $instResult = Start-Process -FilePath msiexec.exe -ArgumentList (" /q /i  " + $pathToMSI + " " + $instalationKeys) -WindowStyle Hidden

    #Wait 30 seconds until the program is installed
    Write-Host "Wait 30 seconds until the program is installed..."
    Start-Sleep 30

    #create folders for database and logs
    Write-Host "Creating folders for database and logs..."
    
    if(!(Test-Path $pathToDB)){
        New-Item $pathToDB -ItemType Directory -ErrorAction Stop | Out-Null
        New-Item ($pathToDB + "\log") -ItemType Directory  -ErrorAction Stop | Out-Null
        New-Item ($pathToDB + "\db") -ItemType Directory  -ErrorAction Stop | Out-Null
        }

    #create config file with content
    Write-Host "Create config file with default content"
    $configFile = $installocation + "mongod.cfg"
    $content = "systemLog:`r`n    destination: file`r`n    path: " + $pathToDB + "log\mongod.log`r`nstorage:`r`n    dbPath: " + $pathToDB + "db`r`n"
    Set-Content  $configFile $content -Force -ErrorAction Stop
    Write-Host "Instalation MongoDB as service"
    $mongod = '"' + $installocation + 'bin\mongod.exe' + '"'
    $instService =Start-Process -FilePath $mongod -ArgumentList (' --config "' + $installocation + 'mongod.cfg" --install') -WindowStyle Hidden

    #wait until service is installed
    Write-Host "Wait 10 seconds until service is started..."
    Start-Sleep 10

    #add rule in to firewall
    Write-Host "Add rule to firewall" 
    $addRuleRes = Start-Process -FilePath C:\Windows\System32\cmd.exe `
    -ArgumentList (' /C netsh advfirewall firewall add rule name="Allow MongoDB" dir=in action=allow protocol=TCP localport=27017') -WindowStyle Hidden

    #start service
    Write-Host "Starting service"
    $startResult = Start-Process -FilePath C:\Windows\System32\cmd.exe -ArgumentList (" /C net start MongoDB") -WindowStyle Hidden

    #create share folder
    Write-Host "Creating share folder"
    If(!(Test-Path $sharedFolder)){
           New-Item $sharedFolder -ItemType Directory -ErrorAction Stop | Out-Null
        }
    $sharedFolderRes = Start-Process -FilePath C:\Windows\System32\cmd.exe `
    -ArgumentList (' /C net share ' + ($sharedFolder.Split("\")[-1]) + '=' + $sharedFolder + ' /GRANT:"EVERYONE",FULL') -WindowStyle Hidden
    
  }
  Catch{
    Write-Host "Exception in localInstallMongo function: `r`n" $_.Exception.Message -ForegroundColor Red
    Write-Host "Line number:" $_.InvocationInfo.ScriptLineNumber "Offset:" $_.InvocationInfo.OffsetInLine -ForegroundColor Red
    Exit -1
    Exit -1
  }
 Write-Host "Done."
}

#if serverName are defined then run remote installation
if($serverName.Length -gt 0){
    #copy instalation package
    $localPath = copyMSIPackage($pathToMSI)
    #start instalation process
    installMongo($localPath)
}
#else run local installation
else{
    localInstallMongo
}

