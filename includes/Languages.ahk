#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

languages_onInit() {
    global configFileLocation
    ; Check for sufficient tmpKeys in the main GUI script at the language menu, when adding more langues!
    global languageCodeMap := Map(
        "SYSTEM", A_Language,
        ; The english code isn't real, but setting it to "0000" will trigger the default language, which is English.
        "English", "0000",
        "Deutsch", "0407"
    )

    if (!FileExist(configFileLocation) || !checkConfigFileIntegrity(true)) {
        createDefaultConfigFile()
        ; When there is no config file, the script will try to use the system language. Basically the same as "SYSTEM".
        global completeLanguageArrayMap := createLanguageArrayMap(A_Language)
        return
    }
    for key, value in languageCodeMap {
        ; Tries to identify the language in the config file.
        if (InStr(readConfigFile("PREFERRED_LANGUAGE"), key)) {
            global completeLanguageArrayMap := createLanguageArrayMap(value)
            return
        }
    }
    ; This is a fail safe.
    global completeLanguageArrayMap := createLanguageArrayMap(A_Language)
    editConfigFile("PREFERRED_LANGUAGE", "SYSTEM")
}

/*
Creates complete strings out of language arrays. Sometimes we need dynamic values inside these strings, that's why we have
the pVar parameters to fill in those gaps.
@param completeLanguageArrayMapKey [String] Each text is stored in an array, which is then stored in the completeLanguageMap.
To define the specific text we want to access, we need to access the array inside the completeLanguageMap by giving it the right key value,
for example "mainGUI_1" to access the mainGUI_1 array.
@param pVar1-5 [String] Those are values, which will be dynamically added into the string. Only requirement is an emtpy space ("")
in the corresponding specificLanguageArray.
@returns [String] The complete string built from the specificLanguageArray including the empty spaces being replaced by the values
from the pVar parameters in order.
*/
getLanguageArrayString(completeLanguageArrayMapKey, pVar1 := "language_pVar1_unset", pVar2 := "language_pVar2_unset",
    pVar3 := "language_pVar3_unset", pVar4 := "language_pVar4_unset", pVar5 := "language_pVar5_unset") {
    global completeLanguageArrayMap
    ; These values are reversed because we use the Pop() method. If the first element is the last in the array, the Pop() method
    ; will insert the first value as the first filler into the completeLanguageArrayMap.
    varArray := [
        pVar5,
        pVar4,
        pVar3,
        pVar2,
        pVar1
    ]
    if (!completeLanguageArrayMap.Has(completeLanguageArrayMapKey)) {
        MsgBox("[" . A_ThisFunc . "()] [ERROR] Invalid key for completeLanguageArrayMap received: [" .
            completeLanguageArrayMapKey . "]",
            "GTAV Tweaks - [" . A_ThisFunc . "()]", "IconX 262144")
        return "A language error happened! [Invalid completeLanguageArrayMapKey!]"
    }
    ; This represents a specific array, which contains the complete content for one MsgBox or text field.
    specificCompleteLanguageArray := completeLanguageArrayMap.Get(completeLanguageArrayMapKey)
    ; This makes sure, that for every emtpy space ("") inside the specificCompleteLanguageArray, there is a value given to fill in.
    tmpVarArray := varArray.Clone()
    for (string in specificCompleteLanguageArray) {
        ; When there is an emtpy space, the varArray must contain a value to fill into that gap.
        if (string == "" && InStr(tmpVarArray.Pop(), "language_pVar", true)) {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Not enough pVar parameters given for this language array: ["
                . completeLanguageArrayMapKey . "]!",
                "GTAV Tweaks - [" . A_ThisFunc . "()]", "Icon! 262144")
            return "A language error happened! [Not enough pVar parameters received!]"
        }
    }

    ; We are using a copy of the language array, because if we fill in the gaps in the original array, we wouldn't be able
    ; to update the dynamic values again. This is because the empty spaces we use to determine the spots where to insert the
    ; pVar values are now filled.
    tmpSpecificCompleteLanguageArray := specificCompleteLanguageArray.Clone()
    ; Replaces all empty spaces with the values given in the varArray.
    loop (tmpSpecificCompleteLanguageArray.Length) {
        if (tmpSpecificCompleteLanguageArray.Get(A_Index) == "") {
            tmpSpecificCompleteLanguageArray[A_Index] := varArray.Pop()
        }
    }
    ; Builds the final string to display in a MsgBox or text field.
    for (string in tmpSpecificCompleteLanguageArray) {
        finalLanguageString .= string
        ; Looks at the end of the current string. If it ends with "[" or "]" or "`n",
        ; we should not add an emtpy space at the end.
        if (RegExMatch(string, "((\n|\[|\])+)$") || !tmpSpecificCompleteLanguageArray.Has(A_Index + 1)) {
            continue
        }
        ; Checks if the next string in the array starts not with "[" or "]" or "`n".
        ; If that's the case, we can safely add an emtpy space between them with no ugly missalignments.
        if (!RegExMatch(tmpSpecificCompleteLanguageArray.Get(A_Index + 1), "^((\n|\[|\])+)")) {
            finalLanguageString .= A_Space
        }
    }
    return finalLanguageString
}

