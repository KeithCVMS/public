#Log function added KH
Function Log() {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$false)] [String] $message
	)

	$tz = [Regex]::Replace([System.TimeZoneInfo]::Local.StandardName, '([A-Z])\w+\s*', '$1')
	$ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
	Write-Output "$ts $tz -  $message"
}
#Log function end

	
#Create CVMMPA Customization Folder
$AppFolder = "C:\ProgramData\CVMMPA"
If (!(Test-Path $AppFolder)) {
    New-Item -Path "$AppFolder" -ItemType Directory
    Log "The folder $AppFolder was successfully created."
}
<# $AppLog = "$AppFolder\SetTimeZone-$(Get-Date -UFormat "%Y-%m-%d_%H-%M").log"

Start-Transcript $AppLog
 #>
$AppTag = "$AppFolder\SetTimeZone.tag"
$UsrNm = $Env:UserName
$CurrProf = $Env:Userprofile

If (Test-Path $AppTag) {
	Add-Content -Path "$AppTag" -Value "Start Script- $(get-date) - $CurrProf - $UsrNm"
}
Else {
	Set-Content -Path "$AppTag" -Value "Start Script $(get-date) - $CurrProf - $UsrNm"
}

$CVMtz = "Mountain Standard Time"

If ($CVMtz -ieq (Get-TimeZone).Id) {
	Log "TimeZone currently set correctly:"
	Get-Date
	Get-TimeZone
}
Else { 
	Log "Current TimeZone: "
	Get-Date
	Get-TimeZone

	Log "set TimeZone to: $CVMtz"
	# Set the timezone
	Set-TimeZone -Id $CVMtz -PassThru

	Log "New TimeZone: "
	Get-Date
	Get-TimeZone
}

#Stop-Transcript
