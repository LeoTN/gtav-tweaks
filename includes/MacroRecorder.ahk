#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

macroRecorder_onInit ; REMOVE

macroRecorder_onInit()
{
    global macroRecorderTemplateFileLocation := "G:\GitHub Repositories\gtav-tweaks\GTAV_Tweaks\macros\templates\macroRecorderTemplate.txt" ; REMOVE
    global recordedMacroFilesStorageDirectory := "C:\Users\Donnerbaer\Downloads\Macro Test gelände" ; REMOVE
    global macroRecordHotkey := "F5" ; REMOVE

    Hotkey(macroRecordHotkey, (*) => startMacroRecording(), "On S") ; REMOVE
    Hotkey("F6", (*) => stopMacroRecording(), "On S") ; REMOVE
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

    TrayTip("Press [" . macroRecordHotkey . "] to stop recording.", "Macro Recording Started", "20")
    SetTimer(TrayTip, -2000)
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
    global booleanMacroIsRecording := false

    TrayTip("", "Macro Recording Stopped", "20")
    SetTimer(TrayTip, -2000)
}

/*
Creates the basic template for every macro file.
@returns [String] The string, which will be written at the start of the macro file.
*/
getMacroFileTemplateString(pMacroCreationTimeStampString)
{
    global macroRecorderTemplateFileLocation

    If (!FileExist(macroRecorderTemplateFileLocation))
    {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] Unable to find template file [" . macroRecorderTemplateFileLocation . "].")
        stopMacroRecording()
    }
    macroTemplateString .= "/*`n"
    macroTemplateString .= "Created on " . pMacroCreationTimeStampString . "`n"
    macroTemplateString .= "with GTAV Tweaks macro recorder`n"
    macroTemplateString .= "(https://github.com/LeoTN/gtav-tweaks).`n`n"
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
    idleTime := 0
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
        idleTime += 10
        Sleep(10)
    }
    ; We don't want the macro record hotkey to be included into the file.
    If (macroRecorderInputHook.EndKey == macroRecordHotkey)
    {
        Return
    }
    ; ##### MOUSE KEY #####
    Else If (mouseKey != "invalid_mouse_key_received" && mouseKey != "no_mouse_key_pressed")
    {
        ; The array is returned by the checkIfMouseButtonPressed() function and contains all values at the specific indexes.
        mouseX := mouseKeyReturnedArray.Get(2)
        mouseY := mouseKeyReturnedArray.Get(3)
        pixelColorToWaitFor := mouseKeyReturnedArray.Get(4)
        mouseKeyIncompleteString := mouseKeyReturnedArray.Get(5)
        ; The unfinished string from the checkIfMouseButtonPressed() function is being finished here, because we know the idleTime value at this point.
        waitForPixelColorString := 'waitForPixelColor("' . pixelColorToWaitFor . '", ' . idleTime . ', ' . mouseX . ', ' . mouseY . ')'
        pressedKeyCompleteString := StrReplace(mouseKeyIncompleteString, "insert_wait_for_pixel_color_here", waitForPixelColorString)
        Return pressedKeyCompleteString
    }
    ; This checks, if the pressed key is not a letter and the idle time has to be at least 800 milliseconds.
    Else If (!RegExMatch(macroRecorderInputHook.EndKey, "\p{L}") && idleTime < 800)
    {
        ; This is a safety feature to make sure the game has enough time to process the inputs. Otherwise the macros might be broken.
        idleTime := 800
    }
    ; ##### KEYBOARD KEY #####
    pressedKeyCompleteString := "; " . macroRecorderInputHook.EndKey . "`n"
    pressedKeyCompleteString .= "Sleep(" . idleTime . ")`n"
    pressedKeyCompleteString .= 'Send("{' . macroRecorderInputHook.EndKey . ' down}")`n'
    pressedKeyCompleteString .= "Sleep(keyboardKeysMinimumWaitTimeMilliseconds) "
    pressedKeyCompleteString .= "; DO NOT MODIFY`n"
    pressedKeyCompleteString .= 'Send("{' . macroRecorderInputHook.EndKey . ' up}")`n'
    Return pressedKeyCompleteString
}

