;@Ahk2Exe-SetCompanyName Made by LeoTN
;@Ahk2Exe-SetCopyright Licence available on my GitHub project (https://github.com/LeoTN/gtav-tweaks)
;@Ahk2Exe-SetDescription GTAV Tweaks
;@Ahk2Exe-SetName GTAV Tweaks
;@Ahk2Exe-UpdateManifest 0, GTAV Tweaks, , 0

#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Screen"

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
    global version := "0.1.1"
    global booleanFirstTimeLaunch := false
    global ahkBaseFileLocation := A_ScriptDir . "\GTAV_Tweaks\AutoHotkey32.exe"
    global psUpdateScriptLocation := A_ScriptDir . "\GTAV_Tweaks\update\checkForUpdates.ps1"
    global readmeFileLocation := A_ScriptDir . "\GTAV_Tweaks\README.txt"
    global audioHookFileLocation := A_ScriptDir . "\GTAV_Tweaks\soundvolumeview-x64\SoundVolumeView.exe"
    global depositLessThan100kMacroFileLocation := A_ScriptDir . "\GTAV_Tweaks\macros\depositLessThan100kMacro.ahk"
    global depositMoreThan100kMacroFileLocation := A_ScriptDir . "\GTAV_Tweaks\macros\depositMoreThan100kMacro.ahk"

    If (!DirExist(A_ScriptDir . "\GTAV_Tweaks\macros"))
    {
        DirCreate(A_ScriptDir . "\GTAV_Tweaks\macros")
    }
    If (!DirExist(A_ScriptDir . "\GTAV_Tweaks\update"))
    {
        DirCreate(A_ScriptDir . "\GTAV_Tweaks\update")
    }
    ; Copies a bunch of support files into a folder relative to the script directory.
    If (!FileExist(ahkBaseFileLocation) && A_IsCompiled)
    {
        FileInstall("library\build\AutoHotkey32.zip", A_ScriptDir . "\GTAV_Tweaks\AutoHotkey32.zip", true)
        RunWait('powershell.exe -Command "Expand-Archive -Path "' . A_ScriptDir
            . '\GTAV_Tweaks\AutoHotkey32.zip" -DestinationPath "' . A_ScriptDir . '\GTAV_Tweaks" -Force"', , "Hide")
        ; FileDelete(A_ScriptDir . "\GTAV_Tweaks\AutoHotkey32.zip") ; REMOVE
    }
    If (!FileExist(psUpdateScriptLocation) && A_IsCompiled)
    {
        FileInstall("library\build\checkForUpdates.ps1", psUpdateScriptLocation, true)
    }
    If (!FileExist(readmeFileLocation) && A_IsCompiled)
    {
        FileInstall("library\build\README.txt", readmeFileLocation, true)
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
    If (readConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH"))
    {
        checkForAvailableUpdates()
    }
    waitForGTAToExist()
    If (readConfigFile("MUTE_GAME_WHILE_LAUNCH"))
    {
        muteGTAWhileInLoadingScreen()
    }
    ; Checks every 3 seconds if GTA is still existing and if it is the active window.
    SetTimer(checkForExistingGTA, 3000)
}