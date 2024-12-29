#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

functions_onInit() {
    /*
    This causes the script to react upon the user moving his mouse and show
    a tooltip if possible for the GUI element under the cursor.
    */
    OnMessage(0x0200, handleAllGUI_toolTips)
}

; This function determines the current control under the mouse cursor and if it has a tooltip, displays it.
handleAllGUI_toolTips(not_used_1, not_used_2, not_used_3, pWindowHWND) {
    static oldHWND := 0
    if (pWindowHWND != oldHWND) {
        ; Closes all existing tooltips.
        toolTipText := ""
        ToolTip()
        currentControlElement := GuiCtrlFromHwnd(pWindowHWND)
        if (currentControlElement) {
            if (!currentControlElement.HasProp("ToolTip")) {
                ; There is no tooltip for this control element.
                return
            }
            toolTipText := currentControlElement.ToolTip
            ; Displays the tooltip after the user hovers for 1.5 seconds over a control element.
            SetTimer () => displayToolTip(toolTipText, currentControlElement.Hwnd), -1500
        }
        oldHWND := pWindowHWND
    }
    /*
    This function makes sure that the tooltip is only displayed when the user hovers over the same control element for
    more than 1.5 seconds. If the control element under the cursor changes by any means, the tooltip won't be displayed.
    */
    displayToolTip(pToolTipText, pCurrentControlElementHWND) {
        MouseGetPos(, , , &currentControlElementUnderCursorHWND, 2)
        if (pCurrentControlElementHWND == currentControlElementUnderCursorHWND) {
            ToolTip(pToolTipText)
        }
    }
}

/*
Changes application audio settings, as if you would change them in the audio settings.
@param pApplicationName [String] Should be the name of the application or rather it's process, for example Firefox.exe.
@param pAction [String] Can be /mute or /unmute.
*/
manipulateApplicationAudio(pApplicationName, pAction) {
    Run(audioHookFileLocation . ' ' . pAction . ' ' . pApplicationName . ' /waitForItem 120', , "Hide")
}

muteGTAWhileInLoadingScreen() {
    manipulateApplicationAudio("GTA5.exe", "/mute")
    Sleep(10000)
    waitForUserInputInGTA()
    manipulateApplicationAudio("GTA5.exe", "/unmute")
}

waitForGTAToExist() {
    WinWait("ahk_exe GTA5.exe")
    if (readConfigFile("DISPLAY_GTA_LAUNCH_NOTIFICATION")) {
        TrayTip(getLanguageArrayString("generalScriptTrayTip1_1"), getLanguageArrayString("generalScriptTrayTip1_2"),
        "Iconi Mute")
        SetTimer () => TrayTip(), -1500
    }
}

; Waits for the user to press w while the window is active, to continue the script execution and unmute the game.
waitForUserInputInGTA() {
    ; This prevents the script from loading infinitely.
    if (WinWaitActive("ahk_exe GTA5.exe", , 600) == 0) {
        Reload()
    }
    while (WinActive("ahk_exe GTA5.exe")) {
        if (KeyWait("w", "D T1") == 1) {
            return
        }
    }
    return waitForUserInputInGTA()
}

checkForExistingGTA() {
    ; Enables the hotkeys if GTA is the active window.
    if (WinActive("ahk_exe GTA5.exe")) {
        Suspend(false)
    }
    ; Disables the hotkeys if GTA is not the active window.
    else {
        Suspend(true)
    }
}

/*
Forces the script to update to the latest version, depending on the update settings.
@returns [boolean] True or false, depending on the function's success.
*/
forceUpdate() {
    global versionFullName

    if (!A_IsCompiled) {
        MsgBox(getLanguageArrayString("generalScriptMsgBox2_1"), getLanguageArrayString("generalScriptMsgBox2_2"),
        "O Iconi 262144 T3")
        return false
    }
    result := MsgBox(getLanguageArrayString("mainGUIMsgBox2_1"),
    getLanguageArrayString("mainGUIMsgBox2_2"), "OC Icon! 262144")
    if (result != "OK") {
        return false
    }
    if (!startUpdate(true)) {
        return false
    }
    return true
}

