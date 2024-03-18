#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

createCustomHotkeyOverviewGUI()
{
    Global
    customHotkeyOverviewGUI := Gui(, "GTAV Tweaks - Hotkey Overview")

    customHotkeyOverviewGUITotalHotkeyAmountText := customHotkeyOverviewGUI.Add("Text", "yp+10 w140", "Total Hotkeys: NUMBER") ; REMOVE

    customHotkeyOverviewGUIHotkeyFieldText := customHotkeyOverviewGUI.Add("Text", "yp+30", "Keyboard Shortcut")
    customHotkeyOverviewGUIHotkeyField := customHotkeyOverviewGUI.Add("Hotkey", "yp+20 w200 Disabled")
    customHotkeyOverviewGUIHotkeyDescriptionEditText := customHotkeyOverviewGUI.Add("Text", "xp+210 yp-30", "Description")
    customHotkeyOverviewGUIHotkeyDescriptionEdit := customHotkeyOverviewGUI.Add("Edit", "yp+30 w109 R5.2 ReadOnly Disabled")

    customHotkeyArray := ["hotkey1", "hotkey2", "hotkey3"] ; REMOVE
    customHotkeyOverviewGUIHotkeyDropDownListText := customHotkeyOverviewGUI.Add("Text", "xp-210 yp+35", "Select a hotkey below.")
    customHotkeyOverviewGUIHotkeyDropDownList := customHotkeyOverviewGUI.Add("DropDownList", "yp+20 w200", customHotkeyArray) ; REMOVE

    customHotkeyOverviewGUIToggleHotkeyButton := customHotkeyOverviewGUI.Add("Button", "xp-1 yp+40 w100 Default", "Toggle Status")
    customHotkeyOverviewGUIActivateAllHotkeysButton := customHotkeyOverviewGUI.Add("Button", "xp+110 w100", "Enable All")
    customHotkeyOverviewGUIDeactivateAllHotkeysButton := customHotkeyOverviewGUI.Add("Button", "xp+110 w100", "Disable All")
    customHotkeyOverviewGUICreateHotkeyButton := customHotkeyOverviewGUI.Add("Button", "xp-220 yp+30 w100", "Create Hotkey")
    customHotkeyOverviewGUIEditHotkeyButton := customHotkeyOverviewGUI.Add("Button", "xp+110 w100", "Edit")
    customHotkeyOverviewGUIDeleteHotkeyButton := customHotkeyOverviewGUI.Add("Button", "xp+110 w100", "Delete")
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

customHotkeyOverviewGUI_onInit()
{
    createCustomHotkeyOverviewGUI()
}