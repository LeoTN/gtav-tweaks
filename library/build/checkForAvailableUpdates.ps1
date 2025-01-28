[CmdletBinding()]
Param (
    # The GitHub repository link where to check for updates.
    [Parameter(Mandatory = $true)]
    [String]$pGitHubRepositoryLink,
    # The file that is used to determine if an update is required.
    [Parameter(Mandatory = $true)]
    [String]$pCurrentVersionFileLocation,
    # The directory where the current version is installed.
    [Parameter(Mandatory = $true)]
    [String]$pCurrentInstallationDirectory,
    # If provided, will force the script to find the highest available update version, even if the current version is already the highest.
    [Parameter(Mandatory = $false)]
    [switch]$pSwitchForceUpdate,
    # If provided, the script will consider beta releases as available update versions.
    [Parameter(Mandatory = $false)]
    [switch]$pSwitchConsiderBetaReleases
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$Host.UI.RawUI.WindowTitle = "GTAV Tweaks - Update Script"
$scriptParentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFileName = "checkForAvailableUpdates.log"
$logFilePath = Join-Path -Path $scriptParentDirectory -ChildPath $logFileName
$null = Start-Transcript -Path $logFilePath -Force
$null = Clear-Host
$null = Write-Host "Terminal ready..."

function onInit() {
    # A list of all exit codes can be found at the end of this script.

    # Makes sure, that we do not have a shortened path.
    $pCurrentVersionFileLocation = [System.IO.Path]::GetFullPath($pCurrentVersionFileLocation)
    # These variables store information about the update.
    $global:currentVersion = ""
    $global:currentVersionLastUpdateDate = ""
    
    # Exit code list at the end of this file.
    $exitCode = evaluateUpdate
    $null = Write-Host "[onInit()] [INFO] Exiting with exit code [$exitCode]."

    $supportFilesFolderName = "GTAV_Tweaks"
    $supportFilesFolder = Join-Path -Path $pCurrentInstallationDirectory -ChildPath $supportFilesFolderName
    $supportFilesFolderUpdateFolder = Join-Path -Path $supportFilesFolder -ChildPath "update"
    # Copies the log file into the support file folder.
    If (Test-Path -Path $supportFilesFolderUpdateFolder) {
        $null = Copy-Item -Path $logFilePath -Destination (Join-Path -Path $supportFilesFolderUpdateFolder -ChildPath $logFileName) -Force
    }
    # Speeds up the script when it's ran without the user seeing it.
    If (checkIfScriptWindowIsHidden) {
        $null = Start-Sleep -Seconds 3
    }
    Exit $exitCode
}

# Evaluates, if an update is available and returns an exit code accordingly.
function evaluateUpdate() {
    # A list of all exit codes can be found at the end of this script.

    # This function fills the two variables above with a value from the currentVersion.CSV file.
    # If the extraction is not successful, the script will delete the incorrect current version file.
    If (-not (extractCurrentVersionFileContent)) {
        $null = Write-Host "`n`n[evaluateUpdate()] [WARNING] The file [$pCurrentVersionFileLocation] seems corrupted or unavailable. A new file needs to be created by (re)installing the software using the .MSI file.`n`n" -ForegroundColor "Yellow"
        $null = Remove-Item -Path $pCurrentVersionFileLocation -ErrorAction SilentlyContinue
        Return 1
    }
    $null = Write-Host "`n`n[evaluateUpdate()] [INFO] The current version [$global:currentVersion] had it's last update on [$global:currentVersionLastUpdateDate].`n`n" -ForegroundColor "Green"

    $availableUpdateVersion = getAvailableUpdateTag
    If ($availableUpdateVersion -eq "no_available_update") {
        $null = Write-Host "`n`n[evaluateUpdate()] [INFO] There are no updates available.`n`n" -ForegroundColor "Green"
        Return 100
    }
    # Updates the current version file.
    $currentVersionFileObject = readFromCSVFile -pFileLocation $pCurrentVersionFileLocation
    $currentVersionFileObject["AVAILABLE_UPDATE"] = $availableUpdateVersion
    $null = writeToCSVFile -pFileLocation $pCurrentVersionFileLocation -pContent $currentVersionFileObject -pSwitchForce
    $null = Write-Host "`n`n[evaluateUpdate()] [INFO] There is an update available [$availableUpdateVersion].`n`n" -ForegroundColor "Green"
    Return 101
}

function extractCurrentVersionFileContent() {
    $currentVersionHashtable = readFromCSVFile -pFileLocation $pCurrentVersionFileLocation
    If (!$currentVersionHashtable) {
        $null = Write-Host "[extractCurrentVersionFileContent()] [ERROR] Failed to load data from [$pCurrentVersionFileLocation]." -ForegroundColor "Red"
        Return $false
    }

    ForEach ($pair in $currentVersionHashtable.GetEnumerator()) {
        $key = $pair.Key
        $value = $pair.Value
        # Extracs the data from the current version file.
        If ($key -eq "CURRENT_VERSION") {
            $global:currentVersion = $value
        }
        ElseIf ($key -eq "CURRENT_VERSION_LAST_UPDATED") {
            # This date will be checked below.
            $global:currentVersionLastUpdateDate = $value
        }
    }
    # Checks if the provided tag has a valid syntaxt.
    $tmpTag = $global:currentVersion.Replace("v", "").Replace("-beta", "")
    If (-not ($tmpTag -match '^\d+\.\d+\.\d+(\.\d+)?$')) {
        $null = Write-Host "[extractCurrentVersionFileContent()] [ERROR] Found tag name which couldn't be converted to version: [$global:currentVersion]." -ForegroundColor "Red"
        Return $false
    }
    If ($global:currentVersionLastUpdateDate -eq "not_updated_yet") {
        $null = Write-Host "[extractCurrentVersionFileContent()] [INFO] This version [$global:currentVersion] has not been updatet yet. Trying to fetch latest update date..."
        $global:currentVersionLastUpdateDate = getLastUpdatedDateFromTag -pTagName $global:currentVersion
        # This happens, when there is still no latest update date available.
        If ($global:currentVersionLastUpdateDate -eq "not_updated_yet") {
            $null = Write-Host "[extractCurrentVersionFileContent()] [INFO] Could not fetch any update dates for [$global:currentVersion]."
            Return $true
        }
        $null = Write-Host "[extractCurrentVersionFileContent()] [INFO] Fetched last update date: [$global:currentVersionLastUpdateDate]. Updating current version file..."
        $currentVersionHashtable["CURRENT_VERSION_LAST_UPDATED"] = $global:currentVersionLastUpdateDate
        # Corrects the current version file.
        If (writeToCSVFile -pFileLocation $pCurrentVersionFileLocation -pContent $currentVersionHashtable -pSwitchForce) {
            $null = Write-Host "[extractCurrentVersionFileContent()] [INFO] Successfully updated last update date in [$pCurrentVersionFileLocation] for [$global:currentVersion]."
            Return $true
        }
        # If this fails, it isn't a big deal.
        $null = Write-Host "[extractCurrentVersionFileContent()] [WARNING] Failed to update last update date in [$pCurrentVersionFileLocation] for [$global:currentVersion]." -ForegroundColor "Yellow"
        Return $true
    }
    If (-not (checkIfStringIsValidDate -pDateTimeString $global:currentVersionLastUpdateDate)) {
        $null = Write-Host "[extractCurrentVersionFileContent()] [ERROR] Found an invalid last update date [$global:currentVersionLastUpdateDate] for [$global:currentVersion]." -ForegroundColor "Red"
        Return $false
    }
    # Forcing an internationally valid date format here should prevent issues.
    $currentDateTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $highestDateTime = compareDates -pDateString1 $global:currentVersionLastUpdateDate -pDateString2 $currentDateTime
    # This mean the current last update date lies in the future.
    If ((compareDates -pDateString1 $highestDateTime -pDateString2 $currentDateTime) -ne "identical_dates") {
        $null = Write-Host "[extractCurrentVersionFileContent()] [WARNING] The last update date [$global:currentVersionLastUpdateDate] from [$global:currentVersion] lies in the future." -ForegroundColor "Yellow"
        Return $false
    }
    Return $true
}

# Checks for available updates and returns either "no_available_update" or the update tag name.
function getAvailableUpdateTag() {
    If (-not (checkInternetConnectionStatus)) {
        $null = Write-Host "[getAvailableUpdateTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
        Return "no_available_update"
    }

    $currentTag = $global:currentVersion
    $latestTag = getLatestTag
    $highestTag = compareVersions -pVersion1 $currentTag -pVersion2 $latestTag
    # This means there is an update available. We are returning the latest tag and not the highest tag, because returning the
    # highest tag could result in an update to the "current" beta version, when pSwitchConsiderBetaReleases is not true.
    If ($pSwitchForceUpdate) {
        $null = Write-Host "[getAvailableUpdateTag()] [INFO] Forced update. Highest available version: [$latestTag]."
        Return $latestTag
    }
    If ($highestTag -eq $latestTag) {
        $null = Write-Host "[getAvailableUpdateTag()] [INFO] Found a higher version to update: [$highestTag]."
        Return $highestTag
    }

    $currentTagLatestUpdateDate = $global:currentVersionLastUpdateDate
    $latestTagLatestUpdateDate = getLastUpdatedDateFromTag -pTagName $latestTag
    # This might happen with new releases.
    If ($latestTagLatestUpdateDate -eq "not_updated_yet") {
        $null = Write-Host "[getAvailableUpdateTag()] [INFO] Could not find any available updates."
        Return "no_available_update"
    }
    $highestLatestUpdateDate = compareDates -pDateString1 $currentTagLatestUpdateDate -pDateString2 $latestTagLatestUpdateDate
    # This means there is an update available.
    If ($highestLatestUpdateDate -eq $latestTagLatestUpdateDate) {
        $null = Write-Host "[getAvailableUpdateTag()] [INFO] Your current version [$currentTag] has received an update."
        Return $currentTag
    }
    $null = Write-Host "[getAvailableUpdateTag()] [INFO] Could not find any available updates."
    Return "no_available_update"
}

# This function uses semantic versioning to determine if a tag is the latest.
function getLatestTag() {
    If (-not (checkInternetConnectionStatus)) {
        $null = Write-Host "[getLatestTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
        Return $false
    }

    Try {
        # This converts the "normal" repository link in order to use the GitHub API.
        $apiUrl = $pGitHubRepositoryLink -Replace "github\.com", "api.github.com/repos"
        $fullApiUrl = "$apiUrl/tags"
        $tagsResponse = Invoke-RestMethod -Uri $fullApiUrl -Method Get

        $latestTag = "v0.0.0"
        # Iterating through the tags.
        Foreach ($tag in $tagsResponse) {
            $tmpTag = $tag.name
            # Removing unwanted characters and beta label.
            $tmpTag = $tmpTag.Replace("v", "")
            If ($tmpTag -like "*-beta" -and !$pSwitchConsiderBetaReleases) {
                $null = Write-Host "[getLatestTag()] [INFO] Skipping tag [$tmpTag] which is a beta release."
                Continue
            }
            # Checking if the version is valid.
            $tmpTag = $tmpTag.Replace("-beta", "")
            If (-not ($tmpTag -match '^\d+\.\d+\.\d+(\.\d+)?$')) {
                $null = Write-Host "[getLatestTag()] [WARNING] Found tag name which couldn't be converted to version: [$tmpTag]." -ForegroundColor "Yellow"
                Continue
            }
            # Finds the highest version.
            $latestTag = compareVersions -pVersion1 $latestTag -pVersion2 $tag.name
        }
        $null = Write-Host "[getLatestTag()] [INFO] Found highest tag: [$latestTag]."
        Return $latestTag
    }
    Catch {
        $null = Write-Host "[getLatestTag()] [ERROR] Failed to fetsh latest tag! Detailed error description below.`n" -ForegroundColor "Red"
        $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        Return $false
    }
}

function getLastUpdatedDateFromTag() {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$pTagName
    )
   
    If (-not (checkInternetConnectionStatus)) {
        $null = Write-Host "[getLastUpdatedDateFromTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
        Return "not_updated_yet"
    }
    Try {
        # This converts the "normal" repository link in order to use the GitHub API.
        $apiUrl = $pGitHubRepositoryLink -Replace "github\.com", "api.github.com/repos"
        $fullApiUrl = "$apiUrl/releases/tags/$pTagName"
        $tagResponse = Invoke-RestMethod -Uri $fullApiUrl
        # The date is not a valid PowerShell datetime data type. That's why we are converting it.
        $invalidLastUpdateDate = ($tagResponse.assets | Select-Object -ExpandProperty updated_at)
        # This happens, when the release hasn't been updated yet.
        If (!$invalidLastUpdateDate) {
            $null = Write-Host "[getLastUpdatedDateFromTag()] [INFO] No update date for [$pTagName] found."
            Return "not_updated_yet"
        }
        # Forcing an internationally valid date format here should prevent issues.
        $lastUpdateDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss" $invalidLastUpdateDate
    }
    Catch {
        $null = Write-Host "[getLastUpdatedDateFromTag()] [ERROR] Failed to fetch last update date for [$pTagName]! Detailed error description below.`n" -ForegroundColor "Red"
        $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        Return "not_updated_yet"
    }
    $null = Write-Host "[getLastUpdatedDateFromTag()] [INFO] Update date [$lastUpdateDate] for [$pTagName] found."
    Return $lastUpdateDate
}