/*
This functions creates an array for each textbox in their respective language.
Those arrays are returned in a map object for easier access.
Empty spaces ("") will then be filled by using the pVar parameters of the getLanguageArrayString() function.
The function mentioned above also creates a complete string out of the array.
@param pLanguageCode [int] Should be a valid language code to define which language will be used for the text elements.
@returns [Map] A map object containing the languageArrays for the language specified with the pLanguageCode parameter.
*/
createLanguageArrayMap(pLanguageCode) {
    ; See AutoHotkey documentation "A_Language" for more information.
    /*
    +++++++++++++++
    German_Standard
    +++++++++++++++
    */
    if (pLanguageCode == "0407") {
        ; Main GUI
        ; ********
        mainGUI_1 := [
            "Diese Einstellungen werden automatisch gespeichert."
        ]
        mainGUI_2 := [
            "Startverhalten"
        ]
        mainGUI_3 := [
            "Mit GTA starten"
        ]
        mainGUI_4 := [
            "Minimiert im Infobereich starten"
        ]
        mainGUI_5 := [
            "Startnachricht anzeigen"
        ]
        mainGUI_6 := [
            "Auf verfügbare Updates prüfen"
        ]
        mainGUI_7 := [
            "Ich möchte Beta-Versionen erhalten"
        ]
        mainGUI_8 := [
            "Spieloptionen"
        ]
        mainGUI_9 := [
            "GTA während des Starts stummschalten"
        ]
        mainGUI_10 := [
            "Priorität des GTA Prozesses erhöhen [WIP]"
        ]
        mainGUI_11 := [
            "Nachricht beim Start von GTA anzeigen"
        ]
        mainGUI_12 := [
            "Das Skript minimieren beim Schließen dieses Fensters"
        ]
        mainGUI_13 := [
            "Hovere über ein Kontrollkästchen für weitere Informationen"
        ]
        ; Main GUI menus
        ; **************
        mainGUIMenu_1 := [
            "Datei"
        ]
        mainGUIMenu_2 := [
            "Optionen"
        ]
        mainGUIMenu_3 := [
            "Hotkeys && Makros"
        ]
        mainGUIMenu_4 := [
            "Hilfe"
        ]
        ; Main GUI file menu
        ; ******************
        mainGUIFileMenu_1 := [
            "Öffnen"
        ]
        mainGUIFileMenu_2 := [
            "Zurücksetzen"
        ]
        ; Main GUI file menu sub menu 1
        mainGUIFileSubMenu1_1 := [
            "Konfigurationsdatei"
        ]
        mainGUIFileSubMenu1_2 := [
            "Makrokonfigurationsdatei"
        ]
        mainGUIFileSubMenu1_3 := [
            "Skript-Stammverzeichnis"
        ]
        mainGUIFileSubMenu1_4 := [
            "Skript-Arbeitsverzeichnis"
        ]
        ; Main GUI file menu sub menu 2
        mainGUIFileSubMenu2_1 := [
            "Konfigurationsdatei"
        ]
        ; Main GUI options menu
        ; *********************
        mainGUIOptionsMenu_1 := [
            "Skript beenden"
        ]
        mainGUIOptionsMenu_2 := [
            "Skript neu laden"
        ]
        mainGUIOptionsMenu_3 := [
            "Sprache"
        ]
        mainGUIOptionsMenu_4 := [
            "Update erzwingen"
        ]
        mainGUIOptionsMenu_5 := [
            "Desktopverknüpfung erstellen"
        ]
        ; Main GUI info menu
        ; ******************
        mainGUIHelpMenu_1 := [
            "language_string_unused"
        ]
        mainGUIHelpMenu_2 := [
            "Dieses Repository (gtav-tweaks)"
        ]
        mainGUIHelpMenu_3 := [
            "language_string_unused"
        ]
        mainGUIHelpMenu_4 := [
            "README-Datei"
        ]
        mainGUIHelpMenu_5 := [
            "Hilfsdatenbank"
        ]
        ; Main GUI tooltips
        ; #################
        mainGUIToolTip_1 := [
            "Startet das Skript zusammen mit GTA."
        ]
        mainGUIToolTip_2 := [
            "Startet das Skript ohne das Hauptfenster zu öffnen.",
            "Klicke doppelt auf das Tray Icon um es trotzdem zu öffnen."
        ]
        mainGUIToolTip_3 := [
            "Zeigt mit Hilfe einer Nachricht an, dass das Skript gestartet wurde."
        ]
        mainGUIToolTip_4 := [
            "Versucht beim Start neue Updates zu finden."
        ]
        mainGUIToolTip_5 := [
            "Hiermit kann das Skript auf die aktuellste Beta Version updaten.",
            "Um auf die neuste Vollversion (zurück) zu kommen,",
            "deaktiviere diese Option und führe ein erzwungenes Update durch."
        ]
        mainGUIToolTip_6 := [
            "Schaltet das Spiel im Ladebildschirm stumm.",
            "Sobald du das Spielen beginnst, wird der Ton wieder aktiviert."
        ]
        mainGUIToolTip_7 := [
            "Im Moment nicht implementiert [WIP]."
        ]
        mainGUIToolTip_8 := [
            "Zeigt mit Hilfe einer Nachricht an, dass GTA V gestartet wurde."
        ]
        mainGUIToolTip_9 := [
            "Minimiert das Skript anstatt es beim Schließen des Hauptfensters zu beenden."
        ]
        ; Hotkey Overview GUI
        ; ###################
        hotkeyOverviewGUI_1 := [
            "GTAV Tweaks - Hotkey Übersicht"
        ]
        hotkeyOverviewGUI_2 := [
            "Hotkey Gesamtanzahl:",
            ""
        ]
        hotkeyOverviewGUI_3 := [
            "Hotkey"
        ]
        hotkeyOverviewGUI_4 := [
            "Beschreibung"
        ]
        hotkeyOverviewGUI_5 := [
            "Wähle unten ein Hotkey aus."
        ]
        hotkeyOverviewGUI_6 := [
            "Hotkey aktiviert"
        ]
        hotkeyOverviewGUI_7 := [
            "Hotkey deaktiviert"
        ]
        hotkeyOverviewGUI_8 := [
            "Status umschalten"
        ]
        hotkeyOverviewGUI_9 := [
            "Alle aktivieren"
        ]
        hotkeyOverviewGUI_10 := [
            "Alle deaktivieren"
        ]
        hotkeyOverviewGUI_11 := [
            "Hotkey erstellen"
        ]
        hotkeyOverviewGUI_12 := [
            "Bearbeiten"
        ]
        hotkeyOverviewGUI_13 := [
            "Löschen"
        ]
        ; Hotkey Overview GUI Tooltips
        ; ############################
        hotkeyOverviewGUITooltip_1 := [
            "Aktiviert oder deaktiviert den ausgewählten Hotkey."
        ]
        ; New Custom Hotkey GUI
        ; #####################
        newCustomHotkeyGUI_1 := [
            "GTAV Tweaks - Neuer Hotkey"
        ]
        newCustomHotkeyGUI_2 := [
            "Hotkey Name"
        ]
        newCustomHotkeyGUI_3 := [
            "Hotkey"
        ]
        newCustomHotkeyGUI_4 := [
            "Beschreibung"
        ]
        newCustomHotkeyGUI_5 := [
            "Makrodatei Speicherort"
        ]
        newCustomHotkeyGUI_6 := [
            "Wie bekomme ich Makrodateien?"
        ]
        newCustomHotkeyGUI_7 := [
            "Hotkey speichern"
        ]
        newCustomHotkeyGUI_8 := [
            "Schließen"
        ]
        newCustomHotkeyGUI_9 := [
            "Makro aufzeichnen"
        ]
        ; Info & Help GUI
        ; ###############
        infoAndHelpGUI_1 := [
            "GTAV Tweaks - Info & Hilfe"
        ]
        infoAndHelpGUI_2 := [
            "Suchleiste"
        ]
        infoAndHelpGUI_3 := [
            "Skript Infos"
        ]
        ; We need to take this extra step because there would be a gap between href= and the url (href= "url_here"), which breaks the link.
        ; The same goes for the space after the url ends.
        infoAndHelpGUI_4 := [
            'Version: <a href="replace_space_after',
            "",
            '">',
            "",
            'replace_space_before</a>'
        ]
        ; We need to take this extra step because there would be a gap between href= and the url (href= "url_here"), which breaks the link.
        ; The same goes for the space after the url ends.
        infoAndHelpGUI_5 := [
            '<a href="replace_space_after',
            "",
            'replace_space_before">Feature vorschlagen</a> oder <a href="replace_space_after',
            "",
            'replace_space_before">Bugreport</a>'
        ]
        infoAndHelpGUI_6 := [
            "Doppelt auf einen Eintrag klicken zum Öffnen."
        ]
        infoAndHelpGUIListView_1 := [
            "Thema"
        ]
        infoAndHelpGUIListView_2 := [
            "Typ"
        ]
        infoAndHelpGUIListView_3 := [
            "Titel"
        ]
        infoAndHelpGUIListView_4 := [
            "Keine Ergebnisse gefunden."
        ]
        ; Interactive Tutorial GUI
        ; ########################
        tutorialGUI_1 := [
            "Zurück"
        ]
        tutorialGUI_2 := [
            "Beenden"
        ]
        tutorialGUI_3 := [
            "Weiter"
        ]
        tutorialGUI_4 := [
            "Schritt",
            "",
            "/",
            ""
        ]
        ; Reload & Terminate GUI
        ; ######################
        reloadAndTerminateGUI_1 := [
            "GTAV Tweaks - Skript wird neu geladen"
        ]
        reloadAndTerminateGUI_2 := [
            "Das Skript wird in",
            "",
            "Sekunde(n) neu geladen."
        ]
        reloadAndTerminateGUI_3 := [
            "Das Skript wurde neu geladen."
        ]
        reloadAndTerminateGUI_4 := [
            "GTAV Tweaks - Skript wird beendet"
        ]
        reloadAndTerminateGUI_5 := [
            "Das Skript wird in",
            "",
            "Sekunde(n) beendet."
        ]
        reloadAndTerminateGUI_6 := [
            "Das Skript wurde beendet."
        ]
        reloadAndTerminateGUI_7 := [
            "Okay"
        ]
        reloadAndTerminateGUI_8 := [
            "Abbrechen"
        ]
        ; General Script TrayTips
        ; #######################
        generalScriptTrayTip1_1 := [
            "Aktive GTA V Instanz gefunden."
        ]
        generalScriptTrayTip1_2 := [
            "GTAV Tweaks - Status"
        ]
        generalScriptTrayTip2_1 := [
            "GTAV Tweaks gestartet."
        ]
        generalScriptTrayTip2_2 := [
            "GTAV Tweaks - Status"
        ]
        generalScriptTrayTip3_1 := [
            "GTAV Tweaks beendet."
        ]
        generalScriptTrayTip3_2 := [
            "GTAV Tweaks - Status"
        ]
        generalScriptTrayTip4_1 := [
            "Es wurde eine Desktopverknüpfung erstellt oder aktualisiert."
        ]
        generalScriptTrayTip4_2 := [
            "GTAV Tweaks - Status"
        ]
        ; Macro Recorder TrayTips
        ; #######################
        macroRecorderTrayTip1_1 := [
            "Drücke [",
            "",
            "] um die Aufnahme zu beenden."
        ]
        macroRecorderTrayTip1_2 := [
            "Makro Aufnahme gestartet"
        ]
        macroRecorderTrayTip2_1 := [
            "Datei gespeichert unter [",
            "",
            "]."
        ]
        macroRecorderTrayTip2_2 := [
            "Makro Aufnahme gestoppt"
        ]
        ; General Script MsgBoxes
        ; #######################
        generalScriptMsgBox1_1 := [
            "Skript beendet."
        ]
        generalScriptMsgBox1_2 := [
            "GTAV Tweaks - Skriptstatus"
        ]
        generalScriptMsgBox2_1 := [
            "Du nutzt eine unkompilierte Version dieses Skripts.",
            "`n`nDiese Aktion ist daher nicht möglich."
        ]
        generalScriptMsgBox2_2 := [
            "GTAV Tweaks - Unkompilierte Version"
        ]
        ; Config File MsgBoxes
        ; ####################
        configFileMsgBox1_1 := [
            "Willst du wirklich die aktuelle Konfigurationsdatei durch eine neue ersetzen?"
        ]
        configFileMsgBox1_2 := [
            "GTAV Tweaks - Konfigurationsdatei ersetzen"
        ]
        configFileMsgBox2_1 := [
            "Es wurde eine Standardkonfigurationsdatei generiert."
        ]
        configFileMsgBox2_2 := [
            "GTAV Tweaks - Konfigurationsdateistatus - Information"
        ]
        configFileMsgBox3_1 := [
            "Bitte prüfe den Pfad in der Konfigurationsdatei unter`n[",
            "",
            "] auf seine Gültigkeit!"
        ]
        configFileMsgBox3_2 := [
            "GTAV Tweaks - Konfigurationsdateistatus - Fehler"
        ]
        configFileMsgBox4_1 := [
            "Der Schlüssel [",
            "",
            "] konnte in der Konfigurationsdatei nicht gefunden werden.",
            "`nSkript beendet."
        ]
        configFileMsgBox4_2 := [
            "GTAV Tweaks - Konfigurationsdateistatus - Fehler"
        ]
        configFileMsgBox5_1 := [
            "Die Skriptkonfigurationsdatei scheint beschädigt oder nicht verfügbar zu sein!`n`n",
            "Möchtest du eine neue mit der Vorlage erstellen?"
        ]
        configFileMsgBox5_2 := [
            "GTAV Tweaks - Konfigurationsdateistatus - Warnung"
        ]
        configFileMsgBox6_1 := [
            "Das Verzeichnis`n[",
            "",
            "] existiert nicht.",
            "`n`nSoll es erstellt werden?"
        ]
        configFileMsgBox6_2 := [
            "GTAV Tweaks - Konfigurationsdateistatus - Warnung"
        ]
        ; Custom Hotkey Overview GUI MsgBoxes
        ; ###################################
        customHotkeyOverviewGUIMsgBox1_1 := [
            "Bist du sicher, dass du diesen Hotkey löschen möchtest?"
        ]
        customHotkeyOverviewGUIMsgBox1_2 := [
            "GTAV Tweaks - Hotkey löschen"
        ]
        ; Functions MsgBoxes
        ; ##################
        functionsMsgBox1_1 := [
            "Es ist ein Update verfügbar.`n`nUpdate von [",
            "",
            "] auf [",
            "",
            "] jetzt durchführen?"
        ]
        functionsMsgBox1_2 := [
            "GTAV Tweaks - Update verfügbar"
        ]
        functionsMsgBox2_1 := [
            "Keine README-Datei gefunden."
        ]
        functionsMsgBox2_2 := [
            "GTAV Tweaks - Fehlende README-Datei"
        ]
        functionsMsgBox3_1 := [
            "Möchtest du eine Desktopverknüpfung erstellen?"
        ]
        functionsMsgBox3_2 := [
            "GTAV Tweaks - Desktopverknüpfung erstellen"
        ]
        ; Main GUI MsgBoxes
        ; #################
        mainGUIMsgBox1_1 := [
            "Sieht aus, als hätte jemand ein Easter Egg gefunden!`n`nEs scheint, als magst du das Testen genau wie mein Freund,",
            "der mir sehr hilft indem er dieses Skript für mich testet.`n`nDanke Elias!"
        ]
        mainGUIMsgBox1_2 := [
            "Was ist das?"
        ]
        mainGUIMsgBox2_1 := [
            "Damit wird das Skript dazu gezwungen, auf die höchste verfügbare Version zu aktualisieren, abhängig von deinen Update-Einstellungen.",
            "`n`nEs wird sogar aktualisiert, wenn die aktuelle Version bereits die neueste ist.",
            "`n`nDas Update sollte ca. 5-15 Sekunden nach dem Bestätigen starten."
        ]
        mainGUIMsgBox2_2 := [
            "GTAV Tweaks - Update erzwingen"
        ]
        ; New Custom Hotkey GUI MsgBoxes
        ; ##############################
        newCustomHotkeyOverviewGUIMsgBox1_1 := [
            "Bitte gib einen Namen für deinen Hotkey ein."
        ]
        newCustomHotkeyOverviewGUIMsgBox1_2 := [
            "GTAV Tweaks - Fehlender Hotkey-Name"
        ]
        newCustomHotkeyOverviewGUIMsgBox2_1 := [
            "Bitte gib eine Tastenkombination für deinen Hotkey ein."
        ]
        newCustomHotkeyOverviewGUIMsgBox2_2 := [
            "GTAV Tweaks - Fehlende Tastenkombination für Hotkey"
        ]
        newCustomHotkeyOverviewGUIMsgBox3_1 := [
            "Deine Makrodatei existiert nicht."
        ]
        newCustomHotkeyOverviewGUIMsgBox3_2 := [
            "GTAV Tweaks - Fehlende Makrodatei für Hotkey"
        ]
        newCustomHotkeyOverviewGUIMsgBox4_1 := [
            "Bitte wähle eine gültige Makrodatei aus."
        ]
        newCustomHotkeyOverviewGUIMsgBox4_2 := [
            "GTAV Tweaks - Ungültiger Speicherort der Makrodatei"
        ]
        newCustomHotkeyOverviewGUIMsgBox5_1 := [
            "Was ist ein Makro?`n`nEin Makro ist eine automatisierte Sequenz von Tastenanschlägen und Mausbewegungen, die du vorher aufzeichnest",
            "und dann abspielst."
        ]
        newCustomHotkeyOverviewGUIMsgBox5_2 := [
            "GTAV Tweaks - Was ist ein Makro"
        ]
        newCustomHotkeyOverviewGUIMsgBox6_1 := [
            "Um die Aufzeichnung eines Makros zu starten, Drücke die`n[",
            "",
            "] Taste, nachdem du [Makro aufzeichnen] geklickt hast.`n`nDie Makrodatei wird dann unter`n[",
            "",
            "]`ngespeichert und mit dem aktuellen Zeitstempel benannt."
        ]
        newCustomHotkeyOverviewGUIMsgBox6_2 := [
            "GTAV Tweaks - Wie zeichne ich Makros auf"
        ]
        newCustomHotkeyOverviewGUIMsgBox7_1 := [
            "Beim Aufzeichnen von Makros wird das Scrollen mit dem Mausrad nicht aufgezeichnet.`n`n",
            "Es wird empfohlen, Aktionen langsamer als üblich auszuführen, um sicherzustellen, dass das Makro am Ende funktioniert."
        ]
        newCustomHotkeyOverviewGUIMsgBox7_2 := [
            "GTAV Tweaks - Tipps zur Makroaufzeichnung"
        ]
        newCustomHotkeyOverviewGUIMsgBox8_1 := [
            "Weitere Informationen findest du in den FAQ in der README.txt-Datei.`n`n",
            "Drücke [Ja], um sie zu öffnen."
        ]
        newCustomHotkeyOverviewGUIMsgBox8_2 := [
            "GTAV Tweaks - Makro-FAQ"
        ]
        newCustomHotkeyOverviewGUIMsgBox9_1 := [
            "Du hast 15 Sekunden nach dem Schließen dieser Info-Box Zeit, um mit der Aufzeichnung zu beginnen indem du [",
            "",
            "] drückst.`n`nUm die Aufzeichnung zu stoppen, drücke einfach [",
            "",
            "] erneut."
        ]
        newCustomHotkeyOverviewGUIMsgBox9_2 := [
            "GTAV Tweaks - Manuelle Makroaufzeichnung"
        ]
        ; Object MsgBoxes
        ; ###############
        objectsMsgBox1_1 := [
            "Fehler beim Importieren des benutzerdefinierten Hotkeys [",
            "",
            "]!`n`nDer Makrodateipfad`n[",
            "",
            "]`nkonnte nicht zum angenommenen neuen Speicherort der Makrodatei`n[",
            "",
            "].`numgewandelt werden.`n`nDu musst die Makrodatei für diesen Hotkey manuell auswählen,",
            "indem du sie über das Hotkey Übersichtsfenster bearbeitest."
        ]
        objectsMsgBox1_2 := [
            "GTAV Tweaks - Hotkey Autoimport - Fehler"
        ]
        objectsMsgBox2_1 := [
            "Dieser Name wird bereits von einem anderen Hotkey verwendet: [",
            "",
            "]."
        ]
        objectsMsgBox2_2 := [
            "GTAV Tweaks - Doppelter Hotkey Name"
        ]
        objectsMsgBox3_1 := [
            "Dieser Tastaturkürzel wird bereits von einem anderen Hotkey verwendet: [",
            "",
            "]."
        ]
        objectsMsgBox3_2 := [
            "GTAV Tweaks - Doppelter Hotkey Tastaturkürzel"
        ]
        objectsMsgBox4_1 := [
            "Hotkey erfolgreich gespeichert!"
        ]
        objectsMsgBox4_2 := [
            "GTAV Tweaks - Status der Hotkey Datenbank"
        ]
        ; Tutorial MsgBoxes
        ; #################
        ; Start and stop tutorial MsgBoxes.
        tutorialMsgBox1_1 := [
            "Möchtest du ein kurzes Tutorial darüber haben, wie du diese Software benutzt?"
        ]
        tutorialMsgBox1_2 := [
            "GTAV Tweaks - Tutorial Starten"
        ]
        tutorialMsgBox2_1 := [
            "Drücke [Ja], um das Tutorial",
            "beim nächsten Mal, wenn du dieses Skript ausführst zu deaktivieren."
        ]
        tutorialMsgBox2_2 := [
            "GTAV Tweaks - Tutorial Deaktivieren für das Nächste Mal"
        ]
        tutorialMsgBox3_1 := [
            "Hey! Danke, dass du diese Software installiert hast!",
            "`n`nDamit kannst du deine eigenen Makros für GTA V mit deinen eigenen Hotkeys erstellen.",
            "`n`nEs gibt noch ein paar andere Funktionen, aber fangen wir an.",
            "`n`nDrücke [Okay] zum fortfahren."
        ]
        tutorialMsgBox3_2 := [
            "GTAV Tweaks - Danke fürs Installieren"
        ]
        ; This string (which is technically an array in this form) will be converted into an array later on.
        tutorialSearchBarDemoArrayString :=
            [
                "E,r,s,t,e, ,S,c,h,r,i,t,t,e"
            ]
        ; How To Use Help GUI TUTORIAL
        ; ############################
        tutorialHowToUseHelpGUI_1_2 := [
            "Allgemein"
        ]
        tutorialHowToUseHelpGUI_2_2 := [
            "Tutorial"
        ]
        tutorialHowToUseHelpGUI_3_2 := [
            "Wie man die Hilfsdatenbank nutzt"
        ]
        tutorialHowToUseHelpGUI_1_1 := [
            "Dieses Tutorial zeigt dir im Grunde nur, wie du an weitere Infos und Hilfe kommst."
        ]
        tutorialHowToUseHelpGUI_2_1 := [
            "Zum Öffnen der Hilfsdatenbank musst du lediglich auf das [Hilfe] Menü klicken."
        ]
        tutorialHowToUseHelpGUI_3_1 := [
            "Du kannst diese Einträge mit Hilfe der Suchleiste durchsuchen (markiert durch einen roten Rahmen)."
        ]
        tutorialHowToUseHelpGUI_4_1 := [
            "Klicke doppelt auf einen Eintrag, um ein interaktives Tutorial oder einen simplen Infotext zu starten."
        ]
        ; This string (which is technically an array in this form) will be converted into an array later on.
        tutorialSearchBarDemoArrayString :=
            [
                "E,r,s,t,e, ,S,c,h,r,i,t,t,e"
            ]
        ; How To Record Macros TUTORIAL
        ; #############################
        tutorialHowToRecordMacros_1_2 := [
            "Makros"
        ]
        tutorialHowToRecordMacros_2_2 := [
            "Tutorial"
        ]
        tutorialHowToRecordMacros_3_2 := [
            "Wie man Makros aufnimmt"
        ]
        tutorialHowToRecordMacros_1_1 := [
            "Zuerst muss das [Hotkey Übersicht] Fenster geöffnet werden.`n`n",
            "Du kannst dazu das [Hotkey && Makros] Menü im Hauptfenster anklicken."
        ]
        tutorialHowToRecordMacros_2_1 := [
            "Dort angekommen, musst du auf den [Hotkey erstellen] Knopf drücken."
        ]
        tutorialHowToRecordMacros_3_1 := [
            "Um den Aufnahmeprozess zu starten, musst du lediglich den [Makro aufzeichnen] Knopf drücken."
        ]
        ; Getting Started TUTORIAL
        ; #############################
        tutorialGettingStarted_1_2 := [
            "Allgemein"
        ]
        tutorialGettingStarted_2_2 := [
            "Tutorial"
        ]
        tutorialGettingStarted_3_2 := [
            "Erste Schritte"
        ]
        tutorialGettingStarted_1_1 := [
            "Sieh dir bei Gelegenheit mal die Optionen im Hauptfenster an.",
            "`n`nHovere mit dem Mauszeiger über eine Option, um weiter Informationen zu erhalten."
        ]
        tutorialGettingStarted_2_1 := [
            "Das [Optionen] Menü stellt eine Reihe von Funktionen bereit.`n`nDu kannst dort zum Beispiel die Skriptsprache ändern."
        ]
        tutorialGettingStarted_3_1 := [
            "Nutze das [Datei] Menü, um die Skript-Konfigurationsdatei und weitere Dinge zu öffnen."
        ]
        tutorialGettingStarted_4_1 := [
            "Weitere Information zum Thema Hotkeys und Makros kannst du in der Hilfsdatenbank finden."
        ]
        ; Built-in Hotkey Description
        ; #########################
        builtInHotkeyDescription_1 := [
            "Hält die W Taste gedrücket und sendet hin und wieder Numpad Up.",
            "Dieser Hotkey eignet sich zum Beispiel gut zum AFK Laufen, Fahren oder Fliegen von Flugzeugen.",
            "Wenn der Hotkey erneut gedrücket wird, werden die Tasten losgelassen.",
            ; The empty space is intended.
            " [Das hier ist ein eingebauter Hotkey]"
        ]
        builtInHotkeyDescription_2 := [
            "Pausiert den GTAV Prozess und erstellt somit eine Sololobby.",
            ; The empty space is intended.
            " [Das hier ist ein eingebauter Hotkey]"
        ]
    }
    ; The fallback language is english.
    else {
        ; Main GUI
        ; ########
        mainGUI_1 := [
            "Changes will be applied automatically."
        ]
        mainGUI_2 := [
            "Startup Behavior"
        ]
        mainGUI_3 := [
            "Start with GTA"
        ]
        mainGUI_4 := [
            "Launch minimized to tray"
        ]
        mainGUI_5 := [
            "Display a launch message"
        ]
        mainGUI_6 := [
            "Check for available updates"
        ]
        mainGUI_7 := [
            "I want to receive beta versions"
        ]
        mainGUI_8 := [
            "Game Options"
        ]
        mainGUI_9 := [
            "Mute GTA during launch"
        ]
        mainGUI_10 := [
            "Increase GTA process priority [WIP]"
        ]
        mainGUI_11 := [
            "Display message when launching GTA"
        ]
        mainGUI_12 := [
            "Minimize to tray when closing this window"
        ]
        mainGUI_13 := [
            "Hover over any checkbox to get additional information"
        ]
        ; Main GUI menus
        ; **************
        mainGUIMenu_1 := [
            "File"
        ]
        mainGUIMenu_2 := [
            "Options"
        ]
        mainGUIMenu_3 := [
            "Hotkeys && Macros"
        ]
        mainGUIMenu_4 := [
            "Help"
        ]
        ; Main GUI file menu
        ; ******************
        mainGUIFileMenu_1 := [
            "Open"
        ]
        mainGUIFileMenu_2 := [
            "Reset"
        ]
        ; Main GUI file menu sub menu 1
        mainGUIFileSubMenu1_1 := [
            "Config File"
        ]
        mainGUIFileSubMenu1_2 := [
            "Macro Config File"
        ]
        mainGUIFileSubMenu1_3 := [
            "Script Parent Directory"
        ]
        mainGUIFileSubMenu1_4 := [
            "Script Working Directory"
        ]
        ; Main GUI file menu sub menu 2
        mainGUIFileSubMenu2_1 := [
            "Config File"
        ]
        ; Main GUI options menu
        ; *********************
        mainGUIOptionsMenu_1 := [
            "Terminate Script"
        ]
        mainGUIOptionsMenu_2 := [
            "Reload Script"
        ]
        mainGUIOptionsMenu_3 := [
            "Language"
        ]
        mainGUIOptionsMenu_4 := [
            "Force Update"
        ]
        mainGUIOptionsMenu_5 := [
            "Create Desktop Shortcut"
        ]
        ; Main GUI info menu
        ; ******************
        mainGUIHelpMenu_1 := [
            "language_string_unused"
        ]
        mainGUIHelpMenu_2 := [
            "This repository (gtav-tweaks)"
        ]
        mainGUIHelpMenu_3 := [
            "language_string_unused"
        ]
        mainGUIHelpMenu_4 := [
            "README File"
        ]
        mainGUIHelpMenu_5 := [
            "Help database"
        ]
        ; Main GUI tooltips
        ; #################
        mainGUIToolTip_1 := [
            "Launches the script together with GTA."
        ]
        mainGUIToolTip_2 := [
            "Launches the script without showing the main window.",
            "You can still access it by double-clicking the tray icon."
        ]
        mainGUIToolTip_3 := [
            "Displays a little message which indicates that the script has been launched."
        ]
        mainGUIToolTip_4 := [
            "Tries to find new updates when launching the script."
        ]
        mainGUIToolTip_5 := [
            "This allows the script to receive the latest beta version updates.",
            "Disable this checkbox and force update the script to return to the latest full version."
        ]
        mainGUIToolTip_6 := [
            "Mutes the game while it's in the loading screen. Once you start playing it will unmute."
        ]
        mainGUIToolTip_7 := [
            "Currently not implemented [WIP]."
        ]
        mainGUIToolTip_8 := [
            "Displays a little message which indicates that GTA V has been launched."
        ]
        mainGUIToolTip_9 := [
            "Minimizes the script instead of exiting it when closing the main window."
        ]
        ; Hotkey Overview GUI
        ; ###################
        hotkeyOverviewGUI_1 := [
            "GTAV Tweaks - Hotkey Overview"
        ]
        hotkeyOverviewGUI_2 := [
            "Total Hotkeys:",
            ""
        ]
        hotkeyOverviewGUI_3 := [
            "Keyboard Shortcut"
        ]
        hotkeyOverviewGUI_4 := [
            "Description"
        ]
        hotkeyOverviewGUI_5 := [
            "Select a hotkey below."
        ]
        hotkeyOverviewGUI_6 := [
            "Hotkey enabled"
        ]
        hotkeyOverviewGUI_7 := [
            "Hotkey disabled"
        ]
        hotkeyOverviewGUI_8 := [
            "Toggle Status"
        ]
        hotkeyOverviewGUI_9 := [
            "Enable all"
        ]
        hotkeyOverviewGUI_10 := [
            "Disable all"
        ]
        hotkeyOverviewGUI_11 := [
            "Create Hotkey"
        ]
        hotkeyOverviewGUI_12 := [
            "Edit"
        ]
        hotkeyOverviewGUI_13 := [
            "Delete"
        ]
        ; Hotkey Overview GUI Tooltips
        ; ############################
        hotkeyOverviewGUITooltip_1 := [
            "Enables or disables the selected hotkey."
        ]
        ; New Custom Hotkey GUI
        ; #####################
        newCustomHotkeyGUI_1 := [
            "GTAV Tweaks - New Hotkey"
        ]
        newCustomHotkeyGUI_2 := [
            "Hotkey Name"
        ]
        newCustomHotkeyGUI_3 := [
            "Keyboard Shortcut"
        ]
        newCustomHotkeyGUI_4 := [
            "Hotkey Description"
        ]
        newCustomHotkeyGUI_5 := [
            "Macro File Location"
        ]
        newCustomHotkeyGUI_6 := [
            "How do I get macro files?"
        ]
        newCustomHotkeyGUI_7 := [
            "Save Hotkey"
        ]
        newCustomHotkeyGUI_8 := [
            "Close"
        ]
        newCustomHotkeyGUI_9 := [
            "Record Macro"
        ]
        ; Info & Help GUI
        ; ###############
        infoAndHelpGUI_1 := [
            "GTAV Tweaks - Info & Help"
        ]
        infoAndHelpGUI_2 := [
            "Search Bar"
        ]
        infoAndHelpGUI_3 := [
            "Script Info"
        ]
        ; We need to take this extra step because there would be a gap between href= and the url (href= "url_here"), which breaks the link.
        ; The same goes for the space after the url ends.
        infoAndHelpGUI_4 := [
            'Version: <a href="replace_space_after',
            "",
            '">',
            "",
            'replace_space_before</a>'
        ]
        ; We need to take this extra step because there would be a gap between href= and the url (href= "url_here"), which breaks the link.
        ; The same goes for the space after the url ends.
        infoAndHelpGUI_5 := [
            '<a href="replace_space_after',
            "",
            'replace_space_before">Feature Request</a> or <a href="replace_space_after',
            "",
            'replace_space_before">Bug Report</a>'
        ]
        infoAndHelpGUI_6 := [
            "Double click an entry to access it's content."
        ]
        infoAndHelpGUIListView_1 := [
            "Topic"
        ]
        infoAndHelpGUIListView_2 := [
            "Type"
        ]
        infoAndHelpGUIListView_3 := [
            "Title"
        ]
        infoAndHelpGUIListView_4 := [
            "No results found."
        ]
        ; Interactive Tutorial GUI
        ; ########################
        tutorialGUI_1 := [
            "Previous"
        ]
        tutorialGUI_2 := [
            "Exit"
        ]
        tutorialGUI_3 := [
            "Next"
        ]
        tutorialGUI_4 := [
            "Step",
            "",
            "/",
            ""
        ]
        ; Reload & Terminate GUI
        ; ######################
        reloadAndTerminateGUI_1 := [
            "GTAV Tweaks - Reloading Script"
        ]
        reloadAndTerminateGUI_2 := [
            "The script will be`nreloaded in",
            "",
            "second(s)."
        ]
        reloadAndTerminateGUI_3 := [
            "The script has been reloaded."
        ]
        reloadAndTerminateGUI_4 := [
            "GTAV Tweaks - Terminating Script"
        ]
        reloadAndTerminateGUI_5 := [
            "The script will be`nterminated in",
            "",
            "second(s)."
        ]
        reloadAndTerminateGUI_6 := [
            "The script has been terminated."
        ]
        reloadAndTerminateGUI_7 := [
            "Okay"
        ]
        reloadAndTerminateGUI_8 := [
            "Cancel"
        ]
        ; General Script TrayTips
        ; #######################
        generalScriptTrayTip1_1 := [
            "Running GTA V instance detected."
        ]
        generalScriptTrayTip1_2 := [
            "GTAV Tweaks - Status"
        ]
        generalScriptTrayTip2_1 := [
            "GTAV Tweaks launched."
        ]
        generalScriptTrayTip2_2 := [
            "GTAV Tweaks - Status"
        ]
        generalScriptTrayTip3_1 := [
            "GTAV Tweaks terminated."
        ]
        generalScriptTrayTip3_2 := [
            "GTAV Tweaks - Status"
        ]
        generalScriptTrayTip4_1 := [
            "A desktop shortcut has been created or updated."
        ]
        generalScriptTrayTip4_2 := [
            "GTAV Tweaks - Status"
        ]
        ; Macro Recorder TrayTips
        ; #######################
        macroRecorderTrayTip1_1 := [
            "Press [",
            "",
            "] to stop recording."
        ]
        macroRecorderTrayTip1_2 := [
            "Macro recording started"
        ]
        macroRecorderTrayTip2_1 := [
            "File saved at [",
            "",
            "]."
        ]
        macroRecorderTrayTip2_2 := [
            "Macro recording stopped"
        ]
        ; General Script MsgBoxes
        ; #######################
        generalScriptMsgBox1_1 := [
            "Script terminated."
        ]
        generalScriptMsgBox1_2 := [
            "GTAV Tweaks - Script Status"
        ]
        generalScriptMsgBox2_1 := [
            "You are using an uncompiled version of this script.",
            "`n`nThis action is therefore not possible."
        ]
        generalScriptMsgBox2_2 := [
            "GTAV Tweaks - Uncompiled Version"
        ]
        ; Config File MsgBoxes
        ; #####################
        configFileMsgBox1_1 := [
            "Do you really want to replace the current config file with a new one ?"
        ]
        configFileMsgBox1_2 := [
            "GTAV Tweaks - Replace Config File"
        ]
        configFileMsgBox2_1 := [
            "A default config file has been generated."
        ]
        configFileMsgBox2_2 := [
            "GTAV Tweaks - Config File Status - Information"
        ]
        configFileMsgBox3_1 := [
            "Check the config file for a valid path at`n[",
            "",
            "]!"
        ]
        configFileMsgBox3_2 := [
            "GTAV Tweaks - Config File Status - Error"
        ]
        configFileMsgBox4_1 := [
            "Unable to find key [",
            "",
            "] in the config file.",
            "`nScript terminated."
        ]
        configFileMsgBox4_2 := [
            "GTAV Tweaks - Config File Status - Error"
        ]
        configFileMsgBox5_1 := [
            "The script config file seems to be corrupted or unavailable!`n`n",
            "Do you want to create a new one using the template?"
        ]
        configFileMsgBox5_2 := [
            "GTAV Tweaks - Config File Status - Warning"
        ]
        configFileMsgBox6_1 := [
            "The directory`n[",
            "",
            "] does not exist.",
            "`n`nWould you like to create it?"
        ]
        configFileMsgBox6_2 := [
            "GTAV Tweaks - Config File Status - Warning"
        ]
        ; Custom Hotkey Overview GUI MsgBoxes
        ; ###################################
        customHotkeyOverviewGUIMsgBox1_1 := [
            "Are you sure, that you want to delete this hotkey?"
        ]
        customHotkeyOverviewGUIMsgBox1_2 := [
            "GTAV Tweaks - Delete Hotkey"
        ]
        ; Functions MsgBoxes
        ; ##################
        functionsMsgBox1_1 := [
            "There is an update available.`n`nUpdate from [",
            "",
            "] to [",
            "",
            "] now?"
        ]
        functionsMsgBox1_2 := [
            "GTAV Tweaks - Update Available"
        ]
        functionsMsgBox2_1 := [
            "No README file found."
        ]
        functionsMsgBox2_2 := [
            "GTAV Tweaks - Missing README File"
        ]
        functionsMsgBox3_1 := [
            "Woukd you like to create a desktop shortcut?"
        ]
        functionsMsgBox3_2 := [
            "GTAV Tweaks - Create Desktop Shortcut"
        ]
        ; Main GUI MsgBoxes
        ; #################
        mainGUIMsgBox1_1 := [
            "Looks like some found an easter egg!`n`nIt seems you like testing, just like my friend",
            "who helps me a lot by testing this script for me.`n`nThank you Elias!"
        ]
        mainGUIMsgBox1_2 := [
            "What's that?"
        ]
        mainGUIMsgBox2_1 := [
            "This will force the script to update to the highest available version, depending on your update settings.",
            "`n`nIt will even update when the current version is the highest.",
            "`n`nThe update should start 5-15 seconds after confirming."
        ]
        mainGUIMsgBox2_2 := [
            "GTAV Tweaks - Force Update"
        ]
        ; New Custom Hotkey GUI MsgBoxes
        ; ##############################
        newCustomHotkeyOverviewGUIMsgBox1_1 := [
            "Please enter a name for your hotkey."
        ]
        newCustomHotkeyOverviewGUIMsgBox1_2 := [
            "GTAV Tweaks - Missing Hotkey Name"
        ]
        newCustomHotkeyOverviewGUIMsgBox2_1 := [
            "Please provide a keyboard shortcut for your hotkey."
        ]
        newCustomHotkeyOverviewGUIMsgBox2_2 := [
            "GTAV Tweaks - Missing Hotkey Keyboard Shortcut"
        ]
        newCustomHotkeyOverviewGUIMsgBox3_1 := [
            "You macro file does not exist."
        ]
        newCustomHotkeyOverviewGUIMsgBox3_2 := [
            "GTAV Tweaks - Missing Hotkey Macro File"
        ]
        newCustomHotkeyOverviewGUIMsgBox4_1 := [
            "Please select a valid macro file."
        ]
        newCustomHotkeyOverviewGUIMsgBox4_2 := [
            "GTAV Tweaks - Invalid Macro File Location"
        ]
        newCustomHotkeyOverviewGUIMsgBox5_1 := [
            "What is a macro?`n`nA macro is an automated sequence of keystrokes and mouse movements that you record",
            "beforehand and then play back."
        ]
        newCustomHotkeyOverviewGUIMsgBox5_2 := [
            "GTAV Tweaks - What Is A Macro"
        ]
        newCustomHotkeyOverviewGUIMsgBox6_1 := [
            "To start recording a macro, press the [",
            "",
            "] key after clicking [Record Macro].`n`nThe macro file will then be saved at`n[",
            "",
            "]`nand named with the current timestamp."
        ]
        newCustomHotkeyOverviewGUIMsgBox6_2 := [
            "GTAV Tweaks - How To Record Macros"
        ]
        newCustomHotkeyOverviewGUIMsgBox7_1 := [
            "When recording macros, please note that scrolling with the mouse wheel will not be recorded.`n`n",
            "It is recommended to perform actions slower than usual during recording to ensure the macro will work in the end."
        ]
        newCustomHotkeyOverviewGUIMsgBox7_2 := [
            "GTAV Tweaks - Macro Recording Tips"
        ]
        newCustomHotkeyOverviewGUIMsgBox8_1 := [
            "You can find additional information in the FAQ contained in the README.txt file.`n`n",
            "Press [Yes] to open it."
        ]
        newCustomHotkeyOverviewGUIMsgBox8_2 := [
            "GTAV Tweaks - Macro FAQ"
        ]
        newCustomHotkeyOverviewGUIMsgBox9_1 := [
            "You have 15 seconds after closing this info box to begin recording by pressing [",
            "",
            "]`n`nTo stop recording, simply press [",
            "",
            "] again."
        ]
        newCustomHotkeyOverviewGUIMsgBox9_2 := [
            "GTAV Tweaks - Macro Recording Manual"
        ]
        ; Object MsgBoxes
        ; ###############
        objectsMsgBox1_1 := [
            "Error while importing custom hotkey [",
            "",
            "]!`n`nCould not update macro file path`n[",
            "",
            "]`nto the assumed new macro file location`n[",
            "",
            "].`n`nYou will have to select the macro file for this hotkey manually by editing it via the custom hotkey overview window."
        ]
        objectsMsgBox1_2 := [
            "GTAV Tweaks - Hotkey Auto Import - Error"
        ]
        objectsMsgBox2_1 := [
            "This name is already used by another hotkey: [",
            "",
            "]."
        ]
        objectsMsgBox2_2 := [
            "GTAV Tweaks - Duplicate Hotkey Name"
        ]
        objectsMsgBox3_1 := [
            "This keyboard shortcut is already used by another hotkey: [",
            "",
            "]."
        ]
        objectsMsgBox3_2 := [
            "GTAV Tweaks - Duplicate Hotkey Keyboard Shortcut"
        ]
        objectsMsgBox4_1 := [
            "Hotkey saved successfully!"
        ]
        objectsMsgBox4_2 := [
            "GTAV Tweaks - Hotkey Operation Status"
        ]
        ; Tutorial MsgBoxes
        ; #################
        ; Start and stop tutorial MsgBoxes.
        tutorialMsgBox1_1 := [
            "Would you like to have a short tutorial on how to use this software?"
        ]
        tutorialMsgBox1_2 := [
            "GTAV Tweaks - Start Tutorial"
        ]
        tutorialMsgBox2_1 := [
            "Press [Yes] to disable the tutorial",
            "for the next time you run this script."
        ]
        tutorialMsgBox2_2 := [
            "GTAV Tweaks - Disable Tutorial for Next Time"
        ]
        tutorialMsgBox3_1 := [
            "Hey there! Thanks for installing this software!",
            "`n`nIt allows you to create your own macros for GTA V binded to your own keyboard shortcuts.",
            "`n`nThere are a few other functions additionally, but let's start the tutorial.",
            "`n`nPress [Okay] to continue."
        ]
        tutorialMsgBox3_2 := [
            "GTAV Tweaks - Thanks for Installing"
        ]
        ; How To Use Help GUI TUTORIAL
        ; ############################
        tutorialHowToUseHelpGUI_1_2 := [
            "General"
        ]
        tutorialHowToUseHelpGUI_2_2 := [
            "Tutorial"
        ]
        tutorialHowToUseHelpGUI_3_2 := [
            "How to use the help database"
        ]
        tutorialHowToUseHelpGUI_1_1 := [
            "This tutorial will basically teach you how to find more tutorials and information."
        ]
        tutorialHowToUseHelpGUI_2_1 := [
            "At first, you need to click on the [Help] menu in the top right corner of the main window."
        ]
        tutorialHowToUseHelpGUI_3_1 := [
            "You can search these entries with the search bar (highlighted with a red border)."
        ]
        tutorialHowToUseHelpGUI_4_1 := [
            "Double clicking them can start interactive tutorials or just a simple info text."
        ]
        ; This string (which is technically an array in this form) will be converted into an array later on.
        tutorialSearchBarDemoArrayString :=
            [
                "G,e,t,t,i,n,g, ,s,t,a,r,t,e,d"
            ]
        ; How To Record Macros TUTORIAL
        ; #############################
        tutorialHowToRecordMacros_1_2 := [
            "Macros"
        ]
        tutorialHowToRecordMacros_2_2 := [
            "Tutorial"
        ]
        tutorialHowToRecordMacros_3_2 := [
            "How to record macros"
        ]
        tutorialHowToRecordMacros_1_1 := [
            "First, the [Hotkey Overview] window must be opened",
            "by clicking on the [Hotkeys && Macros] menu in the main window."
        ]
        tutorialHowToRecordMacros_2_1 := [
            "Next you have to press the [Create Hotkey] button."
        ]
        tutorialHowToRecordMacros_3_1 := [
            "To start the recording process, simply press the [Record Macro] button."
        ]
        ; Getting Started TUTORIAL
        ; #############################
        tutorialGettingStarted_1_2 := [
            "General"
        ]
        tutorialGettingStarted_2_2 := [
            "Tutorial"
        ]
        tutorialGettingStarted_3_2 := [
            "Getting started"
        ]
        tutorialGettingStarted_1_1 := [
            "You might want to take a look at the options in the main window.",
            "`n`nSimply hover over an option with the cursor to get more information."
        ]
        tutorialGettingStarted_2_1 := [
            "You can perform a few actions by opening the [Options] menu.",
            "`n`nThis includes changing the script language."
        ]
        tutorialGettingStarted_3_1 := [
            "Use the [File] menu access the script's config file and many other things."
        ]
        tutorialGettingStarted_4_1 := [
            "Additional information about macros and hotkeys can be found in the help database."
        ]
        ; Built-in Hotkey Description
        ; #########################
        builtInHotkeyDescription_1 := [
            "Holds the W key and sends the Numpad Up key periodically.",
            "You could use this hotkey to walk, drive or fly AFK."
            "If you press the hotkey again, it will stop holding down keys.",
            ; The empty space is intended.
            " [This is a built-in hotkey]"
        ]
        builtInHotkeyDescription_2 := [
            "Pauses the GTA V process and creates a solo lobby.",
            ; The empty space is intended.
            " [This is a built-in hotkey]"
        ]
    }
    ; Saves every array object with it's real name to find them more easily.
    ; BE CAREFUL WHEN CHANGING THESE NAMES!
    completeLanguageArrayMap := Map(
        "mainGUI_1", mainGUI_1,
        "mainGUI_2", mainGUI_2,
        "mainGUI_3", mainGUI_3,
        "mainGUI_4", mainGUI_4,
        "mainGUI_5", mainGUI_5,
        "mainGUI_6", mainGUI_6,
        "mainGUI_7", mainGUI_7,
        "mainGUI_8", mainGUI_8,
        "mainGUI_9", mainGUI_9,
        "mainGUI_10", mainGUI_10,
        "mainGUI_11", mainGUI_11,
        "mainGUI_12", mainGUI_12,
        "mainGUI_13", mainGUI_13,
        "mainGUIMenu_1", mainGUIMenu_1,
        "mainGUIMenu_2", mainGUIMenu_2,
        "mainGUIMenu_3", mainGUIMenu_3,
        "mainGUIMenu_4", mainGUIMenu_4,
        "mainGUIFileMenu_1", mainGUIFileMenu_1,
        "mainGUIFileMenu_2", mainGUIFileMenu_2,
        "mainGUIFileSubMenu1_1", mainGUIFileSubMenu1_1,
        "mainGUIFileSubMenu1_2", mainGUIFileSubMenu1_2,
        "mainGUIFileSubMenu1_3", mainGUIFileSubMenu1_3,
        "mainGUIFileSubMenu1_4", mainGUIFileSubMenu1_4,
        "mainGUIFileSubMenu2_1", mainGUIFileSubMenu2_1,
        "mainGUIOptionsMenu_1", mainGUIOptionsMenu_1,
        "mainGUIOptionsMenu_2", mainGUIOptionsMenu_2,
        "mainGUIOptionsMenu_3", mainGUIOptionsMenu_3,
        "mainGUIOptionsMenu_4", mainGUIOptionsMenu_4,
        "mainGUIOptionsMenu_5", mainGUIOptionsMenu_5,
        "mainGUIHelpMenu_1", mainGUIHelpMenu_1,
        "mainGUIHelpMenu_2", mainGUIHelpMenu_2,
        "mainGUIHelpMenu_3", mainGUIHelpMenu_3,
        "mainGUIHelpMenu_4", mainGUIHelpMenu_4,
        "mainGUIHelpMenu_5", mainGUIHelpMenu_5,
        "mainGUIToolTip_1", mainGUIToolTip_1,
        "mainGUIToolTip_2", mainGUIToolTip_2,
        "mainGUIToolTip_3", mainGUIToolTip_3,
        "mainGUIToolTip_4", mainGUIToolTip_4,
        "mainGUIToolTip_5", mainGUIToolTip_5,
        "mainGUIToolTip_6", mainGUIToolTip_6,
        "mainGUIToolTip_7", mainGUIToolTip_7,
        "mainGUIToolTip_8", mainGUIToolTip_8,
        "mainGUIToolTip_9", mainGUIToolTip_9,
        "hotkeyOverviewGUI_1", hotkeyOverviewGUI_1,
        "hotkeyOverviewGUI_2", hotkeyOverviewGUI_2,
        "hotkeyOverviewGUI_3", hotkeyOverviewGUI_3,
        "hotkeyOverviewGUI_4", hotkeyOverviewGUI_4,
        "hotkeyOverviewGUI_5", hotkeyOverviewGUI_5,
        "hotkeyOverviewGUI_6", hotkeyOverviewGUI_6,
        "hotkeyOverviewGUI_7", hotkeyOverviewGUI_7,
        "hotkeyOverviewGUI_8", hotkeyOverviewGUI_8,
        "hotkeyOverviewGUI_9", hotkeyOverviewGUI_9,
        "hotkeyOverviewGUI_10", hotkeyOverviewGUI_10,
        "hotkeyOverviewGUI_11", hotkeyOverviewGUI_11,
        "hotkeyOverviewGUI_12", hotkeyOverviewGUI_12,
        "hotkeyOverviewGUI_13", hotkeyOverviewGUI_13,
        "hotkeyOverviewGUITooltip_1", hotkeyOverviewGUITooltip_1,
        "newCustomHotkeyGUI_1", newCustomHotkeyGUI_1,
        "newCustomHotkeyGUI_2", newCustomHotkeyGUI_2,
        "newCustomHotkeyGUI_3", newCustomHotkeyGUI_3,
        "newCustomHotkeyGUI_4", newCustomHotkeyGUI_4,
        "newCustomHotkeyGUI_5", newCustomHotkeyGUI_5,
        "newCustomHotkeyGUI_6", newCustomHotkeyGUI_6,
        "newCustomHotkeyGUI_7", newCustomHotkeyGUI_7,
        "newCustomHotkeyGUI_8", newCustomHotkeyGUI_8,
        "newCustomHotkeyGUI_9", newCustomHotkeyGUI_9,
        "infoAndHelpGUI_1", infoAndHelpGUI_1,
        "infoAndHelpGUI_2", infoAndHelpGUI_2,
        "infoAndHelpGUI_3", infoAndHelpGUI_3,
        "infoAndHelpGUI_4", infoAndHelpGUI_4,
        "infoAndHelpGUI_5", infoAndHelpGUI_5,
        "infoAndHelpGUI_6", infoAndHelpGUI_6,
        "infoAndHelpGUIListView_1", infoAndHelpGUIListView_1,
        "infoAndHelpGUIListView_2", infoAndHelpGUIListView_2,
        "infoAndHelpGUIListView_3", infoAndHelpGUIListView_3,
        "infoAndHelpGUIListView_4", infoAndHelpGUIListView_4,
        "tutorialGUI_1", tutorialGUI_1,
        "tutorialGUI_2", tutorialGUI_2,
        "tutorialGUI_3", tutorialGUI_3,
        "tutorialGUI_4", tutorialGUI_4,
        "reloadAndTerminateGUI_1", reloadAndTerminateGUI_1,
        "reloadAndTerminateGUI_2", reloadAndTerminateGUI_2,
        "reloadAndTerminateGUI_3", reloadAndTerminateGUI_3,
        "reloadAndTerminateGUI_4", reloadAndTerminateGUI_4,
        "reloadAndTerminateGUI_5", reloadAndTerminateGUI_5,
        "reloadAndTerminateGUI_6", reloadAndTerminateGUI_6,
        "reloadAndTerminateGUI_7", reloadAndTerminateGUI_7,
        "reloadAndTerminateGUI_8", reloadAndTerminateGUI_8,
        "generalScriptTrayTip1_1", generalScriptTrayTip1_1,
        "generalScriptTrayTip1_2", generalScriptTrayTip1_2,
        "generalScriptTrayTip2_1", generalScriptTrayTip2_1,
        "generalScriptTrayTip2_2", generalScriptTrayTip2_2,
        "generalScriptTrayTip3_1", generalScriptTrayTip3_1,
        "generalScriptTrayTip3_2", generalScriptTrayTip3_2,
        "generalScriptTrayTip4_1", generalScriptTrayTip4_1,
        "generalScriptTrayTip4_2", generalScriptTrayTip4_2,
        "macroRecorderTrayTip1_1", macroRecorderTrayTip1_1,
        "macroRecorderTrayTip1_2", macroRecorderTrayTip1_2,
        "macroRecorderTrayTip2_1", macroRecorderTrayTip2_1,
        "macroRecorderTrayTip2_2", macroRecorderTrayTip2_2,
        "generalScriptMsgBox1_1", generalScriptMsgBox1_1,
        "generalScriptMsgBox1_2", generalScriptMsgBox1_2,
        "generalScriptMsgBox2_1", generalScriptMsgBox2_1,
        "generalScriptMsgBox2_2", generalScriptMsgBox2_2,
        "configFileMsgBox1_1", configFileMsgBox1_1,
        "configFileMsgBox1_2", configFileMsgBox1_2,
        "configFileMsgBox2_1", configFileMsgBox2_1,
        "configFileMsgBox2_2", configFileMsgBox2_2,
        "configFileMsgBox3_1", configFileMsgBox3_1,
        "configFileMsgBox3_2", configFileMsgBox3_2,
        "configFileMsgBox4_1", configFileMsgBox4_1,
        "configFileMsgBox4_2", configFileMsgBox4_2,
        "configFileMsgBox5_1", configFileMsgBox5_1,
        "configFileMsgBox5_2", configFileMsgBox5_2,
        "configFileMsgBox6_1", configFileMsgBox6_1,
        "configFileMsgBox6_2", configFileMsgBox6_2,
        "customHotkeyOverviewGUIMsgBox1_1", customHotkeyOverviewGUIMsgBox1_1,
        "customHotkeyOverviewGUIMsgBox1_2", customHotkeyOverviewGUIMsgBox1_2,
        "functionsMsgBox1_1", functionsMsgBox1_1,
        "functionsMsgBox1_2", functionsMsgBox1_2,
        "functionsMsgBox2_1", functionsMsgBox2_1,
        "functionsMsgBox2_2", functionsMsgBox2_2,
        "functionsMsgBox3_1", functionsMsgBox3_1,
        "functionsMsgBox3_2", functionsMsgBox3_2,
        "mainGUIMsgBox1_1", mainGUIMsgBox1_1,
        "mainGUIMsgBox1_2", mainGUIMsgBox1_2,
        "mainGUIMsgBox2_1", mainGUIMsgBox2_1,
        "mainGUIMsgBox2_2", mainGUIMsgBox2_2,
        "newCustomHotkeyOverviewGUIMsgBox1_1", newCustomHotkeyOverviewGUIMsgBox1_1,
        "newCustomHotkeyOverviewGUIMsgBox1_2", newCustomHotkeyOverviewGUIMsgBox1_2,
        "newCustomHotkeyOverviewGUIMsgBox2_1", newCustomHotkeyOverviewGUIMsgBox2_1,
        "newCustomHotkeyOverviewGUIMsgBox2_2", newCustomHotkeyOverviewGUIMsgBox2_2,
        "newCustomHotkeyOverviewGUIMsgBox3_1", newCustomHotkeyOverviewGUIMsgBox3_1,
        "newCustomHotkeyOverviewGUIMsgBox3_2", newCustomHotkeyOverviewGUIMsgBox3_2,
        "newCustomHotkeyOverviewGUIMsgBox4_1", newCustomHotkeyOverviewGUIMsgBox4_1,
        "newCustomHotkeyOverviewGUIMsgBox4_2", newCustomHotkeyOverviewGUIMsgBox4_2,
        "newCustomHotkeyOverviewGUIMsgBox5_1", newCustomHotkeyOverviewGUIMsgBox5_1,
        "newCustomHotkeyOverviewGUIMsgBox5_2", newCustomHotkeyOverviewGUIMsgBox5_2,
        "newCustomHotkeyOverviewGUIMsgBox6_1", newCustomHotkeyOverviewGUIMsgBox6_1,
        "newCustomHotkeyOverviewGUIMsgBox6_2", newCustomHotkeyOverviewGUIMsgBox6_2,
        "newCustomHotkeyOverviewGUIMsgBox7_1", newCustomHotkeyOverviewGUIMsgBox7_1,
        "newCustomHotkeyOverviewGUIMsgBox7_2", newCustomHotkeyOverviewGUIMsgBox7_2,
        "newCustomHotkeyOverviewGUIMsgBox8_1", newCustomHotkeyOverviewGUIMsgBox8_1,
        "newCustomHotkeyOverviewGUIMsgBox8_2", newCustomHotkeyOverviewGUIMsgBox8_2,
        "newCustomHotkeyOverviewGUIMsgBox9_1", newCustomHotkeyOverviewGUIMsgBox9_1,
        "newCustomHotkeyOverviewGUIMsgBox9_2", newCustomHotkeyOverviewGUIMsgBox9_2,
        "objectsMsgBox1_1", objectsMsgBox1_1,
        "objectsMsgBox1_2", objectsMsgBox1_2,
        "objectsMsgBox2_1", objectsMsgBox2_1,
        "objectsMsgBox2_2", objectsMsgBox2_2,
        "objectsMsgBox3_1", objectsMsgBox3_1,
        "objectsMsgBox3_2", objectsMsgBox3_2,
        "objectsMsgBox4_1", objectsMsgBox4_1,
        "objectsMsgBox4_2", objectsMsgBox4_2,
        "tutorialMsgBox1_1", tutorialMsgBox1_1,
        "tutorialMsgBox1_2", tutorialMsgBox1_2,
        "tutorialMsgBox2_1", tutorialMsgBox2_1,
        "tutorialMsgBox2_2", tutorialMsgBox2_2,
        "tutorialMsgBox3_1", tutorialMsgBox3_1,
        "tutorialMsgBox3_2", tutorialMsgBox3_2,
        "tutorialHowToUseHelpGUI_1_2", tutorialHowToUseHelpGUI_1_2,
        "tutorialHowToUseHelpGUI_2_2", tutorialHowToUseHelpGUI_2_2,
        "tutorialHowToUseHelpGUI_3_2", tutorialHowToUseHelpGUI_3_2,
        "tutorialHowToUseHelpGUI_1_1", tutorialHowToUseHelpGUI_1_1,
        "tutorialHowToUseHelpGUI_2_1", tutorialHowToUseHelpGUI_2_1,
        "tutorialHowToUseHelpGUI_3_1", tutorialHowToUseHelpGUI_3_1,
        "tutorialHowToUseHelpGUI_4_1", tutorialHowToUseHelpGUI_4_1,
        "tutorialSearchBarDemoArrayString", tutorialSearchBarDemoArrayString,
        "tutorialHowToRecordMacros_1_1", tutorialHowToRecordMacros_1_1,
        "tutorialHowToRecordMacros_2_1", tutorialHowToRecordMacros_2_1,
        "tutorialHowToRecordMacros_3_1", tutorialHowToRecordMacros_3_1,
        "tutorialHowToRecordMacros_1_2", tutorialHowToRecordMacros_1_2,
        "tutorialHowToRecordMacros_2_2", tutorialHowToRecordMacros_2_2,
        "tutorialHowToRecordMacros_3_2", tutorialHowToRecordMacros_3_2,
        "tutorialGettingStarted_1_2", tutorialGettingStarted_1_2,
        "tutorialGettingStarted_2_2", tutorialGettingStarted_2_2,
        "tutorialGettingStarted_3_2", tutorialGettingStarted_3_2,
        "tutorialGettingStarted_1_1", tutorialGettingStarted_1_1,
        "tutorialGettingStarted_2_1", tutorialGettingStarted_2_1,
        "tutorialGettingStarted_3_1", tutorialGettingStarted_3_1,
        "tutorialGettingStarted_4_1", tutorialGettingStarted_4_1,
        "builtInHotkeyDescription_1", builtInHotkeyDescription_1,
        "builtInHotkeyDescription_2", builtInHotkeyDescription_2
    )
    return completeLanguageArrayMap
}
