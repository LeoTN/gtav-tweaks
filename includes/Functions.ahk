#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

functions_onInit()
{

}

/*
Changes application audio settings, as if you would change them in the audio settings.
@param pApplicationName [String] Should be the name of the application or rather it's process, for example Firefox.exe.
@param pAction [String] Can be /mute or /unmute.
*/
manipulateApplicationAudio(pApplicationName, pAction)
{
    Run(audioHookFileLocation . ' ' . pAction . ' ' . pApplicationName . ' /waitForItem 120', , "Hide")
}

muteGTAWhileInLoadingScreen()
{
    manipulateApplicationAudio("GTA5.exe", "/mute")
    Sleep(10000)
    waitForUserInputInGTA()
    manipulateApplicationAudio("GTA5.exe", "/unmute")
}

waitForGTAToExist()
{
    WinWait("ahk_exe GTA5.exe")
    If (readConfigFile("DISPLAY_GTA_LAUNCH_NOTIFICATION"))
    {
        TrayTip("Running GTAV instance detected.", "GTAV Tweaks - Status", "Iconi Mute")
        Sleep(1500)
        TrayTip()
    }
}

; Waits for the user to press w while the window is active, to continue the script execution and unmute the game.
waitForUserInputInGTA()
{
    ; This prevents the script from loading infinitely.
    If (WinWaitActive("ahk_exe GTA5.exe", , 600) == 0)
    {
        Reload()
    }
    While (WinActive("ahk_exe GTA5.exe"))
    {
        If (KeyWait("w", "D T1") == 1)
        {
            Return
        }
    }
    Return waitForUserInputInGTA()
}

; Checks if GTA still exists and reloads the script if it doesn't, to prepare for the next GTA launch.
checkForExistingGTA()
{
    If (!WinExist("ahk_exe GTA5.exe"))
    {
        Reload()
    }
    ; Enables the hotkeys if GTA is the active window.
    Else If (WinActive("ahk_exe GTA5.exe"))
    {
        Suspend(false)
    }
    ; Disables the hotkeys if GTA is not the active window.
    Else
    {
        Suspend(true)
    }
}

/*
Forces the script to update to the latest version, depending on the update settings.
@returns [boolean] True or false, depending on the function's success.
*/
forceUpdate()
{
    global versionFullName

    If (!A_IsCompiled)
    {
        MsgBox(getLanguageArrayString("generalScriptMsgBox2_1"), getLanguageArrayString("generalScriptMsgBox2_2"), "O Iconi 262144 T3")
        Return false
    }
    result := MsgBox(getLanguageArrayString("mainGUIMsgBox2_1"),
        getLanguageArrayString("mainGUIMsgBox2_2"), "OC Icon! 262144")
    If (result != "OK")
    {
        Return false
    }
    If (!startUpdate(true))
    {
        Return false
    }
    Return true
}

/*
Checks all GitHub Repository tags to find new versions.
@returns [boolean] Returns true, when an update is available. False otherwise.
*/
checkForAvailableUpdates()
{
    global currentVersionFileLocation
    global psUpdateScriptLocation

    ; Does not check for updates, if there is no Internet connection or the script isn't compiled.
    If (!checkInternetConnection() || !A_IsCompiled)
    {
        Return false
    }
    SplitPath(psUpdateScriptLocation, &outFileName)
    psUpdateScriptLocationTemp := A_Temp . "\" . outFileName
    updateWorkingDir := A_Temp . "\GTAV_Tweaks_AUTO_UPDATE"

    ; Copies the script to the temp directory. This ensure that there are no file errors while the script is moving or copying files,
    ; because it cannot copy itself, while it is running.
    FileCopy(psUpdateScriptLocation, psUpdateScriptLocationTemp, true)
    parameterString := '-pGitHubRepositoryLink "https://github.com/LeoTN/gtav-tweaks" -pCurrentVersionFileLocation "' . currentVersionFileLocation
        . '" -pCurrentExecutableLocation "' . A_ScriptFullPath . '" -pOutputDirectory "' . updateWorkingDir . '"'

    If (readConfigFile("UPDATE_TO_BETA_VERSIONS"))
    {
        parameterString .= " -pSwitchConsiderBetaReleases"
    }
    ; Calls the PowerShell script to check for available updates.
    exitCode := RunWait('powershell.exe -executionPolicy bypass -file "' . psUpdateScriptLocationTemp
        . '" ' . parameterString . ' -pSwitchDoNotStartUpdate', , "Hide")
    Switch (exitCode)
    {
        ; Available update, but pSwitchDoNotStartUpdate was set to true.
        Case 101:
        {
            startUpdate()
            Return true
        }
    }
    ; Maybe more cases in the future.
}

