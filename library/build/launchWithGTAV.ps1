[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$pGTAVTweaksExecutableLocation
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$Host.UI.RawUI.WindowTitle = "GTAV Tweaks Start With GTA V"
$scriptParentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFileName = "launchWithGTAV.log"
$logFilePath = Join-Path -Path $scriptParentDirectory -ChildPath $logFileName
Start-Transcript -Path $logFilePath -Force
Clear-Host
Write-Host "Terminal ready..."

function onInit() {
    $GTAExecutable = "GTA5.exe"
    If (-not (Test-Path -Path $pGTAVTweaksExecutableLocation)) {
        Write-Host "[onInit()] [WARNING] The executable [$pGTAVTweaksExecutableLocation] does not exist." -ForegroundColor "Yellow"
        Exit
    }
    If (-not (waitForProcess -pProcessName $GTAExecutable)) {
        Write-Host "[onInit()] Could not find the GTA V process."
        Exit
    }
    Start-Process -FilePath $pGTAVTweaksExecutableLocation
    Exit
}

function waitForProcess() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$pProcessName,
        [Parameter(Mandatory = $false)]
        [int]$pTimeoutSeconds = -1
    )

    If ($pTimeoutSeconds -eq -1) {
        Write-Host "[waitForProcess()] [INFO] Waiting for [$pProcessName] indefinetely..."
    }
    Else {
        Write-Host "[waitForProcess()] [INFO] Waiting for [$pProcessName] for [$pTimeoutSeconds] seconds..."
    }
    # Removes the .EXE extension if present.
    $pProcessNameWithoutExtension = $pProcessName -replace "\.exe$", ""

    While (($pTimeoutSeconds -ge 0) -or ($pTimeoutSeconds -eq -1)) {
        $process = Get-Process -Name $pProcessNameWithoutExtension -ErrorAction SilentlyContinue
        If ($process) {
            Write-Host "[waitForProcess()] [INFO] Process [$pProcessName] found."
            Return $true
        }
        # Only decrements when the function should not wait indefinetely.
        If ($pTimeoutSeconds -ne -1) {
            $pTimeoutSeconds--
        }
        Start-Sleep -Seconds 1
    }
    Write-Host Write-Host "[waitForProcess()] [INFO] Process [$pProcessName] not found within timeout range."
    Return $false
}

onInit