#SingleInstance Force
#Requires AutoHotkey >=v2.0
SendMode "Input"
CoordMode "Mouse", "Window"

/*
This is a built-in macro from GTAV Tweaks.
******************************************
It will suspend the GTA V process and create a solo lobby as the result.
************************************************************************

More information can be found in the README.txt contained in the installer archive file (downloaded from GitHub) or in the GTAV_Tweaks folder.
Make sure to read it before changing this file!
*/

Process_Suspend("GTA5.exe")
Sleep(8000)
Process_Resume("GTA5.exe")

Process_Suspend(PID_or_Name) {
    PID := ProcessExist(PID_or_Name)
    h := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", PID)
    if (!h) {
        return -1
    }
    DllCall("ntdll.dll\NtSuspendProcess", "Int", h)
    DllCall("CloseHandle", "Int", h)
}

Process_Resume(PID_or_Name) {
    PID := ProcessExist(PID_or_Name)
    h := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", PID)
    if (!h) {
        return -1
    }
    DllCall("ntdll.dll\NtResumeProcess", "Int", h)
    DllCall("CloseHandle", "Int", h)
}
