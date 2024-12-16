$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
# This makes sure to retrieve the script path.
If ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") { 
    $scriptParentDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition 
}
Else {
    $scriptParentDirectory = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0]) 
    If (!$scriptParentDirectory) { 
        $scriptParentDirectory = "." 
    } 
}
Clear-Host

function onInit() {
    $executableName = "GTAV_Tweaks.exe"
    $global:executableLocation = Join-Path -Path $scriptParentDirectory -ChildPath $executableName

    If (-not (Test-Path -Path $global:executableLocation)) {
        Write-Host "[ERROR] Could not find [$executableName] at [$scriptParentDirectory]."
        Exit
    }
    If (unblockExecutable) {
        $null = runExecutable
    }
}

function unblockExecutable() {
    Try {
        $null = Unblock-File -Path $global:executableLocation
        Return $true
    }
    Catch {
        Return $false
    }
}

function runExecutable() {
    Try {
        $null = Start-Process -FilePath $global:executableLocation
        Return $true
    }
    Catch {
        Return $false
    }  
}

onInit