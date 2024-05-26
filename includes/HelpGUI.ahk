#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

help_onInit()
{
    createHelpGUI()
}

createHelpGUI()
{
    Global
    helpGUI := Gui(, getLanguageArrayString("infoAndHelpGUI_1"))
    helpGUISearchBarText := helpGUI.Add("Text", , getLanguageArrayString("infoAndHelpGUI_2"))
    helpGUISearchBarEdit := helpGUI.Add("Edit", "w150 -WantReturn")
    helpGUISearchBarEdit.OnEvent("Change", (*) => searchInListView(helpGUISearchBarEdit.Text))
    ; This selects the text inside the edit once the user clicks on it again after loosing focus.
    helpGUISearchBarEdit.OnEvent("Focus", (*) => ControlSend("^A", helpGUISearchBarEdit))

    helpGUIListViewArray := Array(getLanguageArrayString("infoAndHelpGUIListView_1"),
        getLanguageArrayString("infoAndHelpGUIListView_2"), getLanguageArrayString("infoAndHelpGUIListView_3"))
    helpGUIListView := helpGUI.Add("ListView", "yp+40 w400 R10 -Multi", helpGUIListViewArray)
    helpGUIListView.OnEvent("DoubleClick", (*) => processDoubleClickedListViewItem())

    helpGUIInfoGroupBox := helpGUI.Add("GroupBox", "xp+170 yp-59 w230 R2", getLanguageArrayString("infoAndHelpGUI_3"))

    local currentVersionLink := "https://github.com/LeoTN/gtav-tweaks/releases/" . versionFullName
    local tmpLanguageLink := getLanguageArrayString("infoAndHelpGUI_4", currentVersionLink, versionFullName)
    ; We need to take this extra step because there would be a gap between href= and the url (href= "url_here"), which breaks the link.
    ; The same goes for the space after the url ends.
    local tmpLanguageLink := StrReplace(tmpLanguageLink, "replace_space_after ")
    local tmpLanguageLink := StrReplace(tmpLanguageLink, " replace_space_before")
    helpGUIScriptVersionLink := helpGUI.Add("Link", "xp+10 yp+18", tmpLanguageLink)

    ; These links need to be changed when renaming the .YAML files for the GitHub issues section.
    local featureRequestLink := "https://github.com/LeoTN/gtav-tweaks/issues/new?assignees=&labels=enhancement&projects=&template=feature-request.yml&title=Feature+Request"
    local bugReportLink := "https://github.com/LeoTN/gtav-tweaks/issues/new?assignees=&labels=bug&projects=&template=bug-report.yml&title=Bug+Report"
    local tmpLanguageLink := getLanguageArrayString("infoAndHelpGUI_5", featureRequestLink, bugReportLink)
    ; We need to take this extra step because there would be a gap between href= and the url (href= "url_here"), which breaks the link.
    ; The same goes for the space after the url ends.
    local tmpLanguageLink := StrReplace(tmpLanguageLink, "replace_space_after ")
    local tmpLanguageLink := StrReplace(tmpLanguageLink, " replace_space_before")
    helpGUIFeatureAndBugSubmitLink := helpGUI.Add("Link", "yp+20", tmpLanguageLink)

    helpGUIStatusBar := helpGUI.Add("StatusBar", , getLanguageArrayString("infoAndHelpGUI_6"))
    helpGUIStatusBar.SetIcon("shell32.dll", 278)
    ; This is used for the easter egg.
    helpGUIStatusBar.OnEvent("Click", (*) => handleHelpGUI_helpSectionEasterEgg())

    helpGUIListViewContentCollectionArray := createListViewContentCollectionArray()
    For (contentEntry in helpGUIListViewContentCollectionArray)
    {
        addLineToListView(contentEntry)
    }
    ; Sorts the data according to the title column.
    helpGUIListView.ModifyCol(3, "SortHdr")
}

