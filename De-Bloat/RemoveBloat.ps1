<#
.SYNOPSIS
.Removes bloat from a fresh Windows build
. forked from Andrew Taylor
.DESCRIPTION
.Removes AppX Packages
.Disables Cortana
.Removes McAfee
.Removes HP Bloat
.Removes Dell Bloat
.Removes Lenovo Bloat
.Windows 10 and Windows 11 Compatible
.Removes any unwanted installed applications
.Removes unwanted services and tasks
.Removes Edge Surf Game

.INPUTS
.OUTPUTS
C:\ProgramData\Debloat\Debloat.log
.NOTES
  Version:        4.2.25
  Author:         Andrew Taylor
  Twitter:        @AndrewTaylor_2
  WWW:            andrewstaylor.com
  Creation Date:  08/03/2022
  Purpose/Change: Initial script development
  Change: 12/08/2022 - Added additional HP applications
  Change 23/09/2022 - Added Clipchamp (new in W11 22H2)
  Change 28/10/2022 - Fixed issue with Dell apps
  Change 23/11/2022 - Added Teams Machine wide to exceptions
  Change 27/11/2022 - Added Dell apps
  Change 07/12/2022 - Whitelisted Dell Audio and Firmware
  Change 19/12/2022 - Added Windows 11 start menu support
  Change 20/12/2022 - Removed Gaming Menu from Settings
  Change 18/01/2023 - Fixed Scheduled task error and cleared up $null posistioning
  Change 22/01/2023 - Re-enabled Telemetry for Endpoint Analytics
  Change 30/01/2023 - Added Microsoft Family to removal list
  Change 31/01/2023 - Fixed Dell loop
  Change 08/02/2023 - Fixed HP apps (thanks to http://gerryhampsoncm.blogspot.com/2023/02/remove-pre-installed-hp-software-during.html?m=1)
  Change 08/02/2023 - Removed reg keys for Teams Chat
  Change 14/02/2023 - Added HP Sure Apps
  Change 07/03/2023 - Enabled Location tracking (with commenting to disable)
  Change 08/03/2023 - Teams chat fix
  Change 10/03/2023 - Dell array fix
  Change 19/04/2023 - Added loop through all users for HKCU keys for post-OOBE deployments
  Change 29/04/2023 - Removes News Feed
  Change 26/05/2023 - Added Set-ACL
  Change 26/05/2023 - Added multi-language support for Set-ACL commands
  Change 30/05/2023 - Logic to check if gamepresencewriter exists before running Set-ACL to stop errors on re-run
  Change 25/07/2023 - Added Lenovo apps (Thanks to Simon Lilly and Philip Jorgensen)
  Change 31/07/2023 - Added LenovoAssist
  Change 21/09/2023 - Remove Windows backup for Win10
  Change 28/09/2023 - Enabled Diagnostic Tracking for Endpoint Analytics
  Change 02/10/2023 - Lenovo Fix
  Change 06/10/2023 - Teams chat fix
  Change 09/10/2023 - Dell Command Update change
  Change 11/10/2023 - Grab all uninstall strings and use native uninstaller instead of uninstall-package
  Change 14/10/2023 - Updated HP Audio package name
  Change 31/10/2023 - Added PowerAutomateDesktop and update Microsoft.Todos
  Change 01/11/2023 - Added fix for Windows backup removing Shell Components
  Change 06/11/2023 - Removes Windows CoPilot
  Change 07/11/2023 - HKU fix
  Change 13/11/2023 - Added CoPilot removal to .Default Users
  Change 14/11/2023 - Added logic to stop errors on HP machines without HP docs installed
  Change 14/11/2023 - Added logic to stop errors on Lenovo machines without some installers
  Change 15/11/2023 - Code Signed for additional security
  Change 02/12/2023 - Added extra logic before app uninstall to check if a user has logged in
  Change 04/01/2024 - Added Dropbox and DevHome to AppX removal
  Change 05/01/2024 - Added MSTSC to whitelist
  Change 25/01/2024 - Added logic for LenovoNow/LenovoWelcome
  Change 25/01/2024 - Updated Dell app list (thanks Hrvoje in comments)
  Change 29/01/2024 - Changed /I to /X in Dell command
  Change 30/01/2024 - Fix Lenovo Vantage version
  Change 31/01/2024 - McAfee fix and Dell changes
  Change 01/02/2024 - Dell fix
  Change 01/02/2024 - Added logic around appxremoval to stop failures in logging
  Change 05/02/2024 - Added whitelist parameters
  Change 16/02/2024 - Added wildcard to dropbox
  Change 23/02/2024 - Added Lenovo SmartMeetings
  Change 06/03/2024 - Added Lenovo View and Vantage
  Change 08/03/2024 - Added Lenovo Smart Noise Cancellation
  Change 13/03/2024 - Added updated McAfee
  Change 20/03/2024 - Dell app fixes
  Change 02/04/2024 - Stopped it removing Intune Management Extension!
  Change 03/04/2024 - Switched Win32 removal from whitelist to blacklist
  Change 10/04/2024 - Office uninstall string fix
  Change 11/04/2024 - Added Office support for multi-language
  Change 17/04/2024 - HP Apps update
  Change 19/04/2024 - HP Fix
  Change 24/04/2024 - Switched provisionedpackage and appxpackage arround
  Change 02/05/2024 - Fixed notlike to notin
  Change 03/05/2024 - Change $uninstallprograms
  Change 19/05/2024 - Disabled feeds on Win11
  Change 21/05/2024 - Added QuickAssist to removal after security issues
  Change 25/05/2024 - Whitelist array fix
  Change KH fork	- change to $DebloatFolder directory (purely a tenant specific mod)
					- logic to use a tag file for sensing previous installs and preventing multiple executions during pre-provisioning
					- additional HP bloat removal for WildTangent and Edge favorites
					- adjustments to ensure all whiteliste and nonremovable packages are accounted for in later remove-package loops
					- a few more additional Mcafee cleanup items at end of section
					- minor correction to entry logic for "other stuff removal" after Mcafee cleanup					
					- change to use a corrected version of MS SaRA Enterprise tool to remove Office versions so subsequent M365 MSTeams installs work reliably
N/A
#>

############################################################################################################
#                                         Initial Setup                                                    #
#                                                                                                          #
############################################################################################################
param (
    [string[]]$customwhitelist
)

##Elevate if needed

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host "                                               3"
    Start-Sleep 1
    Write-Host "                                               2"
    Start-Sleep 1
    Write-Host "                                               1"
    Start-Sleep 1
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -WhitelistApps {1}" -f $PSCommandPath, ($WhitelistApps -join ',')) -Verb RunAs
    Exit
}

#no errors throughout
$ErrorActionPreference = 'SilentlyContinue'


#Create Folder
$DebloatFolder = "C:\ProgramData\Debloat"
If (Test-Path $DebloatFolder) {
    Write-Output "$DebloatFolder exists. Skipping."
}
Else {
    Write-Output "The folder '$DebloatFolder' doesn't exist. This folder will be used for storing logs created after the script runs. Creating now."
    Start-Sleep 1
    New-Item -Path "$DebloatFolder" -ItemType Directory
    Write-Output "The folder $DebloatFolder was successfully created."
}

#This uses a "tag" file to determine whether the script has been run previously
#The "tag" file also provides a quick way to manually or from Intune to check for its presence on a System
#It can be used in a similar method as the detection mechanism for Win32apps in Intune
#     if coupled with a companion launching script 
#This section EXITS if the script has been previouly run in a preprov environment 
#     (based on the default user running the script).
$DebloatTag = "$DebloatFolder\Debloat.tag"

$Env:UserName
$CurrProf = $Env:Userprofile

If (Test-Path $DebloatTag) {
	if ($CurrProf -like "*systemprofile*") {
		# This prevents the script from running mutiple times during pre-provisioning
		# but still allows it run multiple times if being run in a user Context
		# multiple attempts are recorded in the tag file
		write-host "Script has already been run. Exiting"
		Add-Content -Path "$DebloatTag" -Value "Script has already been run- $(get-date) - Exiting"
		Exit 0
	}
	Else {
		Add-Content -Path "$DebloatTag" -Value "Start Script $(get-date)"
	}
}
Else {
	Set-Content -Path "$DebloatTag" -Value "Start Script $(get-date)"
}

Start-Transcript -Path "C:\ProgramData\Debloat\Debloat.log"

if ($CurrProf -like "*systemprofile*") {
	write-host "AutoPilot PreProvisioning run"
}

$locale = Get-WinSystemLocale | Select-Object -expandproperty Name