/*
Checks all GitHub Repository tags to find new versions.
@returns [boolean] Returns true, when an update is available. False otherwise.
*/
checkForAvailableUpdates() {
    global currentVersionFileLocation
    global psUpdateScriptLocation

    ; Does not check for updates, if there is no Internet connection or the script isn't compiled.
    if (!checkInternetConnection() || !A_IsCompiled) {
        return false
    }
    SplitPath(psUpdateScriptLocation, &outFileName)
    psUpdateScriptLocationTemp := A_Temp . "\" . outFileName
    updateWorkingDir := A_Temp . "\GTAV_Tweaks_AUTO_UPDATE"

    ; Copies the script to the temp directory. This ensure that there are no file errors while the script is moving or copying files,
    ; because it cannot copy itself, while it is running.
    FileCopy(psUpdateScriptLocation, psUpdateScriptLocationTemp, true)
    parameterString := '-pGitHubRepositoryLink "https://github.com/LeoTN/gtav-tweaks" -pCurrentVersionFileLocation "' .
        currentVersionFileLocation
        . '" -pCurrentExecutableLocation "' . A_ScriptFullPath . '" -pOutputDirectory "' . updateWorkingDir . '"'

    if (readConfigFile("UPDATE_TO_BETA_VERSIONS")) {
        parameterString .= " -pSwitchConsiderBetaReleases"
    }
    ; Calls the PowerShell script to check for available updates.
    exitCode := RunWait('powershell.exe -executionPolicy bypass -file "' . psUpdateScriptLocationTemp
        . '" ' . parameterString . ' -pSwitchDoNotStartUpdate', , "Hide")
    switch (exitCode) {
        ; Available update, but pSwitchDoNotStartUpdate was set to true.
        case 101:
        {
            startUpdate()
            return true
        }
    }
    ; Maybe more cases in the future.
}

/*
Calls the PowerShell script to start updating this software.
@param pBooleanForceUpdate [boolean] If set to true, will not show a prompt and update instantly.
@returns [boolean] True or false, depending on the function's success.
*/
startUpdate(pBooleanForceUpdate := false) {
    global currentVersionFileLocation
    global psUpdateScriptLocation

    ; Does not check for updates, if there is no Internet connection or the script isn't compiled.
    if (!checkInternetConnection() || !A_IsCompiled) {
        return false
    }
    SplitPath(psUpdateScriptLocation, &outFileName)
    psUpdateScriptLocationTemp := A_Temp . "\" . outFileName
    updateWorkingDir := A_Temp . "\GTAV_Tweaks_AUTO_UPDATE"

    ; Copies the script to the temp directory. This ensure that there are no file errors while the script is moving or copying files,
    ; because it cannot copy itself, while it is running.
    FileCopy(psUpdateScriptLocation, psUpdateScriptLocationTemp, true)
    parameterString := '-pGitHubRepositoryLink "https://github.com/LeoTN/gtav-tweaks" -pCurrentVersionFileLocation "' .
        currentVersionFileLocation
        . '" -pCurrentExecutableLocation "' . A_ScriptFullPath . '" -pOutputDirectory "' . updateWorkingDir . '"'
    ; Depending on the parameters and settings.
    if (readConfigFile("UPDATE_TO_BETA_VERSIONS")) {
        parameterString .= " -pSwitchConsiderBetaReleases"
    }
    ; Extracts the available update from the current version file.
    currentVersionFileMap := readFromCSVFile(currentVersionFileLocation)
    updateVersion := currentVersionFileMap.Get("AVAILABLE_UPDATE")
    if (updateVersion == "no_available_update" && !pBooleanForceUpdate) {
        return false
    }
    ; We need to disable the automatic start with GTA V here because it can cause problems while the script is updating.
    ; We should not need a sleep delay or wait for the task here because the PowerShell script works fast.
    setAutostartWithGTAV(false)
    if (pBooleanForceUpdate) {
        ; Calls the PowerShell script to install the update.
        Run('powershell.exe -executionPolicy bypass -file "' . psUpdateScriptLocationTemp
            . '" ' . parameterString . ' -pSwitchForceUpdate')
        ExitApp()
        ExitApp()
    }
    result := MsgBox(getLanguageArrayString("functionsMsgBox1_1", versionFullName, updateVersion),
    getLanguageArrayString("functionsMsgBox1_2"), "YN Iconi T30 262144")
    if (result != "Yes") {
        return false
    }
    ; Calls the PowerShell script to install the update.
    Run('powershell.exe -executionPolicy bypass -file "' . psUpdateScriptLocationTemp
        . '" ' . parameterString)
    ExitApp()
    ExitApp()
}

