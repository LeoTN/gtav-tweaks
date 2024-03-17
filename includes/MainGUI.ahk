#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

createMainGUI()
{
    Global
    fileSelectionMenuOpen := Menu()
    fileSelectionMenuOpen.Add("Config-File`t1", (*) => openConfigFile())
    fileSelectionMenuOpen.SetIcon("Config-File`t1", "shell32.dll", 70)

    fileSelectionMenuReset := Menu()
    fileSelectionMenuReset.Add("Config-File`tShift+1", (*) => createDefaultConfigFile(, true))
    fileSelectionMenuReset.SetIcon("Config-File`tShift+1", "shell32.dll", 70)

    fileMenu := Menu()
    fileMenu.Add("&Open...", fileSelectionMenuOpen)
    fileMenu.SetIcon("&Open...", "shell32.dll", 127)
    fileMenu.Add("&Reset...", fileSelectionMenuReset)
    fileMenu.SetIcon("&Reset...", "shell32.dll", 239)

    optionsMenu := Menu()
    optionsMenu.Add("Terminate Script", (*) => terminateScriptPrompt())
    optionsMenu.SetIcon("Terminate Script", "shell32.dll", 28)
    optionsMenu.Add("Reload Script", (*) => reloadScriptPrompt())
    optionsMenu.SetIcon("Reload Script", "shell32.dll", 207)

    helpMenu := Menu()
    If (versionFullName != "")
    {
        helpMenu.Add("Version - " . versionFullName, (*) => handleMainGUI_helpSectionEasterEgg())
        helpMenu.SetIcon("Version - " . versionFullName, "shell32.dll", 79)
    }
    helpMenu.Add("This repository (gtav-tweaks)",
        (*) => Run("https://github.com/LeoTN/gtav-tweaks#readme"))
    helpMenu.SetIcon("This repository (gtav-tweaks)", "shell32.dll", 26)
    helpMenu.Add("README File", (*) => openReadMeFile())
    helpMenu.SetIcon("README File", "shell32.dll", 2)
    helpMenu.Add("Built in Tutorial", (*) => scriptTutorial())
    helpMenu.SetIcon("Built in Tutorial", "shell32.dll", 24)

    allMenus := MenuBar()
    allMenus.Add("&File", fileMenu)
    allMenus.SetIcon("&File", "shell32.dll", 4)
    allMenus.Add("&Options", optionsMenu)
    allMenus.SetIcon("&Options", "shell32.dll", 317)
    allMenus.Add("&Hotkeys", (*) => customHotkeyOverviewGUI.Show())
    allMenus.SetIcon("&Hotkeys", "shell32.dll", 177)
    allMenus.Add("&Info", helpMenu)
    allMenus.SetIcon("&Info", "shell32.dll", 24)

    mainGUI := Gui(, "GTAV Tweaks")
    mainGUI.MenuBar := allMenus
    ; When closing the main window, the changes are applied.
    mainGUI.OnEvent("ContextMenu", (*) => handleMainGUI_writeValuesToConfigFile())

    ; This part begins to fill the GUI with checkboxes and all that stuff.
    applyChangesText := mainGUI.Add("Text", "", "Changes will be applied once you right-click this window.")
    startupBehaviorGroupbox := mainGUI.Add("GroupBox", "yp+20 w265 R5.3", "Startup Behavior")
    launchWithWindowsCheckbox := mainGUI.Add("Checkbox", "xp+10 yp+20 vLaunchWithWindowsCheckbox", "Start with windows")
    launchMinimzedToTrayCheckbox := mainGUI.Add("Checkbox", "yp+20 vLaunchMinimzedToTrayCheckbox", "Launch minimized to tray")
    showLaunchMessageCheckbox := mainGUI.Add("Checkbox", "yp+20 vShowLaunchMessageCheckbox", "Display a launch message")
    checkForUpdateAtLaunchCheckbox := mainGUI.Add("Checkbox", "yp+20 vCheckForUpdateAtLaunchCheckbox", "Check for available updates")
    updateToBetaReleasesCheckbox := mainGUI.Add("Checkbox", "yp+20 vUpdateToBetaReleasesCheckbox", "I want to receive beta versions")

    gameOptionsGroupbox := mainGUI.Add("GroupBox", "xp-10 yp+30 w265 R3.3", "Game Options")
    muteGameWhileLaunchCheckbox := mainGUI.Add("Checkbox", "xp+10 yp+20 vMuteGameWhileLaunchCheckbox", "Mute GTA during launch")
    setGameProcessPriorityHighCheckbox := mainGUI.Add("Checkbox", "yp+20 vSetGameProcessPriorityHighCheckbox", "Increase GTA process priority [WIP]")
    showGTALaunchMessageCheckbox := mainGUI.Add("Checkbox", "yp+20 vShowGTALaunchMessageCheckbox", "Display GTA launch message")
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
        MsgBox("Looks like some found an easter egg!`n`nIt seems you like testing, just like my friend,"
            . " who helps me a lot by testing this script for me.`n`nThank you [REDACTED]!", "What's that?", "Iconi")
    }
}