#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

createNewCustomHotkeyGUI()
{
    Global
    newCustomHotkeyGUI := Gui(, getLanguageArrayString("newCustomHotkeyGUI_1"))

    newCustomHotkeyGUIHotkeyNameText := newCustomHotkeyGUI.Add("Text", "yp+10", getLanguageArrayString("newCustomHotkeyGUI_2"))
    newCustomHotkeyGUIHotkeyNameEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 w200")

    newCustomHotkeyGUIHotkeyFieldText := newCustomHotkeyGUI.Add("Text", "yp+30", getLanguageArrayString("newCustomHotkeyGUI_3"))
    newCustomHotkeyGUIHotkeyField := newCustomHotkeyGUI.Add("Hotkey", "yp+20 w200")

    newCustomHotkeyGUIHotkeyDescriptionText := newCustomHotkeyGUI.Add("Text", "xp+210 yp-70", getLanguageArrayString("newCustomHotkeyGUI_4"))
    newCustomHotkeyGUIHotkeyDescriptionEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 R4.85 w108 -WantReturn")

    newCustomHotkeyGUIMacroFileLocationText := newCustomHotkeyGUI.Add("Text", "xp-210 yp+82", getLanguageArrayString("newCustomHotkeyGUI_5"))
    newCustomHotkeyGUIMacroFileLocationEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 w285")
    newCustomHotkeyGUIMacroFileLocationButton := newCustomHotkeyGUI.Add("Button", "xp+299 yp-1 w20", "...")
    newCustomHotkeyGUIWhatIsAMacroFileButton := newCustomHotkeyGUI.Add("Button", "xp-300 yp+30 w140", getLanguageArrayString("newCustomHotkeyGUI_6"))

    newCustomHotkeyGUISaveHotkeyButton := newCustomHotkeyGUI.Add("Button", "yp+41 w100", getLanguageArrayString("newCustomHotkeyGUI_7"))
    newCustomHotkeyGUICloseHotkeyButton := newCustomHotkeyGUI.Add("Button", "xp+110 w100", getLanguageArrayString("newCustomHotkeyGUI_8"))
    newCustomHotkeyGUIRecordMacroButton := newCustomHotkeyGUI.Add("Button", "xp+110 w100", getLanguageArrayString("newCustomHotkeyGUI_9"))
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
        MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox1_1"), getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox1_2"), "O Icon! 262144 T1.5")
        Return
    }
    Else If (!saveHotkeyHotkey)
    {
        MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox2_1"), getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox2_2"), "O Icon! 262144 T1.5")
        Return
    }
    ; Makes sure that the path is an actual file and not a directory or more specifically a folder.
    SplitPath(saveHotkeyMacroFileLocation, , , &outExtension)
    If (!FileExist(saveHotkeyMacroFileLocation) || outExtension != "ahk")
    {
        MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox3_1"), getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox3_2"), "O Icon! 262144 T1.5")
        Return
    }
    ; This means that the user wants to edit an existing hotkey.
    If (currentlySelectedHotkeyDDLIndex != 0)
    {
        ; This happens when editing was successful.
        If (editHotkey(currentlySelectedHotkeyDDLIndex, saveHotkeyName, saveHotkeyDescription, saveHotkeyHotkey, saveHotkeyMacroFileLocation))
        {
            handleNewCustomHotkeyGUI_closeButton()
        }
    }
    Else
    {
        ; This happens when creating the hotkey was successful.
        If (createHotkey(saveHotkeyName, saveHotkeyDescription, saveHotkeyHotkey, saveHotkeyMacroFileLocation))
        {
            handleNewCustomHotkeyGUI_closeButton()
        }
    }
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

    ; This will open the current directory where the current macro file is stored in if one is selected.
    If (newCustomHotkeyGUIMacroFileLocationEdit.Value != "")
    {
        SplitPath(newCustomHotkeyGUIMacroFileLocationEdit.Value, , &outDir, &outExtension)
        ; This means there is no file at the end of the path.
        If ((outExtension == "") && DirExist(newCustomHotkeyGUIMacroFileLocationEdit.Value))
        {
            selectPath := newCustomHotkeyGUIMacroFileLocationEdit.Value
        }
        Else If (DirExist(outDir))
        {
            selectPath := outDir
        }
        Else
        {
            selectPath := recordedMacroFilesStorageDirectory
        }
    }
    Else
    {
        selectPath := recordedMacroFilesStorageDirectory
    }

    macroFile := FileSelect(3, selectPath, "Please select a macro file.", "*.ahk")
    ; Makes sure that the path is an actual file and not a directory or more specifically a folder.
    SplitPath(macroFile, , , &outExtension)
    ; This usually happens, when the user cancels the selection.
    If (macroFile == "")
    {
        Return
    }
    Else If (!FileExist(macroFile) || outExtension != "ahk")
    {
        MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox4_1"), getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox4_2"), "O Icon! 262144 T1.5")
        Return
    }
    newCustomHotkeyGUIMacroFileLocationEdit.Value := macroFile
}

handleNewCustomHotkeyGUI_explainMacros()
{
    global macroRecordHotkey
    global recordedMacroFilesStorageDirectory

    MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox5_1"),
        getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox5_2"), "O Iconi 262144 ")
    MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox6_1", macroRecordHotkey, recordedMacroFilesStorageDirectory),
        getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox6_2"), "O Iconi 262144")
    MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox7_1"),
        getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox7_2"), "O Icon! 262144 ")
    result := MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox8_1"),
        getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox8_2"), "YN Iconi 262144 ")
    If (result == "Yes")
    {
        openReadMeFile()
    }
}

handleNewCustomHotkeyGUI_recordMacro()
{
    global macroRecordHotkey
    global recordedMacroFilesStorageDirectory

    result := MsgBox(getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox9_1", macroRecordHotkey, macroRecordHotkey),
        getLanguageArrayString("newCustomHotkeyOverviewGUIMsgBox9_2"), "OC Iconi 262144")
    If (result != "OK")
    {
        Return
    }
    If (KeyWait(macroRecordHotkey, "D T15"))
    {
        ; This hotkey cannot be suspended.
        Hotkey(macroRecordHotkey, (*) => stopMacroRecording(), "On S")
        ; Records the macro file with the current time stamp as it's file name.
        startMacroRecording()
    }
    Hotkey(macroRecordHotkey, (*) => stopMacroRecording(), "Off S")
}