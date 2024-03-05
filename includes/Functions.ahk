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

muteGTAWhileInLoadingScreen()
{
    manipulateApplicationAudio("GTA5.exe", "/mute")
    Sleep(10000)
    waitForUserInputInGTA()
    manipulateApplicationAudio("GTA5.exe", "/unmute")
}

; Waits for the user to press w a & d while the window is active to continue the script execution.
waitForUserInputInGTA()
{
    static timeoutCounter := 0
    ; This prevents the script from loading infinetly.
    If (WinWaitActive("ahk_exe GTA5.exe", , 600) = 0)
    {
        If (timeoutCounter >= 5)
        {
            result := MsgBox("Are you still waiting for GTA to load?", "GTAV Tweaks - Continue Waiting?", "YN Icon? T30")
            If (result = "Yes")
            {
                timeoutCounter := 0
                Return waitForUserInputInGTA()
            }
            Else
            {
                ExitApp()
            }
        }
        timeoutCounter++
        Return waitForUserInputInGTA()
    }
    Else
    {
        While (WinActive("ahk_exe GTA5.exe"))
        {
            If (KeyWait("w", "D T1") = 1)
            {
                Return
            }
        }

        Return waitForUserInputInGTA()
    }
}

; Checks if GTA still exists and reloads the script if it doesn't to prepare for the next GTA launch.
checkForExistingGTA()
{
    If (!WinExist("ahk_exe GTA5.exe"))
    {
        Reload()
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

; Shows a tutorial to the user.
scriptTutorial()
{
    ; Nothing yet
    MsgBox("Tutorial GTAV Tweaks")
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
Adds / removes the script from the autostart folder.
@param pBooleanEnableAutostart [boolean] If set to true, will put a shortcut to this script into the autostart folder.
*/
setAutostart(pBooleanEnableAutostart)
{
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