/*
Checks if the given mouse button is pressed.
@param pMouseButton [String] Should be a valid mouse button, for instance "RButton".
@returns [Array] An array which contains multiple values. The string (conained in the 5th index) needs to be further processed,
using the other values in the array from index 2-4.
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
        pixelColorToWaitFor := getPixelColor(mouseX, mouseY)
        mouseKeyIncompleteString .= 'mouseKey := "' . mouseKeyLongName . '"`n'
        mouseKeyIncompleteString .= "mouseX := " . mouseX . "`n"
        mouseKeyIncompleteString .= "mouseY := " . mouseY . "`n"
        mouseKeyIncompleteString .= 'pixelColorToWaitFor := "' . pixelColorToWaitFor . '"`n'
        ; The function will be inserted, once the sleep time (idleTime) is known.
        mouseKeyIncompleteString .= "insert_wait_for_pixel_color_here`n"
        mouseKeyIncompleteString .= "MouseMove(mouseX, mouseY)`n"
        mouseKeyIncompleteString .= "Sleep(mouseClickMinimumWaitTimeMilliseconds) "
        mouseKeyIncompleteString .= "; Be careful when changing this value.`n"
        mouseKeyIncompleteString .= 'Click(mouseX, mouseY, "mouseKey", "D")`n'
        mouseKeyIncompleteString .= "Sleep(mouseClickMinimumWaitTimeMilliseconds) "
        mouseKeyIncompleteString .= "; Be careful when changing this value.`n"
        mouseKeyIncompleteString .= 'Click(mouseX, mouseY, "mouseKey", "U")`n'
        ; We need an array, because we have multiple values, that need to be returned.
        mouseKeyReturnArray := Array(mouseKeyLongName, mouseX, mouseY, pixelColorToWaitFor, mouseKeyIncompleteString)
        macroRecorderInputHook.Stop()
        ; Waits for the mouse button to be released.
        KeyWait(pMouseButton, "L")
        Return mouseKeyReturnArray
    }
    mouseKeyReturnArray := Array("no_mouse_key_pressed")
    Return mouseKeyReturnArray
}

/*
Tries to find a given color at a specific pixel coordinate.
@param pMouseX [int] Should be a x coordinate from the computer screen or window.
@param pMouseY [int] Here goes the same as for the x coordinate. Both coordinates can be omitted. The function will
use the current mouse cursor position instead.
@param pColor [String] Should be a valid color in the hexadecimal format.
@param pVariation [int] Can be a value from 0 to 255. This allows for similar colors to be detected, depending on how high the
value is set. 255 would allow for all colors to be found and 0 only for the exact color given.
@returns [boolean] True, if the given color was found. False otherwise.
*/
getPixelColor(pMouseX := unset, pMouseY := unset, pColor := unset, pVariation := 0)
{
    ; Both parameters are omitted.
    If (!IsSet(pMouseX) && !IsSet(pMouseY))
    {
        ; We use the current mouse cursor position here.
        MouseGetPos(&pMouseX, &pMouseY)
    }
    ; Only one parameter is given and the other one is missing.
    Else If (!IsSet(pMouseX) || !IsSet(pMouseY))
    {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] Make sure that either both (pMouseX and pMouseY) are given or omitted entirely.")
        Return false
    }
    If (IsSet(pColor))
    {
        If (pVariation < 0 || pVariation > 255)
        {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] pVariation is an invalid value: [" . pVariation . "].")
            Return false
        }
        ; Tries to find the color with an optional variation.
        If (PixelSearch(&outputX_not_used, &outputY_not_used, pMouseX, pMouseY, pMouseX, pMouseX, pColor, pVariation))
        {
            Return true
        }
        Else
        {
            Return false
        }
    }
    buttonColor := PixelGetColor(pMouseX, pMouseY)
    Return buttonColor
}