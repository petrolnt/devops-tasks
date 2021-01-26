#This script designed for search computers form input file list in AD and write computers that not in AD in to output file
#
param(
    #this arguments with default values, you can specify it belong or start script with arguments: .\searchComputers.ps -inputFile="path:\to\file" -outputFile "path:\to\file" -pathToSearch "LDAP://OU=unitName,DC=domain,DC=name"
    [string]$inputFile = "c:\test\inputFile.txt",
    [string]$outputFile = "C:\test\output.txt",
    [string]$pathToSearch = ""
)

function searchInAD($computerName){
    $filter = "(&(objectClass=computer)(cn=" + $computerName + "))"
    $objSearcher.Filter = $filter
    $objSearcher.SearchScope = "Subtree"
    $res = $objSearcher.FindOne()
    if($res -ne $Null){
        return $TRUE
        }
    return $FALSE
}


#get Directory Entry with $partToSearch, if $parthToSearch not specified than Directory Entry is root of default domain
$objDomain = New-Object System.DirectoryServices.DirectoryEntry $pathToSearch
#if error path then exit
if($objDomain.Properties -eq $Null){
    Write-Host "The domain or Path: " $pathToSearch "not found"
    Exit -1
}
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain

#read computer names from inputFile and search in AD
$machines = get-content $inputFile
$machinesNotInAD = ""
foreach($item in $machines){
    #if not found then write to string
    if(-Not(searchInAD($item))){
        $machinesNotInAD = $machinesNotInAD + $item + "`r`n"
    }
}

#And write all computer names that not found in AD to output file
$machinesNotInAD | Out-File $outputFile