; A small tour to show off the basic functions of this script.
scriptTutorial()
{
    result := MsgBox(getLanguageArrayString("tutorialMsgBox1_1"),
        getLanguageArrayString("tutorialMsgBox1_2"), "YN Iconi 262144")
    If (result == "Yes")
    {
        minimizeAllGUIs()
        ; Welcome message.
        MsgBox(getLanguageArrayString("tutorialMsgBox3_1"), getLanguageArrayString("tutorialMsgBox3_2"), "O Iconi 262144")
        ; Start of tutorial.
        MsgBox(getLanguageArrayString("tutorialMsgBox4_1"), getLanguageArrayString("tutorialMsgBox4_2"), "O Iconi 262144")
        If (!WinActive("ahk_id " . mainGUI.Hwnd))
        {
            mainGUI.Show()
        }
        MsgBox(getLanguageArrayString("tutorialMsgBox5_1"), getLanguageArrayString("tutorialMsgBox5_2"), "O Iconi 262144 T3")
        If (WinWaitActive("ahk_id " . helpGUI.Hwnd, , 5) == 0)
        {
            helpGUI.Show()
            MsgBox(getLanguageArrayString("tutorialMsgBox6_1"), getLanguageArrayString("tutorialMsgBox6_2"), "O Iconi 262144 T5")
        }
        highlightedSearchBarObject := highlightControl(helpGUISearchBarEdit)
        MsgBox(getLanguageArrayString("tutorialMsgBox7_1"), getLanguageArrayString("tutorialMsgBox7_2"), "O Iconi 262144")
        ; This array contains the letters "typed" into the search bar for demonstration purposes.
        searchBarDemoLetterArray := stringToArray(getLanguageArrayString("tutorialSearchBarDemoArrayString"))
        ; Demonstrates the search bar to the user.
        For (letter in searchBarDemoLetterArray)
        {
            If (WinExist("ahk_id " . helpGUI.Hwnd))
            {
                WinActivate()
            }
            ControlSend(letter, helpGUISearchBarEdit, "ahk_id " . helpGUI.Hwnd)
            Sleep(50)
        }
        highlightedSearchBarObject.destroy()
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
    If (WinExist("ahk_id " . helpGUI.Hwnd))
    {
        WinMinimize()
    }
}

/*
Allows to search for elements in the list view element.
@param pSearchString [String] A string to search for.
*/
searchInListView(pSearchString)
{
    helpGUIListView.Delete()
    ; Shows all data when the search bar is empty.
    If (pSearchString == "")
    {
        For (contentEntry in helpGUIListViewContentCollectionArray)
        {
            addLineToListView(contentEntry)
        }
        Return
    }
    resultArrayCollection := Array()
    ; Scans every string in the content array.
    For (contentEntry in helpGUIListViewContentCollectionArray)
    {
        If (InStr(contentEntry.topic, pSearchString))
        {
            resultArrayCollection.Push(contentEntry)
        }
        Else If (InStr(contentEntry.type, pSearchString))
        {
            resultArrayCollection.Push(contentEntry)
        }
        Else If (InStr(contentEntry.title, pSearchString))
        {
            resultArrayCollection.Push(contentEntry)
        }
    }
    For (resultEntry in resultArrayCollection)
    {
        addLineToListView(resultEntry)
    }
    Else
    {
        tmpListViewEntry := ListViewEntry("*****", "No results found.", "*****", (*) => 0, 0)
        addLineToListView(tmpListViewEntry)
        Return
    }
}

/*
Adds the content of a list view entry object into the list view element.
@param pListViewObject [ListViewEntry] An object containing relevant information to create an item in the list view.
@param pBooleanAutoAdjust [boolean] If set to true, the column width will be adjusted accordingly to the content.
*/
addLineToListView(pListViewObject, pBooleanAutoAdjust := true)
{
    helpGUIListView.Add(, pListViewObject.topic, pListViewObject.type, pListViewObject.title)
    If (pBooleanAutoAdjust)
    {
        ; Adjust the width accordingly to the content.
        Loop (helpGUIListViewArray.Length)
        {
            helpGUIListView.ModifyCol(A_Index, "AutoHdr")
        }
    }
}

/*
Creates an array, which contains list view entry objects. They contain the required data to be added into a list view element.
@returns [Array] This array is filled with list view objects.
*/
createListViewContentCollectionArray()
{
    ; This array contains all list view entries.
    helpGUIListViewContentCollectionArray := Array()
    ; 1. Topic 2. Type 3. Title 4. Action 5. Index
    listViewEntry_1 := ListViewEntry("Test_Topic", "Test_Type", "This is a test entry", (*) => MsgBox("You triggered a test MsgBox."), 1)

    ; The number needes to be updated depending on how many list view entries there are.
    Loop (1)
    {
        helpGUIListViewContentCollectionArray.InsertAt(A_Index, %"listViewEntry_" . A_Index%)
    }
    Return helpGUIListViewContentCollectionArray
}

; Runs the bound action of the currently selected list view element.
processDoubleClickedListViewItem()
{
    ; This map stores all list view entries together with their index.
    static actionMap := Map()
    If (!actionMap.Has(1))
    {
        For (contentEntry in helpGUIListViewContentCollectionArray)
        {
            actionMap[contentEntry.index] := contentEntry
        }
    }
    ; Finds out the currently selected entries index number and calls the corresponding action.
    focusedEntryIndex := helpGUIListView.GetNext(, "Focused")
    If (actionMap.Has(focusedEntryIndex))
    {
        actionMap[focusedEntryIndex].runAction()
    }
}

/*
Highlights a control with a colored border.
@param pControlElement [controlElement] Should be a control element (like a button or a checkbox) created within an AutoHotkey GUI.
@param pColor [String] Determines the color of the border.
@param pLineeThickness [int] Defines how thin the border is (in pixels).
@param pLineTransparicy [int] Should be a value between 0 and 255. 0 makes the border invisible and 255 makes it entirely visible.
@returns [RectangleHollowBox] This object can be used to control the border and it's properties.
*/
highlightControl(pControlElement, pColor := "red", pLineThickness := 2, pLineTransparicy := 200)
{
    Try
    {
        ; Retrieves the control's position relative to the computer screen.
        WinGetClientPos(&screenControlX, &screenControlY, &controlWidth, &controlHeight, pControlElement)
    }
    Catch
    {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] The control with the text [" . pControlElement.Text . "] does not exist.",
            "GTAV Tweaks - [" . A_ThisFunc . "()]", "IconX 262144")
    }
    highlightBox := RectangleHollowBox(screenControlX, screenControlY, controlWidth, controlHeight, pColor, pLineThickness, pLineTransparicy)
    highlightBox.draw()
    Return highlightBox
}