# Returns the higher version. If the versions are identical, it will return the string "identical_versions".
function compareVersions {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$pVersion1,
        [Parameter(Mandatory = $true)]
        [String]$pVersion2
    )

    $ver1 = [version]$pVersion1.Replace("v", "").Replace("-beta", "")
    $ver2 = [version]$pVersion2.Replace("v", "").Replace("-beta", "")

    $isVer1Beta = $pVersion1 -match "-beta$"
    $isVer2Beta = $pVersion2 -match "-beta$"

    If ($ver1 -gt $ver2) {
        $null = Write-Host "[compareVersions()] [INFO] [$pVersion1] is higher than [$pVersion2]."
        Return $pVersion1
    }
    ElseIf ($ver1 -lt $ver2) {
        $null = Write-Host "[compareVersions()] [INFO] [$pVersion2] is higher than [$pVersion1]."
        Return $pVersion2
    }
    Else {
        # Only one of them is a beta version.
        If ($isVer1Beta -and !$isVer2Beta) {
            $null = Write-Host "[compareVersions()] [INFO] [$pVersion2] is higher than [$pVersion1]."
            Return $pVersion2
        }
        ElseIf ($isVer2Beta -and !$isVer1Beta) {
            $null = Write-Host "[compareVersions()] [INFO] [$pVersion1] is higher than [$pVersion2]."
            Return $pVersion1
        }
        $null = Write-Host "[compareVersions()] [INFO] [$pVersion1] is identical to [$pVersion2]."
        Return "identical_versions"
    }
}

