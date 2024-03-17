#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

createNewCustomHotkeyGUI()
{
    Global
    newCustomHotkeyGUI := Gui(, "GTAV Tweaks - Create New Hotkey")

    newCustomHotkeyGUIHotkeyNameText := newCustomHotkeyGUI.Add("Text", "yp+10", "Hotkey Name")
    newCustomHotkeyGUIHotkeyNameEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 w200")

    newCustomHotkeyGUIHotkeyFieldText := newCustomHotkeyGUI.Add("Text", "yp+30", "Keyboard Shortcut")
    newCustomHotkeyGUIHotkeyField := newCustomHotkeyGUI.Add("Hotkey", "yp+20 w200")

    newCustomHotkeyGUIHotkeyDescriptionText := newCustomHotkeyGUI.Add("Text", "xp+210 yp-70", "Hotkey Description")
    newCustomHotkeyGUIHotkeyDescriptionEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 R4.85 w108")

    newCustomHotkeyGUIMacroFileLocationText := newCustomHotkeyGUI.Add("Text", "xp-210 yp+82", "Macro File Location")
    newCustomHotkeyGUIMacroFileLocationEdit := newCustomHotkeyGUI.Add("Edit", "yp+20 w285")
    newCustomHotkeyGUIMacroFileLocationButton := newCustomHotkeyGUI.Add("Button", "xp+299 yp-1 w20", "...")
    newCustomHotkeyGUIWhatIsAMacroFileButton := newCustomHotkeyGUI.Add("Button", "xp-300 yp+30 w140", "How do I get macro files?")

    newCustomHotkeyGUISaveHotkeyButton := newCustomHotkeyGUI.Add("Button", "yp+41 w100", "Save Hotkey")
    newCustomHotkeyGUICancelHotkeyButton := newCustomHotkeyGUI.Add("Button", "xp+110 w100", "Cancel")
    newCustomHotkeyGUIRecordMacroButton := newCustomHotkeyGUI.Add("Button", "xp+110 w100", "Record Macro")
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

newCustomHotkeyGUI_onInit()
{
    createNewCustomHotkeyGUI()
}