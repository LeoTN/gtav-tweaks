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
    If (checkIfOtherInstanceIsAlreadyRunning) {
        Write-Host "[onInit()] [INFO] There is an existing instance of this script. Exiting this script..."
        Exit
    }
    $GTAExecutable = "GTA5.exe"
    If (-not (Test-Path -Path $pGTAVTweaksExecutableLocation)) {
        Write-Host "[onInit()] [WARNING] The executable [$pGTAVTweaksExecutableLocation] does not exist." -ForegroundColor "Yellow"
        Exit
    }
    If (-not (waitForProcess -pProcessName $GTAExecutable)) {
        Write-Host "[onInit()] [WARNING] Could not find the GTA V process."
        Exit
    }
    # Checks if there is already a running GTAV Tweaks instance.
    If (-not (Get-Process -Name "GTAV_Tweaks")) {
        Write-Host "[onInit()] [INFO] Launching [$pGTAVTweaksExecutableLocation]..."
        Start-Process -FilePath $pGTAVTweaksExecutableLocation
    }
    Else {
        Write-Host "[onInit()] [INFO] There is an already running instance of GTAV Tweaks."
        # Waits for the process to close and refreshes the scheduled task after that.
        Wait-Process -Name "GTAV_Tweaks"
        $taskName = "GTAV Tweaks Start With GTA V"
        Start-ScheduledTask -TaskName $taskName  | Out-Null
        Write-Host "[onInit()] [INFO] Started task [$taskName]."
    }
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

function checkIfOtherInstanceIsAlreadyRunning() {
    $allPowershellProcesses = Get-Process -name "powershell"
    ForEach ($processPID in $allPowershellProcesses.Id) {
        # We don't want to include this instance of this script.
        If ($processPID -eq $pid) {
            Continue
        }
        $process = Get-WmiObject "Win32_Process" -Filter "ProcessId = $processPID"
        If ($process.CommandLine -like "*-pGTAVTweaksExecutableLocation ""$pGTAVTweaksExecutableLocation""*") {
            Write-Host "[checkIfOtherInstanceIsAlreadyRunning()] [INFO] The PowerShell process with the pid [$processPID] is already running."
            Return $true
        }
    }
    Write-Host "[checkIfOtherInstanceIsAlreadyRunning()] [INFO] Could not find existing instance."
    Return $false
}

onInit