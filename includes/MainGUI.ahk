#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

createMainGUI() {
    global
    fileSelectionMenuOpen := Menu()
    fileSelectionMenuOpen.Add(getLanguageArrayString("mainGUIFileSubMenu1_1") . "`t1", (*) => openConfigFile())
    fileSelectionMenuOpen.SetIcon(getLanguageArrayString("mainGUIFileSubMenu1_1") . "`t1", iconFileLocation, 3) ; ICON_DLL_USED_HERE
    fileSelectionMenuOpen.Add(getLanguageArrayString("mainGUIFileSubMenu1_2") . "`t2", (*) => openMacroConfigFile())
    fileSelectionMenuOpen.SetIcon(getLanguageArrayString("mainGUIFileSubMenu1_2") . "`t2", iconFileLocation, 10) ; ICON_DLL_USED_HERE
    ; The reason why the path is opened explicitly with explorer.exe is, that sometimes it will attempt to sort of guess the file
    ; extension and open other files. For example GTAV_Tweaks.exe instead of the folder GTAV_Tweaks.
    fileSelectionMenuOpen.Add(getLanguageArrayString("mainGUIFileSubMenu1_3") . "`t3", (*) => Run('explorer.exe "' .
        A_ScriptDir . '"'))
    fileSelectionMenuOpen.SetIcon(getLanguageArrayString("mainGUIFileSubMenu1_3") . "`t3", iconFileLocation, 12) ; ICON_DLL_USED_HERE
    fileSelectionMenuOpen.Add(getLanguageArrayString("mainGUIFileSubMenu1_4") . "`t4", (*) => Run('explorer.exe "' .
        scriptMainDirectory . '"'))
    fileSelectionMenuOpen.SetIcon(getLanguageArrayString("mainGUIFileSubMenu1_4") . "`t4", iconFileLocation, 2) ; ICON_DLL_USED_HERE

    fileSelectionMenuReset := Menu()
    fileSelectionMenuReset.Add(getLanguageArrayString("mainGUIFileSubMenu2_1") . "`tShift+1", (*) =>
        createDefaultConfigFile(, true, true))
    fileSelectionMenuReset.SetIcon(getLanguageArrayString("mainGUIFileSubMenu2_1") . "`tShift+1", iconFileLocation, 3) ; ICON_DLL_USED_HERE

    fileMenu := Menu()
    fileMenu.Add("&" . getLanguageArrayString("mainGUIFileMenu_1") . "...", fileSelectionMenuOpen)
    fileMenu.SetIcon("&" . getLanguageArrayString("mainGUIFileMenu_1") . "...", iconFileLocation, 11) ; ICON_DLL_USED_HERE
    fileMenu.Add("&" . getLanguageArrayString("mainGUIFileMenu_2") . "...", fileSelectionMenuReset)
    fileMenu.SetIcon("&" . getLanguageArrayString("mainGUIFileMenu_2") . "...", iconFileLocation, 13) ; ICON_DLL_USED_HERE

    languageMenu := Menu()
    ; Adds all supported langues to the menu.
    ; Currently supported language amount: 4. One slot is occupied by the SYSTEM option.
    static tmpKey1 := unset
    static tmpKey2 := unset
    static tmpKey3 := unset
    static tmpKey4 := unset
    static tmpKey5 := unset
    selectedLanguage := readConfigFile("PREFERRED_LANGUAGE")
    ; Remember to CHANGE the icons as well when adding a new language.
    for (key in languageCodeMap) {
        if (!IsSet(tmpKey1)) {
            tmpKey1 := key
            languageMenu.Add(tmpKey1, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey1) reloadScriptPrompt())
            languageMenu.SetIcon(tmpKey1, iconFileLocation, 18) ; ICON_DLL_USED_HERE
            ; Disables the currently selected language option.
            if (selectedLanguage == tmpKey1) {
                languageMenu.Disable(tmpKey1)
            }
        }
        else if (!IsSet(tmpKey2)) {
            tmpKey2 := key
            languageMenu.Add(tmpKey2, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey2) reloadScriptPrompt())
            languageMenu.SetIcon(tmpKey2, iconFileLocation, 19) ; ICON_DLL_USED_HERE
            ; Disables the currently selected language option.
            if (selectedLanguage == tmpKey2) {
                languageMenu.Disable(tmpKey2)
            }
        }
        else if (!IsSet(tmpKey3)) {
            tmpKey3 := key
            languageMenu.Add(tmpKey3, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey3) reloadScriptPrompt())
            languageMenu.SetIcon(tmpKey3, iconFileLocation, 17) ; ICON_DLL_USED_HERE
            ; Disables the currently selected language option.
            if (selectedLanguage == tmpKey3) {
                languageMenu.Disable(tmpKey3)
            }
        }
        else if (!IsSet(tmpKey4)) {
            tmpKey4 := key
            languageMenu.Add(tmpKey4, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey4) reloadScriptPrompt())
            languageMenu.SetIcon(tmpKey4, iconFileLocation, 1) ; ICON_DLL_USED_HERE
            ; Disables the currently selected language option.
            if (selectedLanguage == tmpKey4) {
                languageMenu.Disable(tmpKey4)
            }
        }
        else if (!IsSet(tmpKey5)) {
            tmpKey5 := key
            languageMenu.Add(tmpKey5, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey5) reloadScriptPrompt())
            languageMenu.SetIcon(tmpKey5, iconFileLocation, 1) ; ICON_DLL_USED_HERE
            ; Disables the currently selected language option.
            if (selectedLanguage == tmpKey4) {
                languageMenu.Disable(tmpKey4)
            }
        }
    }

    optionsMenu := Menu()
    optionsMenu.Add(getLanguageArrayString("mainGUIOptionsMenu_3"), languageMenu)
    optionsMenu.SetIcon(getLanguageArrayString("mainGUIOptionsMenu_3"), iconFileLocation, 7) ; ICON_DLL_USED_HERE
    optionsMenu.Add()
    optionsMenu.Add(getLanguageArrayString("mainGUIOptionsMenu_4"), (*) => handleMainGUI_menu_searchForUpdates())
    optionsMenu.SetIcon(getLanguageArrayString("mainGUIOptionsMenu_4"), iconFileLocation, 4) ; ICON_DLL_USED_HERE
    optionsMenu.Add(getLanguageArrayString("mainGUIOptionsMenu_5"), (*) => manageDesktopShortcut(true))
    optionsMenu.SetIcon(getLanguageArrayString("mainGUIOptionsMenu_5"), iconFileLocation, 20) ; ICON_DLL_USED_HERE
    optionsMenu.Add()
    optionsMenu.Add(getLanguageArrayString("mainGUIOptionsMenu_1"), (*) => terminateScriptPrompt())
    optionsMenu.SetIcon(getLanguageArrayString("mainGUIOptionsMenu_1"), iconFileLocation, 5) ; ICON_DLL_USED_HERE
    optionsMenu.Add(getLanguageArrayString("mainGUIOptionsMenu_2"), (*) => reloadScriptPrompt())
    optionsMenu.SetIcon(getLanguageArrayString("mainGUIOptionsMenu_2"), iconFileLocation, 16) ; ICON_DLL_USED_HERE
    allMenus := MenuBar()
    allMenus.Add("&" . getLanguageArrayString("mainGUIMenu_1"), fileMenu)
    allMenus.SetIcon("&" . getLanguageArrayString("mainGUIMenu_1"), iconFileLocation, 6) ; ICON_DLL_USED_HERE
    allMenus.Add("&" . getLanguageArrayString("mainGUIMenu_2"), optionsMenu)
    allMenus.SetIcon("&" . getLanguageArrayString("mainGUIMenu_2"), iconFileLocation, 14) ; ICON_DLL_USED_HERE
    allMenus.Add("&" . getLanguageArrayString("mainGUIMenu_3"), (*) => customHotkeyOverviewGUI.Show())
    allMenus.SetIcon("&" . getLanguageArrayString("mainGUIMenu_3"), iconFileLocation, 15) ; ICON_DLL_USED_HERE
    allMenus.Add("&" . getLanguageArrayString("mainGUIMenu_4"), (*) => helpGUI.Show())
    allMenus.SetIcon("&" . getLanguageArrayString("mainGUIMenu_4"), iconFileLocation, 8) ; ICON_DLL_USED_HERE
    mainGUI := Gui(, "GTAV Tweaks")
    mainGUI.MenuBar := allMenus
    ; This part begins to fill the GUI with checkboxes and all that stuff.
    applyChangesText := mainGUI.Add("Text", "", getLanguageArrayString("mainGUI_1"))
    startupBehaviorGroupbox := mainGUI.Add("GroupBox", "yp+20 w320 R6.3", getLanguageArrayString("mainGUI_2"))
    launchWithGTACheckbox := mainGUI.Add("Checkbox", "xp+10 yp+20 vLaunchWithGTACheckbox",
        getLanguageArrayString("mainGUI_3"))
    launchMinimizedToTrayCheckbox := mainGUI.Add("Checkbox", "yp+20 vLaunchMinimizedToTrayCheckbox",
        getLanguageArrayString("mainGUI_4"))
    minimizeToTrayInsteadOfCloseCheckbox := mainGUI.Add("Checkbox", "yp+20 vMinimizeToTrayInsteadOfCloseCheckbox",
        getLanguageArrayString("mainGUI_12"))
    showLaunchMessageCheckbox := mainGUI.Add("Checkbox", "yp+20 vShowLaunchMessageCheckbox", getLanguageArrayString(
        "mainGUI_5"))
    checkForUpdateAtLaunchCheckbox := mainGUI.Add("Checkbox", "yp+20 vCheckForUpdateAtLaunchCheckbox",
        getLanguageArrayString("mainGUI_6"))
    updateToBetaReleasesCheckbox := mainGUI.Add("Checkbox", "yp+20 vUpdateToBetaReleasesCheckbox",
        getLanguageArrayString("mainGUI_7"))
    gameOptionsGroupbox := mainGUI.Add("GroupBox", "xp-10 yp+30 w320 R3.3", getLanguageArrayString("mainGUI_8"))
    muteGameWhileLaunchCheckbox := mainGUI.Add("Checkbox", "xp+10 yp+20 vMuteGameWhileLaunchCheckbox",
        getLanguageArrayString("mainGUI_9"))
    setGameProcessPriorityHighCheckbox := mainGUI.Add("Checkbox", "yp+20 vSetGameProcessPriorityHighCheckbox",
        getLanguageArrayString("mainGUI_10"))
    showGTALaunchMessageCheckbox := mainGUI.Add("Checkbox", "yp+20 vShowGTALaunchMessageCheckbox",
        getLanguageArrayString("mainGUI_11"))
    mainGUIStatusBar := mainGUI.Add("StatusBar", , getLanguageArrayString("mainGUI_13"))
    mainGUIStatusBar.SetIcon(iconFileLocation, 9) ; ICON_DLL_USED_HERE
    ; Adds an action when the main GUI is closed.
    mainGUI.OnEvent("Close", (*) => handleMainGUI_close())
    ; Makes it, that every checkbox triggers the save function to apply the changes when clicked.
    for (GUIControlObject in mainGUI) {
        if (!InStr(GUIControlObject.Type, "Checkbox")) {
            continue
        }
        ; Some checkboxes require more actions such as restarting the script.
        switch (GUIControlObject.Name) {
            case "LaunchWithGTACheckbox":
            {
                GUIControlObject.OnEvent("Click", (*) => handleMainGUI_checkbox_launchWithGTA())
            }
            case "CheckForUpdateAtLaunchCheckbox":
            {
                GUIControlObject.OnEvent("Click", (*) => handleMainGUI_checkbox_checkForAvailableUpdatesAtLaunch())
            }
            case "UpdateToBetaReleasesCheckbox":
            {
                GUIControlObject.OnEvent("Click", (*) => handleMainGUI_checkbox_updateToBetaReleases())
            }
            default:
            {
                GUIControlObject.OnEvent("Click", (*) => handleMainGUI_writeValuesToConfigFile())
            }
        }
    }
    ; Adds a tooltip to some GUI elements.
    launchWithGTACheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_1")
    launchMinimizedToTrayCheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_2")
    minimizeToTrayInsteadOfCloseCheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_9")
    showLaunchMessageCheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_3")
    checkForUpdateAtLaunchCheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_4")
    updateToBetaReleasesCheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_5")
    muteGameWhileLaunchCheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_6")
    setGameProcessPriorityHighCheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_7")
    showGTALaunchMessageCheckbox.ToolTip := getLanguageArrayString("mainGUIToolTip_8")
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

