#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

objects_onInit() {
    global customMacroObjectArray := []
    global macroConfigFileLocation
    global builtInHK_NameArray :=
        [
            "Drive, Fly or Walk AFK",
            "Create Solo Lobby"
        ]

    loadHotkeys()
    ; Disables the hotkeys until GTA V is launched.
    Suspend(true)
}

loadHotkeys() {
    global ahkBaseFileLocation
    global macroConfigFileLocation
    global customMacroObjectArray
    global builtInHK_NameArray
    global macroFilesStorageDirectory

    hotkeyNameArray := scanFileForHotkeyNames()
    ; At the beginning, all built-in hotkeys will be marked to be loaded. The code below sorts out already existing
    ; hotkeys to avoid overwriting their values.
    builtInHotkeysNeedToBeLoadedArray := builtInHK_NameArray
    ; Prepares all existing hotkeys to be loaded.
    for (name in hotkeyNameArray) {
        tmpObject := CustomMacro()
        tmpObject.ahkBaseFileLocation := ahkBaseFileLocation
        tmpObject.macroConfigFileLocation := macroConfigFileLocation
        ; Checks if the hotkey from the macro config file is a built-in hotkey.
        ; If that's the case, it won't be loaded afterwards.
        loop (builtInHotkeysNeedToBeLoadedArray.Length) {
            if (name == builtInHotkeysNeedToBeLoadedArray.Get(A_Index)) {
                builtInHotkeysNeedToBeLoadedArray.RemoveAt(A_Index)
                break
            }
        }
        ; This allows the custom macro object to load the rest of it's configuration from the macro config file all by itself.
        tmpObject.name := name
        ; To avoid an error due to an invalid hotkey, we just give a random hotkey as a parameter here.
        ; It doesn't matter because the hotkey will be loaded from the file anyway.
        tmpObject.hotkey := "^!+CapsLock"
        tmpObject.loadMacroFromFile()

        ; Checks if a macro file path correction is required.
        SplitPath(tmpObject.macroFileLocation, &outFileName, &outDir)
        if (!FileExist(tmpObject.macroFileLocation)) {
            tmpNewMacroFileLocation := macroFilesStorageDirectory . "\" . outFileName
            ; This will allow users to copy & paste their macros from other locations because
            ; the macro file path will be updated (if possible) in the macro config file.
            ; Searches the macro file in the macro folder.
            if (FileExist(tmpNewMacroFileLocation)) {
                ; Updates the path.
                tmpObject.macroFileLocation := tmpNewMacroFileLocation
                tmpObject.saveMacroToFile()
            }
            else {
                MsgBox(getLanguageArrayString("objectsMsgBox1_1", tmpObject.name, tmpObject.macroFileLocation,
                    tmpNewMacroFileLocation),
                getLanguageArrayString("objectsMsgBox1_2"), "O Icon! 262144")
            }
        }
        ; Applies the changes.
        customMacroObjectArray.Push(tmpObject)
    }
    ; This option determines if built-in hotkeys will be loaded or not.
    if (!readConfigFile("loadBuiltInHotkeys")) {
        return
    }
    for (name in builtInHotkeysNeedToBeLoadedArray) {
        loadBuiltInHotkey(name)
    }
}

