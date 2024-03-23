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
        ; If a hotkey was marked as active in the config file, it would become deactivated while loading. This variable
        ; remebers the original state and reactivates the hotkey after it has been loaded.
        hotkeyWasEnabled := IniRead(this.macroConfigFileLocation, this.name, "Enabled", "empty_enabled")
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
        If (this.isEnabled || hotkeyWasEnabled)
        {
            this.enableHotkey()
        }
        Return true
    }
    deleteHotkey()
    {
        ; Checks if the config file exists.
        If (!this.isMacroConfigFileExisting())
        {
            SplitPath(this.macroConfigFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Macro config file [" . outFileName . "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return false
        }
        IniDelete(this.macroConfigFileLocation, this.name)
    }
    enableHotkey()
    {
        this.isEnabled := true
        Hotkey(this.hotkey, (*) => RunWait(this.ahkBaseFileLocation . ' "' . this.macroFileLocation . '"'), "On")
        ; Changes the enabled value in the config file.
        IniWrite(this.isEnabled, this.macroConfigFileLocation, this.name, "Enabled")
        Return true
    }
    disableHotkey()
    {
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
    global customMacroObjectArray := []
    global macroConfigFileLocation
    global builtInHK_NameArray :=
        [
            "AFK Cayo Perico Plane Flight",
            "Create Solo Lobby"
        ]

    loadHotkeys()
    ; Disables the hotkeys until GTA V is launched.
    Suspend(true)
}

loadHotkeys()
{
    global ahkBaseFileLocation
    global macroConfigFileLocation
    global customMacroObjectArray
    global builtInHK_NameArray

    hotkeyNameArray := scanFileForHotkeyNames()
    ; At the beginning, all built-in hotkeys will be marked to be loaded. The code below sorts out already existing
    ; hotkeys to avoid overwriting their values.
    builtInHotkeysNeededToBeLoadedArray := builtInHK_NameArray
    ; Prepares all existing hotkeys to be loaded.
    For (name in hotkeyNameArray)
    {
        tmpObject := CustomMacro()
        tmpObject.ahkBaseFileLocation := ahkBaseFileLocation
        tmpObject.macroConfigFileLocation := macroConfigFileLocation
        ; Checks if the hotkey from the macro config file is a built-in hotkey.
        ; If that's the case, it won't be loaded afterwards.
        Loop (builtInHotkeysNeededToBeLoadedArray.Length)
        {
            If (name == builtInHotkeysNeededToBeLoadedArray.Get(A_Index))
            {
                tmpObject.name := builtInHotkeysNeededToBeLoadedArray.Get(A_Index)
                tmpObject.loadMacroFromFile()
                customMacroObjectArray.Push(tmpObject)
                builtInHotkeysNeededToBeLoadedArray.RemoveAt(A_Index)
                Continue 2
            }
        }
        ; This allows the custom macro object to load the rest of it's configuration from the macro config file all by itself.
        tmpObject.name := name
        tmpObject.loadMacroFromFile()
        customMacroObjectArray.Push(tmpObject)
    }
    For (name in builtInHotkeysNeededToBeLoadedArray)
    {
        loadBuiltInHotkey(name)
    }
}

/*
Loads one or all built-in hotkeys.
@param pHotkeyname [String] Should be the name of a built-in hotkey to load.
*/
loadBuiltInHotkey(pHotkeyName)
{
    global ahkBaseFileLocation
    global macroConfigFileLocation
    global customMacroObjectArray
    global builtInHK_NameArray
    global builtInHKLocation_cayoPrepPlaneAfkFlight
    global builtInHKLocation_createSololobby

    hotkeyNameArray := builtInHK_NameArray
    hotkeyDescriptionArray :=
        [
            "Allows you to automatically keep the Cayo Perico Heist preperation plane in the air. [This is a built-in hotkey]",
            "Suspends the GTA V process and therefore creates a solo lobby. [This is a built-in hotkey]"
        ]
    hotkeyHotkeyArray :=
        [
            "^F9",
            "^F10"
        ]
    hotkeyMacroFileLocationArray :=
        [
            builtInHKLocation_cayoPrepPlaneAfkFlight,
            builtInHKLocation_createSololobby
        ]

    For (name in hotkeyNameArray)
    {
        tmpObject := CustomMacro()
        tmpObject.name := hotkeyNameArray.Get(A_Index)
        tmpObject.description := hotkeyDescriptionArray.Get(A_Index)
        tmpObject.hotkey := hotkeyHotkeyArray.Get(A_Index)
        tmpObject.macroFileLocation := hotkeyMacroFileLocationArray.Get(A_Index)
        tmpObject.ahkBaseFileLocation := ahkBaseFileLocation
        tmpObject.macroConfigFileLocation := macroConfigFileLocation
        ; This will only load one hotkey.
        If (name == pHotkeyName)
        {
            tmpObject.saveMacroToFile()
            customMacroObjectArray.Push(tmpObject)
        }
    }
}

/*
Scanns a given hotkey config file for it's hotkey names.
The names will be later used by the CustomMacro objects to load the corresponding hotkeys from the config file.
@returns [Array] An array which contains all hotkey's names.
*/
scanFileForHotkeyNames()
{
    global macroConfigFileLocation
    hotkeyNameArray := []

    Loop Read (macroConfigFileLocation)
    {
        ; Finds every string at the start of a new line which equals to this pattern: [any letters or numbers].
        If (!RegExMatch(A_LoopReadLine, "A)\[.+?\]", &match))
        {
            Continue
        }
        matchString := match[]
        ; Ignores the standard text.
        If (InStr(matchString, "[CustomHotkeysBelow]"))
        {
            Continue
        }
        ; Removes the brackets at the start and end.
        matchString := StrReplace(matchString, "[",)
        matchString := StrReplace(matchString, "]")
        hotkeyNameArray.Push(matchString)
    }
    Return hotkeyNameArray
}