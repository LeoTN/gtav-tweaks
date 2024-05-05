#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

macroRecorder_onInit()
{

}

/*
Starts the macro recording process. This will pause the current thread until the macro recording is
terminated via the stopMacroRecording() function.
*/
startMacroRecording()
{
    global booleanMacroIsRecording := true
    global recordedMacroFilesStorageDirectory
    global macroRecordHotkey
    currentDateString := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")
    macroFileLocation := recordedMacroFilesStorageDirectory . "\" . currentDateString . ".ahk"

    TrayTip(getLanguageArrayString("macroRecorderTrayTip1_1", macroRecordHotkey), getLanguageArrayString("macroRecorderTrayTip1_2"), "20")
    SetTimer(TrayTip, -6000)
    macroFileString .= getMacroFileTemplateString(currentDateString)

    While (booleanMacroIsRecording)
    {
        currentlyRecoredMacro := appendToMacroFileString(waitForAnyKey())
    }
    macroFileString .= currentlyRecoredMacro
    FileAppend(macroFileString, macroFileLocation)
}

stopMacroRecording()
{
    global recordedMacroFilesStorageDirectory
    global booleanMacroIsRecording := false

    TrayTip(getLanguageArrayString("macroRecorderTrayTip2_1", recordedMacroFilesStorageDirectory), getLanguageArrayString("macroRecorderTrayTip2_2"), "20")
    SetTimer(TrayTip, -6000)
}

/*
Creates the basic template for every macro file.
@returns [String] The string, which will be written at the start of the macro file.
*/
getMacroFileTemplateString(pMacroCreationTimeStampString)
{
    global macroRecorderTemplateFileLocation
    global scriptMainDirectory

    If (!FileExist(macroRecorderTemplateFileLocation))
    {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] Unable to find template file [" . macroRecorderTemplateFileLocation . "].")
        stopMacroRecording()
    }
    SplitPath(scriptMainDirectory, &outFolderName)
    macroTemplateString .= "/*`n"
    macroTemplateString .= "Created on " . pMacroCreationTimeStampString . "`n"
    macroTemplateString .= "with GTAV Tweaks macro recorder`n"
    macroTemplateString .= "(https://github.com/LeoTN/gtav-tweaks).`n`n"
    macroTemplateString .= "Make sure to take a look at the README.txt before changing this file!`n"
    macroTemplateString .= "You can find it in the script folder (" . outFolderName . ")`n"
    macroTemplateString .= "or in the installer archive (downloaded from GitHub).`n"
    macroTemplateString .= "**************************************************`n"
    macroTemplateString .= "*/`n`n"
    macroTemplateString .= FileRead(macroRecorderTemplateFileLocation) . "`n`n"
    Return macroTemplateString
}

/*
Appends strings to the macro file string, which will be later written into a macro file.
@param pString [String] Should be an ordinary string. Can be omitted.
@param pBooleanClearString [boolean] If set to true, the internally stored string will be cleared.
@returns [String] The macro file string.
*/
appendToMacroFileString(pString := unset, pBooleanClearString := false)
{
    static commitCounter := 0
    static macroFileString := ""

    If (pBooleanClearString)
    {
        commitCounter := 0
        macroFileString := ""
    }
    If (IsSet(pString))
    {
        commitCounter++
        macroFileString .= "/*##### " . commitCounter . " #####*/`n"
        macroFileString .= pString . "`n"
    }
    Return macroFileString
}