##Switch on locale to set variables
## Switch on locale to set variables
switch ($locale) {
    "ar-SA" {
        $everyone = "الجميع"
        $builtin = "مدمج"
    }
    "bg-BG" {
        $everyone = "Всички"
        $builtin = "Вграден"
    }
    "cs-CZ" {
        $everyone = "Všichni"
        $builtin = "Vestavěný"
    }
    "da-DK" {
        $everyone = "Alle"
        $builtin = "Indbygget"
    }
    "de-DE" {
        $everyone = "Jeder"
        $builtin = "Integriert"
    }
    "el-GR" {
        $everyone = "Όλοι"
        $builtin = "Ενσωματωμένο"
    }
    "en-US" {
        $everyone = "Everyone"
        $builtin = "Builtin"
    }    
    "en-GB" {
        $everyone = "Everyone"
        $builtin = "Builtin"
    }
    "es-ES" {
        $everyone = "Todos"
        $builtin = "Incorporado"
    }
    "et-EE" {
        $everyone = "Kõik"
        $builtin = "Sisseehitatud"
    }
    "fi-FI" {
        $everyone = "Kaikki"
        $builtin = "Sisäänrakennettu"
    }
    "fr-FR" {
        $everyone = "Tout le monde"
        $builtin = "Intégré"
    }
    "he-IL" {
        $everyone = "כולם"
        $builtin = "מובנה"
    }
    "hr-HR" {
        $everyone = "Svi"
        $builtin = "Ugrađeni"
    }
    "hu-HU" {
        $everyone = "Mindenki"
        $builtin = "Beépített"
    }
    "it-IT" {
        $everyone = "Tutti"
        $builtin = "Incorporato"
    }
    "ja-JP" {
        $everyone = "すべてのユーザー"
        $builtin = "ビルトイン"
    }
    "ko-KR" {
        $everyone = "모든 사용자"
        $builtin = "기본 제공"
    }
    "lt-LT" {
        $everyone = "Visi"
        $builtin = "Įmontuotas"
    }
    "lv-LV" {
        $everyone = "Visi"
        $builtin = "Iebūvēts"
    }
    "nb-NO" {
        $everyone = "Alle"
        $builtin = "Innebygd"
    }
    "nl-NL" {
        $everyone = "Iedereen"
        $builtin = "Ingebouwd"
    }
    "pl-PL" {
        $everyone = "Wszyscy"
        $builtin = "Wbudowany"
    }
    "pt-BR" {
        $everyone = "Todos"
        $builtin = "Integrado"
    }
    "pt-PT" {
        $everyone = "Todos"
        $builtin = "Incorporado"
    }
    "ro-RO" {
        $everyone = "Toată lumea"
        $builtin = "Incorporat"
    }
    "ru-RU" {
        $everyone = "Все пользователи"
        $builtin = "Встроенный"
    }
    "sk-SK" {
        $everyone = "Všetci"
        $builtin = "Vstavaný"
    }
    "sl-SI" {
        $everyone = "Vsi"
        $builtin = "Vgrajen"
    }
    "sr-Latn-RS" {
        $everyone = "Svi"
        $builtin = "Ugrađeni"
    }
    "sv-SE" {
        $everyone = "Alla"
        $builtin = "Inbyggd"
    }
    "th-TH" {
        $everyone = "ทุกคน"
        $builtin = "ภายในเครื่อง"
    }
    "tr-TR" {
        $everyone = "Herkes"
        $builtin = "Yerleşik"
    }
    "uk-UA" {
        $everyone = "Всі"
        $builtin = "Вбудований"
    }
    "zh-CN" {
        $everyone = "所有人"
        $builtin = "内置"
    }
    "zh-TW" {
        $everyone = "所有人"
        $builtin = "內建"
    }
    default {
        $everyone = "Everyone"
        $builtin = "Builtin"
    }
}

#Define PS-Drives for non-default registry paths if not present on system
if (!(Test-Path HKCR:)) {
	New-PSDrive -PSProvider Registry -Name HKCR -Root HKEY_CLASSES_ROOT | Out-Null
}
if (!(Test-Path HKU:)) {
	New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
}

############################################################################################################
#                                        Remove AppX Packages                                              #
#                                                                                                          #
############################################################################################################

    #Removes AppxPackages
    $WhitelistedApps = @(
        'Microsoft.WindowsNotepad',
        'Microsoft.CompanyPortal',
        'Microsoft.ScreenSketch',
        'Microsoft.Paint3D',
        'Microsoft.WindowsCalculator',
        'Microsoft.WindowsStore',
        'Microsoft.Windows.Photos',
        'CanonicalGroupLimited.UbuntuonWindows',
        'Microsoft.MicrosoftStickyNotes',
        'Microsoft.MSPaint',
        'Microsoft.WindowsCamera',
        '.NET',
        'Framework',
        'Microsoft.HEIFImageExtension',
        'Microsoft.ScreenSketch',
        'Microsoft.StorePurchaseApp',
        'Microsoft.VP9VideoExtensions',
        'Microsoft.WebMediaExtensions',
        'Microsoft.WebpImageExtension',
        'Microsoft.DesktopAppInstaller',
        'WindSynthBerry',
        'MIDIBerry',
        'Slack'
    )
    ##If $customwhitelist is set, split on the comma and add to whitelist
    if ($customwhitelist) {
        $customWhitelistApps = $customwhitelist -split ","
        foreach ($whitelistapp in $customwhitelistapps) {
            ##Add to the array
            $WhitelistedApps += $whitelistapp
        }
    }
    
    #NonRemovable Apps that where getting attempted and the system would reject the uninstall, speeds up debloat and prevents 'initalizing' overlay when removing apps
    $NonRemovable = @(
        '1527c705-839a-4832-9118-54d4Bd6a0c89',
        'c5e2524a-ea46-4f67-841f-6a9465d9d515',
        'E2A4F912-2574-4A75-9BB0-0D023378592B',
        'F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE',
        'InputApp',
        'Microsoft.AAD.BrokerPlugin',
        'Microsoft.AccountsControl',
        'Microsoft.BioEnrollment',
        'Microsoft.CredDialogHost',
        'Microsoft.ECApp',
        'Microsoft.LockApp',
        'Microsoft.MicrosoftEdgeDevToolsClient',
        'Microsoft.MicrosoftEdge',
        'Microsoft.PPIProjection',
        'Microsoft.Win32WebViewHost',
        'Microsoft.Windows.Apprep.ChxApp',
        'Microsoft.Windows.AssignedAccessLockApp',
        'Microsoft.Windows.CapturePicker',
        'Microsoft.Windows.CloudExperienceHost',
        'Microsoft.Windows.ContentDeliveryManager',
        'Microsoft.Windows.Cortana',
        'Microsoft.Windows.NarratorQuickStart',
        'Microsoft.Windows.ParentalControls',
        'Microsoft.Windows.PeopleExperienceHost',
        'Microsoft.Windows.PinningConfirmationDialog',
        'Microsoft.Windows.SecHealthUI',
        'Microsoft.Windows.SecureAssessmentBrowser',
        'Microsoft.Windows.ShellExperienceHost',
        'Microsoft.Windows.XGpuEjectDialog',
        'Microsoft.XboxGameCallableUI',
        'Windows.CBSPreview',
        'windows.immersivecontrolpanel',
        'Windows.PrintDialog',
        'Microsoft.VCLibs.140.00',
        'Microsoft.Services.Store.Engagement',
        'Microsoft.UI.Xaml.2.0',
        '*Nvidia*'
    )

    ##Combine the two arrays
    $appstoignore = $WhitelistedApps += $NonRemovable

###blocked this out as it removes a lot of stuff and produces a lot of hidden errors trying to remove Windows uninstallable components
#    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -notin $appstoignore} | Remove-AppxProvisionedPackage -Online
#    Get-AppxPackage -AllUsers | Where-Object {$_.Name -notin $appstoignore} | Remove-AppxPackage
##

##Remove bloat
$Bloatware = @(
    #Unnecessary Windows 10/11 AppX Apps
    "Microsoft.549981C3F5F10"
    "Microsoft.BingNews"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Messaging"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.MixedReality.Portal"
    "Microsoft.News"
    "Microsoft.Office.Lens"
    "Microsoft.Office.OneNote"
    "Microsoft.Office.Sway"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.RemoteDesktop"
    "Microsoft.SkypeApp"
    "Microsoft.StorePurchaseApp"
    "Microsoft.Office.Todo.List"
    "Microsoft.Whiteboard"
    "Microsoft.WindowsAlarms"
    #"Microsoft.WindowsCamera"
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "MicrosoftTeams"
    "Microsoft.YourPhone"
    "Microsoft.XboxGamingOverlay_5.721.10202.0_neutral_~_8wekyb3d8bbwe"
    "Microsoft.GamingApp"
    "Microsoft.Todos"
    "Microsoft.PowerAutomateDesktop"
    "SpotifyAB.SpotifyMusic"
    "Microsoft.MicrosoftJournal"
    "Disney.37853FC22B2CE"
    "*EclipseManager*"
    "*ActiproSoftwareLLC*"
    "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
    "*Duolingo-LearnLanguagesforFree*"
    "*PandoraMediaInc*"
    "*CandyCrush*"
    "*BubbleWitch3Saga*"
    "*Wunderlist*"
    "*Flipboard*"
    "*Twitter*"
    "*Facebook*"
    "*Spotify*"
    "*Minecraft*"
    "*Royal Revolt*"
    "*Sway*"
    "*Speed Test*"
    "*Dolby*"
    "*Office*"
    "*Disney*"
    "clipchamp.clipchamp"
    "*gaming*"
    "MicrosoftCorporationII.MicrosoftFamily"
    "C27EB4BA.DropboxOEM*"
    "*DevHome*"
    "MicrosoftCorporationII.QuickAssist"
    #Optional: Typically not removed but you can if you need to for some reason
    #"*Microsoft.Advertising.Xaml_10.1712.5.0_x64__8wekyb3d8bbwe*"
    #"*Microsoft.Advertising.Xaml_10.1712.5.0_x86__8wekyb3d8bbwe*"
    "*Microsoft.BingWeather*"
    #"*Microsoft.MSPaint*"
    #"*Microsoft.MicrosoftStickyNotes*"
    #"*Microsoft.Windows.Photos*"
    #"*Microsoft.WindowsCalculator*"
    #"*Microsoft.WindowsStore*"
)
##remove appstoignore from array
    $Bloatware = $Bloatware | Where-Object { $appstoignore -notcontains $_ }
    

    foreach ($Bloat in $Bloatware) {
        
        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat -ErrorAction SilentlyContinue) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
            Write-Host "Removed provisioned package for $Bloat."
        } else {
            Write-Host "Provisioned package for $Bloat not found."
        }

        if (Get-AppxPackage -Name $Bloat -ErrorAction SilentlyContinue) {
            Get-AppxPackage -allusers -Name $Bloat | Remove-AppxPackage -AllUsers
            Write-Host "Removed $Bloat."
        } else {
            Write-Host "$Bloat not found."
        }



        

    }
############################################################################################################
#                                        Remove Registry Keys                                              #
#                                                                                                          #
############################################################################################################

