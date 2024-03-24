[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$pGitHubRepositoryLink,
    [Parameter(Mandatory = $true)]
    [String]$pCurrentVersion,
    [Parameter(Mandatory = $true)]
    [String]$pCurrentExecutableLocation,
    [Parameter(Mandatory = $true)]
    [String]$pOutputDirectory,
    [Parameter(Mandatory = $false)]
    [Switch]$pBooleanDoNotStartUpdate = $false,
    [Parameter(Mandatory = $false)]
    [Switch]$pBooleanConsiderBetaReleases = $false
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
    # Makes sure, that we do not have a shortened path.
    $pCurrentExecutableLocation = [System.IO.Path]::GetFullPath($pCurrentExecutableLocation)
    $pOutputDirectory = [System.IO.Path]::GetFullPath($pOutputDirectory)
    # Adds a subfolder so that we can delete this entire folder instead of deleting every file individually.
    $pOutputDirectory = Join-Path -Path $pOutputDirectory -ChildPath "GTAV_Tweaks_temp_update"
    $global:updateVersion = ""
    # Removes old available update files.
    $availableUpdateFileName = "GTAV_Tweaks_Available_Update.txt"
    $availableUpdateFilePath = Join-Path -Path $scriptParentDirectory -ChildPath $availableUpdateFileName
    Remove-Item -Path $availableUpdateFilePath -Force -ErrorAction SilentlyContinue
    # Exit code list at the end of this file.
    $exitCode = 0

    $tmpResult = checkIfUpdateAvailable
    If ($tmpResult -and !$pBooleanDoNotStartUpdate) {
        If (downloadReleaseAsset -pReleaseName $global:updateVersion -pAssetName "GTAV_Tweaks.zip" -pOutputDirectory "$pOutputDirectory") {
            If (executeUpdate) {
                Write-Host "[onInit()] [INFO] Successfully updated from version [$pCurrentVersion] to ["$global:updateVersion"]."
                # Launch the new and updated script.
                Start-Process -FilePath $pCurrentExecutableLocation
                $exitCode = 10
            }
            Else {
                Write-Host "[onInit()] [INFO] Failed to update from version [$pCurrentVersion] to ["$global:updateVersion"]."
                $exitCode = 20
            }
            # Copies the log file into the back up folder.
            $currentExecutableParentDirectory = Split-Path -Path $pCurrentExecutableLocation -Parent
            $oldFilesBackupFolder = Join-Path -Path $currentExecutableParentDirectory -ChildPath ("GTAV_Tweaks_backup_from_version_$pCurrentVersion")
            Copy-Item -Path $logFilePath -Destination (Join-Path -Path $oldFilesBackupFolder -ChildPath "executedUpdate.log") -Force
        }
    }
    ElseIf ($tmpResult) {
        New-Item -Path $availableUpdateFilePath -ItemType "file" -Value $global:updateVersion -Force | Out-Null
        $exitCode = 5
    }
    Else {
        $exitCode = 15
    }
    Start-Sleep -Seconds 3
    Exit $exitCode
}

function checkIfUpdateAvailable() {
    If (-not (checkInternetConnectionStatus)) {
        Write-Host "[checkIfUpdateAvailable()] [WARNING] No active Internet connection found."
        Return $false
    }
    # This converts the "normal" repository link to use the GitHub API.
    $apiUrl = $pGitHubRepositoryLink -Replace "github\.com", "api.github.com/repos"
    $fullApiUrl = "$apiUrl/tags"
    $tagsResponse = Invoke-RestMethod -Uri $fullApiUrl -Method Get

    $highestVersion = "v0.0.0"
    # Iterating through the tags.
    Foreach ($tag in $tagsResponse) {
        $tmpTag = $tag.name
        # Removing unwanted characters and beta label.
        $tmpTag = $tmpTag.Replace("v", "")
        If ($tmpTag -like "*-beta" -and !$pBooleanConsiderBetaReleases) {
            Write-Host "[checkIfUpdateAvailable()] [INFO] Skipping tag [$tmpTag] which is a beta release."
            Continue
        }
        # Checking if the version is valid.
        $tmpTag = $tmpTag.Replace("-beta", "")
        If (-not ($tmpTag -match '^\d+\.\d+\.\d+$')) {
            Write-Host "[checkIfUpdateAvailable()] [WARNING] Found tag name which couldn't be converted to version: [$tmpTag]."
            Continue
        }
        # Finds the highest version.
        $highestVersion = compareVersions -pVersion1 $highestVersion -pVersion2 $tag.name
    }
    # Compares the highest released version and the current version.
    $tmpHighestVersion = compareVersions -pVersion1 $highestVersion -pVersion2 $pCurrentVersion
    # This means there is an update available.
    If ($tmpHighestVersion -eq $highestVersion) {
        Write-Host "[checkIfUpdateAvailable()] [INFO] Found a higher version to update: [$highestVersion]."
        $global:updateVersion = $highestVersion
        Return $true
    }
    Write-Host "[checkIfUpdateAvailable()] [INFO] Could not find any available updates."
    Return $false
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
        Write-Host "[downloadReleaseAsset()] [WARNING] No active Internet connection found."
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
        Write-Host "[downloadReleaseAsset()] [ERROR] Could not download assets from [$gitHubUrl]!"
        Return $false
    }
}

