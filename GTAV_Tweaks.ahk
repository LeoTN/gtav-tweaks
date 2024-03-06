#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

; Imports important functions and variables.
; Sets the directory for all following files.
#Include "includes\"
#Include "ConfigFile.ahk"
#Include "Functions.ahk"
#Include "GUI.ahk"
#Include "Hotkeys.ahk"

onInit()

onInit()
{
    global version := "0.1.0"
    global booleanFirstTimeLaunch := false
    global audioHookFileLocation := A_ScriptDir . "\GTAV_Tweaks\soundvolumeview-x64\SoundVolumeView.exe"
    ; Includes the PowerShell audio hook file into the script.
    If (!DirExist(A_ScriptDir . "\GTAV_Tweaks"))
    {
        DirCreate(A_ScriptDir . "\GTAV_Tweaks")
    }
    If (!FileExist(audioHookFileLocation) && A_IsCompiled)
    {
        FileInstall("library\build\soundvolumeview-x64.zip", A_ScriptDir . "\GTAV_Tweaks\soundvolumeview-x64.zip", true)
        RunWait('powershell.exe -Command "Expand-Archive -Path "' . A_ScriptDir
            . '\GTAV_Tweaks\soundvolumeview-x64.zip" -DestinationPath "' . A_ScriptDir . '\GTAV_Tweaks\soundvolumeview-x64" -Force"', , "Hide")
        FileDelete(A_ScriptDir . "\GTAV_Tweaks\soundvolumeview-x64.zip")
    }
    config_onInit()
    functions_onInit()
    hotkeys_onInit()
    mainGUI_onInit()
    If (readConfigFile("DISPLAY_LAUNCH_NOTIFICATION"))
    {
        TrayTip("GTAV Tweaks launched.", "GTAV Tweaks - Status", "Iconi Mute")
        Sleep(1500)
        TrayTip()
    }
    waitForGTAToExist()
    If (readConfigFile("MUTE_GAME_WHILE_LAUNCH"))
    {
        muteGTAWhileInLoadingScreen()
    }
    ; Checks every 10 seconds if GTA is still existing.
    SetTimer(checkForExistingGTA, 10000)
}