##We need to grab all SIDs to remove at user level
$UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName

    
    #These are the registry keys that it will delete.
            
    $Keys = @(
            
        #Remove Background Tasks
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
            
        #Windows File
        "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            
        #Registry keys to delete if they aren't uninstalled by RemoveAppXPackage/RemoveAppXProvisionedPackage
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
            
        #Scheduled Tasks to delete
        "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
            
        #Windows Protocol Keys
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
               
        #Windows Share Target
        "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    )
        
    #This writes the output of each key it is removing and also removes the keys listed above.
    ForEach ($Key in $Keys) {
        Write-Host "Removing $Key from registry"
        Remove-Item $Key -Recurse
    }


    #Disables Windows Feedback Experience
    Write-Host "Disabling Windows Feedback Experience program"
    $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    If (!(Test-Path $Advertising)) {
        New-Item $Advertising
    }
    If (Test-Path $Advertising) {
        Set-ItemProperty $Advertising Enabled -Value 0 
    }
            
    #Stops Cortana from being used as part of your Windows Search Function
    Write-Host "Stopping Cortana from being used as part of your Windows Search Function"
    $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    If (!(Test-Path $Search)) {
        New-Item $Search
    }
    If (Test-Path $Search) {
        Set-ItemProperty $Search AllowCortana -Value 0 
    }

    #Disables Web Search in Start Menu
    Write-Host "Disabling Bing Search in Start Menu"
    $WebSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    If (!(Test-Path $WebSearch)) {
        New-Item $WebSearch
    }
    Set-ItemProperty $WebSearch DisableWebSearch -Value 1 
    ##Loop through all user SIDs in the registry and disable Bing Search
    foreach ($sid in $UserSIDs) {
        $WebSearch = "Registry::HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
        If (!(Test-Path $WebSearch)) {
            New-Item $WebSearch
        }
        Set-ItemProperty $WebSearch BingSearchEnabled -Value 0
    }
    
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled -Value 0 

            
    #Stops the Windows Feedback Experience from sending anonymous data
    Write-Host "Stopping the Windows Feedback Experience program"
    $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
    If (!(Test-Path $Period)) { 
        New-Item $Period
    }
    Set-ItemProperty $Period PeriodInNanoSeconds -Value 0 

    ##Loop and do the same
    foreach ($sid in $UserSIDs) {
        $Period = "Registry::HKU\$sid\Software\Microsoft\Siuf\Rules"
        If (!(Test-Path $Period)) { 
            New-Item $Period
        }
        Set-ItemProperty $Period PeriodInNanoSeconds -Value 0 
    }

    #Prevents bloatware applications from returning and removes Start Menu suggestions               
    Write-Host "Adding Registry key to prevent bloatware apps from returning"
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    $registryOEM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    If (!(Test-Path $registryPath)) { 
        New-Item $registryPath
    }
    Set-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 

    If (!(Test-Path $registryOEM)) {
        New-Item $registryOEM
    }
    Set-ItemProperty $registryOEM  ContentDeliveryAllowed -Value 0 
    Set-ItemProperty $registryOEM  OemPreInstalledAppsEnabled -Value 0 
    Set-ItemProperty $registryOEM  PreInstalledAppsEnabled -Value 0 
    Set-ItemProperty $registryOEM  PreInstalledAppsEverEnabled -Value 0 
    Set-ItemProperty $registryOEM  SilentInstalledAppsEnabled -Value 0 
    Set-ItemProperty $registryOEM  SystemPaneSuggestionsEnabled -Value 0  
    
    ##Loop through users and do the same
    foreach ($sid in $UserSIDs) {
        $registryOEM = "Registry::HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        If (!(Test-Path $registryOEM)) {
            New-Item $registryOEM
        }
        Set-ItemProperty $registryOEM  ContentDeliveryAllowed -Value 0 
        Set-ItemProperty $registryOEM  OemPreInstalledAppsEnabled -Value 0 
        Set-ItemProperty $registryOEM  PreInstalledAppsEnabled -Value 0 
        Set-ItemProperty $registryOEM  PreInstalledAppsEverEnabled -Value 0 
        Set-ItemProperty $registryOEM  SilentInstalledAppsEnabled -Value 0 
        Set-ItemProperty $registryOEM  SystemPaneSuggestionsEnabled -Value 0 
    }
    
    #Preping mixed Reality Portal for removal    
    Write-Host "Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
    $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"    
    If (Test-Path $Holo) {
        Set-ItemProperty $Holo  FirstRunSucceeded -Value 0 
    }

    ##Loop through users and do the same
    foreach ($sid in $UserSIDs) {
        $Holo = "Registry::HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Holographic"    
        If (Test-Path $Holo) {
            Set-ItemProperty $Holo  FirstRunSucceeded -Value 0 
        }
    }

    #Disables Wi-fi Sense
    Write-Host "Disabling Wi-Fi Sense"
    $WifiSense1 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
    $WifiSense2 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
    $WifiSense3 = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
    If (!(Test-Path $WifiSense1)) {
        New-Item $WifiSense1
    }
    Set-ItemProperty $WifiSense1  Value -Value 0 
    If (!(Test-Path $WifiSense2)) {
        New-Item $WifiSense2
    }
    Set-ItemProperty $WifiSense2  Value -Value 0 
    Set-ItemProperty $WifiSense3  AutoConnectAllowedOEM -Value 0 
        
    #Disables live tiles
    Write-Host "Disabling live tiles"
    $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"    
    If (!(Test-Path $Live)) {      
        New-Item $Live
    }
    Set-ItemProperty $Live  NoTileApplicationNotification -Value 1 

    ##Loop through users and do the same
    foreach ($sid in $UserSIDs) {
        $Live = "Registry::HKU\$sid\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"    
        If (!(Test-Path $Live)) {      
            New-Item $Live
        }
        Set-ItemProperty $Live  NoTileApplicationNotification -Value 1 
    }
        
    #Turns off Data Collection via the AllowTelemtry key by changing it to 0
    # This is needed for Intune reporting to work, uncomment if using via other method
    #Write-Host "Turning off Data Collection"
    #$DataCollection1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    #$DataCollection2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    #$DataCollection3 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"    
    #If (Test-Path $DataCollection1) {
    #    Set-ItemProperty $DataCollection1  AllowTelemetry -Value 0 
    #}
    #If (Test-Path $DataCollection2) {
    #    Set-ItemProperty $DataCollection2  AllowTelemetry -Value 0 
    #}
    #If (Test-Path $DataCollection3) {
    #    Set-ItemProperty $DataCollection3  AllowTelemetry -Value 0 
    #}
    

###Enable location tracking for "find my device", uncomment if you don't need it

    #Disabling Location Tracking
    #Write-Host "Disabling Location Tracking"
    #$SensorState = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
    #$LocationConfig = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
    #If (!(Test-Path $SensorState)) {
    #    New-Item $SensorState
    #}
    #Set-ItemProperty $SensorState SensorPermissionState -Value 0 
    #If (!(Test-Path $LocationConfig)) {
    #    New-Item $LocationConfig
    #}
    #Set-ItemProperty $LocationConfig Status -Value 0 
        
    #Disables People icon on Taskbar
    Write-Host "Disabling People icon on Taskbar"
    $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
    If (Test-Path $People) {
        Set-ItemProperty $People -Name PeopleBand -Value 0
    }

    ##Loop through users and do the same
    foreach ($sid in $UserSIDs) {
        $People = "Registry::HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"
        If (Test-Path $People) {
            Set-ItemProperty $People -Name PeopleBand -Value 0
        }
    }

    Write-Host "Disabling Cortana"
    $Cortana1 = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
    $Cortana2 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
    $Cortana3 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
    If (!(Test-Path $Cortana1)) {
        New-Item $Cortana1
    }
    Set-ItemProperty $Cortana1 AcceptedPrivacyPolicy -Value 0 
    If (!(Test-Path $Cortana2)) {
        New-Item $Cortana2
    }
    Set-ItemProperty $Cortana2 RestrictImplicitTextCollection -Value 1 
    Set-ItemProperty $Cortana2 RestrictImplicitInkCollection -Value 1 
    If (!(Test-Path $Cortana3)) {
        New-Item $Cortana3
    }
    Set-ItemProperty $Cortana3 HarvestContacts -Value 0

    ##Loop through users and do the same
    foreach ($sid in $UserSIDs) {
        $Cortana1 = "Registry::HKU\$sid\SOFTWARE\Microsoft\Personalization\Settings"
        $Cortana2 = "Registry::HKU\$sid\SOFTWARE\Microsoft\InputPersonalization"
        $Cortana3 = "Registry::HKU\$sid\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
        If (!(Test-Path $Cortana1)) {
            New-Item $Cortana1
        }
        Set-ItemProperty $Cortana1 AcceptedPrivacyPolicy -Value 0 
        If (!(Test-Path $Cortana2)) {
            New-Item $Cortana2
        }
        Set-ItemProperty $Cortana2 RestrictImplicitTextCollection -Value 1 
        Set-ItemProperty $Cortana2 RestrictImplicitInkCollection -Value 1 
        If (!(Test-Path $Cortana3)) {
            New-Item $Cortana3
        }
        Set-ItemProperty $Cortana3 HarvestContacts -Value 0
    }


    #Removes 3D Objects from the 'My Computer' submenu in explorer
    Write-Host "Removing 3D Objects from explorer 'My Computer' submenu"
    $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    If (Test-Path $Objects32) {
        Remove-Item $Objects32 -Recurse 
    }
    If (Test-Path $Objects64) {
        Remove-Item $Objects64 -Recurse 
    }

   
    ##Removes the Microsoft Feeds from displaying
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
$Name = "EnableFeeds"
$value = "0"

if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
}

else {
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
}

##Kill Cortana again
Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove AppxPackage -allusers
    