function executeUpdate() {
    $updateZipArchiveLocation = Join-Path -Path $pOutputDirectory -ChildPath "GTAV_Tweaks.zip"
    $updateArchiveLocation = Join-Path -Path $pOutputDirectory -ChildPath "GTAV_Tweaks"
    $oldExecutableLocation = $pCurrentExecutableLocation
    $newExecutableLocation = Join-Path -Path $updateArchiveLocation -ChildPath "GTAV_Tweaks.exe"

    Write-Host "[executeUpdate()] [INFO] Starting update process..."
    If (-not (Test-Path -Path $updateZipArchiveLocation)) {
        Write-Host "[executeUpdate()] [ERROR] Could not find installer archive at [$pOutputDirectory\GTAV_Tweaks.zip]."
        Return $false
    }
    Expand-Archive -Path $updateZipArchiveLocation -DestinationPath $updateArchiveLocation -Force
    # Unblock every file.
    Get-ChildItem -Path $updateArchiveLocation -Recurse | ForEach-Object {
        If (-not $_.PSIsContainer) {
            Unblock-File -Path $_.FullName -ErrorAction Continue
        }
    }
    Try {
        Write-Host "[executeUpdate()] [INFO] Backing up files from old version..."
        $currentExecutableParentDirectory = Split-Path -Path $pCurrentExecutableLocation -Parent
        $oldSupportFilesFolder = Join-Path -Path $currentExecutableParentDirectory -ChildPath "GTAV_Tweaks"
        $oldFilesBackupFolder = Join-Path -Path $currentExecutableParentDirectory -ChildPath ("GTAV_Tweaks_backup_from_version_$pCurrentVersion")

        # Moves the old files into a backup folder.
        Get-ChildItem -Path $oldSupportFilesFolder -Recurse | ForEach-Object {
            $destinationFile = Join-Path -Path $oldFilesBackupFolder -ChildPath $_.FullName.Substring($oldSupportFilesFolder.Length + 1)
            $destinationDirectory = Split-Path -Path $destinationFile -Parent
        
            # Skips the temporary update files to not include them into the backup.
            If ($_.Directory.Name -eq "GTAV_Tweaks_temp_update") {
                Continue
            }
            If (-not (Test-Path -Path $destinationDirectory)) {
                New-Item -ItemType Directory -Path $destinationDirectory -Force
            }
            If ($_.Extension -eq ".ini" -or $_.Extension -eq ".ini_old" -or $_.Directory.Name -eq "macros") {
                Copy-Item -Path $_.FullName -Destination $destinationFile -Force
            }
            Else {
                Move-Item -Path $_.FullName -Destination $destinationFile -Force
            }
        }
        # Moves the old executable into the back up directory.
        Move-Item -LiteralPath $oldExecutableLocation -Destination $oldFilesBackupFolder -Force

        # Move the new executable into the directory that contained the old one.
        Move-Item -Path $newExecutableLocation -Destination $currentExecutableParentDirectory -Force
        Write-Host "[executeUpdate()] [INFO] Successfully moved new executable file to target destination."
        # Clean up the folder.
        If (Test-Path -Path $pOutputDirectory) {
            Remove-Item -Path $pOutputDirectory -Recurse -Force
        }
        Return $true
    }
    Catch {
        Write-Host "[executeUpdate()] [ERROR] Failed update execution. Detailed error description below.`n"
        Write-Host $Error[0]
        # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object, 
        # which are interpreted as true.
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

function checkInternetConnectionStatus() {
    Try {
        Test-Connection -ComputerName "www.google.com" -Count 1 -ErrorAction Stop
        Write-Host "[checkInternetConnectionStatus()] [INFO] Computer is connected to the Internet."
        Return $true
    }
    Catch {
        Write-Host "[checkInternetConnectionStatus()] [WARNING] Computer is not connected to the Internet."
        Return $false
    }
}

onInit

<# 
Exit Code List

5: An update is available but it hasn't been installed yet.
10: An available update has been successfully installed.
15: There are no updates available.
20: An available update has not been successfully installed.
#>