/*
Tries to ping google.com to determine the computer's Internet connection status.
@returns [boolean] True, if the computer is connected to the Internet. False otherwise.
*/
checkInternetConnection() {
    ; Checks if the user has an established Internet connection.
    try
    {
        httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        httpRequest.Open("GET", "http://www.google.com", false)
        httpRequest.Send()

        if (httpRequest.Status == 200) {
            return true
        }
    }

    return false
}

/*
Opens the config file.
@returns [boolean] Depeding on the function's success.
*/
openConfigFile() {
    global configFileLocation

    try
    {
        if (FileExist(configFileLocation)) {
            Run(configFileLocation)
            return true
        }
        else {
            createDefaultConfigFile()
            return true
        }
    }
    catch as error {
        displayErrorMessage(error, "This error is rare.", true)
        ; Technically unreachable :D
        return false
    }
}

/*
Opens the macro config file.
@returns [boolean] Depeding on the function's success.
*/
openMacroConfigFile() {
    global macroConfigFileLocation

    try
    {
        if (FileExist(macroConfigFileLocation)) {
            Run(macroConfigFileLocation)
            return true
        }
        else {
            IniWrite("Always back up your files!", macroConfigFileLocation, "CustomHotkeysBelow", "Advice")
            return openMacroConfigFile()
        }
    }
    catch as error {
        displayErrorMessage(error)
        return false
    }
}

/*
Opens the README file.
@returns [boolean] Depeding on the function's success.
*/
openReadMeFile() {
    global readmeFileLocation

    try
    {
        if (FileExist(readmeFileLocation)) {
            Run(readmeFileLocation)
            return true
        }
        else {
            MsgBox(getLanguageArrayString("functionsMsgBox2_1"), getLanguageArrayString("functionsMsgBox2_2"),
            "Icon! T5")
            return false
        }
    }
    catch as error {
        displayErrorMessage(error, "This error is rare.")
        return false
    }
}

/*
Enables / disables the abillity of the script to start simultaniously with GTA V.
@param pBooleanEnableAutostart [boolean] If set to true, will create a task that checks for a running GTA V instance.
*/
setAutostartWithGTAV(pBooleanEnableAutostart) {
    global psManageAutoStartTaskFileLocation
    global silentAutoStartScriptLauncherExecutableLocation

    ; Creating an autostart for the .AHK file doesn't make sense in this case.
    if (!A_IsCompiled) {
        return
    }
    parameterString_1 := 'powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "' .
        psManageAutoStartTaskFileLocation . '"'
    parameterString_2 := parameterString_1 . ' -pLaunchWithGTAScriptLauncherLocation "' .
        silentAutoStartScriptLauncherExecutableLocation . '"'
    parameterString_3 := parameterString_2 . ' -pGTAVTweaksExecutableLocation "' . A_ScriptFullPath . '"'
    ; Disables the task.
    if (!pBooleanEnableAutostart) {
        parameterString_3 .= " -pSwitchDeleteTask"
    }
    Run(parameterString_3, , "Hide")
}

