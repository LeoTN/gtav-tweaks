#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

hotkeys_onInit()
{

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

hotkey_deposit100kLess()
{
    MsgBox("Less than 100k")
}