/*
Calls the PowerShell script to start updating this software.
@param pBooleanForceUpdate [boolean] If set to true, will not show a prompt and update instantly.
@returns [boolean] True or false, depending on the function's success.
*/
startUpdate(pBooleanForceUpdate := false)
{
    global currentVersionFileLocation
    global psUpdateScriptLocation

    ; Does not check for updates, if there is no Internet connection or the script isn't compiled.
    If (!checkInternetConnection() || !A_IsCompiled)
    {
        Return false
    }
    SplitPath(psUpdateScriptLocation, &outFileName)
    psUpdateScriptLocationTemp := A_Temp . "\" . outFileName
    updateWorkingDir := A_Temp . "\GTAV_Tweaks_AUTO_UPDATE"

    ; Copies the script to the temp directory. This ensure that there are no file errors while the script is moving or copying files,
    ; because it cannot copy itself, while it is running.
    FileCopy(psUpdateScriptLocation, psUpdateScriptLocationTemp, true)
    parameterString := '-pGitHubRepositoryLink "https://github.com/LeoTN/gtav-tweaks" -pCurrentVersionFileLocation "' . currentVersionFileLocation
        . '" -pCurrentExecutableLocation "' . A_ScriptFullPath . '" -pOutputDirectory "' . updateWorkingDir . '"'
    ; Depending on the parameters and settings.
    If (readConfigFile("UPDATE_TO_BETA_VERSIONS"))
    {
        parameterString .= " -pSwitchConsiderBetaReleases"
    }
    ; Extracts the available update from the current version file.
    currentVersionFileMap := readFromCSVFile(currentVersionFileLocation)
    updateVersion := currentVersionFileMap.Get("AVAILABLE_UPDATE")
    If (updateVersion == "no_available_update")
    {
        Return false
    }
    If (pBooleanForceUpdate)
    {
        ; Calls the PowerShell script to install the update.
        Run('powershell.exe -executionPolicy bypass -file "' . psUpdateScriptLocationTemp
            . '" ' . parameterString . ' -pSwitchForceUpdate')
        ExitApp()
    }
    result := MsgBox(getLanguageArrayString("functionsMsgBox1_1", versionFullName, updateVersion),
        getLanguageArrayString("functionsMsgBox1_2"), "YN Iconi T30 262144")
    If (result != "Yes")
    {
        Return false
    }
    ; Calls the PowerShell script to install the update.
    Run('powershell.exe -executionPolicy bypass -file "' . psUpdateScriptLocationTemp
        . '" ' . parameterString, , "Hide")
    ExitApp()
}

/*
Tries to ping google.com to determine the computer's Internet connection status.
@returns [boolean] True, if the computer is connected to the Internet. False otherwise.
*/
checkInternetConnection()
{
    ; Checks if the user has an established Internet connection.
    Try
    {
        httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        httpRequest.Open("GET", "http://www.google.com", false)
        httpRequest.Send()

        If (httpRequest.Status == 200)
        {
            Return true
        }
    }

    Return false
}

