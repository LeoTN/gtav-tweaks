#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

createMainGUI()
{
    Global
    fileSelectionMenuOpen := Menu()
    fileSelectionMenuOpen.Add(getLanguageArrayString("mainGUIFileSubMenu1_1") . "`t1", (*) => openConfigFile())
    fileSelectionMenuOpen.SetIcon(getLanguageArrayString("mainGUIFileSubMenu1_1") . "`t1", "shell32.dll", 70)
    fileSelectionMenuOpen.Add(getLanguageArrayString("mainGUIFileSubMenu1_2") . "`t2", (*) => openMacroConfigFile())
    fileSelectionMenuOpen.SetIcon(getLanguageArrayString("mainGUIFileSubMenu1_2") . "`t2", "shell32.dll", 174)
    ; The reason why the path is opened explicitly with explorer.exe is, that sometimes it will attempt to sort of guess the file
    ; extension and open other files. For example GTAV_Tweaks.exe instead of the folder GTAV_Tweaks.
    fileSelectionMenuOpen.Add(getLanguageArrayString("mainGUIFileSubMenu1_3") . "`t3", (*) => Run('explorer.exe "' . A_ScriptDir . '"'))
    fileSelectionMenuOpen.SetIcon(getLanguageArrayString("mainGUIFileSubMenu1_3") . "`t3", "shell32.dll", 276)
    fileSelectionMenuOpen.Add(getLanguageArrayString("mainGUIFileSubMenu1_4") . "`t4", (*) => Run('explorer.exe "' . A_ScriptDir . '\GTAV_Tweaks"'))
    fileSelectionMenuOpen.SetIcon(getLanguageArrayString("mainGUIFileSubMenu1_4") . "`t4", "shell32.dll", 279)

    fileSelectionMenuReset := Menu()
    fileSelectionMenuReset.Add(getLanguageArrayString("mainGUIFileSubMenu2_1") . "`tShift+1", (*) => createDefaultConfigFile(, true))
    fileSelectionMenuReset.SetIcon(getLanguageArrayString("mainGUIFileSubMenu2_1") . "`tShift+1", "shell32.dll", 70)

    fileMenu := Menu()
    fileMenu.Add("&" . getLanguageArrayString("mainGUIFileMenu_1") . "...", fileSelectionMenuOpen)
    fileMenu.SetIcon("&" . getLanguageArrayString("mainGUIFileMenu_1") . "...", "shell32.dll", 127)
    fileMenu.Add("&" . getLanguageArrayString("mainGUIFileMenu_2") . "...", fileSelectionMenuReset)
    fileMenu.SetIcon("&" . getLanguageArrayString("mainGUIFileMenu_2") . "...", "shell32.dll", 239)

    languageMenu := Menu()
    ; Adds all supported langues to the menu.
    ; Currently supported language amount: 5.
    static tmpKey1 := unset
    static tmpKey2 := unset
    static tmpKey3 := unset
    static tmpKey4 := unset
    static tmpKey5 := unset
    For key in languageCodeMap
    {
        If (!IsSet(tmpKey1))
        {
            tmpKey1 := key
            languageMenu.Add(tmpKey1, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey1) reloadScriptPrompt())
        }
        Else If (!IsSet(tmpKey2))
        {
            tmpKey2 := key
            languageMenu.Add(tmpKey2, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey2) reloadScriptPrompt())
        }
        Else If (!IsSet(tmpKey3))
        {
            tmpKey3 := key
            languageMenu.Add(tmpKey3, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey3) reloadScriptPrompt())
        }
        Else If (!IsSet(tmpKey4))
        {
            tmpKey4 := key
            languageMenu.Add(tmpKey4, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey4) reloadScriptPrompt())
        }
        Else If (!IsSet(tmpKey5))
        {
            tmpKey5 := key
            languageMenu.Add(tmpKey5, (*) => editConfigFile("PREFERRED_LANGUAGE", tmpKey5) reloadScriptPrompt())
        }
    }

    optionsMenu := Menu()
    optionsMenu.Add(getLanguageArrayString("mainGUIOptionsMenu_3"), languageMenu)
    optionsMenu.SetIcon(getLanguageArrayString("mainGUIOptionsMenu_3"), "shell32.dll", 231)
    optionsMenu.Add()
    optionsMenu.Add(getLanguageArrayString("mainGUIOptionsMenu_1"), (*) => terminateScriptPrompt())
    optionsMenu.SetIcon(getLanguageArrayString("mainGUIOptionsMenu_1"), "shell32.dll", 28)
    optionsMenu.Add(getLanguageArrayString("mainGUIOptionsMenu_2"), (*) => reloadScriptPrompt())
    optionsMenu.SetIcon(getLanguageArrayString("mainGUIOptionsMenu_2"), "shell32.dll", 207)

    helpMenu := Menu()
    If (versionFullName != "")
    {
        helpMenu.Add(getLanguageArrayString("mainGUIInfoMenu_1", versionFullName), (*) => handleMainGUI_helpSectionEasterEgg())
        helpMenu.SetIcon(getLanguageArrayString("mainGUIInfoMenu_1", versionFullName), "shell32.dll", 79)
    }
    helpMenu.Add(getLanguageArrayString("mainGUIInfoMenu_2"),
        (*) => Run("https://github.com/LeoTN/gtav-tweaks#readme"))
    helpMenu.SetIcon(getLanguageArrayString("mainGUIInfoMenu_2"), "shell32.dll", 26)
    helpMenu.Add(getLanguageArrayString("mainGUIInfoMenu_3"),
        (*) => Run("https://github.com/LeoTN/gtav-tweaks/issues/new/choose"))
    helpMenu.SetIcon(getLanguageArrayString("mainGUIInfoMenu_3"), "shell32.dll", 81)
    helpMenu.Add(getLanguageArrayString("mainGUIInfoMenu_4"), (*) => openReadMeFile())
    helpMenu.SetIcon(getLanguageArrayString("mainGUIInfoMenu_4"), "shell32.dll", 2)
    helpMenu.Add(getLanguageArrayString("mainGUIInfoMenu_5"), (*) => scriptTutorial())
    helpMenu.SetIcon(getLanguageArrayString("mainGUIInfoMenu_5"), "shell32.dll", 24)

    allMenus := MenuBar()
    allMenus.Add("&" . getLanguageArrayString("mainGUIMenu_1"), fileMenu)
    allMenus.SetIcon("&" . getLanguageArrayString("mainGUIMenu_1"), "shell32.dll", 4)
    allMenus.Add("&" . getLanguageArrayString("mainGUIMenu_2"), optionsMenu)
    allMenus.SetIcon("&" . getLanguageArrayString("mainGUIMenu_2"), "shell32.dll", 317)
    allMenus.Add("&" . getLanguageArrayString("mainGUIMenu_3"), (*) => customHotkeyOverviewGUI.Show())
    allMenus.SetIcon("&" . getLanguageArrayString("mainGUIMenu_3"), "shell32.dll", 177)
    allMenus.Add("&" . getLanguageArrayString("mainGUIMenu_4"), helpMenu)
    allMenus.SetIcon("&" . getLanguageArrayString("mainGUIMenu_4"), "shell32.dll", 24)

    mainGUI := Gui(, "GTAV Tweaks")
    mainGUI.MenuBar := allMenus
    ; When closing the main window, the changes are applied.
    mainGUI.OnEvent("ContextMenu", (*) => handleMainGUI_writeValuesToConfigFile())

    ; This part begins to fill the GUI with checkboxes and all that stuff.
    applyChangesText := mainGUI.Add("Text", "", getLanguageArrayString("mainGUI_1"))
    startupBehaviorGroupbox := mainGUI.Add("GroupBox", "yp+20 w320 R5.3", getLanguageArrayString("mainGUI_2"))
    launchWithWindowsCheckbox := mainGUI.Add("Checkbox", "xp+10 yp+20 vLaunchWithWindowsCheckbox", getLanguageArrayString("mainGUI_3"))
    launchMinimzedToTrayCheckbox := mainGUI.Add("Checkbox", "yp+20 vLaunchMinimzedToTrayCheckbox", getLanguageArrayString("mainGUI_4"))
    showLaunchMessageCheckbox := mainGUI.Add("Checkbox", "yp+20 vShowLaunchMessageCheckbox", getLanguageArrayString("mainGUI_5"))
    checkForUpdateAtLaunchCheckbox := mainGUI.Add("Checkbox", "yp+20 vCheckForUpdateAtLaunchCheckbox", getLanguageArrayString("mainGUI_6"))
    updateToBetaReleasesCheckbox := mainGUI.Add("Checkbox", "yp+20 vUpdateToBetaReleasesCheckbox", getLanguageArrayString("mainGUI_7"))

    gameOptionsGroupbox := mainGUI.Add("GroupBox", "xp-10 yp+30 w320 R3.3", getLanguageArrayString("mainGUI_8"))
    muteGameWhileLaunchCheckbox := mainGUI.Add("Checkbox", "xp+10 yp+20 vMuteGameWhileLaunchCheckbox", getLanguageArrayString("mainGUI_9"))
    setGameProcessPriorityHighCheckbox := mainGUI.Add("Checkbox", "yp+20 vSetGameProcessPriorityHighCheckbox", getLanguageArrayString("mainGUI_10"))
    showGTALaunchMessageCheckbox := mainGUI.Add("Checkbox", "yp+20 vShowGTALaunchMessageCheckbox", getLanguageArrayString("mainGUI_11"))
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

