#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

/*
DEBUG SECTION
-------------------------------------------------
Add debug variables here.
*/
; This variable is also written into the config file.
global booleanDebugMode := false
global loadBuiltInHotkeys := true

;------------------------------------------------

/*
CONFIG VARIABLE TEMPLATE SECTION
-------------------------------------------------
These default variables are used to generate the config file template.
***IMPORTANT NOTE***: Do NOT change the name of these variables!
Otherwise this can lead to fatal errors and failures!
*/

configFile_onInit() {
    ; Determines the location of the script's configuration file.
    global configFileLocation := scriptMainDirectory . "\GTAV_Tweaks.ini"

    ; Specifies the preferred language for text boxes. Leave it to "SYSTEM", to use the system language, if available.
    global PREFERRED_LANGUAGE := "SYSTEM"

    ; Defines if the script should ask the user for a brief explaination of it's core functions.
    global ASK_FOR_TUTORIAL := true
    ; Launch script with GTA.
    global LAUNCH_WITH_GTA := false
    ; Launch minimized.
    global LAUNCH_MINIMIZED := false
    ; Minimize the script to tray when closing the main GUI.
    global MINIMIZE_INSTEAD_OF_CLOSE := true
    ; Display a notification when launching.
    global DISPLAY_LAUNCH_NOTIFICATION := true
    ; Checks out the GitHub page for a new release.
    global CHECK_FOR_UPDATES_AT_LAUNCH := true
    ; Decide if you would like to receive beta versions as available updates.
    global UPDATE_TO_BETA_VERSIONS := false

    ; Mute GTA during launch.
    global MUTE_GAME_WHILE_LAUNCH := false
    ; (Possibly) increase GTA performance by increasing it's process priority.
    global INCREASE_GAME_PRIORITY := false
    ; Show a notification when GTA has been detected.
    global DISPLAY_GTA_LAUNCH_NOTIFICATION := true

    ;------------------------------------------------

    ; Will contain all config values matching with each variable name in the array below.
    ; For example configVariableNameArray[2] == "ASK_FOR_TUTORIAL"
    ; and configFileContentArray[2] == "true", so basically ASK_FOR_TUTORIAL == "true".
    ; NOTE: This had to be done because changing a global variable using a dynamic
    ; expression like global %myGlobalVarName% := "newValue" won't work.
    global configFileContentArray := []

    ; Create an array including all settings variables names.
    ; This array makes it easier to apply certain values from the config file to the configFileContentArray.
    ; IMPORTANT NOTE: Do NOT forget to add each new config variable name into the array!!!
    global configVariableNameArray :=
        [
            "booleanDebugMode",
            "loadBuiltInHotkeys",
            "PREFERRED_LANGUAGE",
            "ASK_FOR_TUTORIAL",
            "LAUNCH_WITH_GTA",
            "LAUNCH_MINIMIZED",
            "MINIMIZE_INSTEAD_OF_CLOSE",
            "DISPLAY_LAUNCH_NOTIFICATION",
            "CHECK_FOR_UPDATES_AT_LAUNCH",
            "UPDATE_TO_BETA_VERSIONS",
            "MUTE_GAME_WHILE_LAUNCH",
            "INCREASE_GAME_PRIORITY",
            "DISPLAY_GTA_LAUNCH_NOTIFICATION"
        ]
    ; Create an array including the matching section name for EACH item in the configVariableNameArray.
    ; This makes it easier to read and write the config file.
    ; IMPORTANT NOTE: Do NOT forget to add the SECTION NAME for EACH new item added in the configVariableNameArray!!!
    global configSectionNameArray :=
        [
            "DebugSettings",
            "DebugSettings",
            "GeneralSettings",
            "StartupSettings",
            "StartupSettings",
            "StartupSettings",
            "StartupSettings",
            "StartupSettings",
            "StartupSettings",
            "StartupSettings",
            "GameSettings",
            "GameSettings",
            "GameSettings"
        ]

    if (!FileExist(configFileLocation)) {
        global booleanFirstTimeLaunch := true
    }
    languages_onInit()
    checkConfigFileIntegrity()
}

/*
CONFIG FILE SECTION
-------------------------------------------------
Creates, reads and manages the script's config file.
*/

