[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$pGitHubRepositoryLink,
    [Parameter(Mandatory = $true)]
    [String]$pCurrentVersionFileLocation,
    [Parameter(Mandatory = $true)]
    [String]$pCurrentExecutableLocation,
    [Parameter(Mandatory = $true)]
    [String]$pOutputDirectory = $env:TEMP,
    [Parameter(Mandatory = $false)]
    [switch]$pSwitchDoNotStartUpdate,
    [Parameter(Mandatory = $false)]
    [switch]$pSwitchForceUpdate,
    [Parameter(Mandatory = $false)]
    [switch]$pSwitchConsiderBetaReleases
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$scriptParentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFileName = "checkForUpdates.log"
$logFilePath = Join-Path -Path $scriptParentDirectory -ChildPath $logFileName
Start-Transcript -Path $logFilePath -Force
Clear-Host
Write-Host "Terminal ready..."

function onInit() {
    # A list of all exit codes can be found at the end of this script.

    If ($pSwitchDoNotStartUpdate -and $pSwitchForceUpdate) {
        Write-Host "`n`n[onInit()] pSwitchDoNotStartUpdate and pSwitchForceUpdate cannot be used at the same time.`n`n"
        Return 4
    }
    # Makes sure, that we do not have a shortened path.
    $pCurrentVersionFileLocation = [System.IO.Path]::GetFullPath($pCurrentVersionFileLocation)
    $pCurrentExecutableLocation = [System.IO.Path]::GetFullPath($pCurrentExecutableLocation)
    $pOutputDirectory = [System.IO.Path]::GetFullPath($pOutputDirectory)
    # Adds a subfolder, so that we can delete this entire folder instead of deleting every file individually.
    $pOutputDirectory = Join-Path -Path $pOutputDirectory -ChildPath "GTAV_Tweaks_temp_update"
    # These variables store information about the update.
    $global:currentVersion = ""
    $global:currentVersionLastUpdateDate = ""
    
    # Exit code list at the end of this file.
    $exitCode = evaluateUpdate
    Write-Host "[onInit()] [INFO] Exiting with exit code [$exitCode]."

    $currentExecutableParentDirectory = Split-Path -Path $pCurrentExecutableLocation -Parent
    $supportFilesFolderName = "GTAV_Tweaks"
    $supportFilesFolder = Join-Path -Path $currentExecutableParentDirectory -ChildPath $supportFilesFolderName
    $supportFilesFolderUpdateFolder = Join-Path -Path $supportFilesFolder -ChildPath "update"
    $logFileNameUpdate = "executedUpdate.log"
    # Copies the log file into the back up folders.
    If (Test-Path -Path $global:targetBackupFolder)
    {
        Copy-Item -Path $logFilePath -Destination (Join-Path -Path $global:targetBackupFolder -ChildPath $logFileNameUpdate) -Force
        Copy-Item -Path $logFilePath -Destination (Join-Path -Path $global:targetBackupFolderTemp -ChildPath $logFileNameUpdate) -Force
    }
    # Copies the log file into the support file folder.
    If (Test-Path -Path $supportFilesFolderUpdateFolder)
    {
        Copy-Item -Path $logFilePath -Destination (Join-Path -Path $supportFilesFolderUpdateFolder -ChildPath $logFileName) -Force
    }
    
    Start-Sleep -Seconds 3
    Exit $exitCode
}

# Evaluates, if an update is available and returns an exit code accordingly.
function evaluateUpdate() {
    # A list of all exit codes can be found at the end of this script.

    # This function fills the two variables above with a value from the currentVersion.CSV file.
    # If the extraction is not successful, the script will delete the incorrect current version file
    # because the AutoHotkey executable will replace it with a new and correct one at it's next launch.
    If (-not (extractCurrentVersionFileContent)) {
        Write-Host "`n`n[evaluateUpdate()] [WARNING] The file [$pCurrentVersionFileLocation] seems corrupted or unavailable. The GTAV_Tweaks.exe will create a new and valid file at next launch. Deleting file...`n`n" -ForegroundColor "Yellow"
        Remove-Item -Path $pCurrentVersionFileLocation -ErrorAction SilentlyContinue
        Return 1
    }
    Write-Host "`n`n[evaluateUpdate()] [INFO] The current version [$global:currentVersion] had it's last update on [$global:currentVersionLastUpdateDate].`n`n" -ForegroundColor "Green"

    $availableUpdateVersion = getAvailableUpdateTag
    If ($availableUpdateVersion -eq "no_available_update") {
        Write-Host "`n`n[evaluateUpdate()] [INFO] There are no updates available.`n`n" -ForegroundColor "Green"
        Return 100
    }
    If ($pSwitchDoNotStartUpdate) {
        # Updates the current version file.
        $currentVersionFileObject = readFromCSVFile -pFileLocation $pCurrentVersionFileLocation
        $currentVersionFileObject["AVAILABLE_UPDATE"] = $availableUpdateVersion
        # Avoids the annoying "polution" of the return values.
        writeToCSVFile -pFileLocation $pCurrentVersionFileLocation -pContent $currentVersionFileObject -pSwitchForce | Out-Null
        Write-Host "`n`n[evaluateUpdate()] [INFO] There is an update available [$availableUpdateVersion], but pSwitchDoNotStartUpdate has been set to true.`n`n" -ForegroundColor "Green"
        Return 101
    }
    # Downloads and executes the update.
    If (-not (downloadReleaseAsset -pReleaseName $availableUpdateVersion -pAssetName "GTAV_Tweaks.zip" -pOutputDirectory $pOutputDirectory)) {
        Write-Host "`n`n[evaluateUpdate()] [INFO] There is an update available [$availableUpdateVersion], but the script failed to download it.`n`n" -ForegroundColor "Green"
        Return 2
    }
    If (-not (executeUpdate)) {
        Write-Host "`n`n[evaluateUpdate()] [INFO] Failed to execute update from version [$global:currentVersion] to [$availableUpdateVersion].`n`n" -ForegroundColor "Green"
        Return 3
    }
    Else {
        Start-Process -FilePath $pCurrentExecutableLocation
        Write-Host "`n`n[evaluateUpdate()] [INFO] Successfully updated from version [$global:currentVersion] to [$availableUpdateVersion].`n`n" -ForegroundColor "Green"
        # Launch the new and updated script.
        Start-Process -FilePath $pCurrentExecutableLocation 
        Return 102
    }
}

function extractCurrentVersionFileContent() {
    $currentVersionHashtable = readFromCSVFile -pFileLocation $pCurrentVersionFileLocation
    If (!$currentVersionHashtable) {
        Write-Host "[extractCurrentVersionFileContent()] [ERROR] Failed to load data from [$pCurrentVersionFileLocation]." -ForegroundColor "Red"
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
    If (-not ($tmpTag -match '^\d+\.\d+\.\d+$')) {
        Write-Host "[extractCurrentVersionFileContent()] [ERROR] Found tag name which couldn't be converted to version: [$global:currentVersion]." -ForegroundColor "Red"
        Return $false
    }
    If ($global:currentVersionLastUpdateDate -eq "not_updated_yet") {
        Write-Host "[extractCurrentVersionFileContent()] [INFO] This version [$global:currentVersion] has not been updatet yet. Trying to fetch latest update date..."
        $global:currentVersionLastUpdateDate = getLastUpdatedDateFromTag -pTagName $global:currentVersion
        # This happens, when there is still no latest update date available.
        If ($global:currentVersionLastUpdateDate -eq "not_updated_yet") {
            Write-Host "[extractCurrentVersionFileContent()] [INFO] Could not fetch any update dates for [$global:currentVersion]."
            Return $true
        }
        Write-Host "[extractCurrentVersionFileContent()] [INFO] Fetched last update date: [$global:currentVersionLastUpdateDate]. Updating current version file..."
        $currentVersionHashtable["CURRENT_VERSION_LAST_UPDATED"] = $global:currentVersionLastUpdateDate
        # Corrects the current version file.
        If (writeToCSVFile -pFileLocation $pCurrentVersionFileLocation -pContent $currentVersionHashtable -pSwitchForce) {
            Write-Host "[extractCurrentVersionFileContent()] [INFO] Successfully updated last update date in [$pCurrentVersionFileLocation] for [$global:currentVersion]."
            Return $true
        }
        # If this fails, it isn't a big deal.
        Write-Host "[extractCurrentVersionFileContent()] [WARNING] Failed to update last update date in [$pCurrentVersionFileLocation] for [$global:currentVersion]." -ForegroundColor "Yellow"
        Return $true
    }
    If (-not (checkIfStringIsValidDate -pDateTimeString $global:currentVersionLastUpdateDate)) {
        Write-Host "[extractCurrentVersionFileContent()] [ERROR] Found an invalid last update [$global:currentVersionLastUpdateDate] date for [$global:currentVersion]." -ForegroundColor "Red"
        Return $false
    }
    $currentDateTime = Get-Date
    $highestDateTime = compareDates -pDateString1 $global:currentVersionLastUpdateDate -pDateString2 $currentDateTime
    # This mean the current last update date lies in the future.
    If ((compareDates -pDateString1 $highestDateTime -pDateString2 $currentDateTime) -ne "identical_dates") {
        Write-Host "[extractCurrentVersionFileContent()] [WARNING] The last update date [$global:currentVersionLastUpdateDate] from [$global:currentVersion] lies in the future." -ForegroundColor "Yellow"
        Return $false
    }
    Return $true
}

# Checks for available updates and returns either "no_available_update" or the update tag name.
function getAvailableUpdateTag() {
    If (-not (checkInternetConnectionStatus)) {
        Write-Host "[getAvailableUpdateTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
        Return "no_available_update"
    }

    $currentTag = $global:currentVersion
    $latestTag = getLatestTag
    $highestTag = compareVersions -pVersion1 $currentTag -pVersion2 $latestTag
    # This mean there is an update available. We are returning the latest tag and not the highest tag, because returning the
    # highest tag could result in an update to the "current" beta version, when pSwitchConsiderBetaReleases is not true.
    If ($pSwitchForceUpdate) {
        Write-Host "[getAvailableUpdateTag()] [INFO] Forced update. Highest available version: [$latestTag]."
        Return $latestTag
    }
    If ($highestTag -eq $latestTag) {
        Write-Host "[getAvailableUpdateTag()] [INFO] Found a higher version to update: [$highestTag]."
        Return $highestTag
    }

    $currentTagLatestUpdateDate = $global:currentVersionLastUpdateDate
    $latestTagLatestUpdateDate = getLastUpdatedDateFromTag -pTagName $latestTag
    # This might happen with new releases.
    If ($latestTagLatestUpdateDate -eq "not_updated_yet") {
        Write-Host "[getAvailableUpdateTag()] [INFO] Could not find any available updates."
        Return "no_available_update"
    }
    $highestLatestUpdateDate = compareDates -pDateString1 $currentTagLatestUpdateDate -pDateString2 $latestTagLatestUpdateDate
    # This means there is an update available.
    If ($highestLatestUpdateDate -eq $latestTagLatestUpdateDate) {
        Write-Host "[getAvailableUpdateTag()] [INFO] Your current version [$currentTag] has received an update."
        Return $currentTag
    }
    Write-Host "[getAvailableUpdateTag()] [INFO] Could not find any available updates."
    Return "no_available_update"
}

# This function uses semantic versioning to determine if a tag is the latest.
function getLatestTag() {
    If (-not (checkInternetConnectionStatus)) {
        Write-Host "[getLatestTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
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
                Write-Host "[getLatestTag()] [INFO] Skipping tag [$tmpTag] which is a beta release."
                Continue
            }
            # Checking if the version is valid.
            $tmpTag = $tmpTag.Replace("-beta", "")
            If (-not ($tmpTag -match '^\d+\.\d+\.\d+$')) {
                Write-Host "[getLatestTag()] [WARNING] Found tag name which couldn't be converted to version: [$tmpTag]." -ForegroundColor "Yellow"
                Continue
            }
            # Finds the highest version.
            $latestTag = compareVersions -pVersion1 $latestTag -pVersion2 $tag.name
        }
        Write-Host "[getLatestTag()] [INFO] Found highest tag: [$latestTag]."
        Return $latestTag
    }
    Catch {
        Write-Host "[getLatestTag()] [ERROR] Failed to fetsh latest tag! Detailed error description below.`n" -ForegroundColor "Red"
        Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
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
        Write-Host "[getLastUpdatedDateFromTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
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
            Write-Host "[getLastUpdatedDateFromTag()] [INFO] No update date for [$pTagName] found."
            Return "not_updated_yet"
        }
        $lastUpdateDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss" $invalidLastUpdateDate
    }
    Catch {
        Write-Host "[getLastUpdatedDateFromTag()] [ERROR] Failed to fetch last update date for [$pTagName]! Detailed error description below.`n" -ForegroundColor "Red"
        Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
        Return "not_updated_yet"
    }
    Write-Host "[getLastUpdatedDateFromTag()] [INFO] Update date [$lastUpdateDate] for [$pTagName] found."
    Return $lastUpdateDate
}

