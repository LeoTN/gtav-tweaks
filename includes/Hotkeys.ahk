#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

hotkeys_onInit()
{
    ; Deactivates the hotkeys for now. They will be reactivated once the script detects a running GTA V instance.
    Suspend(true)
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
    SetNumLockState("On")
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

hotkey_deposit100kLess()
{
    If (!FileExist(depositLessThan100kMacroFileLocation))
    {
        explainMacroRecording(depositLessThan100kMacroFileLocation)
    }
    Else
    {
        RunWait(ahkBaseFileLocation . " " . depositLessThan100kMacroFileLocation)
    }
}

hotkey_deposit100kPlus()
{
    If (!FileExist(depositMoreThan100kMacroFileLocation))
    {
        explainMacroRecording(depositMoreThan100kMacroFileLocation)
    }
    Else
    {
        RunWait(ahkBaseFileLocation . " " . depositMoreThan100kMacroFileLocation)
    }
}

; Only enabled temporarily while recording.
hotkey_stopMacroRecording()
{
    global booleanMacroIsRecording := false
}