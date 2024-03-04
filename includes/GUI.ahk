#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

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

    activeHotkeyMenu := Menu()
    activeHotkeyMenu.Add("Create Online Sololobby → " . expandHotkey(readConfigFile("SOLO_LOBBY_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Create Online Sololobby → " .
            expandHotkey(readConfigFile("SOLO_LOBBY_HK")), 1), "+Radio")

    activeHotkeyMenu.Add("Toggle AFK Cayo Perico Flight → " . expandHotkey(readConfigFile("AFK_PERCIO_FLIGHT_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Toggle AFK Cayo Perico Flight → " .
            expandHotkey(readConfigFile("AFK_PERCIO_FLIGHT_HK")), 2), "+Radio")

    activeHotkeyMenu.Add("Deposit less than 100K Money → " . expandHotkey(readConfigFile("DEPOSIT_MONEY_LESS_100K_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Deposit less than 100K Money → " .
            expandHotkey(readConfigFile("DEPOSIT_MONEY_LESS_100K_HK")), 3), "+Radio")

    activeHotkeyMenu.Add("Deposit more than 100K Money → " . expandHotkey(readConfigFile("DEPOSIT_MONEY_MORE_100K_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Deposit more than 100K Money → " .
            expandHotkey(readConfigFile("DEPOSIT_MONEY_MORE_100K_HK")), 4), "+Radio")

    activeHotkeyMenu.Add()
    activeHotkeyMenu.Add("Enable All", (*) => handleMainGUI_MenuCheckAll("activeHotkeyMenu"))
    activeHotkeyMenu.SetIcon("Enable All", "shell32.dll", 297)
    activeHotkeyMenu.Add("Disable All", (*) => handleMainGUI_MenuUncheckAll("activeHotkeyMenu"))
    activeHotkeyMenu.SetIcon("Disable All", "shell32.dll", 132)

    optionsMenu := Menu()
    optionsMenu.Add("Terminate Script", (*) => terminateScriptPrompt())
    optionsMenu.SetIcon("Terminate Script", "shell32.dll", 28)
    optionsMenu.Add("Reload Script", (*) => reloadScriptPrompt())
    optionsMenu.SetIcon("Reload Script", "shell32.dll", 207)

    helpMenu := Menu()
    If (version != "")
    {
        helpMenu.Add("Version - " . version, (*) => handleMainGUI_helpSectionEasterEgg())
    }
    helpMenu.Add("This repository (gtav-tweaks)",
        (*) => Run("https://github.com/LeoTN/gtav-tweaks#readme"))
    helpMenu.Add("Built in Tutorial", (*) => scriptTutorial())
    helpMenu.SetIcon("Built in Tutorial", "shell32.dll", 24)

    allMenus := MenuBar()
    allMenus.Add("&File", fileMenu)
    allMenus.SetIcon("&File", "shell32.dll", 4)
    allMenus.Add("&Options", optionsMenu)
    allMenus.SetIcon("&Options", "shell32.dll", 317)
    allMenus.Add("&Active Hotkeys...", activeHotkeyMenu)
    allMenus.SetIcon("&Active Hotkeys...", "shell32.dll", 177)
    allMenus.Add("&Info", helpMenu)
    allMenus.SetIcon("&Info", "shell32.dll", 24)

    mainGUI := Gui(, "Tweaks - Control Panel")
    mainGUI.MenuBar := allMenus
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

; Runs a few commands when the script is executed.
mainGUI_onInit()
{
    createMainGUI()
    mainGUI.Show() ; REMOVE
    handleMainGUI_ApplyCheckmarksFromConfigFile("activeHotkeyMenu")
}

/*
Necessary in place for the normal way of toggeling the checkmark.
This function also flips the checkMarkArrays values to keep track of the checkmarks.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
@param pMenuItemName [String] Should be a valid menu item name from the menu mentioned above.
@param pMenuItemPosition [int] Should be a valid menu item position. See AHK help for more info about this topic.
*/
handleMainGUI_ToggleCheck(pMenuName, pMenuItemName, pMenuItemPosition)
{
    ; Executes the command so that the checkmark becomes visible for the user.
    %pMenuName%.ToggleCheck(pMenuItemName)
    ; Registers the change in the matching array.
    handleMainGUI_MenuCheckHandler(pMenuName, pMenuItemPosition, "toggle")
}

/*
Checks all menu options from the (most likely) hotkey menu.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
*/
handleMainGUI_MenuCheckAll(pMenuName)
{
    menuItemCount := DllCall("GetMenuItemCount", "ptr", %pMenuName%.Handle)

    Loop (MenuItemCount - 3)
    {
        %pMenuName%.Check(A_Index . "&")
        ; Protects the code from the invalid index error caused by the check array further on.
        Try
        {
            handleMainGUI_MenuCheckHandler(pMenuName, A_Index, true)
        }
    }
}

/*
Unchecks all menu options from the (most likely) hotkey menu.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
*/
handleMainGUI_MenuUncheckAll(pMenuName)
{
    menuItemCount := DllCall("GetMenuItemCount", "ptr", %pMenuName%.Handle)

    Loop (MenuItemCount - 3)
    {
        %pMenuName%.Uncheck(A_Index . "&")
        ; Protects the code from the invalid index error caused by the check array further on.
        Try
        {
            handleMainGUI_MenuCheckHandler(pMenuName, A_Index, false)
        }
    }
}

/*
This function stores all menu items check states. In other words if there is a checkmark next to an option.
Leave only pBooleanState ommited to receive the current value of a submenu item or every parameter to receive the complete array.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
@param pSubMenuPosition [int] Should be the position of a sub menu element from the main menu mentioned above.
@param pBooleanState [boolean] / [String] Defines the state of the checkmarks to set. Pass "toggle" to invert the checkmark's
current state.
*/
handleMainGUI_MenuCheckHandler(pMenuName := unset, pSubMenuPosition := unset, pBooleanState := unset)
{
    menuCheckArray_activeHotKeyMenu := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))

    ; Returns the menu check array if those parameters are omitted.
    If (!IsSet(pMenuName) || !isSet(pSubMenuPosition))
    {
        Return menuCheckArray_activeHotKeyMenu
    }
    Try
    {
        If (pMenuName = "activeHotkeyMenu")
        {
            If (pBooleanState = "toggle")
            {
                ; Toggles the boolean value at a specific position.
                menuCheckArray_activeHotKeyMenu[pSubMenuPosition] := !menuCheckArray_activeHotKeyMenu[pSubMenuPosition]
                editConfigFile("HOTKEY_STATE_ARRAY", menuCheckArray_activeHotKeyMenu)
            }
            ; Only if there is a state given to apply to a menu.
            Else If (pBooleanState || !pBooleanState)
            {
                menuCheckArray_activeHotKeyMenu[pSubMenuPosition] := pBooleanState
                editConfigFile("HOTKEY_STATE_ARRAY", menuCheckArray_activeHotKeyMenu)
            }
            Else
            {
                Return menuCheckArray_activeHotKeyMenu[pSubMenuPosition]
            }
            toggleHotkey(menuCheckArray_activeHotKeyMenu)
        }
    }
    Catch As error
    {
        displayErrorMessage(error)
    }
}

/*
Applies the checkmarks stored in the config file so that they become visible to the user in the GUI.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
*/
handleMainGUI_ApplyCheckmarksFromConfigFile(pMenuName)
{
    stateArray := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))

    If (pMenuName = "activeHotkeyMenu")
    {
        Loop (stateArray.Length)
        {
            If (stateArray.Get(A_Index))
            {
                activeHotkeyMenu.Check(A_Index . "&")
            }
            Else If (!stateArray.Get(A_Index))
            {
                activeHotkeyMenu.Uncheck(A_Index . "&")
            }
            Else
            {
                Throw ("No valid state in state array.")
            }
        }
        stateArray := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))
        toggleHotkey(stateArray)
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