function downloadReleaseAsset() {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$pReleaseName,
        [Parameter(Mandatory = $true)]
        [String]$pAssetName,
        [Parameter(Mandatory = $true)]
        [String]$pOutputDirectory
    )
    If (-not (checkInternetConnectionStatus)) {
        Write-Host "[downloadReleaseAsset()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
        Return $false
    }
    If (-not (Test-Path -Path $pOutputDirectory)) {
        New-Item -ItemType Directory -Path $pOutputDirectory -Force | Out-Null
    }
    Try {
        $gitHubUrl = "$pGitHubRepositoryLink/releases/download/$pReleaseName/$pAssetName"
        $outputFile = Join-Path -Path $pOutputDirectory -ChildPath $pAssetName
        Invoke-WebRequest -Uri $gitHubUrl -OutFile $outputFile
        Write-Host "[downloadReleaseAsset()] [INFO] Successfully downloaded [$pAssetName] into [$pOutputDirectory]."
        Return $true
    }
    Catch {
        Write-Host "[downloadReleaseAsset()] [ERROR] Could not download assets from [$gitHubUrl]!" -ForegroundColor "Red"
        Return $false
    }
}

function executeUpdate() {
    $updateZipArchiveLocation = Join-Path -Path $pOutputDirectory -ChildPath "GTAV_Tweaks.zip"
    $updateArchiveLocation = Join-Path -Path $pOutputDirectory -ChildPath "GTAV_Tweaks"
    $newExecutableLocation = join-path -Path $updateArchiveLocation -ChildPath "GTAV_Tweaks.exe"

    Write-Host "[executeUpdate()] [INFO] Starting update process..."
    If (-not (Test-Path -Path $updateZipArchiveLocation)) {
        Write-Host "[executeUpdate()] [ERROR] Could not find installer archive at [$pOutputDirectory\GTAV_Tweaks.zip]." -ForegroundColor "Red"
        Return $false
    }
    Try {
        $currentExecutableParentDirectory = Split-Path -Path $pCurrentExecutableLocation -Parent
        If (-not (backupOldVersionFiles -pCurrentExecutableLocation $pCurrentExecutableLocation -pBackupTargetDirectory $currentExecutableParentDirectory)) {
            Write-Host "[executeUpdate()] [ERROR] Failed to backup old version files." -ForegroundColor "Red"
            Return $false
        }
        Expand-Archive -Path $updateZipArchiveLocation -DestinationPath $updateArchiveLocation -Force
        # Unblock every file.
        Get-ChildItem -Path $updateArchiveLocation -Recurse | ForEach-Object {
            If (-not $_.PSIsContainer) {
                Unblock-File -Path $_.FullName -ErrorAction Continue
            }
        }
        # Moves the new executable to the old place.
        Move-Item -Path $newExecutableLocation -Destination $pCurrentExecutableLocation -Force
        Write-Host "[executeUpdate()] [INFO] Moved [$newExecutableLocation] to [$pCurrentExecutableLocation]."
        # Clean up the folder.
        If (Test-Path -Path $pOutputDirectory) {
            Remove-Item -Path $pOutputDirectory -Recurse -Force
        }
        Write-Host "[executeUpdate()] [INFO] Successfully executed update."
        Return $true
    }
    Catch {
        Write-Host "[executeUpdate()] [ERROR] Failed update execution. Detailed error description below.`n" -ForegroundColor "Red"
        Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object, which are interpreted as true.
        Return $false
    }
}