/*
Loads one or all built-in hotkeys.
@param pHotkeyname [String] Should be the name of a built-in hotkey to load.
*/
loadBuiltInHotkey(pHotkeyName) {
    global ahkBaseFileLocation
    global macroConfigFileLocation
    global customMacroObjectArray
    global builtInHK_NameArray
    global builtInHKLocation_walkDriveFlyAFK
    global builtInHKLocation_createSololobby

    hotkeyNameArray := builtInHK_NameArray
    hotkeyDescriptionArray :=
        [
            getLanguageArrayString("builtInHotkeyDescription_1"),
            getLanguageArrayString("builtInHotkeyDescription_2")
        ]
    hotkeyHotkeyArray :=
        [
            "^F9",
            "^F10"
        ]
    hotkeyMacroFileLocationArray :=
        [
            builtInHKLocation_walkDriveFlyAFK,
            builtInHKLocation_createSololobby
        ]

    for (name in hotkeyNameArray) {
        tmpObject := CustomMacro()
        tmpObject.name := hotkeyNameArray.Get(A_Index)
        tmpObject.description := hotkeyDescriptionArray.Get(A_Index)
        tmpObject.hotkey := hotkeyHotkeyArray.Get(A_Index)
        tmpObject.macroFileLocation := hotkeyMacroFileLocationArray.Get(A_Index)
        tmpObject.ahkBaseFileLocation := ahkBaseFileLocation
        tmpObject.macroConfigFileLocation := macroConfigFileLocation
        ; This will only load one hotkey.
        if (name == pHotkeyName) {
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
scanFileForHotkeyNames() {
    global macroConfigFileLocation
    hotkeyNameArray := []

    loop read (macroConfigFileLocation) {
        ; Finds every string at the start of a new line which equals to this pattern: [any letters or numbers].
        if (!RegExMatch(A_LoopReadLine, "A)\[.+?\]", &match)) {
            continue
        }
        matchString := match[]
        ; Ignores the standard text.
        if (InStr(matchString, "[CustomHotkeysBelow]")) {
            continue
        }
        ; Removes the brackets at the start and end.
        matchString := StrReplace(matchString, "[",)
        matchString := StrReplace(matchString, "]")
        hotkeyNameArray.Push(matchString)
    }
    return hotkeyNameArray
}

/*
Edits an already existing hotkey in the macro config file.
@param pHotkeyArrayIndex [int] Should be a valid index in the customMacroObjectArray. This marks the hotkey that is currently being edited.
@param pHotkeyName [String] Should be a valid hotkey name.
@param pHotkeyDescription [String] Should be a valid hotkey description with no line breakers (`n).
@param pHotkeyHotkey [String] Should be a valid hotkey in the AutoHotkey format. For example (^!A).
@param pHotkeyMacroFileLocation [String] Should be a valid path to a macro file.
@returns [boolean] True if the hotkey was edited successfully. False otherwise
*/
editHotkey(pHotkeyArrayIndex, pHotkeyName, pHotkeyDescription, pHotkeyHotkey, pHotkeyMacroFileLocation) {
    global customMacroObjectArray
    global customHotkeyNameArray
    global ahkBaseFileLocation
    global macroConfigFileLocation

    if (!customHotkeyNameArray.Has(pHotkeyArrayIndex)) {
        MsgBox("[" . A_ThisFunc . "()] [ERROR] Invalid customHotkeyNameArray index received: [" . pHotkeyArrayIndex .
            "]."
            , "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
        return false
    }
    ; Checks for already exsiting properties in the existing hotkeys with the only exception being the currently edited hotkey.
    for (object in customMacroObjectArray) {
        ; This skips the hotkey that is currently being edited.
        if (A_Index == pHotkeyArrayIndex) {
            continue
        }
        else if (object.name == pHotkeyName) {
            MsgBox(getLanguageArrayString("objectsMsgBox2_1", object.name),
            getLanguageArrayString("objectsMsgBox2_2"), "O Icon! 262144 T2")
            return false
        }
        else if (object.hotkey == pHotkeyHotkey) {
            MsgBox(getLanguageArrayString("objectsMsgBox3_1", object.name),
            getLanguageArrayString("objectsMsgBox3_2"), "O Icon! 262144 T2")
            return false
        }
    }
    try
    {
        currentlyEditedHotkeyObject := customMacroObjectArray.Get(pHotkeyArrayIndex)
        tmpFileCache := ""
        loop read (currentlyEditedHotkeyObject.macroConfigFileLocation) {
            ; Searches the section from the old hotkey and renames it.
            if (A_LoopReadLine == "[" . currentlyEditedHotkeyObject.name . "]") {
                tmpFileCache .= "[" . pHotkeyName . "]`n"
            }
            else {
                tmpFileCache .= A_LoopReadLine . "`n"
            }
        }
        ; Writes the content in the tmpFileCache variable to the file.
        FileDelete(currentlyEditedHotkeyObject.macroConfigFileLocation)
        FileAppend(tmpFileCache, currentlyEditedHotkeyObject.macroConfigFileLocation)
        ; Writes the new values to the edited hotkey.
        currentlyEditedHotkeyObject.name := pHotkeyName
        currentlyEditedHotkeyObject.description := pHotkeyDescription
        currentlyEditedHotkeyObject.hotkey := pHotkeyHotkey
        currentlyEditedHotkeyObject.macroFileLocation := pHotkeyMacroFileLocation
        ; This is just a safety measure.
        currentlyEditedHotkeyObject.ahkBaseFileLocation := ahkBaseFileLocation
        currentlyEditedHotkeyObject.macroConfigFileLocation := macroConfigFileLocation
        currentlyEditedHotkeyObject.saveMacroToFile()
        ; Deletes the old macro object.
        customMacroObjectArray.RemoveAt(pHotkeyArrayIndex)
        ; Applies the changes by pushing the edited object back into the array.
        customMacroObjectArray.InsertAt(pHotkeyArrayIndex, currentlyEditedHotkeyObject)
        ; Updates the hotkey activation status.
        if (customMacroObjectArray.Get(pHotkeyArrayIndex).isEnabled) {
            customMacroObjectArray.Get(pHotkeyArrayIndex).enableHotkey()
        }
        else {
            customMacroObjectArray.Get(pHotkeyArrayIndex).disableHotkey()
        }
        ; Refreshes the overview GUI.
        handleCustomHotkeyOverviewGUI_fillInValuesFromCustomMacroObject()
        MsgBox(getLanguageArrayString("objectsMsgBox4_1"), getLanguageArrayString("objectsMsgBox4_2"),
        "O Iconi 262144 T0.75")
        return true
    }
    catch as error {
        displayErrorMessage(error)
        return false
    }
}

/*
Creates a new custom hotkey.
@param pHotkeyName [String] Should be a valid hotkey name.
@param pHotkeyDescription [String] Should be a valid hotkey description with no line breakers (`n).
@param pHotkeyHotkey [String] Should be a valid hotkey in the AutoHotkey format. For example (^!A).
@param pHotkeyMacroFileLocation [String] Should be a valid path to a macro file.
@returns [boolean] True if the hotkey was edited successfully. False otherwise
*/
createHotkey(pHotkeyName, pHotkeyDescription, pHotkeyHotkey, pHotkeyMacroFileLocation) {
    global customMacroObjectArray
    global customHotkeyNameArray
    global ahkBaseFileLocation
    global macroConfigFileLocation

    ; Checks for already exsiting properties in the existing hotkeys.
    for (object in customMacroObjectArray) {
        if (object.name == pHotkeyName) {
            MsgBox(getLanguageArrayString("objectsMsgBox2_1", object.name),
            getLanguageArrayString("objectsMsgBox2_2"), "O Icon! 262144 T2")
            return false
        }
        else if (object.hotkey == pHotkeyHotkey) {
            MsgBox(getLanguageArrayString("objectsMsgBox3_1", object.name),
            getLanguageArrayString("objectsMsgBox3_2"), "O Icon! 262144 T2")
            return false
        }
    }
    try
    {
        newMacroObject := CustomMacro()
        ; Adds the values from the GUI.
        newMacroObject.name := pHotkeyName
        newMacroObject.description := pHotkeyDescription
        newMacroObject.hotkey := pHotkeyHotkey
        newMacroObject.macroFileLocation := pHotkeyMacroFileLocation
        ; Adds other required values.
        newMacroObject.ahkBaseFileLocation := ahkBaseFileLocation
        newMacroObject.macroConfigFileLocation := macroConfigFileLocation
        ; Tells the object to save into the macro config file.
        newMacroObject.saveMacroToFile()
        ; Adds the new hotkey to the array.
        customMacroObjectArray.Push(newMacroObject)
        ; Updates the hotkey activation status.
        if (customMacroObjectArray.Get(customMacroObjectArray.Length).isEnabled) {
            customMacroObjectArray.Get(customMacroObjectArray.Length).enableHotkey()
        }
        else {
            customMacroObjectArray.Get(customMacroObjectArray.Length).disableHotkey()
        }
        ; Refreshes the overview GUI.
        handleCustomHotkeyOverviewGUI_fillInValuesFromCustomMacroObject()
        MsgBox(getLanguageArrayString("objectsMsgBox4_1"), getLanguageArrayString("objectsMsgBox4_2"),
        "O Iconi 262144 T0.75")
        return true
    }
    catch as error {
        displayErrorMessage(error)
        return false
    }
}

/*
Creates a custom macro object. It has all properties required to create a custom macro with a corresponding hotkey.
If the macro config file (where all custom macros are saved) does not exist, it will produce an error!
@returns [Any] Can return multiple values depending on which functions are called.
*/
class CustomMacro {
    __New() {
        this.name := "new_custom_macro"
        this.description := "new_custom_macro_description"
        this.hotkey := "new_custom_macro_hotkey"
        this.macroFileLocation := "new_custom_macro_file_location"
        this.macroConfigFileLocation := "new_custom_macro_config_file_location"
        this.ahkBaseFileLocation := "new_custom_macro_ahk_base_file_location"
        this.isEnabled := true
    }
    saveMacroToFile() {
        if (!this.integrityCheck()) {
            return false
        }
        IniWrite(this.description, this.macroConfigFileLocation, this.name, "Description")
        IniWrite(this.hotkey, this.macroConfigFileLocation, this.name, "Hotkey")
        IniWrite(this.macroFileLocation, this.macroConfigFileLocation, this.name, "MacroFileLocation")
        IniWrite(this.isEnabled, this.macroConfigFileLocation, this.name, "Enabled")
        return true
    }
    loadMacroFromFile() {
        ; Checks if the config file exists.
        if (!this.isMacroConfigFileExisting()) {
            SplitPath(this.macroConfigFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Macro config file [" . outFileName .
                "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            return false
        }
        ; If a hotkey was marked as active in the config file, it would become deactivated while loading. This variable
        ; remebers the original state and reactivates the hotkey after it has been loaded.
        hotkeyWasEnabled := IniRead(this.macroConfigFileLocation, this.name, "Enabled", "empty_enabled")
        ; Disables the hotkey because in case the key changes while loading the file, the old hotkey would become
        ; a "ghost" hotkey, which is replaced by the new one from the file. By disabeling the hotkey temporarily, we avoid
        ; duplicate hotkeys calling the same macro file.
        if (this.isEnabled) {
            this.disableHotkey()
        }
        this.description := IniRead(this.macroConfigFileLocation, this.name, "Description", "empty_description")
        this.hotkey := IniRead(this.macroConfigFileLocation, this.name, "Hotkey", "empty_hotkey")
        this.macroFileLocation := IniRead(this.macroConfigFileLocation, this.name, "MacroFileLocation",
            "empty_macroFileLocation")
        this.isEnabled := IniRead(this.macroConfigFileLocation, this.name, "Enabled", "empty_enabled")
        if (!this.integrityCheck()) {
            return false
        }
        ; Calling this function here updates the hotkey if necessary. See comment above for more information.
        if (this.isEnabled || hotkeyWasEnabled) {
            this.enableHotkey()
        }
        return true
    }
    deleteHotkey() {
        ; Checks if the config file exists.
        if (!this.isMacroConfigFileExisting()) {
            SplitPath(this.macroConfigFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Macro config file [" . outFileName .
                "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            return false
        }
        IniDelete(this.macroConfigFileLocation, this.name)
    }
    enableHotkey() {
        this.isEnabled := true
        Hotkey(this.hotkey, (*) => RunWait(this.ahkBaseFileLocation . ' "' . this.macroFileLocation . '"'), "On")
        ; Changes the enabled value in the config file.
        IniWrite(this.isEnabled, this.macroConfigFileLocation, this.name, "Enabled")
        return true
    }
    disableHotkey() {
        this.isEnabled := false
        Hotkey(this.hotkey, (*) => RunWait(this.ahkBaseFileLocation . ' "' . this.macroFileLocation . '"'), "Off")
        ; Changes the enabled value in the config file.
        IniWrite(this.isEnabled, this.macroConfigFileLocation, this.name, "Enabled")
        return true
    }
    /*
    Checks if all variables contain a valid value and if required files are present.
    @returns [boolean] True if all checks have passed. False otherwise.
    */
    integrityCheck() {
        if (!this.isHotkeyValid()) {
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Invalid hotkey found: [" . this.hotkey .
                "]!`n`n"
                , "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            return false
        }
        else if (!this.isMacroFileExisting()) {
            SplitPath(this.macroFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Macro file [" . outFileName .
                "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            return false
        }
        else if (!this.isMacroConfigFileExisting()) {
            SplitPath(this.macroConfigFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] Macro config file [" . outFileName .
                "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            return false
        }
        else if (!FileExist(this.ahkBaseFileLocation)) {
            SplitPath(this.ahkBaseFileLocation, &outFileName, &outDir)
            MsgBox("[" . A_ThisFunc . "() from {" . this.name . "}]`n`n[WARNING] AutoHotkey base file [" . outFileName .
                "] not found "
                . "at [" . outDir . "]!`n`n", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            return false
        }
        return true
    }
    ; Creates an empty hotkey to validate the value inside the hotkey property.
    isHotkeyValid() {
        try
        {
            Hotkey(this.hotkey, (*) => "Off")
            return true
        }
        catch {
            return false
        }
    }
    isMacroFileExisting() {
        if (FileExist(this.macroFileLocation)) {
            return true
        }
        return false
    }
    isMacroConfigFileExisting() {
        if (FileExist(this.macroConfigFileLocation)) {
            return true
        }
        return false
    }
}
