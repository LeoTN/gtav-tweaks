#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

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
    If (WinWaitActive("ahk_exe GTA5.exe", , 600) = 0)
    {
        Reload()
    }
    While (WinActive("ahk_exe GTA5.exe"))
    {
        If (KeyWait("w", "D T1") = 1)
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

checkForAvailableUpdates()
{
    ; Does not check for updates if there is no Internet connection or the script isn't compiled.
    If (!checkInternetConnection() || !A_IsCompiled)
    {
        Return
    }
    SplitPath(psUpdateScriptLocation, &outFileName)
    psUpdateScriptLocationTemp := A_Temp . "\" . outFileName
    updateWorkingDir := A_Temp . "\GTAV_Tweaks_AUTO_UPDATE"
    availableUpdateFileLocation := A_Temp . "\GTAV_Tweaks_Available_Update.txt"
    ; Copies the script to the temp directory. This ensure that there are no file errors while the script is moving or copying files,
    ; because it cannot copy itself, while it is running.
    FileCopy(psUpdateScriptLocation, psUpdateScriptLocationTemp, true)
    parameterString := '-pGitHubRepositoryLink "https://github.com/LeoTN/gtav-tweaks" -pCurrentVersion "' . versionFullName
        . '" -pCurrentExecutableLocation "' . A_ScriptFullPath . '" -pOutputDirectory "' . updateWorkingDir . '"'

    If (readConfigFile("UPDATE_TO_BETA_VERSIONS"))
    {
        parameterString .= " -pBooleanConsiderBetaReleases"
    }
    ; Calls the PowerShell script to check for available updates.
    exitCode := RunWait('powershell.exe -executionPolicy bypass -file "' . psUpdateScriptLocationTemp
        . '" ' . parameterString . ' -pBooleanDoNotStartUpdate', , "Hide")
    Switch (exitCode)
    {
        ; This exit code states that an update is available.
        Case 5:
        {
            If (!FileExist(availableUpdateFileLocation))
            {
                SplitPath(availableUpdateFileLocation, &outFileName, &outDir)
                MsgBox("[" . A_ThisFunc . "()] [WARNING] Could not find [" . outFileName . "] at [" . outDir . "]`n`n"
                    . "Update has been canceled.", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
                Return
            }
            updateVersion := FileRead(availableUpdateFileLocation)
            result := MsgBox("There is an update available. `n`nUpdate from [" . versionFullName . "] to [" . updateVersion . "] now?",
                "GTAV Tweaks - Update Available", "YN Iconi T30 262144")
            Switch (result)
            {
                Case "Yes":
                    {
                        ; Runs the PowerShell update script with the instruction to execute the update.
                        Run('powershell.exe -executionPolicy bypass -file "' . psUpdateScriptLocationTemp . '" ' . parameterString)
                        ExitApp()
                    }
            }
        }
    }
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

        If (httpRequest.Status = 200)
        {
            Return true
        }
    }

    Return false
}

; Shows a tutorial to the user.
scriptTutorial()
{
    ; Nothing yet
    MsgBox("Tutorial GTAV Tweaks (not finished)")
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
            MsgBox("No README file found.", "GTAV Tweaks - Missing README File", "Icon! T5")
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
Displays a bunch of information to the user on how to create macros.
This functions starts recordMacro() if the user confirms it.
@param pOutputFileLocation [String] Should be a valid path such as "C:\Users\User\macro.ahk".
*/
explainMacroRecording(pOutputFileLocation)
{
    SplitPath(pOutputFileLocation, &outFileName, &outDir)
    result := MsgBox("This action requires a macro file.`n`nYou can either put it into [" . outDir . "] or start recording it now."
        "`nThe file is called [" . outFileName . "].`n`nPress [Yes] to receive more information about recording macro files and start the process.",
        "GTAV Tweaks - Missing Macro File", "YN Icon! 262144")
    Switch (result)
    {
        Case "Yes":
            {
                MsgBox("This feature is still experimental!`n`nAfter closing this info box, press [F5] within 15 seconds, to initiate the recording. "
                    . "The recording actually starts after pressing any key, once it has been initiated. Pressing the [F5] key again "
                    . "will end the recording process.`n`nYou just have to do the desired action step by step (but a little bit slower than usual)."
                    "`n`nFor example open your phone, select the browser, navigate to maze bank...; to record the "
                    . "macro for depositing cash.`n`nRemember that you can always delete the macro file and record a new one.`n`n"
                    "More information can be found in the README.txt contained in the installer archive file (downloaded from GitHub) or in the GTAV_Tweaks folder.",
                    "GTAV Tweaks - How to Record Macros", "262208")
                If (KeyWait("F5", "D T15"))
                {
                    Hotkey("F5", (*) => hotkey_stopMacroRecording(), "On")
                    recordMacro(pOutputFileLocation)
                    Hotkey("F5", (*) => hotkey_stopMacroRecording(), "Off")
                }
            }
            Return
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
    macroRecordHotkey := "F5"
    ; This adds a short delay before the recorded macro executes.
    idleTime := 500
    macroStorage := "; This macro was created on " . FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss") . ".`n`n"
    macroStorage .= '#SingleInstance Force`n#Requires AutoHotkey >=v2.0`nSendMode "Input"`nCoordMode "Mouse", "Screen"`n`n'
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
            Return waitForAnyKey()
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
                result := MsgBox("There seems to be a shortcut in the autostart folder already.`n`nWould you like to overwrite it?",
                    "GTAV Tweaks - Found Existing Autostart Shortcut", "YN Icon? 262144")
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
Works together with handleMainGUI_MenuCheckHandler() to enable / disable certain hotkeys depending on
the checkmark array generated by the script GUI.
@param pStateArray [Array] Should be a valid state array for example the one from the config file.
*/
toggleHotkey(pStateArray)
{
    ; This array will be manipulated depending on the values in the array above.
    static onOffArray := ["On", "On", "On", "On"]

    Loop (pStateArray.Length)
    {
        ; The old pStateArray.Get(A_Index) = true condition has been replaced for compatibillity reasons.
        If (InStr(pStateArray.Get(A_Index), "0", 0))
        {
            onOffArray.InsertAt(A_Index, "Off")
        }
        Else If (InStr(pStateArray.Get(A_Index), "1", 0))
        {
            onOffArray.InsertAt(A_Index, "On")
        }
    }

    Hotkey(readConfigFile("AFK_PERCIO_FLIGHT_HK"), (*) => hotkey_afkCayoPericoFlight(), onOffArray.Get(1))
    Hotkey(readConfigFile("SOLO_LOBBY_HK"), (*) => hotkey_createSoloLobby(), onOffArray.Get(2))
    Hotkey(readConfigFile("DEPOSIT_MONEY_LESS_100K_HK"), (*) => hotkey_deposit100kLess(), onOffArray.Get(3))
    Hotkey(readConfigFile("DEPOSIT_MONEY_MORE_100K_HK"), (*) => hotkey_deposit100kPlus(), onOffArray.Get(4))
}

reloadScriptPrompt()
{
    ; Number in seconds.
    i := 4

    reloadScriptGUI := Gui(, "GTAV Tweaks - Reloading Script")
    textField := reloadScriptGUI.Add("Text", "r3 w260 x20 y40", "The script will be`n reloaded in " . i . " seconds.")
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := reloadScriptGUI.Add("Progress", "w280 h20 x10 y100", 0)
    buttonOkay := reloadScriptGUI.Add("Button", "Default w80 x60 y170", "Okay")
    buttonCancel := reloadScriptGUI.Add("Button", "w80 x160 y170", "Cancel")
    reloadScriptGUI.Show("w300 h200")

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

            If (i = 1)
            {
                textField.Text := "The script will be`n reloaded in " . i . " second."
            }
            Else
            {
                textField.Text := "The script will be`n reloaded in " . i . " seconds."
            }
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

    terminateScriptGUI := Gui(, "GTAV Tweaks - Terminating Script")
    textField := terminateScriptGUI.Add("Text", "r3 w260 x20 y40", "The script will be`n terminated in " . i . " seconds.")
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := terminateScriptGUI.Add("Progress", "w280 h20 x10 y100 cRed backgroundBlack", 0)
    buttonOkay := terminateScriptGUI.Add("Button", "Default w80 x60 y170", "Okay")
    buttonCancel := terminateScriptGUI.Add("Button", "w80 x160 y170", "Cancel")
    terminateScriptGUI.Show("w300 h200")

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

            If (i = 1)
            {
                textField.Text := "The script will be`n terminated in " . i . " second."
            }
            Else
            {
                textField.Text := "The script will be`n terminated in " . i . " seconds."
            }
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