#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

tutorials_onInit()
{
    ; Initializes all tutorials and info texts.
    tutorial_howToRecordMacros()
}

/*
Creates an array, which contains list view entry objects. They contain the required data to be added into a list view element.
@returns [Array] This array is filled with list view objects.
*/
createListViewContentCollectionArray()
{
    ; This array contains all list view entries.
    helpGUIListViewContentArray := Array()
    ; 1. Topic 2. Type 3. Title 4. Action
    listViewEntry_1 := ListViewEntry(
        getLanguageArrayString("tutorialHowToRecordMacros_1_2"), getLanguageArrayString("tutorialHowToRecordMacros_2_2"),
        getLanguageArrayString("tutorialHowToRecordMacros_3_2"),
        ; This will show the window at the current mouse cursor position.
        (*) => calculateInteractiveTutorialGUICoordinates(&x, &y) howToRecordMacrosTutorial.start(x, y)
    )

    ; The number needes to be updated depending on how many list view entries there are.
    Loop (1)
    {
        helpGUIListViewContentArray.InsertAt(A_Index, %"listViewEntry_" . A_Index%)
    }
    Return helpGUIListViewContentArray
}

/*
Calculates the position for the interactive tutorial window to appear.
The position will be selected relatively to the help GUI.
@var coordinateX [int] The x coordinate for the window.
@var coordinateY [int] The y coordinate for the window.
*/
calculateInteractiveTutorialGUICoordinates(&coordinateX, &coordinateY)
{
    coordinateX := 0
    coordinateY := 0
    If (!WinExist("ahk_id " . helpGUI.Hwnd))
    {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] Could not find help GUI window.",
            "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
        Return
    }
    ; We receive the coordinates from the top left corner of the help GUI.
    helpGUI.GetPos(&helpGUITopLeftCornerX, &helpGUITopLeftCornerY, &helpGUIWidth)
    helpGUITopRightCornerX := helpGUITopLeftCornerX + helpGUIWidth
    helpGUITopRightCornerY := helpGUITopLeftCornerY
    ; We add an ofset for the x coordinate.
    helpGUITopRightCornerX += 50
    coordinateX := helpGUITopRightCornerX
    coordinateY := helpGUITopRightCornerY
}