; A small tour to show off the basic functions of this script.
scriptTutorial()
{
    result := MsgBox(getLanguageArrayString("tutorialMsgBox1_1"),
        getLanguageArrayString("tutorialMsgBox1_2"), "YN Iconi 262144")
    If (result == "Yes")
    {
        minimizeAllGUIs()
        MsgBox(getLanguageArrayString("tutorialMsgBox3_1"), getLanguageArrayString("tutorialMsgBox3_2"), "O Iconi 262144")
        If (!WinExist("ahk_id " . mainGUI.Hwnd))
        {
            mainGUI.Show()
        }
        ; Main GUI.
        WinActivate("ahk_id " . mainGUI.Hwnd)
        MsgBox(getLanguageArrayString("tutorialMsgBox4_1"), getLanguageArrayString("tutorialMsgBox4_2"), "O Iconi 262144")
        ; Options menu.
        MsgBox(getLanguageArrayString("tutorialMsgBox5_1"), getLanguageArrayString("tutorialMsgBox5_2"), "O Iconi 262144")
        ; Hotkeys & Macros menu.
        MsgBox(getLanguageArrayString("tutorialMsgBox6_1"), getLanguageArrayString("tutorialMsgBox6_2"), "O Iconi 262144")
        ; Hotkey Overview GUI.
        If (WinWaitActive("ahk_id " . customHotkeyOverviewGUI.Hwnd, , 5) == 0)
        {
            customHotkeyOverviewGUI.Show()
            MsgBox(getLanguageArrayString("tutorialMsgBox7_1"), getLanguageArrayString("tutorialMsgBox7_2"), "O Iconi 262144 T3")
        }
        minimizeAllGUIs()
        WinActivate("ahk_id " . customHotkeyOverviewGUI.Hwnd)
        MsgBox(getLanguageArrayString("tutorialMsgBox8_1"), getLanguageArrayString("tutorialMsgBox8_2"), "O Iconi 262144")
        ; Drop Down List.
        ControlFocus(customHotkeyOverviewGUIHotkeyDropDownList.Hwnd, "ahk_id " . customHotkeyOverviewGUI.Hwnd) ; REMOVE
        MsgBox(getLanguageArrayString("tutorialMsgBox9_1"), getLanguageArrayString("tutorialMsgBox9_2"), "O Iconi 262144")
        MsgBox(getLanguageArrayString("tutorialMsgBox10_1"), getLanguageArrayString("tutorialMsgBox10_2"), "O Iconi 262144")
        ; Hotkey Creation GUI.
        If (WinWaitActive("ahk_id " . newCustomHotkeyGUI.Hwnd, , 5) == 0)
        {
            newCustomHotkeyGUI.Show()
            MsgBox(getLanguageArrayString("tutorialMsgBox11_1"), getLanguageArrayString("tutorialMsgBox11_2"), "O Iconi 262144 T3")
        }
        minimizeAllGUIs()
        WinActivate("ahk_id " . newCustomHotkeyGUI.Hwnd)
        MsgBox(getLanguageArrayString("tutorialMsgBox12_1"), getLanguageArrayString("tutorialMsgBox12_2"), "O Iconi 262144")
        ; Final infos.
        MsgBox(getLanguageArrayString("tutorialMsgBox13_1"), getLanguageArrayString("tutorialMsgBox13_2"), "O Iconi 262144")
        MsgBox(getLanguageArrayString("tutorialMsgBox14_1"), getLanguageArrayString("tutorialMsgBox14_2"), "O Iconi 262144")
    }
    ; The dialog to disable the tutorial for the next time is only shown when the config file entry mentioned below is true.
    If (readConfigFile("ASK_FOR_TUTORIAL"))
    {
        result := MsgBox(getLanguageArrayString("tutorialMsgBox2_1"),
            getLanguageArrayString("tutorialMsgBox2_2"), "YN Iconi 262144")
        If (result == "Yes")
        {
            editConfigFile("ASK_FOR_TUTORIAL", false)
        }
    }
    minimizeAllGUIs()
    {
        ; Minimizes all script windows to reduce diversion.
        If (WinExist("ahk_id " . mainGUI.Hwnd))
        {
            WinMinimize()
        }
        If (WinExist("ahk_id " . customHotkeyOverviewGUI.Hwnd))
        {
            WinMinimize()
        }
        If (WinExist("ahk_id " . newCustomHotkeyGUI.Hwnd))
        {
            WinMinimize()
        }
    }
}

