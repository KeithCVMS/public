<#
.SYNOPSIS
.Intune shell script to drive script to remove bloat from a fresh Windows build
.DESCRIPTION
.Download and calls Remove-Bloat.ps1
.Usually used in PreProvisioning 
.Passes whitelist to Remove-Bloat.ps1

.INPUTS
.OUTPUTS
C:\ProgramData\Debloat\Debloat-shell.log
C:\ProgramData\Debloat\Remove-Bloat.ps1
.NOTES
  Version:        1.0.01
  Author:         Keith Hay forked from Andrew Taylor
  Twitter:       
  WWW:           
  Creation Date:  2024-05-12
  Purpose/Change: script customization
  Change: 2024-05-12 - Forked from original at https://github.com/andrew-s-taylor/public/blob/main/De-Bloat/
  Change 2024-05-12 Added log for Shell script 
  Change 2024-05-12 changed script source to KeithCVMS github
  Change 2024-05-12 customized whitelist parameter for CVMMPA HP consumer laptops
#>

#Set TimeZone in case it has been changed
invoke-expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/KeithCVMS/CVMS/main/scripts/SetTimeZone.ps1" -UseBasicParsing).Content  
#Enhanced Logging function
invoke-expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/KeithCVMS/CVMS/main/scripts/Log.ps1" -UseBasicParsing).Content  

$CommonFolder = "C:\ProgramData\CVMMPA"
If (!(Test-Path $CommonFolder)) {
    New-Item -Path "$CommonFolder" -ItemType Directory
    WRite-Host "The folder $CommonFolder was successfully created."
}
$DebloatFolder = "C:\ProgramData\CVMMPA\Debloat"
If (!(Test-Path $DebloatFolder)) {
    New-Item -Path "$DebloatFolder" -ItemType Directory
    WRite-Host "The folder $DebloatFolder was successfully created."
}

Start-Transcript -Path "$CommonFolder\Debloat-Shell.log" -Append
Log "##############################################################"
Log "######### 				Debloat-Shell_5_3_0.ps1						#############"
Log "##############################################################"
Log ""

$DebloatShellTag = "$CommonFolder\Debloat-Shell.tag"

#$Env:UserName
$UsrNm = $Env:UserName
$CurrProf = $Env:Userprofile
Log "Username: $UsrNm"
Log "Profile:  $CurrProf"

If (Test-Path $DebloatShellTag) {
	if ($CurrProf -like "*systemprofile*") {
		# This prevents the script from running mutiple times during pre-provisioning
		# but still allows it run multiple times if being run in a user Context
		# multiple attempts are recorded in the tag file
		Log "Debloat-Shell Script has already been run for provisioning. Exiting"
		Add-Content -Path "$DebloatShellTag" -Value "Script has already been run- $(get-date) $tz - $CurrProf - $UsrNm - Exiting"
		Exit 0
	}
	Else {
		Add-Content -Path "$DebloatShellTag" -Value "Start Script $(get-date) $tz - $CurrProf - $UsrNm"
	}
}
Else {
	Set-Content -Path "$DebloatShellTag" -Value "Start Script $(get-date) $tz - $CurrProf - $UsrNm"
}

$templateFilePath = "$DebloatFolder\RemoveBloat.ps1"
####-Uri "https://raw.githubusercontent.com/KeithCVMS/public/main/De-Bloat/RemoveBloat.ps1" `

Invoke-WebRequest `
-Uri "https://raw.githubusercontent.com/KeithCVMS/public/main/De-Bloat/RemoveBloat_5_3_0KH.ps1" `
-OutFile $templateFilePath `
-UseBasicParsing `
-Headers @{"Cache-Control"="no-cache"}

##Populate between the speechmarks any apps you want to whitelist, comma-separated
$arguments = ' -customwhitelist ' +
	#Microsoft package apps
	'"Microsoft.Getstarted,Microsoft.GetHelp,Microsoft.WindowsSoundRecorder' +
	',Microsoft.WindowsCamera,Microsoft.SecHealthUI,Microsoft.Todos,MicrosoftCorporationII.QuickAssist,clipchamp.clipchamp' +
	#HP package apps
	',AD2F1837.HPSupportAssistant' +
	#ASUS package apps
	',B9ECED6F.ASUSExpertWidget,B9ECED6F.ASUSPCAssistant' +
	',AppUp.IntelGraphicsExperience,AppUp.IntelManagementandSecurityStatus' +
	',DolbyLaboratories.DolbyAccess,DolbyLaboratories.DolbyDigitalPlusDecoderOEM' +
	',DrivewintechTechnologyCo.DiracAudoManager,IntelligoTechnologyInc.541271065CCE8' +
	'"'
	
write-host " " 
Log "Arguments:$arguments"

Add-Content -Path "$DebloatShellTag" -Value "invoke debloat $(get-date) $tz - $CurrProf - $UsrNm"
Log "Calling Debloat"

Stop-Transcript

invoke-expression -Command "$templateFilePath $arguments"

Start-Transcript -Append -Path "$CommonFolder\Debloat-Shell.log"

Log "Return from debloat"

Add-Content -Path "$DebloatShellTag" -Value "After Debloat $(get-date) $tz - $CurrProf - $UsrNm"

Stop-Transcript