/*
Writes values to a comma seperated file (CSV).
@param pFileLocation [String] Should be the path to a .CSV file. The function will create the file if necessary.
@param pContent [Map] Should be a map object.
@param pBooleanForce [boolean] If set to true, will overwrite already existing files.
@returns [boolean] True or false, depending on the success.
*/
writeToCSVFile(pFileLocation, pContent, pBooleanForce := false) {
    ; Checks if the file exists.
    if (FileExist(pFileLocation) && !pBooleanForce) {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] The file [" . pFileLocation . "] does already exist.`n`n"
            "To overwrite it, set pBooleanForce to 'true'.", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
        return false
    }

    try
    {
        fileObject := FileOpen(pFileLocation, "w")
        ; Writes the map object to the file.
        for (key, value in pContent) {
            fileObject.WriteLine('"' . key . '","' . value . '"')
        }
        fileObject.Close()
        return true
    }
    catch as error {
        displayErrorMessage(error)
        return false
    }
}

/*
Reads values from a comma seperated file (CSV).
@param pFileLocation [String] Should be the path to a .CSV file.
@returns [Map] A map object containing all key and value pairs from the file.
*/
readFromCSVFile(pFileLocation) {
    ; Checks, if the file is available.
    if (!FileExist(pFileLocation)) {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] The file [" . pFileLocation . "] does not exist."
            , "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
        return
    }

    try
    {
        CSVMap := Map()
        CSVArray := []
        loop read, pFileLocation {
            loop parse, A_LoopReadLine, "CSV" {
                ; Those two entries are created by the PowerShell script and we don't want them in our map.
                if (A_LoopField != "Key" && A_LoopField != "Value") {
                    CSVArray.Push(A_LoopField)
                }
            }
        }
        ; Writes the key and value data to the actual map.
        i := 0
        loop (CSVArray.Length) {
            if (CSVArray.Has(A_Index + 1 + i)) {
                CSVMap.Set(CSVArray.Get(A_Index + i), CSVArray.Get(A_Index + 1 + i))
                ; This skips the loop to the next key and value pair.
                i++
            }
        }
        return CSVMap
    }
    catch as error {
        displayErrorMessage(error)
        return false
    }
}

reloadScriptPrompt() {
    ; Number in seconds.
    i := 4

    reloadScriptGUI := Gui(, getLanguageArrayString("reloadAndTerminateGUI_1"))
    textField := reloadScriptGUI.Add("Text", "r6 w260 x20 y40", getLanguageArrayString("reloadAndTerminateGUI_2", i))
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := reloadScriptGUI.Add("Progress", "w280 h20 x10 y120", 0)
    buttonOkay := reloadScriptGUI.Add("Button", "Default w80 x60 y190", getLanguageArrayString(
        "reloadAndTerminateGUI_7"))
    buttonCancel := reloadScriptGUI.Add("Button", "w80 x160 y190", getLanguageArrayString("reloadAndTerminateGUI_8"))
    reloadScriptGUI.Show("AutoSize")

    buttonOkay.OnEvent("Click", (*) => Reload())
    buttonCancel.OnEvent("Click", (*) => reloadScriptGUI.Destroy())

    ; The try statement is needed to protect the code from crashing because
    ; of the destroyed GUI when the user presses cancel.
    try
    {
        while (i >= 0) {
            ; Makes the progress bar feel smoother.
            loop (20) {
                progressBar.Value += 1.25
                Sleep(50)
            }
            textField.Text := getLanguageArrayString("reloadAndTerminateGUI_2", i)
            i--
        }
        textField.Text := "The script has been reloaded."
        Sleep(100)
        Reload()
        ExitApp()
        ExitApp()
    }
}