/*
Opens the config file.
@returns [boolean] Depeding on the function's success.
*/
openConfigFile()
{
    global configFileLocation

    Try
    {
        If (FileExist(configFileLocation))
        {
            Run(configFileLocation)
            Return true
        }
        Else
        {
            createDefaultConfigFile()
            Return true
        }
    }
    Catch As error
    {
        displayErrorMessage(error, "This error is rare.", true)
        ; Technically unreachable :D
        Return false
    }
}

/*
Opens the macro config file.
@returns [boolean] Depeding on the function's success.
*/
openMacroConfigFile()
{
    global macroConfigFileLocation

    Try
    {
        If (FileExist(macroConfigFileLocation))
        {
            Run(macroConfigFileLocation)
            Return true
        }
        Else
        {
            IniWrite("Always back up your files!", macroConfigFileLocation, "CustomHotkeysBelow", "Advice")
            Return openMacroConfigFile()
        }
    }
    Catch As error
    {
        displayErrorMessage(error)
        Return false
    }
}

/*
Opens the README file.
@returns [boolean] Depeding on the function's success.
*/
openReadMeFile()
{
    global readmeFileLocation

    Try
    {
        If (FileExist(readmeFileLocation))
        {
            Run(readmeFileLocation)
            Return true
        }
        Else
        {
            MsgBox(getLanguageArrayString("functionsMsgBox2_1"), getLanguageArrayString("functionsMsgBox2_2"), "Icon! T5")
            Return false
        }
    }
    Catch As error
    {
        displayErrorMessage(error, "This error is rare.")
        Return false
    }
}

