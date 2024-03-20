#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

createCustomHotkeyOverviewGUI()
{
    Global
    customHotkeyOverviewGUI := Gui(, "GTAV Tweaks - Hotkey Overview")

    customHotkeyOverviewGUITotalHotkeyAmountText := customHotkeyOverviewGUI.Add("Text", "yp+10 w140", "Total Hotkeys: NUMBER")

    customHotkeyOverviewGUIHotkeyFieldText := customHotkeyOverviewGUI.Add("Text", "yp+30", "Keyboard Shortcut")
    customHotkeyOverviewGUIHotkeyField := customHotkeyOverviewGUI.Add("Hotkey", "yp+20 w200 Disabled")
    customHotkeyOverviewGUIHotkeyDescriptionEditText := customHotkeyOverviewGUI.Add("Text", "xp+210 yp-30", "Description")
    customHotkeyOverviewGUIHotkeyDescriptionEdit := customHotkeyOverviewGUI.Add("Edit", "yp+30 w109 R5.2 ReadOnly Disabled")

    customHotkeyNameArray := []
    customHotkeyOverviewGUIHotkeyDropDownListText := customHotkeyOverviewGUI.Add("Text", "xp-210 yp+35", "Select a hotkey below.")
    customHotkeyOverviewGUIHotkeyDropDownList := customHotkeyOverviewGUI.Add("DropDownList", "yp+20 w200", customHotkeyNameArray)

    customHotkeyOverviewGUIHotkeyStatusIsEnabledRadio := customHotkeyOverviewGUI.Add("Radio", "yp+30 Disabled", "Hotkey enabled")
    customHotkeyOverviewGUIHotkeyStatusIsDisabledRadio := customHotkeyOverviewGUI.Add("Radio", "xp+100 Disabled", "Hotkey disabled")

    customHotkeyOverviewGUIToggleHotkeyButton := customHotkeyOverviewGUI.Add("Button", "xp-101 yp+40 w100 Default", "Toggle Status")
    customHotkeyOverviewGUIActivateAllHotkeysButton := customHotkeyOverviewGUI.Add("Button", "xp+110 w100", "Enable All")
    customHotkeyOverviewGUIDeactivateAllHotkeysButton := customHotkeyOverviewGUI.Add("Button", "xp+110 w100", "Disable All")
    customHotkeyOverviewGUICreateHotkeyButton := customHotkeyOverviewGUI.Add("Button", "xp-220 yp+30 w100", "Create Hotkey")
    customHotkeyOverviewGUIEditHotkeyButton := customHotkeyOverviewGUI.Add("Button", "xp+110 w100", "Edit")
    customHotkeyOverviewGUIDeleteHotkeyButton := customHotkeyOverviewGUI.Add("Button", "xp+110 w100", "Delete")
    ; This triggers the GUI to refresh the element values in case a new hotkey is selected.
    customHotkeyOverviewGUIHotkeyDropDownList.OnEvent("Change", (*) => handleCustomHotkeyOverviewGUI_changeValuesDependingOnWhichHotkeyIsSelected())
    ; Enables or disables a hotkey.
    customHotkeyOverviewGUIToggleHotkeyButton.OnEvent("Click", (*) => handleCustomHotkeyOverviewGUI_toggleStatusButton())
    ; Enables all hotkeys.
    customHotkeyOverviewGUIActivateAllHotkeysButton.OnEvent("Click", (*) => handleCustomHotkeyOverviewGUI_toggleStatusAllHotkeys(true))
    ; Disables all hotkeys.
    customHotkeyOverviewGUIDeactivateAllHotkeysButton.OnEvent("Click", (*) => handleCustomHotkeyOverviewGUI_toggleStatusAllHotkeys(false))
    ; Opens the new custom hotkey GUI to create a new hotkey.
    customHotkeyOverviewGUICreateHotkeyButton.OnEvent("Click", (*) => handleNewCustomHotkeyGUI_openGUI())
    ; Opens the new custom hotkey GUI, but it loads all the values from the currently selected hotkey.
    customHotkeyOverviewGUIEditHotkeyButton.OnEvent("Click", (*) => handleCustomHotkeyOverviewGUI_editHotkey())
    ; Deletes a hotkey.
    customHotkeyOverviewGUIDeleteHotkeyButton.OnEvent("Click", (*) => handleCustomHotkeyOverviewGUI_deleteHotkey())
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

customHotkeyOverviewGUI_onInit()
{
    createCustomHotkeyOverviewGUI()
    handleCustomHotkeyOverviewGUI_fillInValuesFromCustomMacroObject()
}

handleCustomHotkeyOverviewGUI_fillInValuesFromCustomMacroObject()
{
    global customMacroObjectArray
    global customHotkeyNameArray := []

    ; This happens when the macro config file does not contain any hotkeys.
    If (!customMacroObjectArray.Has(1))
    {
        ; Adjusts the GUI element values to match with the fact, that there are no hotkeys.
        customHotkeyOverviewGUITotalHotkeyAmountText.Text := "Total Hotkeys: 0"
        customHotkeyOverviewGUIHotkeyField.Value := ""
        customHotkeyOverviewGUIHotkeyDescriptionEdit.Value := ""
        customHotkeyOverviewGUIHotkeyStatusIsDisabledRadio := false
        customHotkeyOverviewGUIHotkeyStatusIsEnabledRadio := false
        customHotkeyNameArray.InsertAt(1, "No hotkeys in config file found.")
        ; Disables all buttons that are only usefull with at least one hotkey.
        customHotkeyOverviewGUIToggleHotkeyButton.Opt("+Disabled")
        customHotkeyOverviewGUIActivateAllHotkeysButton.Opt("+Disabled")
        customHotkeyOverviewGUIDeactivateAllHotkeysButton.Opt("+Disabled")
        customHotkeyOverviewGUIEditHotkeyButton.Opt("+Disabled")
        customHotkeyOverviewGUIDeleteHotkeyButton.Opt("+Disabled")
    }
    Else
    {
        ; Gathers all hotkey names to display them in the drop down list.
        i := 1
        For (object in customMacroObjectArray)
        {
            customHotkeyNameArray.InsertAt(i, object.name)
            i++
        }
        ; Updates the total hotkey counter.
        customHotkeyOverviewGUITotalHotkeyAmountText.Text := "Total Hotkeys: " . customHotkeyNameArray.Length
        ; Enables all buttons that are only usefull with at least one hotkey.
        customHotkeyOverviewGUIToggleHotkeyButton.Opt("-Disabled")
        customHotkeyOverviewGUIActivateAllHotkeysButton.Opt("-Disabled")
        customHotkeyOverviewGUIDeactivateAllHotkeysButton.Opt("-Disabled")
        customHotkeyOverviewGUIEditHotkeyButton.Opt("-Disabled")
        customHotkeyOverviewGUIDeleteHotkeyButton.Opt("-Disabled")
    }
    ; Refreshes the drop down list.
    customHotkeyOverviewGUIHotkeyDropDownList.Delete()
    customHotkeyOverviewGUIHotkeyDropDownList.Add(customHotkeyNameArray)
}

handleCustomHotkeyOverviewGUI_changeValuesDependingOnWhichHotkeyIsSelected()
{
    global customMacroObjectArray

    ; This happens when the macro config file does not contain any hotkeys.
    If (!customMacroObjectArray.Has(1))
    {
        Return
    }
    ; Writes all affected values to the GUI elements depending on which drop down list entry is selected.
    customHotkeyOverviewGUIHotkeyField.Value := customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).hotkey
    customHotkeyOverviewGUIHotkeyDescriptionEdit.Value := customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).description
    ; Changes the radio element value depending on the hotkey's status.
    If (customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).isEnabled)
    {
        customHotkeyOverviewGUIHotkeyStatusIsEnabledRadio.Value := true
        customHotkeyOverviewGUIHotkeyStatusIsDisabledRadio.Value := false
    }
    Else
    {
        customHotkeyOverviewGUIHotkeyStatusIsEnabledRadio.Value := false
        customHotkeyOverviewGUIHotkeyStatusIsDisabledRadio.Value := true
    }
}