# Compares two date strings. Returns the higher date. If the dates are identical, it returns the string "identical_dates".
function compareDates() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$pDateString1,
        [Parameter(Mandatory = $true)]
        [String]$pDateString2
    )

    # Convert the strings to PowerShell datetime objects.
    $date1 = Get-Date $pDateString1
    $date2 = Get-Date $pDateString2

    # Compare the two dates.
    If ($date1 -gt $date2) {
        $null = Write-Host "[compareDates()] [INFO] [$pDateString1] is later than [$pDateString2]."
        Return $pDateString1
    }
    Elseif ($date1 -lt $date2) {
        $null = Write-Host "[compareDates()] [INFO] [$pDateString2] is later than [$pDateString1]."
        Return $pDateString2
    }
    Else {
        $null = Write-Host "[compareDates()] [INFO] [$pDateString1] is identical to [$pDateString2]."
        Return "identical_dates"
    }
}

function checkInternetConnectionStatus() {
    Try {
        Test-Connection -ComputerName "www.google.com" -Count 1 -ErrorAction Stop
        $null = Write-Host "[checkInternetConnectionStatus()] [INFO] Computer is connected to the Internet."
        Return $true
    }
    Catch {
        $null = Write-Host "[checkInternetConnectionStatus()] [WARNING] Computer is not connected to the Internet." -ForegroundColor "Yellow"
        Return $false
    }
}

