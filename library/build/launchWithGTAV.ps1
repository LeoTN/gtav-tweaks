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
$null = Write-Host "Terminal ready..."

function onInit() {
    $null = endAllOtherScriptInstances
    If (checkIfOtherInstanceOfThisScriptIsAlreadyRunning) {
        $null = Write-Host "[onInit()] [INFO] There is an existing instance of this script. Exiting this script..."
        Exit
    }
    If (-not (Test-Path -Path $pGTAVTweaksExecutableLocation)) {
        $null = Write-Host "[onInit()] [WARNING] The executable [$pGTAVTweaksExecutableLocation] does not exist." -ForegroundColor "Yellow"
        Exit
    }
    $GTAExecutables = @("GTA5.exe", "GTA5_Enhanced.exe")
    If (-not (waitForProcess -pProcessNames $GTAExecutables)) {
        $null = Write-Host "[onInit()] [WARNING] Could not find any GTA V process."
        Exit
    }
    # Checks if there is already a running GTAV Tweaks instance.
    If (-not (Get-Process -Name "GTAV_Tweaks")) {
        $null = Write-Host "[onInit()] [INFO] Launching [$pGTAVTweaksExecutableLocation]..."
        Start-Process -FilePath $pGTAVTweaksExecutableLocation
    }
    Else {
        $null = Write-Host "[onInit()] [INFO] There is an already running instance of GTAV Tweaks."
        # Waits for the process to close and refreshes the scheduled task after that.
        $null = Wait-Process -Name "GTAV_Tweaks"
        $taskName = "GTAV Tweaks Start With GTA V"
        $null = Start-ScheduledTask -TaskName $taskName
        $null = Write-Host "[onInit()] [INFO] Started task [$taskName]."
    }
    Exit
}

function waitForProcess() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String[]]$pProcessNames,
        [Parameter(Mandatory = $false)]
        [int]$pTimeoutSeconds = -1
    )

    $processListString = $pProcessNames -join ", "
    If ($pTimeoutSeconds -eq -1) {
        $null = Write-Host "[waitForProcess()] [INFO] Waiting for [$processListString] indefinitely..."
    }
    Else {
        $null = Write-Host "[waitForProcess()] [INFO] Waiting for [$processListString] for [$pTimeoutSeconds] seconds..."
    }

    While (($pTimeoutSeconds -ge 0) -or ($pTimeoutSeconds -eq -1)) {

        foreach ($processName in $pProcessNames) {
            # Remove .exe if present
            $processNameWithoutExtension = $processName -replace "\.exe$", ""

            $process = Get-Process -Name $processNameWithoutExtension -ErrorAction SilentlyContinue

            If ($process) {
                $null = Write-Host "[waitForProcess()] [INFO] Process [$processName] found."
                Return $true
            }
        }
        # Only decrements when the function should not wait indefinetely.
        If ($pTimeoutSeconds -ne -1) {
            $pTimeoutSeconds--
        }
        $null = Start-Sleep -Seconds 1
    }
    $null = Write-Host "[waitForProcess()] [INFO] None of the processes [$processListString] were found within timeout range."
    Return $false
}

function checkIfOtherInstanceOfThisScriptIsAlreadyRunning() {
    $allPowershellProcesses = Get-Process -Name "powershell"
    ForEach ($processPID in $allPowershellProcesses.Id) {
        # We don't want to include this instance of this script.
        If ($processPID -eq $pid) {
            Continue
        }
        $process = Get-WmiObject "Win32_Process" -Filter "ProcessId = $processPID"
        If ($process.CommandLine -like "*-pGTAVTweaksExecutableLocation ""$pGTAVTweaksExecutableLocation""*") {
            $null = Write-Host "[checkIfOtherInstanceOfThisScriptIsAlreadyRunning()] [INFO] The GTAV Tweaks autostart PowerShell process with the pid [$processPID] is already running."
            Return $true
        }
    }
    $null = Write-Host "[checkIfOtherInstanceOfThisScriptIsAlreadyRunning()] [INFO] Could not find existing instance."
    Return $false
}

# Ends all script instances which are not originating from the current instance of GTAV Tweaks that launched this script.
function endAllOtherScriptInstances() {
    $null = Write-Host "[endAllOtherScriptInstances()] [INFO] Searching for other instances of this script which originate from other instances of GTAV Tweaks..."
    $endCounter = 0
    $allPowershellProcesses = Get-Process -Name "powershell"
    ForEach ($processPID in $allPowershellProcesses.Id) {
        # We don't want to include this instance of this script.
        If ($processPID -eq $pid) {
            Continue
        }
        $process = Get-WmiObject "Win32_Process" -Filter "ProcessId = $processPID"
        # We do not whant to end an already running instance of this script.
        If (($process.CommandLine -notlike "*-pGTAVTweaksExecutableLocation*") -or 
            ($process.CommandLine -like "*-pGTAVTweaksExecutableLocation ""$pGTAVTweaksExecutableLocation""*")) {
            Continue
        }
        $null = Stop-Process -Id $processPID -Force
        $null = Write-Host "[endAllOtherScriptInstances()] [INFO] Ended process with PID [$processPID]."
        $endCounter++
    }
    $null = Write-Host "[endAllOtherScriptInstances] [INFO] Ended [$endCounter] process(es)."
}

$null = onInit