; Runs a few commands when the script is executed.
mainGUI_onInit() {
    global iconFileLocation
    createMainGUI()
    handleMainGUI_applyValuesFromConfigFile()
    if (!readConfigFile("LAUNCH_MINIMIZED")) {
        mainGUI.Show()
    }
    ; Adds a tray menu point to open the main GUI.
    A_TrayMenu.Insert("1&", "Open Main Window", (*) => mainGUI.Show())
    ; When clicking on the tray icon twice, this will make sure, that the main GUI is shown to the user.
    A_TrayMenu.Default := "Open Main Window"
    setAutostartWithGTAV(readConfigFile("LAUNCH_WITH_GTA"))
}

handleMainGUI_writeValuesToConfigFile() {
    try
    {
        editConfigFile("LAUNCH_WITH_GTA", launchWithGTACheckbox.Value)
        editConfigFile("LAUNCH_MINIMIZED", launchMinimizedToTrayCheckbox.Value)
        editConfigFile("MINIMIZE_INSTEAD_OF_CLOSE", minimizeToTrayInsteadOfCloseCheckbox.Value)
        editConfigFile("DISPLAY_LAUNCH_NOTIFICATION", showLaunchMessageCheckbox.Value)
        editConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH", checkForUpdateAtLaunchCheckbox.Value)
        editConfigFile("UPDATE_TO_BETA_VERSIONS", updateToBetaReleasesCheckbox.Value)
        editConfigFile("MUTE_GAME_WHILE_LAUNCH", muteGameWhileLaunchCheckbox.Value)
        editConfigFile("INCREASE_GAME_PRIORITY", setGameProcessPriorityHighCheckbox.Value)
        editConfigFile("DISPLAY_GTA_LAUNCH_NOTIFICATION", showGTALaunchMessageCheckbox.Value)
        setAutostartWithGTAV(readConfigFile("LAUNCH_WITH_GTA"))
        handleMainGUI_handleElementConflicts()
    }
    catch as error {
        displayErrorMessage(error)
    }
}

