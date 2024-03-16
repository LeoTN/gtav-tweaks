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
    # Adds a subfolder so that we can delete this entire folder instead of deleting every file individually.
    $pOutputDirectory = "$pOutputDirectory\GTAV_Tweaks_temp_update"
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
                $exitCode = 10
            }
            Else {
                Write-Host "[onInit()] [INFO] Failed to update from version [$pCurrentVersion] to ["$global:updateVersion"]."
                $exitCode = 20
            }
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
    $tagsResponse = Invoke-RestMethod -Uri "$apiUrl/tags" -Method Get

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
        Invoke-WebRequest -Uri "$pGitHubRepositoryLink/releases/download/$pReleaseName/$pAssetName" -OutFile "$pOutputDirectory\$pAssetName"
        Write-Host "[downloadReleaseAsset()] [INFO] Successfully downloaded [$pAssetName] into [$pOutputDirectory]."
        Return $true
    }
    Catch {
        Write-Host "[downloadReleaseAsset()] [ERROR] Could not download assets from [$pGitHubRepositoryLink/releases/download/$pReleaseName/$pAssetName]!"
        Return $false
    }
}

function executeUpdate() {
    Write-Host "[executeUpdate()] [INFO] Starting update process..."
    If (-not (Test-Path -Path "$pOutputDirectory\GTAV_Tweaks.zip")) {
        Write-Host "[executeUpdate()] [ERROR] Could not find installer archive at [$pOutputDirectory\GTAV_Tweaks.zip]."
        Return $false
    }
    Expand-Archive -Path "$pOutputDirectory\GTAV_Tweaks.zip" -DestinationPath "$pOutputDirectory\GTAV_Tweaks" -Force
    # Unblock every file.
    Get-ChildItem -Path "$pOutputDirectory\GTAV_Tweaks" -Recurse | ForEach-Object {
        If (-not $_.PSIsContainer) {
            Unblock-File -Path $_.FullName -ErrorAction Continue
        }
    }
    Try {
        $parentDirectory = Split-Path -Path $pCurrentExecutableLocation -Parent
        $sourceFolder = "$parentDirectory\GTAV_Tweaks"
        $destinationFolder = "$parentDirectory\GTAV_Tweaks_backup_from_version_$pCurrentVersion"
        # Moves the old files into a backup folder.
        Get-ChildItem -Path $sourceFolder -Recurse | ForEach-Object {
            $destinationFile = Join-Path -Path $destinationFolder -ChildPath $_.FullName.Substring($sourceFolder.Length + 1)
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
        Move-Item -Path $pCurrentExecutableLocation -Destination "$destinationFolder\GTAV_Tweaks.exe" -Force
        # Move the new executable into the directory that contained the old one.
        Move-Item -Path "$pOutputDirectory\GTAV_Tweaks\GTAV_Tweaks.exe" -Destination $pCurrentExecutableLocation -Force
        Write-Host "[executeUpdate()] [INFO] Successfully moved new executable file to target destination."
        # Clean up the folder.
        If (Test-Path -Path $pOutputDirectory) {
            Remove-Item -Path $pOutputDirectory -Recurse -Force
        }
        Return $true
    }
    Catch {
        Write-Host "[executeUpdate()] [ERROR] Failed to move new executable file to target destination.`nDetailed error description`n`n[$_]"
        Return $false
    }
}

# Returns the higher version.
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
        Return $pVersion1
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