/*
Waits for a control element in an AutoHotkey GUI to be clicked.
@param pControlElement [buttonControl] Should be a button, or really any other control element,
that supports .OnEvent("Click") created within an AutoHotkey GUI.
@param pCurrentClickEventFunction [function] If the button called the "doSomething()" function defined with it's
OnEvent function [myButton.OnEvent("Click", (*) => doSomething())], we have to give this information to the waiting function.
In our example the value of this parameter would be "(*) => doSomething()" without the quotation marks.
@param pTimeoutMilliseconds [int] Waits for the specified time. Enter 0 to wait indefinetly.
@returns [boolean] Returns true if the element was pressed or clicked before the timeout. False otherwise.
*/
waitForControlToBeClickedOrPressed(pControlElement, pCurrentClickEventFunction, pTimeoutMilliseconds := 0)
{
    timeoutMilliseconds := pTimeoutMilliseconds
    booleanWait := true
    ; Replaces the current function with this temporary one.
    pControlElement.OnEvent("Click", (*) => booleanWait := false, -1)
    While (booleanWait)
    {
        If (timeoutMilliseconds >= 0)
        {
            timeoutMilliseconds -= 50
        }
        ; If pTimeoutMilliseconds is 0, the function will wait indefinetly.
        If (timeoutMilliseconds < 0 && pTimeoutMilliseconds != 0)
        {
            Return false
        }
        Sleep(50)
    }
    ; Resets the OnEvent function and calls it.
    pControlElement.OnEvent("Click", pCurrentClickEventFunction, -1)
    pCurrentClickEventFunction
    Return true
}

handleHelpGUI_helpSectionEasterEgg()
{
    static i := 0

    i++
    If (i >= 5)
    {
        i := 0
        MsgBox(getLanguageArrayString("mainGUIMsgBox1_1"), getLanguageArrayString("mainGUIMsgBox1_2"), "O Iconi 262144")
    }
}

/*
Stores all data required to create an entry in a list view element.
@param pTopic [String] The topic this entry is about (e.g. General, Macros, etc.).
@param pType [String] The type of content, for instance, Tutorial or Info.
@param pTitle[String] The title of the entry.
@param pAction [Function] Can be a fat arrow function ((*) =>) or a function call (doSomething()).
@param pEntryIndex [int] Should be increased by 1 each time a new entry is created. Starting with 1 initially.
*/
class ListViewEntry
{
    __New(pTopic, pType, pTitle, pAction, pEntryIndex)
    {
        this.topic := pTopic
        this.type := pType
        this.title := pTitle
        this.action := pAction
        this.index := pEntryIndex
    }
    runAction()
    {
        this.action
    }
}

