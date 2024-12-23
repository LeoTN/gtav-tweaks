[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)]
  [String]$pLaunchWithGTAScriptLauncherLocation,
  [Parameter(Mandatory = $true)]
  [String]$pGTAVTweaksExecutableLocation,
  [Parameter(Mandatory = $false)]
  [switch]$pSwitchDeleteTask
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$scriptParentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFileName = "manageAutostartScheduledTask.log"
$logFilePath = Join-Path -Path $scriptParentDirectory -ChildPath $logFileName
Start-Transcript -Path $logFilePath -Force
Clear-Host
$null = Write-Host "Terminal ready..."

function onInit() {
  $global:scheduledTaskName = "GTAV Tweaks Start With GTA V"
  $null = Write-Host "[onInit()] [INFO] pSwitchDeleteTask = $pSwitchDeleteTask"
  If ($pSwitchDeleteTask) {
    $null = deleteTask
  }
  Else {
    If (checkIfTaskNeedsToBeReplaced) {
      $null = deleteTask
      $null = createTask
    }
    $null = triggerTask
  }
  Exit
}

function checkIfTaskNeedsToBeReplaced() {
  If (-not (checkIfTaskExists)) {
    $null = Write-Host "[checkIfTaskNeedsToBeReplaced()] [INFO] Could not find existing task."
    Return $true
  }
  $task = Get-ScheduledTask -TaskName $global:scheduledTaskName
  $taskExecute = $task.Actions.Execute
  $taskArguments = $task.Actions.Arguments

  # This means the task won't execute the correct PowerShell launcher executable.
  If ($taskExecute -ne $pLaunchWithGTAScriptLauncherLocation) {
    $null = Write-Host "[checkIfTaskNeedsToBeReplaced()] [INFO] Invalid PowerShell launcher executable location found: [$taskExecute]. Task needs to be replaced."
    Return $true
  }
  # This means that the GTAV Tweaks executable path of the task is incorrect.
  If ($taskArguments -ne """$pGTAVTweaksExecutableLocation""") {
    $null = Write-Host "[checkIfTaskNeedsToBeReplaced()] [INFO] Invalid GTAV Tweaks executable location found: [$taskArguments]. Task needs to be replaced."
    Return $true
  }
  $null = Write-Host "[checkIfTaskNeedsToBeReplaced()] [INFO] The current task doesn't need to be replaced."
  Return $false
}

function createTask() {
  Try {
    $taskAction = New-ScheduledTaskAction -Execute $pLaunchWithGTAScriptLauncherLocation -Argument """$pGTAVTweaksExecutableLocation"""
    $taskTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $taskSettings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -DontStopOnIdleEnd
    # Creates the task for the current user.
    $null = Register-ScheduledTask -Action $taskAction -Trigger $taskTrigger -TaskName $global:scheduledTaskName -User $env:USERNAME -Settings $taskSettings -Force
    Return $true
  }
  Catch {
    $null = Write-Host "[createTask()] [ERROR] Failed to create scheduled task! Detailed error description below.`n" -ForegroundColor "Red"
    $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
    # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
    Return $false
  }
}

function deleteTask() {
  If (-not (checkIfTaskExists)) {
    $null = Write-Host "[deleteTask()] [INFO] Could not find existing task."
    Return $false
  }
  Try {
    $null = stopTask
    $null = Unregister-ScheduledTask -TaskName $global:scheduledTaskName -Confirm:$false
    $null = Write-Host "[deleteTask()] [INFO] Deleted task [$global:scheduledTaskName]."
    Return $true
  }
  Catch {
    $null = Write-Host "[deleteTask()] [ERROR] Failed to delete scheduled task! Detailed error description below.`n" -ForegroundColor "Red"
    $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
    # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
    Return $false
  }
}

function triggerTask() {
  If (-not (checkIfTaskExists)) {
    $null = Write-Host "[triggerTask()] [INFO] Could not find existing task. Creating new scheduled task..."
    If (-not (createTask)) {
      $null = Write-Host "[triggerTask()] [WARNING] Could not create task."
      Return $false
    }
    $null = Write-Host "[triggerTask()] [WARNING] Successfully created task."
  }
  Try {
    $null = Enable-ScheduledTask -TaskName $global:scheduledTaskName
    $null = Write-Host "[triggerTask()] [INFO] Enabled task [$global:scheduledTaskName]."
    $null = Start-ScheduledTask -TaskName $global:scheduledTaskName
    $null = Write-Host "[triggerTask()] [INFO] Started task [$global:scheduledTaskName]."
    Return $true
  }
  Catch {
    $null = Write-Host "[triggerTask()] [ERROR] Failed to trigger scheduled task! Detailed error description below.`n" -ForegroundColor "Red"
    $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
    # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
    Return $false
  }
}

function stopTask() {
  If (-not (checkIfTaskExists)) {
    $null = Write-Host "[stopTask()] [INFO] Could not find existing task."
    Return $false
  }
  Try {
    $null = Stop-ScheduledTask -TaskName $global:scheduledTaskName
    $null = Write-Host "[stopTask()] [INFO] Stopped task [$global:scheduledTaskName]."
    # This clears up any left over scripts waiting for GTA V to be launched. They would try to start GTAV Tweaks again
    # during the update process which causes unnecessary errors.
    $null = endRunningInstances
    Return $true
  }
  Catch {
    $null = Write-Host "[stopTask()] [ERROR] Failed to stop scheduled task! Detailed error description below.`n" -ForegroundColor "Red"
    $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
    # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
    Return $false
  }
}

function checkIfTaskExists() {
  $result = Get-ScheduledTask -TaskName $global:scheduledTaskName -ErrorAction SilentlyContinue
  If ($result) {
    $null = Write-Host "[checkIfTaskExists()] [INFO] The scheduled task [$global:scheduledTaskName] exists."
    Return $true
  }
  $null = Write-Host "[checkIfTaskExists()] [INFO] Could not find task [$global:scheduledTaskName]."
  Return $false
}

# Ends all script instances of "launchWithGTAV.ps1" which wait for GTA V to be launched.
function endRunningInstances() {
  $null = Write-Host "[endRunningInstances()] [INFO] Searching for other PowerShell script instances of GTAV Tweaks..."
  $endCounter = 0
  $allPowershellProcesses = Get-Process -Name "powershell"
  ForEach ($processPID in $allPowershellProcesses.Id) {
    # We don't want to include this instance of this script.
    If ($processPID -eq $pid) {
      Continue
    }
    $process = Get-WmiObject "Win32_Process" -Filter "ProcessId = $processPID"
    # We only want to end PowerShell instances from GTAV Tweaks.
    If ($process.CommandLine -notlike "*-pGTAVTweaksExecutableLocation*") {
      Continue
    }
    $null = Stop-Process -Id $processPID -Force
    $null = Write-Host "[endRunningInstances()] [INFO] Ended process with PID [$processPID]."
    $endCounter++
  }
  $null = Write-Host "[endRunningInstances] [INFO] Ended [$endCounter] process(es)."
}

$null = onInit