; Runs a few commands when the script is executed.
mainGUI_onInit()
{
    global iconFileLocation
    ; Changes the tray icon and freezes it.
    TraySetIcon(iconFileLocation, , true)
    createMainGUI()
    If (!readConfigFile("LAUNCH_MINIMIZED"))
    {
        mainGUI.Show()
    }
    handleMainGUI_applyValuesFromConfigFile()
    ; Adds a tray menu point to open the main GUI.
    A_TrayMenu.Insert("1&", "Open Main Window", (*) => mainGUI.Show())
    ; When clicking on the tray icon twice, this will make sure, that the main GUI is shown to the user.
    A_TrayMenu.Default := "Open Main Window"
    setAutostart(readConfigFile("LAUNCH_WITH_WINDOWS"))
}

handleMainGUI_writeValuesToConfigFile()
{
    Try
    {
        editConfigFile("LAUNCH_WITH_WINDOWS", launchWithWindowsCheckbox.Value)
        editConfigFile("LAUNCH_MINIMIZED", launchMinimzedToTrayCheckbox.Value)
        editConfigFile("DISPLAY_LAUNCH_NOTIFICATION", showLaunchMessageCheckbox.Value)
        editConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH", checkForUpdateAtLaunchCheckbox.Value)
        editConfigFile("UPDATE_TO_BETA_VERSIONS", updateToBetaReleasesCheckbox.Value)
        editConfigFile("MUTE_GAME_WHILE_LAUNCH", muteGameWhileLaunchCheckbox.Value)
        editConfigFile("INCREASE_GAME_PRIORITY", setGameProcessPriorityHighCheckbox.Value)
        editConfigFile("DISPLAY_GTA_LAUNCH_NOTIFICATION", showGTALaunchMessageCheckbox.Value)
        setAutostart(readConfigFile("LAUNCH_WITH_WINDOWS"))
        handleMainGUI_handleElementConflicts()
    }
    Catch As error
    {
        displayErrorMessage(error)
    }
}

