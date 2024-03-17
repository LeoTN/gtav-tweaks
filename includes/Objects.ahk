#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

/*
Creates a custom macro object. It has all properties required to create a custom macro with a corresponding hotkey.
If the macro config file (where all custom macros are saved) does not exist, it will produce an error!
@returns [Any] Can return multiple values depending on which functions are called.
*/
class CustomMacro
{
    __New()
    {
        this.name := "new custom macro"
        this.description := "new custom macro description"
        this.hotkey := "new custom macro hotkey"
        this.macroFileLocation := "new custom macro file location"
        this.macroConfigFileLocation := "new custom macro config file location"
        this.ahkBaseFileLocation := "new custom macro ahk base file location"
        this.isEnabled := true
    }
    saveMacroToFile()
    {
        If (!this.integrityCheck())
        {
            Return false
        }
        IniWrite(this.description, this.macroConfigFileLocation, this.name, "Description")
        IniWrite(this.hotkey, this.macroConfigFileLocation, this.name, "Hotkey")
        IniWrite(this.macroFileLocation, this.macroConfigFileLocation, this.name, "MacroFileLocation")
        IniWrite(this.isEnabled, this.macroConfigFileLocation, this.name, "Enabled")
        Return true
    }
    loadMacroFromFile()
    {
        ; Checks if the config file exists.
        If (!this.isMacroConfigFileExisting())
        {
            SplitPath(this.macroConfigFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Macro config file [" . outFileName . "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return false
        }
        ; Disables the hotkey because in case the key changes while loading the file, the old hotkey would become
        ; a "ghost" hotkey, which is replaced by the new one from the file. By disabeling the hotkey temporarily, we avoid
        ; duplicate hotkeys calling the same macro file.
        If (this.isEnabled)
        {
            this.disableHotkey()
        }
        this.description := IniRead(this.macroConfigFileLocation, this.name, "Description", "empty_description")
        this.hotkey := IniRead(this.macroConfigFileLocation, this.name, "Hotkey", "empty_hotkey")
        this.macroFileLocation := IniRead(this.macroConfigFileLocation, this.name, "MacroFileLocation", "empty_macroFileLocation")
        this.isEnabled := IniRead(this.macroConfigFileLocation, this.name, "Enabled", "empty_enabled")
        If (!this.integrityCheck())
        {
            Return false
        }
        ; Calling this function here updates the hotkey if necessary. See comment above for more information.
        If (this.isEnabled)
        {
            this.enableHotkey()
        }
        Return true
    }
    enableHotkey()
    {
        If (!this.integrityCheck())
        {
            Return false
        }
        this.isEnabled := true
        Hotkey(this.hotkey, (*) => RunWait(this.ahkBaseFileLocation . ' "' . this.macroFileLocation . '"'), "On")
        ; Changes the enabled value in the config file.
        IniWrite(this.isEnabled, this.macroConfigFileLocation, this.name, "Enabled")
        Return true
    }
    disableHotkey()
    {
        If (!this.integrityCheck())
        {
            Return false
        }
        this.isEnabled := false
        Hotkey(this.hotkey, (*) => RunWait(this.ahkBaseFileLocation . ' "' . this.macroFileLocation . '"'), "Off")
        ; Changes the enabled value in the config file.
        IniWrite(this.isEnabled, this.macroConfigFileLocation, this.name, "Enabled")
        Return true
    }
    /*
    Checks if all variables contain a valid value and if required files are present.
    @returns [boolean] True if all checks have passed. False otherwise.
    */
    integrityCheck()
    {
        If (!this.isHotkeyValid())
        {
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Invalid hotkey found: [" . this.hotkey . "]!`n`n"
                , "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return false
        }
        Else If (!this.isMacroFileExisting())
        {
            SplitPath(this.macroFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Macro file [" . outFileName . "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return false
        }
        Else If (!this.isMacroConfigFileExisting())
        {
            SplitPath(this.macroConfigFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Macro config file [" . outFileName . "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return false
        }
        Else If (!FileExist(this.ahkBaseFileLocation))
        {
            SplitPath(this.ahkBaseFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] AutoHotkey base file [" . outFileName . "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return false
        }
        Return true
    }
    ; Creates an empty hotkey to validate the value inside the hotkey property.
    isHotkeyValid()
    {
        Try
        {
            ; Combines the given hotkey with another key, to avoid overwriting existing hotkeys.
            Hotkey(this.hotkey . " & NumLock", (*) =>, "Off")
            Return true
        }
        Catch
        {
            Return false
        }
    }
    isMacroFileExisting()
    {
        If (FileExist(this.macroFileLocation))
        {
            Return true
        }
        Return false
    }
    isMacroConfigFileExisting()
    {
        If (FileExist(this.macroConfigFileLocation))
        {
            Return true
        }
        Return false
    }
}

objects_onInit()
{

}