tutorial_howToRecordMacros()
{
    global howToRecordMacrosTutorial := InteractiveTutorial("GTAV Tweaks - " . getLanguageArrayString("tutorialHowToRecordMacros_3_2"))
    currentlyHighlightedControlObject := ""

    howToRecordMacrosTutorial.addText(getLanguageArrayString("tutorialHowToRecordMacros_1_1"))
    howToRecordMacrosTutorial.addAction((*) => showMainGUIAndHighlightMenu())
    howToRecordMacrosTutorial.addText(getLanguageArrayString("tutorialHowToRecordMacros_2_1"))
    howToRecordMacrosTutorial.addAction((*) => highlightCreateHotkeyButton())
    howToRecordMacrosTutorial.addText(getLanguageArrayString("tutorialHowToRecordMacros_3_1"))
    howToRecordMacrosTutorial.addAction((*) => highlightRecordMacroButton())
    ; Makes sure the highlighted controls become normal again.
    howToRecordMacrosTutorial.addExitAction((*) => hideAllHighlightedElements())

    showMainGUIAndHighlightMenu()
    {
        hideAllHighlightedElements()
        mainGUI.Show()
        currentlyHighlightedControlObject := highlightMenuElement(mainGUI.Hwnd, 3)
    }
    highlightCreateHotkeyButton()
    {
        hideAllHighlightedElements()
        customHotkeyOverviewGUI.Show()
        currentlyHighlightedControlObject := highlightControl(customHotkeyOverviewGUICreateHotkeyButton)
    }
    highlightRecordMacroButton()
    {
        hideAllHighlightedElements()
        newCustomHotkeyGUI.Show()
        currentlyHighlightedControlObject := highlightControl(newCustomHotkeyGUIRecordMacroButton)
    }
    hideAllHighlightedElements()
    {
        If (IsObject(currentlyHighlightedControlObject))
        {
            ; Hides the highlighted control box.
            currentlyHighlightedControlObject.destroy()
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
Can be used to create an interactive tutorial with a navigation window for the user.
@param pTutorialTitle [String] The title of the navigation window.
IMPORTANT: When adding text to a step, a height of 10 lines must not be exceeded!
In other words: ([K]eep [I]t [S]hort and [S]imple => KISS).
*/
class InteractiveTutorial
{
    __New(pTutorialTitle)
    {
        this.tutorialTitle := pTutorialTitle
        ; Contains the text for each step.
        this.textArray := Array()
        ; Contains an internal function to call for each step. You can enter "empty" functions like that "(*) =>"
        this.actionArray := Array()
        ; Can be filled with functions to execute when the user exits the tutorial.
        this.exitActionArray := Array()
        this.currentStepIndex := 1
        this.gui := Gui("AlwaysOnTop", pTutorialTitle)
        this.gui.OnEvent("Close", (*) => this.exit())
        this.guiText := this.gui.Add("Text", "yp+10 w320 R10", "interactive_tutorial_text")
        this.guiPreviousButton := this.gui.Add("Button", "yp+150 w100", getLanguageArrayString("tutorialGUI_1"))
        this.guiPreviousButton.OnEvent("Click", (*) => this.previous())
        this.guiExitButton := this.gui.Add("Button", "xp+110 w100", getLanguageArrayString("tutorialGUI_2"))
        this.guiExitButton.OnEvent("Click", (*) => this.exit())
        this.guiNextButton := this.gui.Add("Button", "xp+110 w100", getLanguageArrayString("tutorialGUI_3"))
        this.guiNextButton.OnEvent("Click", (*) => this.next())
        this.guiStatusBar := this.gui.Add("StatusBar", , "interactive_tutorial_statusbar_text")
        this.guiStatusBar.SetIcon("shell32.dll", 278)
    }
    ; You can provide optional coordinates for the GUI to show up.
    start(pGuiX := unset, pGuiY := unset)
    {
        ; Both parameters are omitted.
        If (!IsSet(pGuiX) && !IsSet(pGuiY))
        {
            this.gui.Show()
        }
        ; Only one parameter is given and the other one is missing.
        Else If (!IsSet(pGuiX) || !IsSet(pGuiY))
        {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Make sure that either both (pGuiX and pGuiY) are given or omitted entirely.",
                "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            this.gui.Show()
        }
        Else
        {
            this.gui.Show("x" . pGuiX . " y" . pGuiY)
        }
        ; Setting this to 1 will reset the tutorial.
        this.currentStepIndex := 1
        ; Displays the first text and starts the first action.
        this.playStep(1)
    }
    next()
    {
        this.currentStepIndex++
        this.playStep(this.currentStepIndex)
    }
    previous()
    {
        this.currentStepIndex--
        this.playStep(this.currentStepIndex)
    }
    exit()
    {
        /*
        Executes a variety of actions when the user exits the tutorial (if there are any actions provided).
        This could be used to hide certain windows or to stop controls from being highlighted for instance.
        */
        For (action in this.exitActionArray)
        {
            action.Call()
        }
        this.gui.Hide()
    }
    playStep(pStepIndex)
    {
        ; Updates the status bar.
        this.guiStatusBar.SetText(getLanguageArrayString("tutorialGUI_4", this.currentStepIndex, this.textArray.Length))
        ; Enables and disables the buttons accordingly to the current step index.
        If (pStepIndex <= 1)
        {
            ; Disables the previous button because you cannot go any further back on the very first step.
            this.guiPreviousButton.Opt("+Disabled")
        }
        Else
        {
            this.guiPreviousButton.Opt("-Disabled")
        }
        If (pStepIndex >= this.textArray.Length)
        {
            ; Disables the next button because you cannot go any further on the very last step.
            this.guiNextButton.Opt("+Disabled")
        }
        Else
        {
            this.guiNextButton.Opt("-Disabled")
        }

        If (this.textArray.Has(pStepIndex))
        {
            this.guiText.Text := this.textArray.Get(pStepIndex)
        }
        Else
        {
            MsgBox("[" . A_ThisFunc . "()]`n`n[WARNING] Received an invalid text array index: [" . pStepIndex . "].",
                "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
        }
        If (this.actionArray.Has(pStepIndex))
        {
            this.actionArray.Get(pStepIndex).Call()
        }
        Else
        {
            MsgBox("[" . A_ThisFunc . "()]`n`n[WARNING] Received an invalid action array index: [" . pStepIndex . "].",
                "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
        }
    }
    /*
    This method adds a text for the user to read. Will be played along with the actions in the actionArray.
    Do not exceed a length of 10 lines or there will be graphical issues.
    */
    addText(pText)
    {
        this.textArray.Push(pText)
    }
    /*
    This method requires a function object. This should be a function from the code containing instructions for the interactive tutorial.
    You can create these objects by passing the following parameter "(*) => doSomething()" without the quotation marks.
    Our method in the code would be called "doSomething()" in this example.
    */
    addAction(pFuncObject)
    {
        ; Checks if the given data is a valid function object.
        Try
        {
            pFuncObject.IsOptional()
        }
        Catch
        {
            MsgBox("[" . A_ThisFunc . "()]`n`n[WARNING] Received an invalid function object.", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return
        }
        this.actionArray.Push(pFuncObject)
    }
    /*
    This method requires a function object. This should be a function from the code containing instructions for the interactive tutorial.
    You can create these objects by passing the following parameter "(*) => doSomething()" without the quotation marks.
    Our method in the code would be called "doSomething()" in this example.
    */
    addExitAction(pFuncObject)
    {
        ; Checks if the given data is a valid function object.
        Try
        {
            pFuncObject.IsOptional()
        }
        Catch
        {
            MsgBox("[" . A_ThisFunc . "()]`n`n[WARNING] Received an invalid function object.", "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            Return
        }
        this.exitActionArray.Push(pFuncObject)
    }
}