/*
Does what the name implies.
@param pBooleanCreateBackup [boolean] If set to true, the old config file will be saved.
@param pBooleanShowPrompt [boolean] Show a prompt to create the config file or do it silent.
@param pBooleanReloadScript [boolean] Reloads the script, when set to true.
*/
createDefaultConfigFile(pBooleanCreateBackup := true, pBooleanShowPrompt := false, pBooleanReloadScript := false) {
    if (pBooleanShowPrompt) {
        result := MsgBox(getLanguageArrayString("configFileMsgBox1_1"), getLanguageArrayString("configFileMsgBox1_2"),
        "YN Icon! 262144")
        if (result == "No" || result == "Timeout") {
            return
        }
    }
    if (pBooleanCreateBackup) {
        if (!DirExist(SplitPath(configFileLocation, , &outDir))) {
            DirCreate(outDir)
        }
        if (FileExist(configFileLocation)) {
            FileMove(configFileLocation, configFileLocation . "_old", true)
        }
    }
    FileAppend(
        "#Important note: When changing the config file, the script has to be reloaded for the changes to take effect!`n"
        . "#You can find a hotkey list here: (https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols)",
        configFileLocation)
    ; In case you forget to specify a section for EACH new config file entry this will remind you to do so :D
    if (configVariableNameArray.Length != configSectionNameArray.Length) {
        ; Those MsgBoxes typically only appear when changing the code. This means, that they don't need language support.
        MsgBox("Not every config file entry has been asigned to a section!`n`nPlease fix this by checking both arrays.",
            "GTAV Tweaks - Config File Status - Error", "O IconX 262144")
        MsgBox(getLanguageArrayString("generalScriptMsgBox1_1"), getLanguageArrayString("generalScriptMsgBox1_2"),
        "O IconX T1.5")
        exitScriptWithNotification()
    }
    else {
        /*
        This it what it looked like before using an array to define all parameters.
        IniWrite(URL_FILE_LOCATION, configFileLocation, "FileLocations", "URL_FILE_LOCATION")
        */
        loop configVariableNameArray.Length {
            IniWrite(%configVariableNameArray.Get(A_Index)%, configFileLocation, configSectionNameArray.Get(A_Index),
            configVariableNameArray.Get(A_Index))
        }
        if (pBooleanShowPrompt) {
            MsgBox(getLanguageArrayString("configFileMsgBox2_1"), getLanguageArrayString("configFileMsgBox2_2"),
            "O Iconi T3")
        }
    }
    if (pBooleanReloadScript) {
        Reload()
    }
}

