#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

/*
Creates the user inface which asks the user to confirm the update.
@param pUpdateVersion [String] The version of the update or rather the complete tag name.
@param pPowershellArgumentString [String] The argument string to call the PowerShell update script.
*/
createUpdateGUI(pUpdateVersion, pPowershellArgumentString) {
    ; Required information for the update GUI.
    updatePatchNotesURL := "https://github.com/LeoTN/gtav-tweaks/releases/tag/" . pUpdateVersion

    global updateGUI := Gui(, "GTAV Tweaks - Update")
    updateGUIUpdateText := updateGUI.Add("Text", "w320 R3 Center", "Update Available - [" . pUpdateVersion . "]")
    updateGUIUpdateText.SetFont("bold s12")

    updateGUIPatchNotesLink := updateGUI.Add("Text", "yp+40 w320 R2 Center", 'Patch Notes')
    updateGUIPatchNotesLink.SetFont("s10 underline cBlue")
    updateGUIPatchNotesLink.OnEvent("Click", (*) => Run(updatePatchNotesURL))

    updateGUIManualUpdateButton := updateGUI.Add("Button", "yp+30 w100", "Manual Update")
    updateGUIManualUpdateButton.OnEvent("Click", (*) => handleUpdateGUI_manualUpdateButton(pPowershellArgumentString))
    updateGUIAutoUpdateButton := updateGUI.Add("Button", "xp+110 w100", "Auto Update")
    updateGUIAutoUpdateButton.OnEvent("Click", (*) => handleUpdateGUI_autoUpdateButton(pPowershellArgumentString))
    updateGUIAutoUpdateButton.Focus()
    updateGUINoUpdateButton := updateGUI.Add("Button", "xp+110 w100", "No Thanks")
    updateGUINoUpdateButton.OnEvent("Click", (*) => updateGUI.Destroy())

    updateGUI.Show()
}

/*
@param pPowershellArgumentString [String] The argument string to call the PowerShell update script.
*/
handleUpdateGUI_autoUpdateButton(pPowershellArgumentString) {
    ; Calls the PowerShell script to install the update automatically without further user input required.
    Run(pPowershellArgumentString . " -pSwitchAutoUpdate")
    ExitApp()
    ExitApp()
}

/*
@param pPowershellArgumentString [String] The argument string to call the PowerShell update script.
*/
handleUpdateGUI_manualUpdateButton(pPowershellArgumentString) {
    ; Calls the PowerShell script to download the new update, but the user has to install the .MSI file manually.
    Run(pPowershellArgumentString)
    ExitApp()
    ExitApp()
}