handleMainGUI_applyValuesFromConfigFile() {
    try
    {
        ; Those options are set to false, because they are impossible without using the compiled version.
        if (!A_IsCompiled) {
            launchWithGTACheckbox.Value := 0
            checkForUpdateAtLaunchCheckbox.Value := 0
            updateToBetaReleasesCheckbox.Value := 0
        }
        else {
            launchWithGTACheckbox.Value := readConfigFile("LAUNCH_WITH_GTA")
            checkForUpdateAtLaunchCheckbox.Value := readConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH")
            updateToBetaReleasesCheckbox.Value := readConfigFile("UPDATE_TO_BETA_VERSIONS")
        }
        launchMinimizedToTrayCheckbox.Value := readConfigFile("LAUNCH_MINIMIZED")
        minimizeToTrayInsteadOfCloseCheckbox.Value := readConfigFile("MINIMIZE_INSTEAD_OF_CLOSE")
        showLaunchMessageCheckbox.Value := readConfigFile("DISPLAY_LAUNCH_NOTIFICATION")
        muteGameWhileLaunchCheckbox.Value := readConfigFile("MUTE_GAME_WHILE_LAUNCH")
        setGameProcessPriorityHighCheckbox.Value := readConfigFile("INCREASE_GAME_PRIORITY")
        showGTALaunchMessageCheckbox.Value := readConfigFile("DISPLAY_GTA_LAUNCH_NOTIFICATION")
        handleMainGUI_handleElementConflicts()
    }
    catch as error {
        displayErrorMessage(error)
    }
}