############################################################################################################
#                                        Remove Scheduled Tasks                                            #
#                                                                                                          #
############################################################################################################

    #Disables scheduled tasks that are considered unnecessary 
    Write-Host "Disabling scheduled tasks"
    $task1 = Get-ScheduledTask -TaskName XblGameSaveTaskLogon -ErrorAction SilentlyContinue
    if ($null -ne $task1) {
    Get-ScheduledTask  XblGameSaveTaskLogon | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }
    $task2 = Get-ScheduledTask -TaskName XblGameSaveTask -ErrorAction SilentlyContinue
    if ($null -ne $task2) {
    Get-ScheduledTask  XblGameSaveTask | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }
    $task3 = Get-ScheduledTask -TaskName Consolidator -ErrorAction SilentlyContinue
    if ($null -ne $task3) {
    Get-ScheduledTask  Consolidator | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }
    $task4 = Get-ScheduledTask -TaskName UsbCeip -ErrorAction SilentlyContinue
    if ($null -ne $task4) {
    Get-ScheduledTask  UsbCeip | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }
    $task5 = Get-ScheduledTask -TaskName DmClient -ErrorAction SilentlyContinue
    if ($null -ne $task5) {
    Get-ScheduledTask  DmClient | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }
    $task6 = Get-ScheduledTask -TaskName DmClientOnScenarioDownload -ErrorAction SilentlyContinue
    if ($null -ne $task6) {
    Get-ScheduledTask  DmClientOnScenarioDownload | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }


############################################################################################################
#                                             Disable Services                                             #
#                                                                                                          #
############################################################################################################
    ##Write-Host "Stopping and disabling Diagnostics Tracking Service"
    #Disabling the Diagnostics Tracking Service
    ##Stop-Service "DiagTrack"
    ##Set-Service "DiagTrack" -StartupType Disabled


############################################################################################################
#                                        Windows 11 Specific                                               #
#                                                                                                          #
############################################################################################################
    #Windows 11 Customisations
    write-host "Removing Windows 11 Customisations"
    #Remove XBox Game Bar
    
    $packages = @(
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxGameCallableUI",
        "Microsoft.549981C3F5F10",
        "*getstarted*",
        "Microsoft.Windows.ParentalControls"
    )
    ##Remove appstoignore from array
    $packages = $packages | Where-Object { $appstoignore -notcontains $_ }
    

    foreach ($package in $packages) {
 		$appPackage = Get-AppxProvisionedPackage -online | Where-Object { $_.DisplayName -eq $package} -ErrorAction SilentlyContinue
		if ($appPackage) {
			$appPackage | Remove-AppxProvisionedPackage | out-null
			Write-Host "Removed Win11 ProvisionedPackage $package"
		} else {
			Write-Host "Win11 ProvisionedPackage $package not found"
		}

       $appPackage = Get-AppxPackage -allusers $package -ErrorAction SilentlyContinue
        if ($appPackage) {
            Remove-AppxPackage -Package $appPackage.PackageFullName -AllUsers
            Write-Host "Removed $package"
		} else {
			Write-Host "Win11 Package $package not found"
        }
    }

   #Remove Teams Chat
write-host "Remove Teams personal"
$MSTeams = "MicrosoftTeams"

$WinPackage = Get-AppxPackage -allusers | Where-Object {$_.Name -eq $MSTeams}
$ProvisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $MSTeams }
If ($null -ne $ProvisionedPackage) 
{
	write-host "removing provisioned $provisionedPackage"
    Remove-AppxProvisionedPackage -online -Packagename $ProvisionedPackage.Packagename -AllUsers
}

If ($null -ne $WinPackage) 
{
	write-host "removing package $Winpackage"
    Remove-AppxPackage  -Package $WinPackage.PackageFullName -AllUsers
} 

##Tweak reg permissions
invoke-webrequest -uri "https://github.com/andrew-s-taylor/public/raw/main/De-Bloat/SetACL.exe" -outfile "C:\Windows\Temp\SetACL.exe"
C:\Windows\Temp\SetACL.exe -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" -ot reg -actn setowner -ownr "n:$everyone"
 C:\Windows\Temp\SetACL.exe -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" -ot reg -actn ace -ace "n:$everyone;p:full"


##Stop it coming back
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications"
If (!(Test-Path $registryPath)) { 
    New-Item $registryPath
}
Set-ItemProperty $registryPath ConfigureChatAutoInstall -Value 0


##Unpin it
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
If (!(Test-Path $registryPath)) { 
    New-Item $registryPath
}
Set-ItemProperty $registryPath "ChatIcon" -Value 2
write-host "Removed Teams Chat"


##Disable Feeds
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
If (!(Test-Path $registryPath)) { 
    New-Item $registryPath
}
Set-ItemProperty $registryPath "AllowNewsAndInterests" -Value 0
write-host "Disabled Feeds"

############################################################################################################
#                                           Windows Backup App                                             #
#                                                                                                          #
############################################################################################################
$version = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
if ($version -like "*Windows 10*") {
    write-host "Removing Windows Backup"
    $filepath = "C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\WindowsBackup\Assets"
if (Test-Path $filepath) {
Remove-WindowsPackage -Online -PackageName "Microsoft-Windows-UserExperience-Desktop-Package~31bf3856ad364e35~amd64~~10.0.19041.3393"

##Add back snipping tool functionality
write-host "Adding Windows Shell Components"
DISM /Online /Add-Capability /CapabilityName:Windows.Client.ShellComponents~~~~0.0.1.0
write-host "Components Added"
}
write-host "Removed"
}