function backupOldVersionFiles() {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$pCurrentExecutableLocation,
        [Parameter(Mandatory = $true)]
        [String]$pBackupTargetDirectory
    )
    
    $currentExecutableName = Split-Path -Path $pCurrentExecutableLocation -Leaf
    $currentExecutableParentDirectory = Split-Path -Path $pCurrentExecutableLocation -Parent
    $supportFilesFolderName = "GTAV_Tweaks"
    $supportFilesFolder = Join-Path -Path $currentExecutableParentDirectory -ChildPath $supportFilesFolderName
    $targetBackupFolderName = "GTAV_Tweaks_backup_from_version_$($global:currentVersion)_at_$(Get-Date -Format "dd.MM.yyyy_HH-mm-ss")"
    # First backup folder.
    $global:targetBackupFolder = Join-Path -Path $pBackupTargetDirectory -ChildPath $targetBackupFolderName
    $targetBackupFolderSupportFiles = Join-Path -Path $global:targetBackupFolder -ChildPath $supportFilesFolderName
    # Second backup folder.
    $global:targetBackupFolderTemp = Join-Path -Path ([System.IO.Path]::GetFullPath($env:TEMP)) -ChildPath $targetBackupFolderName

    If (-not (Test-Path -Path $pCurrentExecutableLocation)) {
        Write-Host "[backupOldVersionFiles()] [WARNING] Could not find [$currentExecutableName] at [$currentExecutableParentDirectory]." -ForegroundColor "Yellow"
        Return $false
    }
    If (-not (Test-Path -Path $supportFilesFolder)) {
        Write-Host "[backupOldVersionFiles()] [WARNING] Could not find the support file folder [$supportFilesFolderName] at [$currentExecutableParentDirectory]." -ForegroundColor "Yellow"
        Return $false
    }
    Try {
        Write-Host "[backupOldVersionFiles()] [INFO] Creating old version file backup..."
        # Moves the old support files into a backup folder.
        $null = Get-ChildItem -Path $supportFilesFolder -Recurse | ForEach-Object {
            $destinationFileLocation = Join-Path -Path $targetBackupFolderSupportFiles -ChildPath $_.FullName.Substring($supportFilesFolder.Length + 1)
            $destinationFileParentDirectory = Split-Path -Path $destinationFileLocation -Parent
            # Skips temporary update files to not include them into the backup.
            If ($_.Directory.Name -eq "GTAV_Tweaks_temp_update") {
                Continue
            }
            # Creates the parent directory if necessary.
            If (-not (Test-Path -Path $destinationFileParentDirectory)) {
                New-Item -ItemType Directory -Path $destinationFileParentDirectory -Force
            }
            # Copies the config file instead of moving it. The same goes for the content of the macro folders.
            if ($_.Extension -in ".ini", ".ini_old" -or $_.Directory.Name -in "macros", "recorded_macros") {
                Copy-Item -Path $_.FullName -Destination $destinationFileLocation -Force
            }
            Else {
                Move-Item -Path $_.FullName -Destination $destinationFileLocation -Force
            }
        }
        # Moves the old executable into the backup directory.
        Move-Item -Path $pCurrentExecutableLocation -Destination $global:targetBackupFolder -Force
        Copy-Item -Path $global:targetBackupFolder -Destination $global:targetBackupFolderTemp -Recurse
        Write-Host "[backupOldVersionFiles()] [INFO] The files from the old version have been saved to [$global:targetBackupFolder] and [$global:targetBackupFolderTemp]."
        Return $true
    }
    Catch {
        Write-Host "[backupOldVersionFiles()] [ERROR] Failed to backup old version files. Detailed error description below.`n" -ForegroundColor "Red"
        Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object, which are interpreted as true.
        Return $false
    }
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
        Write-Host "[compareVersions()] [INFO] [$pVersion1] is higher than [$pVersion2]."
        Return $pVersion1
    }
    ElseIf ($ver1 -lt $ver2) {
        Write-Host "[compareVersions()] [INFO] [$pVersion2] is higher than [$pVersion1]."
        Return $pVersion2
    }
    Else {
        # Only one of them is a beta version.
        If ($isVer1Beta -and !$isVer2Beta) {
            Write-Host "[compareVersions()] [INFO] [$pVersion2] is higher than [$pVersion1]."
            Return $pVersion2
        }
        ElseIf ($isVer2Beta -and !$isVer1Beta) {
            Write-Host "[compareVersions()] [INFO] [$pVersion1] is higher than [$pVersion2]."
            Return $pVersion1
        }
        Write-Host "[compareVersions()] [INFO] [$pVersion1] is identical to [$pVersion2]."
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
        Write-Host "[compareDates()] [INFO] [$pDateString1] is later than [$pDateString2]."
        Return $pDateString1
    }
    Elseif ($date1 -lt $date2) {
        Write-Host "[compareDates()] [INFO] [$pDateString2] is later than [$pDateString1]."
        Return $pDateString2
    }
    Else {
        Write-Host "[compareDates()] [INFO] [$pDateString1] is identical to [$pDateString2]."
        Return "identical_dates"
    }
}

