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
Write-Host "Terminal ready..."

function onInit() {
  $global:scheduledTaskName = "GTAV Tweaks Start With GTA V"
  Write-Host "[onInit()] [INFO] pSwitchDeleteTask = $pSwitchDeleteTask"
  If ($pSwitchDeleteTask) {
    deleteTask
  }
  Else {
    deleteTask
    createTask
    triggerTask
  }
  Exit
}

function createTask() {
  Try {
    $taskAction = New-ScheduledTaskAction -Execute $pLaunchWithGTAScriptLauncherLocation -Argument """$pGTAVTweaksExecutableLocation"""
    $taskTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $taskSettings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -DontStopOnIdleEnd
    # Creates the task for the current user.
    Register-ScheduledTask -Action $taskAction -Trigger $taskTrigger -TaskName $global:scheduledTaskName -User $env:USERNAME -Settings $taskSettings -Force | Out-Null
    Return $true
  }
  Catch {
    Write-Host "[createTask()] [ERROR] Failed to create scheduled task! Detailed error description below.`n" -ForegroundColor "Red"
    Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
    # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
    Return $false
  }
}

function deleteTask() {
  If (-not (checkIfTaskExists)) {
    Write-Host "[deleteTask()] [INFO] Could not find existing task."
    Return $false
  }
  Try {
    Unregister-ScheduledTask -TaskName $global:scheduledTaskName -Confirm:$false | Out-Null
    Write-Host "[deleteTask()] [INFO] Deleted task [$global:scheduledTaskName]."
    Return $true
  }
  Catch {
    Write-Host "[deleteTask()] [ERROR] Failed to delete scheduled task! Detailed error description below.`n" -ForegroundColor "Red"
    Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
    # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
    Return $false
  }
}

function triggerTask() {
  If (-not (checkIfTaskExists)) {
    Write-Host "[triggerTask()] [INFO] Could not find existing task. Creating new scheduled task..."
    If (-not (createTask)) {
      Write-Host "[triggerTask()] [WARNING] Could not create task."
      Return $false
    }
    Write-Host "[triggerTask()] [WARNING] Successfully created task."
  }
  Try {
    Enable-ScheduledTask -TaskName $global:scheduledTaskName | Out-Null
    Write-Host "[triggerTask()] [INFO] Enabled task [$global:scheduledTaskName]."
    Start-ScheduledTask -TaskName $global:scheduledTaskName | Out-Null
    Write-Host "[triggerTask()] [INFO] Started task [$global:scheduledTaskName]."
    Return $true
  }
  Catch {
    Write-Host "[triggerTask()] [ERROR] Failed to trigger scheduled task! Detailed error description below.`n" -ForegroundColor "Red"
    Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
    # DO NOT REMOVE THIS COMMENT! Removing this space cause the function to return parts of the error object.
    Return $false
  }
}

function checkIfTaskExists() {
  $result = Get-ScheduledTask -TaskName $global:scheduledTaskName -ErrorAction SilentlyContinue
  If ($result) {
    Write-Host "[checkIfTaskExists()] [INFO] The scheduled task [$global:scheduledTaskName] exists."
    Return $true
  }
  Write-Host "[checkIfTaskExists()] [INFO] Could not find task [$global:scheduledTaskName]."
  Return $false
}

onInit