handleMainGUI_applyValuesFromConfigFile()
{
    Try
    {
        launchWithWindowsCheckbox.Value := readConfigFile("LAUNCH_WITH_WINDOWS")
        launchMinimzedToTrayCheckbox.Value := readConfigFile("LAUNCH_MINIMIZED")
        showLaunchMessageCheckbox.Value := readConfigFile("DISPLAY_LAUNCH_NOTIFICATION")
        checkForUpdateAtLaunchCheckbox.Value := readConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH")
        updateToBetaReleasesCheckbox.Value := readConfigFile("UPDATE_TO_BETA_VERSIONS")
        muteGameWhileLaunchCheckbox.Value := readConfigFile("MUTE_GAME_WHILE_LAUNCH")
        setGameProcessPriorityHighCheckbox.Value := readConfigFile("INCREASE_GAME_PRIORITY")
        showGTALaunchMessageCheckbox.Value := readConfigFile("DISPLAY_GTA_LAUNCH_NOTIFICATION")
        handleMainGUI_handleElementConflicts()
    }
    Catch As error
    {
        displayErrorMessage(error)
    }
}

; Enables or disables elements based on the GUI logic.
handleMainGUI_handleElementConflicts()
{
    ; Disables the beta version option because the script does not check for updates at launch.
    If (!readConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH"))
    {
        updateToBetaReleasesCheckbox.Opt("+Disabled")
    }
    Else
    {
        updateToBetaReleasesCheckbox.Opt("-Disabled")
    }
}

handleMainGUI_helpSectionEasterEgg()
{
    static i := 0

    i++
    If (i >= 3)
    {
        i := 0
        MsgBox(getLanguageArrayString("mainGUIMsgBox1_1"), getLanguageArrayString("mainGUIMsgBox1_2"), "Iconi")
    }
}