$processName = "Video.run"
$processName1 = "Slave.exe"
$pathToexe = "C:\Program Files (x86)\Интеллект\intellect.exe"
$logFile  = "c:\exec\process_watcher.log"
$prefMem = 9000000000
Function writeLog{
    param(
        [String]$msg
    )
    if((Test-Path -Path $logFile)){
        New-Item -Path $logFile
    }
    $msg >> $logFile
}
while($True){
    $proc = Get-WmiObject -Query ('SELECT * FROM Win32_PerfFormattedData_PerfProc_Process WHERE Name =' + '"' + $processName + '"')
    $mem = $proc.WorkingSetPrivate
    if ($mem -gt $prefMem){
        Stop-Process -Name $processName1 -Force -ErrorAction SilentlyContinue
        Sleep 5
        $res = Get-Process -Name $processName1 -ErrorAction SilentlyContinue
        if(-Not $res){
            writeLog -msg "Process " + $processName1 + " stopped"
        }else{
            writeLog -msg "Process " + $processName1 + " can not stopped"
        }
        Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
        Sleep 5
        $res1 = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if(-Not $res1){
            writeLog -msg "Process " + $processName + " stopped"
        }else{
            writeLog -msg "Process " + $processName + " can not stopped"
        }
		Sleep 30
        if(-not($res -and $res1)){
            Start-Process -FilePath $pathToexe
        }
        Sleep 30
        $res = Get-Process -Name $process1 -ErrorAction SilentlyContinue
        $res1 = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if($res -and $res1){
            writeLog -msg "Intellect successfully restarted"
        }else{
            writeLog -msg "Can not start Intellect"
        }
    }
    Sleep 60
}