############################################################################################################
#                                           Windows CoPilot                                                #
#                                                                                                          #
############################################################################################################
$version = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
if ($version -like "*Windows 11*") {
    write-host "Removing Windows Copilot"
# Define the registry key and value
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
$propertyName = "TurnOffWindowsCopilot"
$propertyValue = 1

# Check if the registry key exists
if (!(Test-Path $registryPath)) {
    # If the registry key doesn't exist, create it
    New-Item -Path $registryPath -Force | Out-Null
}

# Get the property value
$currentValue = Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction SilentlyContinue

# Check if the property exists and if its value is different from the desired value
if ($null -eq $currentValue -or $currentValue.$propertyName -ne $propertyValue) {
    # If the property doesn't exist or its value is different, set the property value
    Set-ItemProperty -Path $registryPath -Name $propertyName -Value $propertyValue
}


##Grab the default user as well
$registryPath = "HKEY_USERS\.DEFAULT\Software\Policies\Microsoft\Windows\WindowsCopilot"
$propertyName = "TurnOffWindowsCopilot"
$propertyValue = 1

# Check if the registry key exists
if (!(Test-Path $registryPath)) {
    # If the registry key doesn't exist, create it
    New-Item -Path $registryPath -Force | Out-Null
}

# Get the property value
$currentValue = Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction SilentlyContinue

# Check if the property exists and if its value is different from the desired value
if ($null -eq $currentValue -or $currentValue.$propertyName -ne $propertyValue) {
    # If the property doesn't exist or its value is different, set the property value
    Set-ItemProperty -Path $registryPath -Name $propertyName -Value $propertyValue
}


##Load the default hive from c:\users\Default\NTUSER.dat
reg load HKU\temphive "c:\users\default\ntuser.dat"
$registryPath = "registry::hku\temphive\Software\Policies\Microsoft\Windows\WindowsCopilot"
$propertyName = "TurnOffWindowsCopilot"
$propertyValue = 1

# Check if the registry key exists
if (!(Test-Path $registryPath)) {
    # If the registry key doesn't exist, create it
    [Microsoft.Win32.RegistryKey]$HKUCoPilot = [Microsoft.Win32.Registry]::Users.CreateSubKey("temphive\Software\Policies\Microsoft\Windows\WindowsCopilot", [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
    $HKUCoPilot.SetValue("TurnOffWindowsCopilot", 0x1, [Microsoft.Win32.RegistryValueKind]::DWord)
}

        



    $HKUCoPilot.Flush()
    $HKUCoPilot.Close()
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
reg unload HKU\temphive


write-host "Removed"


foreach ($sid in $UserSIDs) {
    $registryPath = "Registry::HKU\$sid\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    $propertyName = "TurnOffWindowsCopilot"
    $propertyValue = 1
    
    # Check if the registry key exists
    if (!(Test-Path $registryPath)) {
        # If the registry key doesn't exist, create it
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Get the property value
    $currentValue = Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction SilentlyContinue
    
    # Check if the property exists and if its value is different from the desired value
    if ($null -eq $currentValue -or $currentValue.$propertyName -ne $propertyValue) {
        # If the property doesn't exist or its value is different, set the property value
        Set-ItemProperty -Path $registryPath -Name $propertyName -Value $propertyValue
    }
}
}

############################################################################################################
#                                             Clear Start Menu                                             #
#                                                                                                          #
############################################################################################################
write-host "Clearing Start Menu"
#Delete layout file if it already exists

##Check windows version
$version = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
if ($version -like "*Windows 10*") {
    write-host "Windows 10 Detected"
    write-host "Removing Current Layout"
    If(Test-Path C:\Windows\StartLayout.xml)

    {
    
    Remove-Item C:\Windows\StartLayout.xml
    
    }
    write-host "Creating Default Layout"
    #Creates the blank layout file
    
    Write-Output "<LayoutModificationTemplate xmlns:defaultlayout=""http://schemas.microsoft.com/Start/2014/FullDefaultLayout"" xmlns:start=""http://schemas.microsoft.com/Start/2014/StartLayout"" Version=""1"" xmlns=""http://schemas.microsoft.com/Start/2014/LayoutModification"">" >> C:\Windows\StartLayout.xml
    
    Write-Output " <LayoutOptions StartTileGroupCellWidth=""6"" />" >> C:\Windows\StartLayout.xml
    
    Write-Output " <DefaultLayoutOverride>" >> C:\Windows\StartLayout.xml
    
    Write-Output " <StartLayoutCollection>" >> C:\Windows\StartLayout.xml
    
    Write-Output " <defaultlayout:StartLayout GroupCellWidth=""6"" />" >> C:\Windows\StartLayout.xml
    
    Write-Output " </StartLayoutCollection>" >> C:\Windows\StartLayout.xml
    
    Write-Output " </DefaultLayoutOverride>" >> C:\Windows\StartLayout.xml
    
    Write-Output "</LayoutModificationTemplate>" >> C:\Windows\StartLayout.xml
}
if ($version -like "*Windows 11*") {
    write-host "Windows 11 Detected"
    write-host "Removing Current Layout"
    If(Test-Path "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml")

    {
    
    Remove-Item "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
    
    }
    
$blankjson = @'
{ 
    "pinnedList": [ 
      { "desktopAppId": "MSEdge" }, 
      { "packagedAppId": "Microsoft.WindowsStore_8wekyb3d8bbwe!App" }, 
      { "packagedAppId": "desktopAppId":"Microsoft.Windows.Explorer" } 
    ] 
  }
'@

$blankjson | Out-File "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" -Encoding utf8 -Force
}


############################################################################################################
#                                              Remove Xbox Gaming                                          #
#                                                                                                          #
############################################################################################################

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\xbgm" -Name "Start" -PropertyType DWORD -Value 4 -Force
Set-Service -Name XblAuthManager -StartupType Disabled
Set-Service -Name XblGameSave -StartupType Disabled
Set-Service -Name XboxGipSvc -StartupType Disabled
Set-Service -Name XboxNetApiSvc -StartupType Disabled
$task = Get-ScheduledTask -TaskName "Microsoft\XblGameSave\XblGameSaveTask" -ErrorAction SilentlyContinue
if ($null -ne $task) {
Set-ScheduledTask -TaskPath $task.TaskPath -Enabled $false
}

##Check if GamePresenceWriter.exe exists
if (Test-Path "$env:WinDir\System32\GameBarPresenceWriter.exe") {
    write-host "GamePresenceWriter.exe exists"
    C:\Windows\Temp\SetACL.exe -on  "$env:WinDir\System32\GameBarPresenceWriter.exe" -ot file -actn setowner -ownr "n:$everyone"
C:\Windows\Temp\SetACL.exe -on  "$env:WinDir\System32\GameBarPresenceWriter.exe" -ot file -actn ace -ace "n:$everyone;p:full"

#Take-Ownership -Path "$env:WinDir\System32\GameBarPresenceWriter.exe"
$NewAcl = Get-Acl -Path "$env:WinDir\System32\GameBarPresenceWriter.exe"
# Set properties
$identity = "$builtin\Administrators"
$fileSystemRights = "FullControl"
$type = "Allow"
# Create new rule
$fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
$fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
# Apply new rule
$NewAcl.SetAccessRule($fileSystemAccessRule)
Set-Acl -Path "$env:WinDir\System32\GameBarPresenceWriter.exe" -AclObject $NewAcl
Stop-Process -Name "GameBarPresenceWriter.exe" -Force
Remove-Item "$env:WinDir\System32\GameBarPresenceWriter.exe" -Force -Confirm:$false

}
else {
    write-host "GamePresenceWriter.exe does not exist"
}

New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\GameDVR" -Name "AllowgameDVR" -PropertyType DWORD -Value 0 -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "SettingsPageVisibility" -PropertyType String -Value "hide:gaming-gamebar;gaming-gamedvr;gaming-broadcasting;gaming-gamemode;gaming-xboxnetworking" -Force
Remove-Item C:\Windows\Temp\SetACL.exe -recurse

############################################################################################################
#                                        Disable Edge Surf Game                                            #
#                                                                                                          #
############################################################################################################
$surf = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge"
If (!(Test-Path $surf)) {
    New-Item $surf
}
New-ItemProperty -Path $surf -Name 'AllowSurfGame' -Value 0 -PropertyType DWord

############################################################################################################
#                                       Grab all Uninstall Strings                                         #
#                                                                                                          #
############################################################################################################


write-host "Checking 32-bit System Registry"
##Search for 32-bit versions and list them
$allstring = @()
$path1 =  "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
#Loop Through the apps if name has Adobe and NOT reader
$32apps = Get-ChildItem -Path $path1 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

foreach ($32app in $32apps) {
#Get uninstall string
$string1 =  $32app.uninstallstring
#Check if it's an MSI install
if ($string1 -match "^msiexec*") {
#MSI install, replace the I with an X and make it quiet
$string2 = $string1 + " /quiet /norestart"
$string2 = $string2 -replace "/I", "/X "
#Create custom object with name and string
$allstring += New-Object -TypeName PSObject -Property @{
    Name = $32app.DisplayName
    String = $string2
}
}
else {
#Exe installer, run straight path
$string2 = $string1
$allstring += New-Object -TypeName PSObject -Property @{
    Name = $32app.DisplayName
    String = $string2
}
}

}
write-host "32-bit check complete"
write-host "Checking 64-bit System registry"
##Search for 64-bit versions and list them

$path2 =  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
#Loop Through the apps if name has Adobe and NOT reader
$64apps = Get-ChildItem -Path $path2 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

foreach ($64app in $64apps) {
#Get uninstall string
$string1 =  $64app.uninstallstring
#Check if it's an MSI install
if ($string1 -match "^msiexec*") {
#MSI install, replace the I with an X and make it quiet
$string2 = $string1 + " /quiet /norestart"
$string2 = $string2 -replace "/I", "/X "
#Uninstall with string2 params
$allstring += New-Object -TypeName PSObject -Property @{
    Name = $64app.DisplayName
    String = $string2
}
}
else {
#Exe installer, run straight path
$string2 = $string1
$allstring += New-Object -TypeName PSObject -Property @{
    Name = $64app.DisplayName
    String = $string2
}
}

}

write-host "64-bit checks complete"

##USER
write-host "Checking 32-bit User Registry"
##Search for 32-bit versions and list them
$path1 =  "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
##Check if path exists
if (Test-Path $path1) {
#Loop Through the apps if name has Adobe and NOT reader
$32apps = Get-ChildItem -Path $path1 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

foreach ($32app in $32apps) {
#Get uninstall string
$string1 =  $32app.uninstallstring
#Check if it's an MSI install
if ($string1 -match "^msiexec*") {
#MSI install, replace the I with an X and make it quiet
$string2 = $string1 + " /quiet /norestart"
$string2 = $string2 -replace "/I", "/X "
#Create custom object with name and string
$allstring += New-Object -TypeName PSObject -Property @{
    Name = $32app.DisplayName
    String = $string2
}
}
else {
#Exe installer, run straight path
$string2 = $string1
$allstring += New-Object -TypeName PSObject -Property @{
    Name = $32app.DisplayName
    String = $string2
}
}
}
}
write-host "32-bit check complete"
write-host "Checking 64-bit Use registry"
##Search for 64-bit versions and list them

$path2 =  "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
#Loop Through the apps if name has Adobe and NOT reader
$64apps = Get-ChildItem -Path $path2 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

foreach ($64app in $64apps) {
#Get uninstall string
$string1 =  $64app.uninstallstring
#Check if it's an MSI install
if ($string1 -match "^msiexec*") {
#MSI install, replace the I with an X and make it quiet
$string2 = $string1 + " /quiet /norestart"
$string2 = $string2 -replace "/I", "/X "
#Uninstall with string2 params
$allstring += New-Object -TypeName PSObject -Property @{
    Name = $64app.DisplayName
    String = $string2
}
}
else {
#Exe installer, run straight path
$string2 = $string1
$allstring += New-Object -TypeName PSObject -Property @{
    Name = $64app.DisplayName
    String = $string2
}
}

}

############################################################################################################
#                                        Remove Manufacturer Bloat                                         #
#                                                                                                          #
############################################################################################################
##Check Manufacturer
write-host "Detecting Manufacturer"
$details = Get-CimInstance -ClassName Win32_ComputerSystem
$manufacturer = $details.Manufacturer

if ($manufacturer -like "*HP*") {
    Write-Host "HP detected"
    #Remove HP bloat


##HP Specific
	####
	###### Do not include WildTangent Games components here as they are handled separately by brute force below #############
	####
$UninstallPrograms = @(
    "HP Client Security Manager"
    "HP Notifications"
    "HP Security Update Service"
    "HP System Default Settings"
    "HP Wolf Security"
    "HP Wolf Security Application Support for Sure Sense"
    "HP Wolf Security Application Support for Windows"
    "AD2F1837.HPPCHardwareDiagnosticsWindows"
    "AD2F1837.HPPowerManager"
    "AD2F1837.HPPrivacySettings"
    "AD2F1837.HPQuickDrop"
    "AD2F1837.HPSupportAssistant"
    "AD2F1837.HPSystemInformation"
    "AD2F1837.myHP"
    "RealtekSemiconductorCorp.HPAudioControl",
    "HP Sure Recover",
    "HP Sure Run Module"
    "RealtekSemiconductorCorp.HPAudioControl_2.39.280.0_x64__dt26b99r8h8gj"
    "HP Wolf Security - Console"
    "HP Wolf Security Application Support for Chrome 122.0.6261.139"
    "Windows Driver Package - HP Inc. sselam_4_4_2_453 AntiVirus  (11/01/2022 4.4.2.453)"

)


    $HPWhitelistedApps = @(
)

##Change to Add apptoignore to $HPWhitelistedApps
#This ensures that we don't inadvertently remove specifically whitelisted or nonremovable packages
	$HPWhitelistedApps = $HPWhitelistedApps + $appstoignore

$UninstallPrograms = $UninstallPrograms | Where-Object{$HPWhitelistedApps -notcontains $_}

$HPidentifier = "AD2F1837"

$ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {(($UninstallPrograms -contains $_.DisplayName) -or ($_.DisplayName -like "*$HPidentifier*")) -and ($_.DisplayName -notin $HPWhitelistedApps)}

$InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {(($UninstallPrograms -contains $_.Name) -or ($_.Name -like "*$HPidentifier*")) -and ($_.Name -notin $HPWhitelistedApps)}

$InstalledPrograms = $allstring | Where-Object {$UninstallPrograms -contains $_.Name -and $_.Name -notin $HPWhitelistedApps}

# Remove provisioned packages first
ForEach ($ProvPackage in $ProvisionedPackages) {

    Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."

    Try {
        $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
        Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
    }
    Catch {Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"}
}

# Remove appx packages
ForEach ($AppxPackage in $InstalledPackages) {
                                            
    Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

    Try {
        $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
    }
    Catch {Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"}
}

# Remove installed programs
$InstalledPrograms | ForEach-Object {

    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    $uninstallcommand = $_.String

    Try {
        if ($uninstallcommand -match "^msiexec*") {
            #Remove msiexec as we need to split for the uninstall
            $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
            #Uninstall with string2 params
            Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
            }
            else {
            #Exe installer, run straight path
            $string2 = $uninstallcommand
            start-process $string2
            }
        #$A = Start-Process -FilePath $uninstallcommand -Wait -passthru -NoNewWindow;$a.ExitCode
        #$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {Write-Warning -Message "Failed to uninstall: [$($_.Name)]"}


}

##Belt and braces, remove via CIM too
foreach ($program in $UninstallPrograms) {
Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
}


#Remove HP Documentation if it exists
if (test-path -Path "C:\Program Files\HP\Documentation\Doc_uninstall.cmd") {
$A = Start-Process -FilePath "C:\Program Files\HP\Documentation\Doc_uninstall.cmd" -Wait -passthru -NoNewWindow
}

##Remove HP Connect Optimizer if setup.exe exists
if (test-path -Path 'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe') {
invoke-webrequest -uri "https://raw.githubusercontent.com/andrew-s-taylor/public/main/De-Bloat/HPConnOpt.iss" -outfile "C:\Windows\Temp\HPConnOpt.iss"

&'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe' @('-s', '-f1C:\Windows\Temp\HPConnOpt.iss')
}

##Remove other crap
if (Test-Path -Path "C:\Program Files (x86)\HP\Shared" -PathType Container) {Remove-Item -Path "C:\Program Files (x86)\HP\Shared" -Recurse -Force}
if (Test-Path -Path "C:\Program Files (x86)\Online Services" -PathType Container) {Remove-Item -Path "C:\Program Files (x86)\Online Services" -Recurse -Force}
if (Test-Path -Path "C:\ProgramData\HP\TCO" -PathType Container) {Remove-Item -Path "C:\ProgramData\HP\TCO" -Recurse -Force}
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Amazon.com.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Amazon.com.lnk" -Force}
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Angebote.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Angebote.lnk" -Force}
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TCO Certified.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TCO Certified.lnk" -Force}
# a couple more HP links to remove	
	if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Booking.com.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Booking.com.lnk" -Force}
	if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Adobe offers.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Adobe offers.lnk" -Force}

#Brute-force removal of WildTangent Games HP crud
	if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\WildTangent Games.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\WildTangent Games.lnk" -Force}
	if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Games" -PathType Container) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Games" -Recurse -Force}
	if (Test-Path -Path "C:\ProgramData\WildTangent" -PathType Container) {Remove-Item -Path "C:\ProgramData\WildTangent" -Recurse -Force}
	if (Test-Path -Path "C:\Program Files (x86)\WildGames" -PathType Container) {Remove-Item -Path "C:\Program Files (x86)\WildGames" -Recurse -Force}
	if (Test-Path -Path "C:\Program Files (x86)\WildTangent Games" -PathType Container) {Remove-Item -Path "C:\Program Files (x86)\WildTangent Games" -Recurse -Force}
	$Keys = @(
		"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\PropertyHandlers\.oidiwin005773primeroselakeSavedGame"
		"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\WildTangent hp Master Uninstall"
		"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WildTangent wildgames Master Uninstall"
		"HKLM:\SOFTWARE\WOW6432Node\WildTangent"
	)
	ForEach ($Key in $Keys) {
		If (test-path -path $Key) {
			Write-Host "Removing $Key from registry"
			Remove-Item $Key -Recurse -Force
		} 
	}
	#remove any leftover WildTangent uninstall keys
	$Keys = Get-ChildItem "HKLM:\Software\WOW6432NODE\Microsoft\Windows\CurrentVersion\Uninstall" | get-itemproperty | `
		where-object {($_.uninstallstring -like '*WildTangent*') -or ($_.uninstallstring -like '*WildGames*')} | select-object pspath
	ForEach ($Key in $Keys) {
		Remove-Item $Key.pspath.replace("Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE", "HKLM:") -Recurse -Force
	}

#This clears any HP preinstalled MsEdge favorites so that it can be cleanly customized using custom json or Intune Managed Favorites

	#Delete the ini file that is involved
	if (Test-Path -Path "C:\HP\HPQWare\BTBHost\WizEdgeFav.ini" -PathType Leaf) {Remove-Item -Path "C:\HP\HPQWare\BTBHost\WizEdgeFav.ini" -Force}

	#Clear Registry keys to delete the pre-loaded favorites
	$Keys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\MicrosoftEdge\Main\FavoriteBarItems" | select-object pspath
	ForEach ($Key in $Keys) {
		Remove-Item $Key.pspath.replace("Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE", "HKLM:") -Recurse -Force
	}

Write-Host "Removed HP bloat"
}



if ($manufacturer -like "*Dell*") {
    Write-Host "Dell detected"
    #Remove Dell bloat

##Dell

$UninstallPrograms = @(
    "Dell Optimizer"
    "Dell Power Manager"
    "DellOptimizerUI"
    "Dell SupportAssist OS Recovery"
    "Dell SupportAssist"
    "Dell Optimizer Service"
        "Dell Optimizer Core"
    "DellInc.PartnerPromo"
    "DellInc.DellOptimizer"
    "DellInc.DellCommandUpdate"
        "DellInc.DellPowerManager"
        "DellInc.DellDigitalDelivery"
        "DellInc.DellSupportAssistforPCs"
        "DellInc.PartnerPromo"
        "Dell Command | Update"
    "Dell Command | Update for Windows Universal"
        "Dell Command | Update for Windows 10"
        "Dell Command | Power Manager"
        "Dell Digital Delivery Service"
    "Dell Digital Delivery"
        "Dell Peripheral Manager"
        "Dell Power Manager Service"
    "Dell SupportAssist Remediation"
    "SupportAssist Recovery Assistant"
        "Dell SupportAssist OS Recovery Plugin for Dell Update"
        "Dell SupportAssistAgent"
        "Dell Update - SupportAssist Update Plugin"
        "Dell Core Services"
        "Dell Pair"
        "Dell Display Manager 2.0"
        "Dell Display Manager 2.1"
        "Dell Display Manager 2.2"
        "Dell SupportAssist Remediation"
        "Dell Update - SupportAssist Update Plugin"
        "DellInc.PartnerPromo"
)



$WhitelistedApps = @(
    "WavesAudio.MaxxAudioProforDell2019"
    "Dell - Extension*"
    "Dell, Inc. - Firmware*"
)

##Add custom whitelist apps
    ##If custom whitelist specified, remove from array
    if ($customwhitelist) {
        $customWhitelistApps = $customwhitelist -split ","
    foreach ($customwhitelistapp in $customwhitelistapps) {
        $WhitelistedApps += $customwhitelistapp
    }        
    }

    $UninstallPrograms = $UninstallPrograms | Where-Object{$WhitelistedApps -notcontains $_}

    $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {(($UninstallPrograms -contains $_.DisplayName) -or (($_.DisplayName -like "*Dell")-and ($_.DisplayName -notin $WhitelistedApps)))}

    $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {(($UninstallPrograms -contains $_.Name) -or (($_.Name -like "*Dell"))-and ($_.Name -notin $WhitelistedApps))}
    
    $InstalledPrograms = $allstring | Where-Object {$UninstallPrograms -contains $_.Name}
    # Remove provisioned packages first
ForEach ($ProvPackage in $ProvisionedPackages) {

    Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."

    Try {
        $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
        Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
    }
    Catch {Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"}
}

# Remove appx packages
ForEach ($AppxPackage in $InstalledPackages) {
                                            
    Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

    Try {
        $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
    }
    Catch {Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"}
}

# Remove any bundled packages
ForEach ($AppxPackage in $InstalledPackages) {
                                            
    Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

    Try {
        $null = Get-AppxPackage -AllUsers -PackageTypeFilter Main, Bundle, Resource -Name $AppxPackage.Name | Remove-AppxPackage -AllUsers
        Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
    }
    Catch {Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"}
}


$ExcludedPrograms = @("Dell Optimizer Core", "Dell SupportAssist Remediation", "Dell SupportAssist OS Recovery Plugin for Dell Update", "Dell Pair", "Dell Display Manager 2.0", "Dell Display Manager 2.1", "Dell Display Manager 2.2", "Dell Peripheral Manager")
$InstalledPrograms2 = $InstalledPrograms | Where-Object { $ExcludedPrograms -notcontains $_.Name }

# Remove installed programs
$InstalledPrograms2 | ForEach-Object {

    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    $uninstallcommand = $_.String

    Try {
        if ($uninstallcommand -match "^msiexec*") {
            #Remove msiexec as we need to split for the uninstall
            $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
            $uninstallcommand = $uninstallcommand + " /quiet /norestart"
            $uninstallcommand = $uninstallcommand -replace "/I", "/X "   
            #Uninstall with string2 params
            Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
            }
            else {
            #Exe installer, run straight path
            $string2 = $uninstallcommand
            start-process $string2
            }
        #$A = Start-Process -FilePath $uninstallcommand -Wait -passthru -NoNewWindow;$a.ExitCode        
        #$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {Write-Warning -Message "Failed to uninstall: [$($_.Name)]"}
}

##Belt and braces, remove via CIM too
foreach ($program in $UninstallPrograms) {
    Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
    }

##Manual Removals

##Dell Optimizer
$dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Optimizer*Core" } | Select-Object -Property UninstallString
 
ForEach ($sa in $dellSA) {
    If ($sa.UninstallString) {
        try {
        cmd.exe /c $sa.UninstallString -silent
        }
        catch {
            Write-Warning "Failed to uninstall Dell Optimizer"
        }
    }
}


##Dell Dell SupportAssist Remediation
$dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist Remediation" } | Select-Object -Property QuietUninstallString
 
ForEach ($sa in $dellSA) {
    If ($sa.QuietUninstallString) {
        try {
            cmd.exe /c $sa.QuietUninstallString
            }
            catch {
                Write-Warning "Failed to uninstall Dell Support Assist Remediation"
            }    }
}

##Dell Dell SupportAssist OS Recovery Plugin for Dell Update
$dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist OS Recovery Plugin for Dell Update" } | Select-Object -Property QuietUninstallString
 
ForEach ($sa in $dellSA) {
    If ($sa.QuietUninstallString) {
        try {
            cmd.exe /c $sa.QuietUninstallString
            }
            catch {
                Write-Warning "Failed to uninstall Dell Support Assist Remediation"
            }    }
}



    ##Dell Display Manager
$dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Display*Manager*" } | Select-Object -Property UninstallString
 
ForEach ($sa in $dellSA) {
    If ($sa.UninstallString) {
        try {
        cmd.exe /c $sa.UninstallString /S
        }
        catch {
            Write-Warning "Failed to uninstall Dell Optimizer"
        }
    }
}

    ##Dell Peripheral Manager

            try {
            start-process c:\windows\system32\cmd.exe '/c "C:\Program Files\Dell\Dell Peripheral Manager\Uninstall.exe" /S'
            }
            catch {
                Write-Warning "Failed to uninstall Dell Optimizer"
            }


    ##Dell Pair

            try {
                start-process c:\windows\system32\cmd.exe '/c "C:\Program Files\Dell\Dell Pair\Uninstall.exe" /S'
            }
            catch {
                Write-Warning "Failed to uninstall Dell Optimizer"
            }

        }


if ($manufacturer -like "Lenovo") {
    Write-Host "Lenovo detected"

    #Remove HP bloat

##Lenovo Specific
    # Function to uninstall applications with .exe uninstall strings

    function UninstallApp {

        param (
            [string]$appName
        )

        # Get a list of installed applications from Programs and Features
        $installedApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object { $_.DisplayName -like "*$appName*" }

        # Loop through the list of installed applications and uninstall them

        foreach ($app in $installedApps) {
            $uninstallString = $app.UninstallString
            $displayName = $app.DisplayName
            Write-Host "Uninstalling: $displayName"
            Start-Process $uninstallString -ArgumentList "/VERYSILENT" -Wait
            Write-Host "Uninstalled: $displayName" -ForegroundColor Green
        }
    }

    ##Stop Running Processes

    $processnames = @(
    "SmartAppearanceSVC.exe"
    "UDClientService.exe"
    "ModuleCoreService.exe"
    "ProtectedModuleHost.exe"
    "*lenovo*"
    "FaceBeautify.exe"
    "McCSPServiceHost.exe"
    "mcapexe.exe"
    "MfeAVSvc.exe"
    "mcshield.exe"
    "Ammbkproc.exe"
    "AIMeetingManager.exe"
    "DADUpdater.exe"
    "CommercialVantage.exe"
    )

    foreach ($process in $processnames) {
        write-host "Stopping Process $process"
        Get-Process -Name $process | Stop-Process -Force
        write-host "Process $process Stopped"
    }

    $UninstallPrograms = @(
        "E046963F.AIMeetingManager"
        "E0469640.SmartAppearance"
        "MirametrixInc.GlancebyMirametrix"
        "E046963F.LenovoCompanion"
        "E0469640.LenovoUtility"
        "E0469640.LenovoSmartCommunication"
        "E046963F.LenovoSettingsforEnterprise"
        "E046963F.cameraSettings"
        "4505Fortemedia.FMAPOControl2_2.1.37.0_x64__4pejv7q2gmsnr"
        "ElevocTechnologyCo.Ltd.SmartMicrophoneSettings_1.1.49.0_x64__ttaqwwhyt5s6t"
    )

        ##If custom whitelist specified, remove from array
        if ($customwhitelist) {
            $customWhitelistApps = $customwhitelist -split ","
            $UninstallPrograms = $UninstallPrograms | Where-Object { $customWhitelistApps -notcontains $_ }
        }
    
    
    $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {(($_.Name -in $UninstallPrograms))}

    $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {(($_.Name -in $UninstallPrograms))}
        
    $InstalledPrograms = $allstring | Where-Object {(($_.Name -in $UninstallPrograms))}
    # Remove provisioned packages first
    ForEach ($ProvPackage in $ProvisionedPackages) {
    
        Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
    
        Try {
            $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
            Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
        }
        Catch {Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"}
    }
    
    # Remove appx packages
    ForEach ($AppxPackage in $InstalledPackages) {
                                                
        Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
    
        Try {
            $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
        }
        Catch {Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"}
    }
    
    # Remove any bundled packages
    ForEach ($AppxPackage in $InstalledPackages) {
                                                
        Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
    
        Try {
            $null = Get-AppxPackage -AllUsers -PackageTypeFilter Main, Bundle, Resource -Name $AppxPackage.Name | Remove-AppxPackage -AllUsers
            Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
        }
        Catch {Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"}
    }
    
    
# Remove installed programs
$InstalledPrograms | ForEach-Object {

    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    $uninstallcommand = $_.String

    Try {
        if ($uninstallcommand -match "^msiexec*") {
            #Remove msiexec as we need to split for the uninstall
            $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
            #Uninstall with string2 params
            Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
            }
            else {
            #Exe installer, run straight path
            $string2 = $uninstallcommand
            start-process $string2
            }
        #$A = Start-Process -FilePath $uninstallcommand -Wait -passthru -NoNewWindow;$a.ExitCode
        #$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {Write-Warning -Message "Failed to uninstall: [$($_.Name)]"}
}

##Belt and braces, remove via CIM too
foreach ($program in $UninstallPrograms) {
    Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
    }

    # Get Lenovo Vantage service uninstall string to uninstall service
    $lvs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object DisplayName -eq "Lenovo Vantage Service"
    if (!([string]::IsNullOrEmpty($lvs.QuietUninstallString))) {
        $uninstall = "cmd /c " + $lvs.QuietUninstallString
        Write-Host $uninstall
        Invoke-Expression $uninstall
    }

    # Uninstall Lenovo Smart
    UninstallApp -appName "Lenovo Smart"

    # Uninstall Ai Meeting Manager Service
    UninstallApp -appName "Ai Meeting Manager"

    # Uninstall ImController service
    ##Check if exists
    $path = "c:\windows\system32\ImController.InfInstaller.exe"
    if (Test-Path $path) {
        Write-Host "ImController.InfInstaller.exe exists"
        $uninstall = "cmd /c " + $path + " -uninstall"
        Write-Host $uninstall
        Invoke-Expression $uninstall
    }
    else {
        Write-Host "ImController.InfInstaller.exe does not exist"
    }
    ##Invoke-Expression -Command 'cmd.exe /c "c:\windows\system32\ImController.InfInstaller.exe" -uninstall'

    # Remove vantage associated registry keys
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\ImController' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Lenovo Vantage' -Recurse -ErrorAction SilentlyContinue
    #Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Commercial Vantage' -Recurse -ErrorAction SilentlyContinue

     # Uninstall AI Meeting Manager Service
     $path = 'C:\Program Files\Lenovo\Ai Meeting Manager Service\unins000.exe'
     $params = "/SILENT"
     if (test-path -Path $path) {
     Start-Process -FilePath $path -ArgumentList $params -Wait
     }
    # Uninstall Lenovo Vantage
    $pathname = (Get-ChildItem -Path "C:\Program Files (x86)\Lenovo\VantageService").name
    $path = "C:\Program Files (x86)\Lenovo\VantageService\$pathname\Uninstall.exe"
    $params = '/SILENT'
    if (test-path -Path $path) {
        Start-Process -FilePath $path -ArgumentList $params -Wait
    }
 
    ##Uninstall Smart Appearance
    $path = 'C:\Program Files\Lenovo\Lenovo Smart Appearance Components\unins000.exe'
    $params = '/SILENT'
    if (test-path -Path $path) {
        try {
            Start-Process -FilePath $path -ArgumentList $params -Wait
        }
        catch {
            Write-Warning "Failed to start the process"
        }
    }
$lenovowelcome = "c:\program files (x86)\lenovo\lenovowelcome\x86"
if (Test-Path $lenovowelcome) {
    # Remove Lenovo Now
    Set-Location "c:\program files (x86)\lenovo\lenovowelcome\x86"

    # Update $PSScriptRoot with the new working directory
    $PSScriptRoot = (Get-Item -Path ".\").FullName
    try {
        invoke-expression -command .\uninstall.ps1 -ErrorAction SilentlyContinue
    } catch {
        write-host "Failed to execute uninstall.ps1"
    }

    Write-Host "All applications and associated Lenovo components have been uninstalled." -ForegroundColor Green
}

$lenovonow = "c:\program files (x86)\lenovo\LenovoNow\x86"
if (Test-Path $lenovonow) {
    # Remove Lenovo Now
    Set-Location "c:\program files (x86)\lenovo\LenovoNow\x86"

    # Update $PSScriptRoot with the new working directory
    $PSScriptRoot = (Get-Item -Path ".\").FullName
    try {
        invoke-expression -command .\uninstall.ps1 -ErrorAction SilentlyContinue
    } catch {
        write-host "Failed to execute uninstall.ps1"
    }

    Write-Host "All applications and associated Lenovo components have been uninstalled." -ForegroundColor Green
}
}


############################################################################################################
#                                        Remove Any other installed crap                                   #
#                                                                                                          #
############################################################################################################

#McAfee

write-host "Detecting McAfee"
$mcafeeinstalled = "false"
$InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($obj in $InstalledSoftware){
     $name = $obj.GetValue('DisplayName')
     if ($name -like "*McAfee*") {
         $mcafeeinstalled = "true"
     }
}

$InstalledSoftware32 = Get-ChildItem "HKLM:\Software\WOW6432NODE\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($obj32 in $InstalledSoftware32){
     $name32 = $obj32.GetValue('DisplayName')
     if ($name32 -like "*McAfee*") {
         $mcafeeinstalled = "true"
     }
}

if ($mcafeeinstalled -eq "true") {
    Write-Host "McAfee detected"
    #Remove McAfee bloat
##McAfee
### Download McAfee Consumer Product Removal Tool ###
write-host "Downloading McAfee Removal Tool"
# Download Source
$URL = 'https://github.com/andrew-s-taylor/public/raw/main/De-Bloat/mcafeeclean.zip'

# Set Save Directory
$destination = 'C:\ProgramData\Debloat\mcafee.zip'

#Download the file
Invoke-WebRequest -Uri $URL -OutFile $destination -Method Get
  
Expand-Archive $destination -DestinationPath "C:\ProgramData\Debloat" -Force

write-host "Removing McAfee"
# Automate Removal and kill services
start-process "C:\ProgramData\Debloat\Mccleanup.exe" -ArgumentList "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s"
write-host "McAfee Removal Tool has been run"

###New MCCleanup
### Download McAfee Consumer Product Removal Tool ###
write-host "Downloading McAfee Removal Tool"
# Download Source
$URL = 'https://github.com/andrew-s-taylor/public/raw/main/De-Bloat/mccleanup.zip'

# Set Save Directory
$destination = 'C:\ProgramData\Debloat\mcafeenew.zip'

#Download the file
Invoke-WebRequest -Uri $URL -OutFile $destination -Method Get
  
New-Item -Path "C:\ProgramData\Debloat\mcnew" -ItemType Directory
Expand-Archive $destination -DestinationPath "C:\ProgramData\Debloat\mcnew" -Force

write-host "Removing McAfee"
# Automate Removal and kill services
start-process "C:\ProgramData\Debloat\mcnew\Mccleanup.exe" -ArgumentList "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s"
write-host "McAfee Removal Tool has been run"

$InstalledPrograms = $allstring | Where-Object {($_.Name -like "*McAfee*")}
$InstalledPrograms | ForEach-Object {

    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    $uninstallcommand = $_.String

    Try {
        if ($uninstallcommand -match "^msiexec*") {
            #Remove msiexec as we need to split for the uninstall
            $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
            $uninstallcommand = $uninstallcommand + " /quiet /norestart"
            $uninstallcommand = $uninstallcommand -replace "/I", "/X "   
            #Uninstall with string2 params
            Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
            }
            else {
            #Exe installer, run straight path
            $string2 = $uninstallcommand
            start-process $string2
            }
        #$A = Start-Process -FilePath $uninstallcommand -Wait -passthru -NoNewWindow;$a.ExitCode        
        #$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {Write-Warning -Message "Failed to uninstall: [$($_.Name)]"}
}

##Remove Safeconnect
$safeconnects = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "McAfee Safe Connect" } | Select-Object -Property UninstallString
 
ForEach ($sc in $safeconnects) {
    If ($sc.UninstallString) {
        cmd.exe /c $sc.UninstallString /quiet /norestart
    }
}
##
##remove some extra leftover Mcafee items from StartMenu-AllApps and uninstall registry keys
##
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\McAfee") {
	Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\McAfee" -Recurse -Force
}
if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\McAfee.WPS") {
	Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\McAfee.WPS" -Recurse -Force
}
#Interesting emough, this producese an erro, but still deletes the package anyway
Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq "McAfeeWPSSparsePackage" | Remove-AppxProvisionedPackage -Online -AllUsers

}


##Look for anything else

##Make sure Intune hasn't installed anything so we don't remove installed apps

$intunepath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"
if (Test-Path $intunepath) {
	$intunecomplete = @(Get-ChildItem $intunepath).count
} else {
	$intunecomplete = 0
}
$userpath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
$userprofiles = Get-ChildItem $userpath | ForEach-Object { Get-ItemProperty $_.PSPath }

$nonAdminLoggedOn = $false
foreach ($user in $userprofiles) {
#first condition changed to use profileimageath as the default use ins not alwasy default e.g. default0 on some systems
if ($user.ProfileImagePath -notlike '*DEFAULT*' -and $user.PSChildName -ne 'S-1-5-18' -and $user.PSChildName -ne 'S-1-5-19' -and $user.PSChildName -ne 'S-1-5-20' -and $user.PSChildName -notmatch 'S-1-5-21-\d+-\d+-\d+-500') {
        $nonAdminLoggedOn = $true
        break
    }
}

# This logic is corrected so that the code runs if there are no intuneinstalled items($intunecomplete -lt 1)
#	and therehas been no nonADmins logged into the system ($nonAdminLoggedOn -eq $false)
if ($intunecomplete -lt 1 -and $nonAdminLoggedOn -eq $false) {


##Apps to remove - NOTE: Chrome has an unusual uninstall so sort on it's own
$blacklistapps = @(

)

 $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString, DisplayName_Localized
 foreach($obj in $InstalledSoftware){
     $name = $obj.DisplayName
     if ($null -eq $name) {
         $name = $obj.DisplayName_Localized
     }
      if (($blacklistapps -contains $name) -and ($null -ne $obj.UninstallString)) {
         $uninstallcommand = $obj.UninstallString
         write-host "Uninstalling $name"
         if ($uninstallcommand -like "*msiexec*") {
         $splitcommand = $uninstallcommand.Split("{")
         $msicode = $splitcommand[1]
         $uninstallapp = "msiexec.exe /X {$msicode /qn"
         start-process "cmd.exe" -ArgumentList "/c $uninstallapp"
         }
         else {
         $splitcommand = $uninstallcommand.Split("{")
        
         $uninstallapp = "$uninstallcommand /S"
         start-process "cmd.exe" -ArgumentList "/c $uninstallapp"
         }
      }

      }


      $InstalledSoftware32 = Get-ChildItem "HKLM:\Software\WOW6432NODE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString, DisplayName_Localized
      foreach($obj32 in $InstalledSoftware32){
         $name32 = $obj32.DisplayName
         if ($null -eq $name32) {
             $name32 = $obj.DisplayName_Localized
         }
         if (($blacklistapps -contains $name32) -and ($null -ne $obj32.UninstallString)) {
         $uninstallcommand32 = $obj.UninstallString
         write-host "Uninstalling $name32"
                 if ($uninstallcommand32 -like "*msiexec*") {
         $splitcommand = $uninstallcommand32.Split("{")
         $msicode = $splitcommand[1]
         $uninstallapp = "msiexec.exe /X {$msicode /qn"
         start-process "cmd.exe" -ArgumentList "/c $uninstallapp"
         }
         else {
         $splitcommand = $uninstallcommand32.Split("{")
        
         $uninstallapp = "$uninstallcommand /S"
         start-process "cmd.exe" -ArgumentList "/c $uninstallapp"
         }
     }
}

##Remove Chrome
$chrome32path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome"

if ($null -ne $chrome32path) {

$versions = (Get-ItemProperty -path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome').version
ForEach ($version in $versions) {
write-host "Found Chrome version $version"
$directory = ${env:ProgramFiles(x86)}
write-host "Removing Chrome"
Start-Process "$directory\Google\Chrome\Application\$version\Installer\setup.exe" -argumentlist  "--uninstall --multi-install --chrome --system-level --force-uninstall"
}

}

$chromepath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome"

if ($null -ne $chromepath) {

$versions = (Get-ItemProperty -path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome').version
ForEach ($version in $versions) {
write-host "Found Chrome version $version"
$directory = ${env:ProgramFiles}
write-host "Removing Chrome"
Start-Process "$directory\Google\Chrome\Application\$version\Installer\setup.exe" -argumentlist  "--uninstall --multi-install --chrome --system-level --force-uninstall"
}


}

##Remove ANY pre-installed versions of Office
# This was changed to use the MS SaRa Enterprise tool as MsTeamsWork installs work unreliably if there is ANY remnant of an Office install
# the SaRa tool was forked and patched for a code bug that prevented it runnning in OfficeScrubScenario
#
if (test-path -path 'C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe') {
	write-host "removing all Office versions"
	### Download SaRa Office Uninstall script ###
	write-host "Downloading SaRa Office Removal Tool"
	
	# Download Source
	#This fork of the SaRa Enterprise tool has a bug fix so that the OfficeScrubScenario will run
		# and is set to do OfficeScrubScenario
	$URL = 'https://github.com/keithcvms/public/raw/main/De-Bloat/ExecuteSaraOfficeUninstall.ps1'
	# Set Save Directory
	$destination = 'C:\ProgramData\Debloat\ExecuteSaraOfficeUninstall.ps1'
	#Download the file
	Invoke-WebRequest -Uri $URL -OutFile $destination -Method Get

	#Run the SaraRemoval script
	invoke-expression -command $destination -ErrorAction Continue
} else {
	write-host "No ClickToRun Office versions found"
}

write-host "Anything else removal complete"


}

write-host "Completed"

#write out completion time to tag File
Add-Content -Path "$DebloatTag" -Value "Complete Script $(get-date)"

Stop-Transcript

Exit 0