; Enables or disables elements based on the GUI logic.
handleMainGUI_handleElementConflicts() {
    ; Disables the beta version option because the script does not check for updates at launch.
    if (!readConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH")) {
        updateToBetaReleasesCheckbox.Opt("+Disabled")
    }
    else {
        updateToBetaReleasesCheckbox.Opt("-Disabled")
    }
}

/*
GUI ELEMENT SUPPORT FUNCTIONS
-------------------------------------------------
*/

handleMainGUI_checkbox_checkForAvailableUpdatesAtLaunch() {
    if (!A_IsCompiled) {
        ; Tells the user that he cannot use this checkbox, because the script is not compiled.
        MsgBox(getLanguageArrayString("generalScriptMsgBox2_1"), getLanguageArrayString("generalScriptMsgBox2_2"),
        "O Iconi 262144 T3")
        checkForUpdateAtLaunchCheckbox.Value := 0
        handleMainGUI_writeValuesToConfigFile()
        return false
    }
    handleMainGUI_writeValuesToConfigFile()
    reloadScriptPrompt()
    ; The function above usually exits the script. This mean the code below won't be executed, unless the user cancels the reload.
    checkForUpdateAtLaunchCheckbox.Value := !checkForUpdateAtLaunchCheckbox.Value
    handleMainGUI_writeValuesToConfigFile()
}

