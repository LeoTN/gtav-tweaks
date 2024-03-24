#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

createNewCustomHotkeyGUI()
{
    Global
    newCustomHotkeyGUI := Gui(, "GTAV Tweaks - New Hotkey")

    newCustomHotkeyGUIHotkeyNameText := newCustomHotkeyGUI.Add("Text", "yp+10", "Hotkey Name")
    newCustomHotkeyGUIHotkeyNameEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 w200")

    newCustomHotkeyGUIHotkeyFieldText := newCustomHotkeyGUI.Add("Text", "yp+30", "Keyboard Shortcut")
    newCustomHotkeyGUIHotkeyField := newCustomHotkeyGUI.Add("Hotkey", "yp+20 w200")

    newCustomHotkeyGUIHotkeyDescriptionText := newCustomHotkeyGUI.Add("Text", "xp+210 yp-70", "Hotkey Description")
    newCustomHotkeyGUIHotkeyDescriptionEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 R4.85 w108 -WantReturn")

    newCustomHotkeyGUIMacroFileLocationText := newCustomHotkeyGUI.Add("Text", "xp-210 yp+82", "Macro File Location")
    newCustomHotkeyGUIMacroFileLocationEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 w285")
    newCustomHotkeyGUIMacroFileLocationButton := newCustomHotkeyGUI.Add("Button", "xp+299 yp-1 w20", "...")
    newCustomHotkeyGUIWhatIsAMacroFileButton := newCustomHotkeyGUI.Add("Button", "xp-300 yp+30 w140", "How do I get macro files?")

    newCustomHotkeyGUISaveHotkeyButton := newCustomHotkeyGUI.Add("Button", "yp+41 w100", "Save Hotkey")
    newCustomHotkeyGUICloseHotkeyButton := newCustomHotkeyGUI.Add("Button", "xp+110 w100", "Close")
    newCustomHotkeyGUIRecordMacroButton := newCustomHotkeyGUI.Add("Button", "xp+110 w100", "Record Macro")
    ; Saves the new (or edited) hotkey.
    newCustomHotkeyGUISaveHotkeyButton.OnEvent("Click", (*) => handleNewCustomHotkeyGUI_saveHotkeyButton())
    newCustomHotkeyGUICloseHotkeyButton.OnEvent("Click", (*) => handleNewCustomHotkeyGUI_closeButton())
    ; Lets the user choose a macro file.
    newCustomHotkeyGUIMacroFileLocationButton.OnEvent("Click", (*) => handleNewCustomHotkeyGUI_selectMacroFileButton())
    newCustomHotkeyGUIWhatIsAMacroFileButton.OnEvent("Click", (*) => handleNewCustomHotkeyGUI_explainMacros())
    newCustomHotkeyGUIRecordMacroButton.OnEvent("Click", (*) => handleNewCustomHotkeyGUI_recordMacro())
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

newCustomHotkeyGUI_onInit()
{
    ; Imagine the following situation: The user wants to edit a hotkey and he has selected the very first one. This means
    ; the DDL in the overview GUI will have an index value of 1. Now he clicks on the edit button and starts changing values.
    ; He selects another hotkey (for example the second one). If he applies the changes and we apply them to the custom macro object
    ; in the custom object array using the currently selected DDL entry index value (2 because the user changed to another hotkey
    ; in the mean time), we would edit the object at index 2, but we want to edit the object at index 1.
    ; This variable saves this information, to avoid this issue.
    global currentlySelectedHotkeyDDLIndex := 0
    createNewCustomHotkeyGUI()
}

/*
Opens the new hotkey GUI. This usually is used to edit hotkeys.
@param pBooleanLoadCurrentlySelectedHotkey [boolean] If set to true, the GUI will load all values from the currently selected hotkey.
*/
handleNewCustomHotkeyGUI_openGUI(pBooleanLoadCurrentlySelectedHotkey := false)
{
    global customMacroObjectArray
    global currentlySelectedHotkeyDDLIndex := customHotkeyOverviewGUIHotkeyDropDownList.Value

    If (!pBooleanLoadCurrentlySelectedHotkey)
    {
        ; Changing this value to 0 tells all following functions, that we are not editing an existing hotkey.
        currentlySelectedHotkeyDDLIndex := 0
    }
    If (currentlySelectedHotkeyDDLIndex != 0)
    {
        newCustomHotkeyGUIHotkeyNameEdit.Value := customMacroObjectArray.Get(currentlySelectedHotkeyDDLIndex).name
        newCustomHotkeyGUIHotkeyDescriptionEdit.Value := customMacroObjectArray.Get(currentlySelectedHotkeyDDLIndex).description
        newCustomHotkeyGUIHotkeyField.Value := customMacroObjectArray.Get(currentlySelectedHotkeyDDLIndex).hotkey
        newCustomHotkeyGUIMacroFileLocationEdit.Value := customMacroObjectArray.Get(currentlySelectedHotkeyDDLIndex).macroFileLocation
    }
    newCustomHotkeyGUI.Show()
}

; Checks if all values are correct and creates a new custom hotkey.
handleNewCustomHotkeyGUI_saveHotkeyButton()
{
    global ahkBaseFileLocation
    global macroConfigFileLocation
    global customMacroObjectArray
    global currentlySelectedHotkeyDDLIndex
    saveHotkeyName := newCustomHotkeyGUIHotkeyNameEdit.Value
    saveHotkeyDescription := newCustomHotkeyGUIHotkeyDescriptionEdit.Value
    saveHotkeyHotkey := newCustomHotkeyGUIHotkeyField.Value
    saveHotkeyMacroFileLocation := newCustomHotkeyGUIMacroFileLocationEdit.Value
    ; Checks if all important fields have a valid value.
    If (!saveHotkeyName)
    {
        MsgBox("Please enter a name for your hotkey.", "GTAV Tweaks - Missing Hotkey Name", "O Icon! 262144 T1.5")
        Return
    }
    Else If (!saveHotkeyHotkey)
    {
        MsgBox("Please provide a keyboard shortcut for your hotkey.", "GTAV Tweaks - Missing Hotkey Keyboard Shortcut", "O Icon! 262144 T1.5")
        Return
    }
    ; Makes sure that the path is an actual file and not a directory or more specifically a folder.
    SplitPath(saveHotkeyMacroFileLocation, , , &outExtension)
    If (!FileExist(saveHotkeyMacroFileLocation) || outExtension != "ahk")
    {
        MsgBox("You macro file does not exist.", "GTAV Tweaks - Missing Hotkey Macro File", "O Icon! 262144 T1.5")
        Return
    }
    ; This means that the user wants to edit an existing hotkey.
    If (currentlySelectedHotkeyDDLIndex != 0)
    {
        editHotkey(currentlySelectedHotkeyDDLIndex, saveHotkeyName, saveHotkeyDescription, saveHotkeyHotkey, saveHotkeyMacroFileLocation)
    }
    Else
    {
        createHotkey(saveHotkeyName, saveHotkeyDescription, saveHotkeyHotkey, saveHotkeyMacroFileLocation)
    }
    handleNewCustomHotkeyGUI_closeButton()
}

handleNewCustomHotkeyGUI_closeButton()
{
    newCustomHotkeyGUI.Hide()
    ; Clears all fields.
    newCustomHotkeyGUIHotkeyNameEdit.Value := ""
    newCustomHotkeyGUIHotkeyDescriptionEdit.Value := ""
    newCustomHotkeyGUIHotkeyField.Value := ""
    newCustomHotkeyGUIMacroFileLocationEdit.Value := ""
}

handleNewCustomHotkeyGUI_selectMacroFileButton()
{
    global recordedMacroFilesStorageDirectory

    macroFile := FileSelect(3, recordedMacroFilesStorageDirectory, "Please select a macro file.", "*.ahk")
    ; Makes sure that the path is an actual file and not a directory or more specifically a folder.
    SplitPath(macroFile, , , &outExtension)
    ; This usually happens, when the user cancels the selection.
    If (macroFile == "")
    {
        Return
    }
    Else If (!FileExist(macroFile) || outExtension != "ahk")
    {
        MsgBox("Please select a valid macro file.", "GTAV Tweaks - Invalid Macro File Location", "O Icon! 262144 T1.5")
        Return
    }
    newCustomHotkeyGUIMacroFileLocationEdit.Value := macroFile
}

handleNewCustomHotkeyGUI_explainMacros()
{
    global macroRecordHotkey
    global recordedMacroFilesStorageDirectory

    MsgBox("What is a macro?`n`nA macro is an automated sequence of keystrokes and mouse movements that you record "
        . "beforehand and then play back.", "GTAV Tweaks - What Is A Macro", "O Iconi 262144 ")
    MsgBox('To start recording the macro, press the [' . macroRecordHotkey . '] key after clicking [Record Macro].`n`nThe macro file will then'
        . ' be saved under the path`n[' . recordedMacroFilesStorageDirectory . ']`nand named with the current timestamp.',
        "GTAV Tweaks - How To Record Macros", "O Iconi 262144")
    MsgBox("When recording macros, please note that scrolling with the mouse wheel will not be recorded.`n`nIt is"
        . " recommended to perform actions slower than usual during recording to ensure the macro will work in the end.",
        "GTAV Tweaks - Macro Recording Tips", "O Icon! 262144 ")
    result := MsgBox("You can find additional information in the FAQ contained in the README.txt file.`n`nPress [Yes] to open it.",
        "GTAV Tweaks - Macro FAQ", "YN Iconi 262144 ")
    If (result == "Yes")
    {
        openReadMeFile()
    }
}

handleNewCustomHotkeyGUI_recordMacro()
{
    global macroRecordHotkey
    global recordedMacroFilesStorageDirectory

    result := MsgBox("You have 15 seconds after closing this info box to begin recording by pressing [" . macroRecordHotkey . "] .`n`n"
        "To stop recording, simply press [" . macroRecordHotkey . "] again.", "Macro Recording Information", "OC Iconi 262144")
    If (result != "OK")
    {
        Return
    }
    If (KeyWait(macroRecordHotkey, "D T15"))
    {
        ; This hotkey cannot be suspended.
        Hotkey(macroRecordHotkey, (*) => hotkey_stopMacroRecording(), "On S")
        ; Records the macro file with the current time stamp as it's file name.
        recordMacro(recordedMacroFilesStorageDirectory . "\" . FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss") . ".ahk")
        Hotkey(macroRecordHotkey, (*) => hotkey_stopMacroRecording(), "On S")
    }
    ; Only enabled temporarily while recording.
    hotkey_stopMacroRecording()
    {
        global booleanMacroIsRecording := false
    }
}