/*
Creates a hollow rectangle box out of 4 seperate GUIs. This could be used to mark controls on another GUI.
@param pTopLeftCornerX [int] Should be a valid screen coordinate. The x and y coordinates will point to the top left corner
of the hollow box inside the borders.
@param pTopLeftCornerY [int] This is the second paramter used in combination with pTopLeftCornerX.
@param pBoxWidth [int] Defines the width of the inner box enclosed by the borders.
@param pBoxHeight [int] Specifies how high the inner box should be.
@param pOuterLineColor [String] Can be a color in any color format known by AutoHotkey.
@param pOuterLineThickness [int] Defines how thick the outer lines around the inner box will be in pixels.
@param pOuterLineTransparicy [int] Should be a value between 0 and 255. 0 makes the borders invisible and 255 makes them entirely visible.
*/
class RectangleHollowBox
{
    __New(pTopLeftCornerX := unset, pTopLeftCornerY := unset, pBoxWidth := 10, pBoxHeight := 10, pOuterLineColor := "red", pOuterLineThickness := 1, pOuterLineTransparicy := 50)
    {
        ; Both parameters are omitted.
        If (!IsSet(pTopLeftCornerX) && !IsSet(pTopLeftCornerY))
        {
            ; We use the current mouse cursor position here.
            MouseGetPos(&mouseX, &mouseY)
            this.topLeftCornerX := mouseX
            this.topLeftCornerY := mouseY
        }
        ; Only one parameter is given and the other one is missing.
        Else If (!IsSet(pTopLeftCornerX) || !IsSet(pTopLeftCornerY))
        {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Make sure that either both (pTopLeftCornerX and pTopLeftCornerY) are given or omitted entirely.",
                "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return
        }
        Else
        {
            this.topLeftCornerX := pTopLeftCornerX
            this.topLeftCornerY := pTopLeftCornerY
        }
        this.boxWidth := pBoxWidth
        this.boxHeight := pBoxHeight
        this.outerLineColor := pOuterLineColor
        this.outerLineThickness := pOuterLineThickness
        this.outerLineTransparicy := pOuterLineTransparicy
    }
    draw()
    {
        /*
        ------
        
        
        */
        this.__line1 := Gui("+AlwaysOnTop -Caption +Disabled +ToolWindow", "")
        this.__line1.BackColor := this.outerLineColor
        showWidth := this.boxWidth + this.outerLineThickness * 2
        showX := this.topLeftCornerX - this.outerLineThickness
        showY := this.topLeftCornerY - this.outerLineThickness
        showString := "x" . showX . " y" . showY . " w" . showWidth
            . " h" . this.outerLineThickness . " NoActivate"
        this.__line1.Show(showString)

        /*
        |
        |
        |
        */
        this.__line2 := Gui("+AlwaysOnTop -Caption +Disabled +ToolWindow", "")
        this.__line2.BackColor := this.outerLineColor
        showX := this.topLeftCornerX - this.outerLineThickness
        showY := this.topLeftCornerY
        showString := "x" . showX . " y" . showY . " w" . this.outerLineThickness
            . " h" . this.boxHeight . " NoActivate"
        this.__line2.Show(showString)

        /*
                |
                |
                |
        */
        this.__line3 := Gui("+AlwaysOnTop -Caption +Disabled +ToolWindow", "")
        this.__line3.BackColor := this.outerLineColor
        showX := this.topLeftCornerX + this.boxWidth
        showY := this.topLeftCornerY
        showString := "x" . showX . " y" . showY . " w" . this.outerLineThickness
            . " h" . this.boxHeight . " NoActivate"
        this.__line3.Show(showString)

        /*
        
        
        -----
        */
        this.__line4 := Gui("+AlwaysOnTop -Caption +Disabled +ToolWindow", "")
        this.__line4.BackColor := this.outerLineColor
        showWidth := this.boxWidth + this.outerLineThickness * 2
        showX := this.topLeftCornerX - this.outerLineThickness
        showY := this.topLeftCornerY + this.boxHeight
        showString := "x" . showX . " y" . showY . " w" . showWidth
            . " h" . this.outerLineThickness . " NoActivate"
        this.__line4.Show(showString)

        WinSetTransparent(this.outerLineTransparicy, this.__line1)
        WinSetTransparent(this.outerLineTransparicy, this.__line2)
        WinSetTransparent(this.outerLineTransparicy, this.__line3)
        WinSetTransparent(this.outerLineTransparicy, this.__line4)
    }
    move(pX, pY)
    {
        this.topLeftCornerX := pX
        this.topLeftCornerY := pY

        this.destroy()
        this.draw()
    }
    ; This does NOT destroy the object, but the rectangle box instead.
    destroy()
    {
        this.__line1.Destroy()
        this.__line2.Destroy()
        this.__line3.Destroy()
        this.__line4.Destroy()
    }
    show()
    {
        this.__line1.Show()
        this.__line2.Show()
        this.__line3.Show()
        this.__line4.Show()
    }
    hide()
    {
        this.__line1.Hide()
        this.__line2.Hide()
        this.__line3.Hide()
        this.__line4.Hide()
    }
}