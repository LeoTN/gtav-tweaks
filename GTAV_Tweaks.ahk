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

    config_onInit()
    functions_onInit()
    hotkeys_onInit()
    mainGUI_onInit()

    SetNumLockState("On")
    muteGTAWhileInLoadingScreen()
    ; Checks every 5 minutes if GTA5 is still existing.
    SetTimer(checkForExistingGTA, 300000)
}

muteGTAWhileInLoadingScreen(pBooleanMute := true, pBooleanWaitForHotkey := true)
{
    booleanMute := pBooleanMute
    booleanWaitForHotkey := pBooleanWaitForHotkey

    If (booleanMute = true)
    {
        Run(A_ComSpec . ' /c ""G:\Programme\Windows_Tools\soundvolumeview-x64\SoundVolumeView.exe" '
            . '/Mute "G:\Spiele\Steam\steamapps\common\Grand Theft Auto V\GTA5.exe" /WaitForItem"', , "Hide")
    }
    Else
    {
        Run(A_ComSpec . ' /c ""G:\Programme\Windows_Tools\soundvolumeview-x64\SoundVolumeView.exe" '
            . '/Unmute "G:\Spiele\Steam\steamapps\common\Grand Theft Auto V\GTA5.exe" /WaitForItem"', , "Hide")
    }

    If (booleanWaitForHotkey = true)
    {
        If (waitForUserInputInGTA() = true)
        {
            Return muteGTAWhileInLoadingScreen(false, false)
        }
    }
}

; Waits for the user to press w a & d while the window is active to continue the script execution.
waitForUserInputInGTA()
{
    static timeoutCounter := 0
    ; This prevents the script from loading infinetly.
    If (WinWaitActive("ahk_exe GTA5.exe", , 300) = 0)
    {
        If (timeoutCounter >= 5)
        {
            result := MsgBox("Are you still waiting for GTA to load?", , "YN Icon? T30")

            If (result = "Yes")
            {
                timeoutCounter := 0
                Return waitForUserInputInGTA()
            }
            Else
            {
                ExitApp()
            }
        }
        timeoutCounter++
        Return waitForUserInputInGTA()
    }
    Else
    {
        While (WinActive("ahk_exe GTA5.exe"))
        {
            If (KeyWait("w", "D T1") = 1)
            {
                If (KeyWait("a", "D T1") = 1)
                {
                    If (KeyWait("d", "D T1") = 1)
                    {
                        Return true
                    }
                }
            }
        }

        Return waitForUserInputInGTA()
    }
}

checkForExistingGTA()
{
    WinWait("ahk_exe GTA5.exe")
    If (!ProcessExist("ahk_exe GTA5.exe"))
    {
        ExitApp()
    }
}