handleMainGUI_checkbox_updateToBetaReleases() {
    if (!A_IsCompiled) {
        ; Tells the user that he cannot use this checkbox, because the script is not compiled.
        MsgBox(getLanguageArrayString("generalScriptMsgBox2_1"), getLanguageArrayString("generalScriptMsgBox2_2"),
        "O Iconi 262144 T3")
        updateToBetaReleasesCheckbox.Value := 0
        handleMainGUI_writeValuesToConfigFile()
        return false
    }
    handleMainGUI_writeValuesToConfigFile()
    reloadScriptPrompt()
    ; The function above usually exits the script. This mean the code below won't be executed, unless the user cancels the reload.
    updateToBetaReleasesCheckbox.Value := !updateToBetaReleasesCheckbox.Value
    handleMainGUI_writeValuesToConfigFile()
}

handleMainGUI_checkbox_launchWithGTA() {
    if (!A_IsCompiled) {
        ; Tells the user that he cannot use this checkbox, because the script is not compiled.
        MsgBox(getLanguageArrayString("generalScriptMsgBox2_1"), getLanguageArrayString("generalScriptMsgBox2_2"),
        "O Iconi 262144 T3")
        launchWithGTACheckbox.Value := 0
        handleMainGUI_writeValuesToConfigFile()
        return false
    }
    handleMainGUI_writeValuesToConfigFile()
}

handleMainGUI_menu_searchForUpdates() {
    if (!A_IsCompiled) {
        ; Tells the user that he cannot use this option, because the script is not compiled.
        MsgBox(getLanguageArrayString("generalScriptMsgBox2_1"), getLanguageArrayString("generalScriptMsgBox2_2"),
        "O Iconi 262144 T3")
        return false
    }
    checkForAvailableUpdates()
}

handleMainGUI_close() {
    if (!readConfigFile("MINIMIZE_INSTEAD_OF_CLOSE")) {
        exitScriptWithNotification()
    }
}