function checkInternetConnectionStatus() {
    Try {
        Test-Connection -ComputerName "www.google.com" -Count 1 -ErrorAction Stop
        Write-Host "[checkInternetConnectionStatus()] [INFO] Computer is connected to the Internet."
        Return $true
    }
    Catch {
        Write-Host "[checkInternetConnectionStatus()] [WARNING] Computer is not connected to the Internet." -ForegroundColor "Yellow"
        Return $false
    }
}

function checkIfStringIsValidDate() {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$pDateTimeString
    )
    
    Try {
        Get-Date $pDateTimeString | Out-Null
        Write-Host "[checkIfStringIsValidDate()] [INFO] The string [$pDateTimeString] is a valid date."
        Return $true
    }
    Catch {
        Write-Host "[checkIfStringIsValidDate()] [WARNING] The string [$pDateTimeString] is an invalid date." -ForegroundColor "Yellow"
        Return $false
    }
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
        Write-Host "[writeToCSVFile()] [WARNING] The file [$pFileLocation] is already present. Use [-pSwitchForce] to overwrite it." -ForegroundColor "Yellow"
        Return $false
    }
    Try {
        # Writes the hashtable into the file.
        $pContent.GetEnumerator() | Select-Object -Property @{Name = "Key"; Expression = { $_.Key } }, @{Name = "Value"; Expression = { $_.Value } } | Export-Csv -Path $pFileLocation -Encoding Default -NoTypeInformation
        Write-Host "[writeToCSVFile()] [INFO] The given hashtable has been successfully written to [$pFileLocation]."
        Return $true
    }
    Catch {
        Write-Host "[writeToCSVFile()] [ERROR] Failed to write the given hashtable to [$pFileLocation]. Detailed error description below.`n" -ForegroundColor "Red"
        Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
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
        Write-Host "[readFromCSVFile()] [WARNING] The file [$pFileLocation] does not exist." -ForegroundColor "Yellow"
        # We are using $null because $false would cause an error.
        Return $null
    }
    Try {
        # Reads the .CSV file and converts it into a hashtable.
        $content = @{}
        Import-Csv -Path $pFileLocation | ForEach-Object {
            $content[$_.Key] = $_.Value
        }
        Write-Host "[readFromCSVFile()] [INFO] The content of the CSV file [$pFileLocation] has been successfully read."
        Return $content
    }
    Catch {
        Write-Host "[readFromCSVFile()] [ERROR] Failed to read the content of the CSV file [$pFileLocation]. Detailed error description below.`n" -ForegroundColor "Red"
        Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
        # We are using $null because $false would cause an error.
        Return $null
    }
}

onInit

<# 
Exit Code List

Bad exit codes
Range: 1-99
1: Corrupted current version file.
2: Available update, but there was a download error.
3: Available update, but there was an error while executing the update process.
4: Invalid script parameter combination.

Normal exit codes
Range: 100-199
100: No available updates.
101: Available update, but pSwitchDoNotStartUpdate is true.
102: Successful update performed.
#>