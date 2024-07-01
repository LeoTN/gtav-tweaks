onInit()

onInit()
{
    If (!A_Args.Has(1))
    {
        MsgBox("This is a GTAV Tweaks utility script, designed to launch a PowerShell file silently."
            "`n`nIt requires specific parameters and cannot be used otherwise.", "GTAV Tweaks - Utility Script", "O Iconi")
        ExitApp()
    }
    scriptName := "launchWithGTAV.ps1"
    scriptLocation := A_ScriptDir . "\" . scriptName
    GTATweaksExecutableLocation := A_Args[1]
    runCommand := 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' . scriptLocation . '"'
    runParameters := '-pGTAVTweaksExecutableLocation "' . GTATweaksExecutableLocation . '"'
    Run(runCommand . " " . runParameters, , "Hide", &processPID)
    If (ProcessExist(processPID))
    {
        ProcessSetPriority("Low", processPID)
    }
}