/*
Function to easily record a simple macro.
This version does not support multiple keys such as Shift + ß, which would be ? as a result.
It is only capable of saving one key at a time, but in this case it is enough.
@param pOutputFileLocation [String] Should be a valid path such as "C:\Users\User\macro.ahk".
*/
recordMacro(pOutputFileLocation)
{
    global booleanMacroIsRecording := true
    global macroRecordHotkey

    ; This adds a short delay before the recorded macro executes.
    idleTime := 500
    macroStorage := "; This macro was created on " . FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss") . ".`n`n"
    macroStorage .= '#SingleInstance Force`n#Requires AutoHotkey >=v2.0`nSendMode "Input"`nCoordMode "Mouse", "Window"`n`n'
        . '; More information can be found in the README.txt contained in the installer archive file (downloaded from GitHub) '
        . 'or in the GTAV_Tweaks folder. Make sure to read it before changing this file!`n`n'

    While (booleanMacroIsRecording)
    {
        macroStorage .= 'Sleep(' . idleTime . ')`n'
        macroStorage .= waitForAnyKey("V")
    }
    ; As a safety measure to ensure the new file is clean.
    If (FileExist(pOutputFileLocation))
    {
        FileDelete(pOutputFileLocation)
    }
    FileAppend(macroStorage, pOutputFileLocation)

    waitForAnyKey(options := "")
    {
        idleTime := 0
        ih := InputHook(options)
        If (!InStr(options, "V"))
        {
            ih.VisibleNonText := false
        }
        ; Waits for any key to be pressed (except for mouse keys for what every reason).
        ih.KeyOpt("{All}", "E")
        ih.Start()
        mouseKey := unset
        While (ih.InProgress)
        {
            ; Left click.
            If (GetKeyState("LButton", "P"))
            {
                MouseGetPos(&posX, &posY)
                ; Creates a click with a 50 millisecond delay between pressing and releasing the button for the game to register the mouse click.
                mouseKey .= 'MouseMove(' . posX . ',' . posY . ')`nSleep(50) '
                mouseKey .= '; DO NOT MODIFY`nClick(' . posX . ', ' . posY . ', "L", "D")`nSleep(50) '
                mouseKey .= '; DO NOT MODIFY`nClick(' . posX . ', ' . posY . ', "L", "U")`n'
                ih.Stop()
                ; Waits until the buttons is released to avoid multiple click orders for the same click.
                KeyWait("LButton", "L")
            }
            ; Right click.
            Else If (GetKeyState("RButton", "P"))
            {
                MouseGetPos(&posX, &posY)
                mouseKey .= 'MouseMove(' . posX . ',' . posY . ')`nSleep(50) '
                mouseKey .= '; DO NOT MODIFY`nClick(' . posX . ', ' . posY . ', "R", "D")`nSleep(50) '
                mouseKey .= '; DO NOT MODIFY`nClick(' . posX . ', ' . posY . ', "R", "U")`n'
                ih.Stop()
                KeyWait("RButton", "L")
            }
            ; Mouse wheel cick.
            Else If (GetKeyState("MButton", "P"))
            {
                MouseGetPos(&posX, &posY)
                mouseKey .= 'MouseMove(' . posX . ',' . posY . ')`nSleep(50) '
                mouseKey .= '; DO NOT MODIFY`nClick(' . posX . ', ' . posY . ', "M", "D")`nSleep(50) '
                mouseKey .= '; DO NOT MODIFY`nClick(' . posX . ', ' . posY . ', "M", "U")`n'
                ih.Stop()
                KeyWait("MButton", "L")
            }
            idleTime += 10
            Sleep(10)
        }
        If (IsSet(mouseKey))
        {
            Return mouseKey
        }
        ; We don't want the macro record hotkey to be included into the file.
        If (ih.EndKey == macroRecordHotkey)
        {
            Return
        }
        ; This is a safety feature to make sure the game has enough time to process the inputs. Otherwise the macros might be broken.
        If (idleTime < 800)
        {
            idleTime := 800
        }
        ; I had to split this string because the DO NOT MODIFY comment made problems in a single string.
        tmpString := 'Send("{' . ih.EndKey . ' down}")`nSleep(100) '
        tmpString .= '; DO NOT MODIFY`nSend("{' . ih.EndKey . ' up}")`n'
        Return tmpString
    }
}