terminateScriptPrompt() {
    ; Number in seconds.
    i := 4

    terminateScriptGUI := Gui(, getLanguageArrayString("reloadAndTerminateGUI_4"))
    textField := terminateScriptGUI.Add("Text", "r6 w260 x20 y40", getLanguageArrayString("reloadAndTerminateGUI_5", i))
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := terminateScriptGUI.Add("Progress", "w280 h20 x10 y120 cRed backgroundBlack", 0)
    buttonOkay := terminateScriptGUI.Add("Button", "Default w80 x60 y190", getLanguageArrayString(
        "reloadAndTerminateGUI_7"))
    buttonCancel := terminateScriptGUI.Add("Button", "w80 x160 y190", getLanguageArrayString("reloadAndTerminateGUI_8"))
    terminateScriptGUI.Show("AutoSize")

    buttonOkay.OnEvent("Click", (*) => exitScriptWithNotification())
    buttonCancel.OnEvent("Click", (*) => terminateScriptGUI.Destroy())

    ; The try statement is needed to protect the code from crashing because
    ; of the destroyed GUI when the user presses cancel.
    try
    {
        while (i >= 0) {
            ; Makes the progress bar feel smoother.
            loop (20) {
                progressBar.Value += 1.25
                Sleep(50)
            }
            textField.Text := getLanguageArrayString("reloadAndTerminateGUI_5", i)
            i--
        }
        textField.Text := "The script has been terminated."
        Sleep(100)
        exitScriptWithNotification()
    }
}

/*
Terminates the script and shows a tray tip message to inform the user.
@param pBooleanUseFallbackMessage [boolean] If set to true, will use the hardcoded English version
of the termination message. This can be useful if the language modules have not been loaded yet.
*/
exitScriptWithNotification(pBooleanUseFallbackMessage := false) {
    if (pBooleanUseFallbackMessage) {
        TrayTip("GTAV Tweaks terminated.", "GTAV Tweaks - Status", "Iconi Mute")
    }
    else {
        TrayTip(getLanguageArrayString("generalScriptTrayTip3_1"), getLanguageArrayString("generalScriptTrayTip3_2"),
        "Iconi Mute")
    }
    ; Using ExitApp() twice ensures that the script will be terminated entirely.
    ExitApp()
    ExitApp()
}

