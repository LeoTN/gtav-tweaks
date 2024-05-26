#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

tutorials_onInit()
{

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
        this.textArray := Array()
        this.actionArray := Array()
        this.currentStepIndex := 1
        this.gui := Gui(, pTutorialTitle)
        this.guiText := this.gui.Add("Text", "yp+10 w320 R10", "interactive_tutorial_text")
        this.guiPreviousButton := this.gui.Add("Button", "yp+150 w100", "Previous")
        this.guiPreviousButton.OnEvent("Click", (*) => this.previous())
        this.guiExitButton := this.gui.Add("Button", "xp+110 w100", "Exit")
        this.guiExitButton.OnEvent("Click", (*) => this.exit())
        this.guiNextButton := this.gui.Add("Button", "xp+110 w100", "Next")
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
        this.gui.Destroy()
    }
    playStep(pStepIndex)
    {
        ; Updates the status bar.
        this.guiStatusBar.SetText("Step " . this.currentStepIndex . " / " . this.textArray.Length)
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
    ; This method adds a text for the user to read. Will be played along with the actions in the actionArray.
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
}