/*
Reads the config file and extracts it's values.
@param pOptionName [String] Should be the name of an config file option for example "URL_FILE_LOCATION"
@param pBooleanAskForPathCreation [boolean] If set to true, will display a prompt to create the path,
if it does not exist on the current system.
@param pBooleanCheckConfigFileStatus [boolean] If set to true, will check the config file integrity while reading.
@returns [Any] A value from the config file.
*/
readConfigFile(pOptionName, pBooleanAskForPathCreation := true, pBooleanCheckConfigFileStatus := true) {
    global configVariableNameArray
    global configFileContentArray
    global booleanFirstTimeLaunch

    if (pBooleanCheckConfigFileStatus) {
        checkConfigFileIntegrity()
    }

    loop (configVariableNameArray.Length) {
        ; Searches in the config file for the given option name to then extract the value.
        if (InStr(configVariableNameArray.Get(A_Index), pOptionName, 0)) {
            ; The following code only applies for path values.
            ; Everything else should be excluded.
            if (InStr(configFileContentArray.Get(A_Index), "\")) {
                booleanCreatePathSilent := false
                if (booleanFirstTimeLaunch) {
                    pBooleanAskForPathCreation := false
                    booleanCreatePathSilent := true
                }
                if (!validatePath(configFileContentArray.Get(A_Index), pBooleanAskForPathCreation,
                booleanCreatePathSilent)) {
                    MsgBox(getLanguageArrayString("configFileMsgBox3_1", configVariableNameArray.Get(A_Index)),
                    getLanguageArrayString("configFileMsgBox3_2"), "O Icon! 262144")
                    MsgBox(getLanguageArrayString("generalScriptMsgBox1_1"), getLanguageArrayString(
                        "generalScriptMsgBox1_2"), "O IconX T1.5")
                    exitScriptWithNotification()
                }
                else {
                    ; This means that there was no error with the path given.
                    return configFileContentArray.Get(A_Index)
                }
            }
            else {
                return configFileContentArray.Get(A_Index)
            }
        }
    }
    MsgBox(getLanguageArrayString("configFileMsgBox4_1", pOptionName), getLanguageArrayString("configFileMsgBox4_2"),
    "O IconX 262144")
    exitScriptWithNotification()
}

/*
Changes existing values in the config file.
@param pOptionName [String] Should be the name of a config file option for example "ASK_FOR_TUTORIAL".
@param pData [Any] The data to replace the old value with.
*/
editConfigFile(pOptionName, pData) {
    ; Basically the same as creating the config file.
    try
    {
        loop (configVariableNameArray.Length) {
            ; Searches in the config file for the given option name to then change the value.
            if (InStr(configVariableNameArray.Get(A_Index), pOptionName, 0)) {
                try
                {
                    ; Check just in case the given data is an array.
                    if (pData.Has(1)) {
                        dataString := arrayToString(pData)
                        IniWrite(dataString, configFileLocation
                            , configSectionNameArray.Get(A_Index)
                            , configVariableNameArray.Get(A_Index))
                    }
                    else {
                        IniWrite(pData, configFileLocation
                            , configSectionNameArray.Get(A_Index)
                            , configVariableNameArray.Get(A_Index))
                    }
                }
                catch {
                    ; If the try statement fails the object above cannot be an array.
                    IniWrite(pData, configFileLocation
                        , configSectionNameArray.Get(A_Index)
                        , configVariableNameArray.Get(A_Index))
                }
            }
        }
    }
    catch as error {
        displayErrorMessage(error)
    }
}

/*
Reads the whole config file and throws an error when something is not right.
@param pBooleanResultOnly [boolean] If set to true, the function will not take any actions and just return
the state of of the config file.
@returns [boolean] True, if the config file is not corrupted. False otherwise.
*/
checkConfigFileIntegrity(pBooleanResultOnly := false) {
    global booleanFirstTimeLaunch

    loop (configVariableNameArray.Length) {
        try
        {
            ; Replaces every slot in the configFileContentArray with the value from the config file's content.
            configFileContentArray.InsertAt(A_Index, IniRead(configFileLocation, configSectionNameArray.Get(A_Index)
            , configVariableNameArray.Get(A_Index)))
        }
        catch {
            if (pBooleanResultOnly) {
                return false
            }
            ; Does not show a prompt when the script is launched for the very first time.
            if (booleanFirstTimeLaunch) {
                createDefaultConfigFile()
                return true
            }
            result := MsgBox(getLanguageArrayString("configFileMsgBox5_1"),
            getLanguageArrayString("configFileMsgBox5_2"), "YN Icon! 262144")
            switch (result) {
                case "Yes":
                {
                    createDefaultConfigFile()
                    return true
                }
                default:
                {
                    MsgBox(getLanguageArrayString("generalScriptMsgBox1_1"), getLanguageArrayString(
                        "generalScriptMsgBox1_2"), "O IconX T1.5")
                    exitScriptWithNotification()
                }
            }
        }
    }
    return true
}

/*
Verfies the integrity of a given path or file location.
NOTE: pBooleanAskForPathCreation and pBooleanCreatePathSilent cannot be true at the same time.
@param pPath [String] Should be a path to validate.
@param pBooleanAskForPathCreation [boolean] If set to true, will display a prompt to create the non-existing directory.
@param pBooleanCreatePathSilent [boolean] If set to true, will create any valid directory, if it doesn't exist.
@returns [boolean] True if a path is valid and false otherwise.
*/
validatePath(pPath, pBooleanAskForPathCreation := true, pBooleanCreatePathSilent := false) {
    if (pBooleanAskForPathCreation && pBooleanCreatePathSilent) {
        MsgBox("[" . A_ThisFunc .
            "()] [ERROR] pBooleanAskForPathCreation and pBooleanCreatePathSilent cannot be true at the "
            . "same time.`nTerminating script.", "GTAV Tweaks - [" . A_ThisFunc . "()]", "IconX 262144")
        exitScriptWithNotification()
    }

    ; SplitPath makes sure the last part of the whole path is removed.
    ; For example it removes the "\YT_URLS.txt"
    SplitPath(pPath, &outFileName, &outDir, &outExtension, , &outDrive)
    ; Replaces the drive name with empty space, because the "C:" would trigger the parse loop below mistakenly.
    pathWithoutDrive := StrReplace(pPath, outDrive)
    ; Looks for one of the specified characters to identify invalid path names.
    ; Searches for common mistakes in the path name.
    specialChars := '<>"/|?*:'
    loop parse (specialChars) {
        if (InStr(pathWithoutDrive, A_LoopField)) {
            return false
        }
    }
    ; Checks if the path contains two or more or no "\".
    if (RegExMatch(pPath, "\\{2,}") || !InStr(pPath, "\")) {
        return false
    }

    ; This means the path has no file at the end.
    if (outExtension == "") {
        if (!DirExist(pPath)) {
            if (pBooleanAskForPathCreation) {
                result := MsgBox(getLanguageArrayString("configFileMsgBox6_1", pPath),
                getLanguageArrayString("configFileMsgBox6_1"), "YN Icon! 262144")
                switch (result) {
                    case "Yes":
                    {
                        DirCreate(pPath)
                    }
                    default:
                    {
                        MsgBox(getLanguageArrayString("generalScriptMsgBox1_1"), getLanguageArrayString(
                            "generalScriptMsgBox1_2"), "O IconX T1.5")
                        exitScriptWithNotification()
                    }
                }
            }
            else if (pBooleanCreatePathSilent) {
                DirCreate(pPath)
            }
        }
    }
    ; This means the path has a file at the end, which has to be excluded.
    else {
        if (!DirExist(outDir)) {
            if (pBooleanAskForPathCreation) {
                result := MsgBox(getLanguageArrayString("configFileMsgBox6_1", outDir),
                getLanguageArrayString("configFileMsgBox6_1"), "YN Icon! 262144")
                switch (result) {
                    case "Yes":
                    {
                        DirCreate(outDir)
                    }
                    default:
                    {
                        MsgBox(getLanguageArrayString("generalScriptMsgBox1_1"), getLanguageArrayString(
                            "generalScriptMsgBox1_2"), "O IconX T1.5")
                        exitScriptWithNotification()
                    }
                }
            }
            else if (pBooleanCreatePathSilent) {
                DirCreate(outDir)
            }
        }
    }
    return true
}