/*
Adds / removes the script from the autostart folder.
@param pBooleanEnableAutostart [boolean] If set to true, will put a shortcut to this script into the autostart folder.
*/
setAutostart(pBooleanEnableAutostart)
{
    ; Creating an autostart for the .AHK file doesn't make sense in this case.
    If (!A_IsCompiled)
    {
        Return
    }
    SplitPath(A_ScriptName, , , , &outNameNoExt)
    If (pBooleanEnableAutostart)
    {
        If (FileExist(A_Startup . "\" . outNameNoExt . ".lnk"))
        {
            FileGetShortcut(A_Startup . "\" . outNameNoExt . ".lnk", &outTarget)
            If (outTarget != A_ScriptFullPath)
            {
                result := MsgBox(getLanguageArrayString("functionsMsgBox3_1"),
                    getLanguageArrayString("functionsMsgBox3_2"), "YN Icon? 262144")
                If (result != "Yes")
                {
                    Return
                }
            }
        }
        FileCreateShortcut(A_ScriptFullPath, A_Startup . "\" . outNameNoExt . ".lnk")
    }
    Else
    {
        If (FileExist(A_Startup . "\" . outNameNoExt . ".lnk"))
        {
            FileDelete(A_Startup . "\" . outNameNoExt . ".lnk")
        }
    }
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
    If (FileExist(pFileLocation) && !pBooleanForce) {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] The file [" . pFileLocation . "] does already exist.`n`n"
            "To overwrite it, set pBooleanForce to 'true'.", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
        Return false
    }

    Try
    {
        fileObject := FileOpen(pFileLocation, "w")
        ; Writes the map object to the file.
        For (key, value in pContent)
        {
            fileObject.WriteLine('"' . key . '","' . value . '"')
        }
        fileObject.Close()
        Return true
    }
    Catch As error
    {
        displayErrorMessage(error)
        Return false
    }
}

/*
Reads values from a comma seperated file (CSV).
@param pFileLocation [String] Should be the path to a .CSV file.
@returns [Map] A map object containing all key and value pairs from the file.
*/
readFromCSVFile(pFileLocation) {
    ; Checks, if the file is available.
    If (!FileExist(pFileLocation)) {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] The file [" . pFileLocation . "] does not exist."
            , "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
        Return
    }

    Try
    {
        CSVMap := Map()
        CSVArray := []
        Loop Read, pFileLocation
        {
            Loop Parse, A_LoopReadLine, "CSV"
            {
                ; Those two entries are created by the PowerShell script and we don't want them in our map.
                If (A_LoopField != "Key" && A_LoopField != "Value")
                {
                    CSVArray.Push(A_LoopField)
                }
            }
        }
        ; Writes the key and value data to the actual map.
        i := 0
        Loop (CSVArray.Length)
        {
            If (CSVArray.Has(A_Index + 1 + i))
            {
                CSVMap.Set(CSVArray.Get(A_Index + i), CSVArray.Get(A_Index + 1 + i))
                ; This skips the loop to the next key and value pair.
                i++
            }
        }
        Return CSVMap
    }
    Catch As error
    {
        displayErrorMessage(error)
        Return false
    }
}

reloadScriptPrompt()
{
    ; Number in seconds.
    i := 4

    reloadScriptGUI := Gui(, getLanguageArrayString("reloadAndTerminateGUI_1"))
    textField := reloadScriptGUI.Add("Text", "r6 w260 x20 y40", getLanguageArrayString("reloadAndTerminateGUI_2", i))
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := reloadScriptGUI.Add("Progress", "w280 h20 x10 y120", 0)
    buttonOkay := reloadScriptGUI.Add("Button", "Default w80 x60 y190", getLanguageArrayString("reloadAndTerminateGUI_7"))
    buttonCancel := reloadScriptGUI.Add("Button", "w80 x160 y190", getLanguageArrayString("reloadAndTerminateGUI_8"))
    reloadScriptGUI.Show("AutoSize")

    buttonOkay.OnEvent("Click", (*) => Reload())
    buttonCancel.OnEvent("Click", (*) => reloadScriptGUI.Destroy())

    ; The try statement is needed to protect the code from crashing because
    ; of the destroyed GUI when the user presses cancel.
    Try
    {
        while (i >= 0)
        {
            ; Makes the progress bar feel smoother.
            Loop (20)
            {
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

terminateScriptPrompt()
{
    ; Number in seconds.
    i := 4

    terminateScriptGUI := Gui(, getLanguageArrayString("reloadAndTerminateGUI_4"))
    textField := terminateScriptGUI.Add("Text", "r6 w260 x20 y40", getLanguageArrayString("reloadAndTerminateGUI_5", i))
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := terminateScriptGUI.Add("Progress", "w280 h20 x10 y120 cRed backgroundBlack", 0)
    buttonOkay := terminateScriptGUI.Add("Button", "Default w80 x60 y190", getLanguageArrayString("reloadAndTerminateGUI_7"))
    buttonCancel := terminateScriptGUI.Add("Button", "w80 x160 y190", getLanguageArrayString("reloadAndTerminateGUI_8"))
    terminateScriptGUI.Show("AutoSize")

    buttonOkay.OnEvent("Click", (*) => ExitApp())
    buttonCancel.OnEvent("Click", (*) => terminateScriptGUI.Destroy())

    ; The try statement is needed to protect the code from crashing because
    ; of the destroyed GUI when the user presses cancel.
    Try
    {
        while (i >= 0)
        {
            ; Makes the progress bar feel smoother.
            Loop (20)
            {
                progressBar.Value += 1.25
                Sleep(50)
            }
            textField.Text := getLanguageArrayString("reloadAndTerminateGUI_5", i)
            i--
        }
        textField.Text := "The script has been terminated."
        Sleep(100)
        ExitApp()
        ExitApp()
    }
}

/*
Outputs an MsgBox containing information about the error. Allows to be copied to the clipboard.
@param pErrorObject [Error Object] Usually created when catching an error via Try / Catch.
@param pAdditionalErrorMessage [String] An optional error message to show.
@param pBooleanTerminatingError [boolean] If set to true, will force the script to terminate once message disappears.
@param pMessageTimeout [double] Optional message timeout. Closes the message after a delay of time.
*/
displayErrorMessage(pErrorObject := unset, pAdditionalErrorMessage := unset, pBooleanTerminatingError := false, pMessageTimeout := unset)
{
    If (IsSet(pErrorObject))
    {
        errorMessageBlock := "*****ERROR MESSAGE*****`n" . pErrorObject.Message . "`n`n*****ERROR TRIGGER*****`n" . pErrorObject.What
        If (pErrorObject.Extra != "")
        {
            errorMessageBlock .= "`n`n*****ADDITIONAL INFO*****`n" . pErrorObject.Extra
        }
        errorMessageBlock .= "`n`n*****FILE*****`n" . pErrorObject.File . "`n`n*****LINE*****`n" . pErrorObject.Line
            . "`n`n*****CALL STACK*****`n" . pErrorObject.Stack
    }
    If (IsSet(pAdditionalErrorMessage))
    {
        errorMessageBlock .= "`n`n#####ADDITIONAL ERROR MESSAGE#####`n" . pAdditionalErrorMessage
    }
    If (pBooleanTerminatingError)
    {
        errorMessageBlock .= "`n`nScript has to exit!"
    }
    If (IsSet(pMessageTimeout))
    {
        If (pMessageTimeout > 0)
        {
            result := MsgBox(errorMessageBlock . "`n`nPress [Yes] to copy error to clipboard.", "GTAV Tweaks - Error Details", "YN IconX T" . pMessageTimeout)
        }
        Else
        {
            result := MsgBox(errorMessageBlock . "`n`nPress [Yes] to copy error to clipboard.", "GTAV Tweaks - Error Details", "YN IconX")
        }
    }
    Else
    {
        result := MsgBox(errorMessageBlock . "`n`nPress [Yes] to copy error to clipboard.", "GTAV Tweaks - Error Details", "YN IconX")
    }
    Switch (result) {
        Case "Yes":
            {
                A_Clipboard := errorMessageBlock
            }
    }
    If (pBooleanTerminatingError)
    {
        ExitApp()
        ExitApp()
    }
}

/*
A simple method to convert an array into a string form.
@param pArray [Array] Should be an array to convert.
@returns [String] The array converted into a string form.
*/
arrayToString(pArray)
{
    string := "["

    For (index, value in pArray)
    {
        string .= value
        if (index < pArray.Length)
        {
            string .= ","
        }
    }

    string .= "]"
    Return string
}

/*
A simple method to convert a string (in array form) into an array.
@param pString [String] Should be a string (in array form) to convert.
@returns [Array] The string converted into an array form.
*/
stringToArray(pString)
{
    pString := SubStr(pString, 2, StrLen(pString) - 2)
    array := StrSplit(pString, ",")

    Return array
}

/*
"Decyphers" the cryptic hotkey symblos into normal words.
@param pHotkey [String] Should be a valid AutoHotkey hotkey for example "+!F4".
@returns [String] A "decyphered" AutoHotkey hotkey for example "Shift + Alt + F4".
*/
expandHotkey(pHotkey)
{
    hotkeyString := pHotkey
    hotkeyString := StrReplace(hotkeyString, "+", "SHIFT + ")
    hotkeyString := StrReplace(hotkeyString, "^", "CTRL + ")
    hotkeyString := StrReplace(hotkeyString, "!", "ALT + ")
    hotkeyString := StrReplace(hotkeyString, "#", "WIN + ")

    Return hotkeyString
}