/*
Outputs a little GUI containing information about the error. Allows to be copied to the clipboard.
@param pErrorObject [Error Object] Usually created when catching an error via Try / Catch.
@param pAdditionalErrorMessage [String] An optional error message to show.
@param pBooleanTerminatingError [boolean] If set to true, will force the script to terminate once the message disappears.
@param pMessageTimeoutMilliseconds [double] Optional message timeout. Closes the message after a delay of time.
*/
displayErrorMessage(pErrorObject := unset, pAdditionalErrorMessage := unset, pBooleanTerminatingError := false,
    pMessageTimeoutMilliseconds := unset) {
    if (IsSet(pErrorObject)) {
        errorMessageBlock := "*****ERROR MESSAGE*****`n" . pErrorObject.Message . "`n`n*****ERROR TRIGGER*****`n" .
            pErrorObject.What
        if (pErrorObject.Extra != "") {
            errorMessageBlock .= "`n`n*****ADDITIONAL INFO*****`n" . pErrorObject.Extra
        }
        errorMessageBlock .= "`n`n*****FILE*****`n" . pErrorObject.File . "`n`n*****LINE*****`n" . pErrorObject.Line
            . "`n`n*****CALL STACK*****`n" . pErrorObject.Stack
    }
    if (IsSet(pAdditionalErrorMessage)) {
        errorMessageBlock .= "`n`n#####ADDITIONAL ERROR MESSAGE#####`n" . pAdditionalErrorMessage
    }
    if (pBooleanTerminatingError) {
        errorMessageBlock .= "`n`nScript has to exit!"
    }
    if (IsSet(pMessageTimeoutMilliseconds)) {
        ; Hides the GUI and therefore
        SetTimer((*) => errorGUI.Destroy(), "-" . pMessageTimeoutMilliseconds)
    }

    funnyErrorMessageArray := Array(
        "This shouldn't have happened :(",
        "Well, this is akward...",
        "Why did we stop?!",
        "Looks like we're lost in the code jungle...",
        "That's not supposed to happen!",
        "Whoopsie daisy, looks like an error!",
        "Error 404: Sense of humor not found",
        "Looks like a glitch in the Matrix...",
        "Houston, we have a problem...",
        "Unexpected error: Please blame the developer",
        "Error: Keyboard not responding, press any key to continue... oh wait",
        "Task failed successfully!"
    )
    ; Selects a "random" funny error message to be displayed.
    funnyErrorMessage := funnyErrorMessageArray.Get(Random(1, funnyErrorMessageArray.Length))

    errorGUI := Gui(, "GTAV Tweaks - Error")

    errorGUIfunnyErrorMessageText := errorGUI.Add("Text", "yp+10 r4 w300", funnyErrorMessage)
    errorGUIfunnyErrorMessageText.SetFont("italic S10")
    errorGUIerrorMessageBlockText := errorGUI.Add("Text", "yp+50", errorMessageBlock)

    errorGUIbuttonGroupBox := errorGUI.Add("GroupBox", "r2.1 w340")
    errorGUIgitHubIssuePageButton := errorGUI.Add("Button", "xp+10 yp+15 w100 R2 Default",
        "Report this issue on GitHub")
    errorGUIgitHubIssuePageButton.OnEvent("Click", (*) => Run("https://github.com/LeoTN/gtav-tweaks/issues/new/choose"))
    errorGUIcopyErrorToClipboardButton := errorGUI.Add("Button", "xp+110 w100 R2", "Copy error to clipboard")
    errorGUIcopyErrorToClipboardButton.OnEvent("Click", (*) => A_Clipboard := errorMessageBlock)

    if (pBooleanTerminatingError) {
        errorGUIActionButton := errorGUI.Add("Button", "xp+110 w100 R2", "Exit Script")
    }
    else {
        errorGUIActionButton := errorGUI.Add("Button", "xp+110 w100 R2", "Continue Script")
    }
    errorGUIActionButton.OnEvent("Click", (*) => errorGUI.Destroy())
    errorGUI.Show()
    errorGUI.Flash()
    ; There might be an error with the while condition, once the GUI is destroyed.
    try
    {
        while (WinExist("ahk_id " . errorGUI.Hwnd)) {
            Sleep(500)
        }
    }

    if (pBooleanTerminatingError) {
        exitScriptWithNotification(true)
    }
}

/*
A simple method to convert an array into a string form.
@param pArray [Array] Should be an array to convert.
@returns [String] The array converted into a string form.
*/
arrayToString(pArray) {
    string := "["

    for (index, value in pArray) {
        string .= value
        if (index < pArray.Length) {
            string .= ","
        }
    }

    string .= "]"
    return string
}

/*
A simple method to convert a string (in array form) into an array.
@param pString [String] Should be a string (in array form) to convert.
@returns [Array] The string converted into an array form.
*/
stringToArray(pString) {
    array := StrSplit(pString, ",")
    return array
}

/*
"Decyphers" the cryptic hotkey symblos into normal words.
@param pHotkey [String] Should be a valid AutoHotkey hotkey for example "+!F4".
@returns [String] A "decyphered" AutoHotkey hotkey for example "Shift + Alt + F4".
*/
expandHotkey(pHotkey) {
    hotkeyString := pHotkey
    hotkeyString := StrReplace(hotkeyString, "+", "SHIFT + ")
    hotkeyString := StrReplace(hotkeyString, "^", "CTRL + ")
    hotkeyString := StrReplace(hotkeyString, "!", "ALT + ")
    hotkeyString := StrReplace(hotkeyString, "#", "WIN + ")

    return hotkeyString
}