/*
Toggles the currently selected hotkey's status.
@param pBooleanStatus [boolean] An optional parameter to disable the toggeling function and set the value directly instead.
Mostly used by the handleCustomHotkeyOverviewGUI_toggleStatusAllHotkeys() function.
*/
handleCustomHotkeyOverviewGUI_toggleStatusButton(pBooleanStatus := unset)
{
    global customMacroObjectArray

    ; This happens, when there is no entry selected.
    If (customHotkeyOverviewGUIHotkeyDropDownList.Value == 0)
    {
        Return
    }
    ; If there is a status given, it will be applied to the currently selected hotkey.
    If (IsSet(pBooleanStatus))
    {
        customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).isEnabled := pBooleanStatus
    }
    Else
    {
        ; Inverts the "isEnabled" value from the corresponding custom macro object.
        customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).isEnabled :=
            !customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).isEnabled
    }
    ; Saves the changes to the macro config file.
    If (customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).isEnabled)
    {
        customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).enableHotkey()
    }
    Else
    {
        customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).disableHotkey()
    }
    ; Calls the "refresh" function to apply the changes.
    handleCustomHotkeyOverviewGUI_changeValuesDependingOnWhichHotkeyIsSelected()
}
/*
Selects every hotkey from the drop down list and sets it's status value to the pBooleanStatus parameter.
@param pBooleanStatus [boolean] If set to true, enables all hotkeys. Does the opposite, when set to false.
*/
handleCustomHotkeyOverviewGUI_toggleStatusAllHotkeys(pBooleanStatus)
{
    global customMacroObjectArray

    Loop (customMacroObjectArray.Length)
    {
        customHotkeyOverviewGUIHotkeyDropDownList.Value := A_Index
        handleCustomHotkeyOverviewGUI_toggleStatusButton(pBooleanStatus)
    }
}

handleCustomHotkeyOverviewGUI_editHotkey()
{
    global customMacroObjectArray

    ; This happens, when there is no entry selected.
    If (customHotkeyOverviewGUIHotkeyDropDownList.Value == 0)
    {
        Return
    }
    currentHotkeyName := customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).name
    currentHotkeyHotkey := customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).hotkey
    handleNewCustomHotkeyGUI_openGUI(true, currentHotkeyName, currentHotkeyHotkey)
}

handleCustomHotkeyOverviewGUI_deleteHotkey()
{
    global customMacroObjectArray

    ; This happens, when there is no entry selected.
    If (customHotkeyOverviewGUIHotkeyDropDownList.Value == 0)
    {
        Return
    }
    result := MsgBox("Are you sure, that you want to delete this hotkey?", "GTAV Tweaks - Delete Hotkey", "YN Icon! 262144")
    If (result != "Yes")
    {
        Return
    }
    ; Tells the macro object to delete it's entry in the macro config file.
    customMacroObjectArray.Get(customHotkeyOverviewGUIHotkeyDropDownList.Value).deleteHotkey()
    ; Refreshes the complete customMacroObjectArray, because the file has changed.
    createCustomMacroObjectArray()
    ; Refreshes the GUI.
    handleCustomHotkeyOverviewGUI_fillInValuesFromCustomMacroObject()
}