#SingleInstance Off
#Requires AutoHotkey >=v2.0
SendMode "Input"
CoordMode "Mouse", "Window"

; This block of code makes this hotkey toggelable. It scans for already existing instances of this script and if it
; detects one, it will close both this and the old instance.
; Do not modify code below!
processSearchQuery := 'AutoHotkey32.exe" "' . A_ScriptFullPath . '"'
scriptPID := WinGetPID(A_ScriptHwnd)
for (process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")) {
    if (InStr(process.CommandLine, processSearchQuery) && process.ProcessID != scriptPID) {
        ProcessClose(process.ProcessID)
        ; Only in case the keys are still pressed by the old script.
        Send("{w Up}")
        Send("{Numpad5 Up}")
        ExitApp()
    }
}
; Do not modify code above!

/*
This is a built-in macro from GTAV Tweaks.
******************************************
Pressing the hotkey will enable the automatic flight and pressing it again will disable it.
*******************************************************************************************

More information can be found in the README.txt contained in the installer archive file (downloaded from GitHub)
or in the GTAV_Tweaks folder. Make sure to read it before changing this file!
*/

SetNumLockState("On")
while (WinActive("ahk_exe GTA5.exe")) {
    Send("{w Down}")
    Send("{Numpad5 Down}")
    Sleep(200)
    Send("{Numpad5 Up}")
    Sleep(3500)
}
Send("{w Up}")
Send("{Numpad5 Up}")