#Running from PowerShell console: reboot_computers Location1

#Parameter Location passed to script as argument
Param(
    [Parameter(Mandatory=$true)]
    [string] $location = $null
)
#end of computer name
$endOfName = "pc"
#computer number
$compNumber = 1
#how many computers will be restarted
$iterations = 20
#timeout before restart the computer
$timeout = 30
do{
    #formatting computer number
    $strNumber = $compNumber.ToString().PadLeft(3,"0")
    # Concatenate parts of name
    $computerName = $location + $endOfName + $strNumber
    #if computer online
    if(Test-Connection -Quiet -Count 1 $computerName){
        Write-Host "Restarting" $computerName
        #This command to immediately force rebooting of the computer
        #Restart-Computer -ComputerName $computerName -Force
        
        #this command to correctly restart the computer with user notification
        $rebootCommand = Invoke-WmiMethod -Class Win32_Process -ComputerName $computerName -Name Create -ArgumentList ("C:\Windows\System32\cmd.exe /C shutdown /r /t " + $timeout)
        }
        else{
        Write-Host $computerName "is not online"
        }
    #Incrementation compNumber
    $compNumber += 1
    }
until($compNumber -gt $iterations)

