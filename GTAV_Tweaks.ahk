#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

onInit()

onInit()
{
    SetNumLockState("On")
    registerHotkeys()
    muteGTAWhileInLoadingScreen()
    ; Checks every 5 minutes if GTA5 is still existing.
    SetTimer(checkForExistingGTA, 300000)
}

registerHotkeys()
{
    ; Toggle AFK Cayo Perico plane flight mode.
    Hotkey("+F9", (*) => hotkey_afkCayoPericoFlight(), "On")
    ; Create GTA solo lobby hotkey.
    Hotkey("+F10", (*) => hotkey_createSoloLobby(), "On")
    ; Deposit less than 100k cash.
    Hotkey("+F11", (*) =>, "Off") ; Still in development.
    ; Deposit more than 100k cash.
    Hotkey("+F12", (*) => hotkey_deposit100kPlus(), "Off") ; Still in development.
}

hotkey_createSoloLobby()
{
    Process_Suspend("GTA5.exe")
    Sleep(8000)
    Process_Resume("GTA5.exe")
    Process_Suspend(PID_or_Name)
    {
        PID := ProcessExist(PID_or_Name)
        h := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", PID)
        If (!h)
        {
            Return -1
        }
        DllCall("ntdll.dll\NtSuspendProcess", "Int", h)
        DllCall("CloseHandle", "Int", h)
    }
    Process_Resume(PID_or_Name)
    {
        PID := ProcessExist(PID_or_Name)
        h := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", PID)
        If (!h)
        {
            Return -1
        }
        DllCall("ntdll.dll\NtResumeProcess", "Int", h)
        DllCall("CloseHandle", "Int", h)
    }
}

hotkey_afkCayoPericoFlight()
{
    static toggle := false
    toggle := !toggle

    While (toggle)
    {
        Send("{w Down}")
        Send("{Numpad5 Down}")
        Sleep(200)
        Send("{Numpad5 Up}")
        Sleep(3500)
    }
    Send("{w Up}")
    Send("{Numpad5 Up}")
}

hotkey_deposit100kPlus()
{
    Send("{Up Down}")
    Sleep (50)
    Send("{Up Up}")
    Sleep(500)
    Loop (2)
    {
        Send("{Up Down}")
        Sleep (50)
        Send("{Up Up}")
        Sleep (300)
    }
    Send ("{Enter down}")
    Sleep(2000)
    MouseMove(1080, 128, 1)
    Sleep (1000)
    Send("{Click Down}")
    Sleep (100)
    Send("{Click Up}")

    Sleep (1000)
    Send("www.maze-bank.com")
    Sleep (500)
    Send ("{Enter down}")
    Sleep (50)
    Send ("{Enter up}")
    Sleep (1000)

    MouseMove(958, 716, 1)
    Sleep (1000)
    Send("{Click Down}")
    Sleep (50)
    Send("{Click Up}")

    MouseMove(965, 544, 1)
    Sleep (1000)
    Send("{Click Down}")
    Sleep (50)
    Send("{Click Up}")

    Sleep (1000)

    MouseMove(1136, 765, 1)
    Sleep (1000)
    Send("{Click Down}")
    Sleep (50)
    Send("{Click Up}")

    Sleep (1000)

    MouseMove(757, 717, 1)
    Sleep (1000)
    Send("{Click Down}")
    Sleep (50)
    Send("{Click Up}")

    MouseMove(1562, 130, 1)
    Sleep (200)
    Send("{Click Down}")
    Sleep (50)
    Send("{Click Up}")
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