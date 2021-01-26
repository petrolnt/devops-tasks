#This script is designed for send Welcome Message to new users, whos mailboxes was created in Exchange

#looking for all mailboxes Made today and treat the resulting array in the loop
Get-Mailbox | where {$_.WhenCreated -gt (get-date).adddays(0)} | foreach{
#pull out the alias (as the user's domain name and e-mail alias in domain did not coincide)
$alias = $_.Alias
#Pull out the user name (here the full name of my name in Russia)
$name = $_.Name
#Mail domain
$domain = "mydomain.ru"
#mail server in local domain
$Smtp = "exch.ntzmk.ru"
#email sender
$from = "support@ntzmk.ru"
#email subject
$Subject = "Welcome to the Service Technical Support Information Technology Department"
#email body
$Body = "<p class='t' style='text-indent:35.4pt' style='margin:10 0 0 0'>This is the text of welcome message</p>"
#convert to UTF-8
$enc = New-Object System.Text.utf8encoding
#Send email
Send-MailMessage -From $from -To $alias@$domain -Subject  $Subject -Body $Body -Encoding $enc -SmtpServer $Smtp -BodyAsHtml
}