; Returns the string for the macro file, depending on the pressed key during recording.
waitForAnyKey()
{
    global macroRecordHotkey
    global macroRecorderInputHook := InputHook("V")
    keyboardKeyMinimumWaitTimeMilliseconds := 800
    idleTimeMilliseconds := 0
    ; Waits for any key to be pressed (except for mouse keys for what ever reason).
    macroRecorderInputHook.KeyOpt("{All}", "E")
    macroRecorderInputHook.Start()

    ; It only stops, when a key or a mouse button is pressed.
    While (macroRecorderInputHook.InProgress)
    {
        ; We have to check the value after each time, because the loop is too fast and won't stop without checking all three keys.
        ; This mean the variable mouseKey will not receive the correct value correspondingly to the pressed mouse key.
        mouseKeyReturnedArray := checkIfMouseButtonPressed("LButton")
        mouseKey := mouseKeyReturnedArray.Get(1)
        If (mouseKey != "invalid_mouse_key_received" && mouseKey != "no_mouse_key_pressed")
        {
            Break
        }
        mouseKeyReturnedArray := checkIfMouseButtonPressed("RButton")
        mouseKey := mouseKeyReturnedArray.Get(1)
        If (mouseKey != "invalid_mouse_key_received" && mouseKey != "no_mouse_key_pressed")
        {
            Break
        }
        mouseKeyReturnedArray := checkIfMouseButtonPressed("MButton")
        mouseKey := mouseKeyReturnedArray.Get(1)
        If (mouseKey != "invalid_mouse_key_received" && mouseKey != "no_mouse_key_pressed")
        {
            Break
        }
        idleTimeMilliseconds += 10
        Sleep(10)
    }
    ; We don't want the macro record hotkey to be included into the file.
    If (macroRecorderInputHook.EndKey == macroRecordHotkey)
    {
        Return "; This is the end of the macro."
    }
    ; ##### MOUSE KEY #####
    If (mouseKey != "invalid_mouse_key_received" && mouseKey != "no_mouse_key_pressed")
    {
        ; The array is returned by the checkIfMouseButtonPressed() function and contains all values at the specific indexes.
        mouseKeyIncompleteString := mouseKeyReturnedArray.Get(2)
        ; We now know the idleTimeMilliseconds and can fill in the value.
        pressedKeyCompleteString := StrReplace(mouseKeyIncompleteString, "insert_sleep_time_milliseconds_here", idleTimeMilliseconds)
        Return pressedKeyCompleteString
    }
    ; ##### KEYBOARD KEY #####
    ; Checks if the given key is not a letter.
    If (!RegExMatch(macroRecorderInputHook.EndKey, "\A\p{L}\z") && idleTimeMilliseconds < keyboardKeyMinimumWaitTimeMilliseconds)
    {
        ; This is a safety feature to make sure the game has enough time to process the inputs. Otherwise the macros might be broken.
        idleTimeMilliseconds := keyboardKeyMinimumWaitTimeMilliseconds
    }
    pressedKeyCompleteString := "; " . macroRecorderInputHook.EndKey . "`n"
    pressedKeyCompleteString .= 'keyboardKey := "' . macroRecorderInputHook.EndKey . '"`n'
    pressedKeyCompleteString .= "sleepTimeMilliseconds := " . idleTimeMilliseconds . "`n"
    pressedKeyCompleteString .= "Sleep(sleepTimeMilliseconds / macroPlayBackSpeedModificator)`n"
    pressedKeyCompleteString .= "Send(`"{`" . keyboardKey . `" down}`")`n"
    pressedKeyCompleteString .= "Sleep(keyboardKeyWaitTimeMilliseconds) "
    pressedKeyCompleteString .= "; Be careful when changing this value.`n"
    pressedKeyCompleteString .= "Send(`"{`" . keyboardKey . `" up}`")`n"
    Return pressedKeyCompleteString
}

/*
Checks if the given mouse button is pressed.
@param pMouseButton [String] Should be a valid mouse button, for instance "RButton".
@returns [Array] An array which contains multiple values. The string (conained in the 2th index) needs to be further processed,
using the other values in the array from index 1-2.
*/
checkIfMouseButtonPressed(pMouseButton)
{
    global macroRecorderInputHook

    Switch (pMouseButton)
    {
        Case "LButton":
            {
                mouseKeyIncompleteString .= "; Left Click`n"
                mouseKeyLongName := "Left"
            }
        Case "RButton":
            {
                mouseKeyIncompleteString .= "; Right Click`n"
                mouseKeyLongName := "Right"
            }
        Case "MButton":
            {
                mouseKeyIncompleteString .= "; Middle Click`n"
                mouseKeyLongName := "Middle"
            }
        Default:
            {
                MsgBox("[" . A_ThisFunc . "()] [WARNING] Received an invalid mouse key: [" . pMouseButton . "].")
                mouseKeyReturnArray := Array("invalid_mouse_key_received")
                Return mouseKeyReturnArray
            }
    }
    If (GetKeyState(pMouseButton, "P"))
    {
        MouseGetPos(&mouseX, &mouseY)
        mouseKeyIncompleteString .= 'mouseKey := "' . mouseKeyLongName . '"`n'
        mouseKeyIncompleteString .= "mouseX := " . mouseX . "`n"
        mouseKeyIncompleteString .= "mouseY := " . mouseY . "`n"
        ; The value will be inserted, once the sleep time (idleTimeMilliseconds) is known.
        mouseKeyIncompleteString .= "sleepTimeMilliseconds := insert_sleep_time_milliseconds_here`n"
        mouseKeyIncompleteString .= "Sleep(sleepTimeMilliseconds / macroPlayBackSpeedModificator)`n"
        mouseKeyIncompleteString .= "MouseMove(mouseX, mouseY)`n"
        mouseKeyIncompleteString .= "Sleep(mouseClickWaitTimeMilliseconds) "
        mouseKeyIncompleteString .= "; Be careful when changing this value.`n"
        mouseKeyIncompleteString .= 'Click(mouseX, mouseY, "mouseKey", "D")`n'
        mouseKeyIncompleteString .= "Sleep(mouseClickWaitTimeMilliseconds) "
        mouseKeyIncompleteString .= "; Be careful when changing this value.`n"
        mouseKeyIncompleteString .= 'Click(mouseX, mouseY, "mouseKey", "U")`n'
        ; We need an array, because we have multiple values, that need to be returned.
        mouseKeyReturnArray := Array(mouseKeyLongName, mouseKeyIncompleteString)
        macroRecorderInputHook.Stop()
        ; Waits for the mouse button to be released.
        KeyWait(pMouseButton, "L")
        Return mouseKeyReturnArray
    }
    mouseKeyReturnArray := Array("no_mouse_key_pressed")
    Return mouseKeyReturnArray
}