function checkIfStringIsValidDate() {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$pDateTimeString
    )
    If ($pDateTimeString -as [datetime]) {
        $null = Write-Host "[checkIfStringIsValidDate()] [INFO] The string [$pDateTimeString] is a valid date."
        Return $true
    }
    $null = Write-Host "[checkIfStringIsValidDate()] [WARNING] The string [$pDateTimeString] is an invalid date." -ForegroundColor "Yellow"
    Return $false
}

function writeToCSVFile() {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$pFileLocation,
        [Parameter(Mandatory = $true)]
        [hashtable]$pContent,
        [Parameter(Mandatory = $false)]
        [switch]$pSwitchForce
    )
    
    # Stops here because the file exists and the function is told to not overwrite the file.
    If ((Test-Path -Path $pFileLocation) -and !$pSwitchForce) {
        $null = Write-Host "[writeToCSVFile()] [WARNING] The file [$pFileLocation] is already present. Use [-pSwitchForce] to overwrite it." -ForegroundColor "Yellow"
        Return $false
    }
    Try {
        # Writes the hashtable into the file.
        $pContent.GetEnumerator() | Select-Object -Property @{Name = "Key"; Expression = { $_.Key } }, @{Name = "Value"; Expression = { $_.Value } } | Export-Csv -Path $pFileLocation -Encoding Default -NoTypeInformation
        $null = Write-Host "[writeToCSVFile()] [INFO] The given hashtable has been successfully written to [$pFileLocation]."
        Return $true
    }
    Catch {
        $null = Write-Host "[writeToCSVFile()] [ERROR] Failed to write the given hashtable to [$pFileLocation]. Detailed error description below.`n" -ForegroundColor "Red"
        $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        Return $false
    }
}

