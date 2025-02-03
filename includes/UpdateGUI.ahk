#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

/*
Creates the user inface which asks the user to confirm the update.
@param pUpdateVersion [String] The version of the update or rather the complete tag name.
*/
createUpdateGUI(pUpdateVersion) {
    ; Required information for the update GUI.
    updatePatchNotesURL := "https://github.com/LeoTN/gtav-tweaks/releases/tag/" . pUpdateVersion
    msiDownloadURL := "https://github.com/LeoTN/gtav-tweaks/releases/download/"
        . pUpdateVersion . "/GTAV_Tweaks_" . pUpdateVersion . "_Installer.msi"

    global updateGUI := Gui(, getLanguageArrayString("updateGUI_1"))
    updateGUIUpdateText := updateGUI.Add("Text", "w320 R3 Center",
        getLanguageArrayString("updateGUI_2", pUpdateVersion))
    updateGUIUpdateText.SetFont("bold s12")

    updateGUIPatchNotesLink := updateGUI.Add("Text", "yp+40 w320 R2 Center", getLanguageArrayString("updateGUI_3"))
    updateGUIPatchNotesLink.SetFont("s10 underline cBlue")
    updateGUIPatchNotesLink.OnEvent("Click", (*) => Run(updatePatchNotesURL))

    updateGUIDownloadMSIButton := updateGUI.Add("Button", "yp+30 xp+50 w100 R2", getLanguageArrayString("updateGUI_4"))
    updateGUIDownloadMSIButton.OnEvent("Click", (*) => handleUpdateGUI_downloadMSIButton(msiDownloadURL))

    updateGUINoUpdateButton := updateGUI.Add("Button", "xp+110 w100 R2", getLanguageArrayString("updateGUI_5"))
    updateGUINoUpdateButton.OnEvent("Click", (*) => updateGUI.Destroy())

    updateGUI.Show()
}

handleUpdateGUI_downloadMSIButton(pMSIDownloadURL) {
    Run(pMSIDownloadURL)
    backupDirectory := A_ScriptDir . "\GTAV_Tweaks_old_version_backups"
    result := MsgBox(getLanguageArrayString("functionsMsgBox1_1", backupDirectory),
    getLanguageArrayString("functionsMsgBox1_2"), "OC Icon! 262144")
    ; Exits the script if the user confirms.
    if (result == "OK") {
        backupOldVersionFiles(backupDirectory)
    }
}