# Check if the returned hashtable exists! If an error occurs, the function will return $null!
function readFromCSVFile() {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$pFileLocation
    )
    
    # Stops here because the file does not exist.
    If (-not (Test-Path -Path $pFileLocation)) {
        $null = Write-Host "[readFromCSVFile()] [WARNING] The file [$pFileLocation] does not exist." -ForegroundColor "Yellow"
        # We are using $null because $false would cause an error.
        Return $null
    }
    Try {
        # Reads the .CSV file and converts it into a hashtable.
        $content = @{}
        Import-Csv -Path $pFileLocation | ForEach-Object {
            $content[$_.Key] = $_.Value
        }
        $null = Write-Host "[readFromCSVFile()] [INFO] The content of the CSV file [$pFileLocation] has been successfully read."
        Return $content
    }
    Catch {
        $null = Write-Host "[readFromCSVFile()] [ERROR] Failed to read the content of the CSV file [$pFileLocation]. Detailed error description below.`n" -ForegroundColor "Red"
        $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        # We are using $null because $false would cause an error.
        Return $null
    }
}

function checkIfScriptWindowIsHidden() {
    # Define the necessary Windows API functions
    $null = Add-Type @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
}
"@
    $consoleHandle = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
    [boolean]$isVisible = [User32]::IsWindowVisible($consoleHandle)
    Return $isVisible
}

$null = onInit

<# 
Exit Code List

Bad exit codes
Range: 1-99
1: Corrupted current version file.

Normal exit codes
Range: 100-199
100: No available updates.
101: Available update found.
#>