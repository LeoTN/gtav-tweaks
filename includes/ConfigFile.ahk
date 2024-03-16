#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

/*
DEBUG SECTION
-------------------------------------------------
Add debug variables here.
*/
; This variable is also written into the config file.
global booleanDebugMode := false

;------------------------------------------------

/*
CONFIG VARIABLE TEMPLATE SECTION
-------------------------------------------------
These default variables are used to generate the config file template.
***IMPORTANT NOTE***: Do NOT change the name of these variables!
Otherwise this can lead to fatal errors and failures!
*/

config_onInit()
{
    ; Determines the location of the script's configuration file.
    global configFileLocation := A_ScriptDir . "\GTAV_Tweaks\GTAV_Tweaks.ini"

    ; Defines if the script should ask the user for a brief explaination of it's core functions.
    global ASK_FOR_TUTORIAL := true
    ; Launch script with windows.
    global LAUNCH_WITH_WINDOWS := false
    ; Launch minimized.
    global LAUNCH_MINIMIZED := false
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

    ; Stores which hotkeys are enabled / disabled via the GUI.
    global HOTKEY_STATE_ARRAY := "[1, 1, 1, 1]"
    ; Just a list of all standard hotkeys.
    global AFK_PERCIO_FLIGHT_HK := "^F9"
    global SOLO_LOBBY_HK := "^F10"
    global DEPOSIT_MONEY_LESS_100K_HK := "^F11"
    global DEPOSIT_MONEY_MORE_100K_HK := "^F12"
    ;------------------------------------------------

    ; Will contain all config values matching with each variable name in the array below.
    ; For example configVariableNameArray[2] = "ASK_FOR_TUTORIAL"
    ; and configFileContentArray[2] = "true", so basically ASK_FOR_TUTORIAL = "true".
    ; NOTE: This had to be done because changing a global variable using a dynamic
    ; expression like global %myGlobalVarName% := "newValue" won't work.
    global configFileContentArray := []

    ; Create an array including all settings variables names.
    ; This array makes it easier to apply certain values from the config file to the configFileContentArray.
    ; IMPORTANT NOTE: Do NOT forget to add each new config variable name into the array!!!
    global configVariableNameArray :=
        [
            "booleanDebugMode",
            "ASK_FOR_TUTORIAL",
            "LAUNCH_WITH_WINDOWS",
            "LAUNCH_MINIMIZED",
            "DISPLAY_LAUNCH_NOTIFICATION",
            "CHECK_FOR_UPDATES_AT_LAUNCH",
            "UPDATE_TO_BETA_VERSIONS",
            "MUTE_GAME_WHILE_LAUNCH",
            "INCREASE_GAME_PRIORITY",
            "DISPLAY_GTA_LAUNCH_NOTIFICATION",
            "HOTKEY_STATE_ARRAY",
            "AFK_PERCIO_FLIGHT_HK",
            "SOLO_LOBBY_HK",
            "DEPOSIT_MONEY_LESS_100K_HK",
            "DEPOSIT_MONEY_MORE_100K_HK"
        ]
    ; Create an array including the matching section name for EACH item in the configVariableNameArray.
    ; This makes it easier to read and write the config file.
    ; IMPORTANT NOTE: Do NOT forget to add the SECTION NAME for EACH new item added in the configVariableNameArray!!!
    global configSectionNameArray :=
        [
            "DebugSettings",
            "GeneralSettings",
            "GeneralSettings",
            "GeneralSettings",
            "GeneralSettings",
            "GeneralSettings",
            "GeneralSettings",
            "GameSettings",
            "GameSettings",
            "GameSettings",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys"
        ]

    If (!FileExist(configFileLocation))
    {
        global booleanFirstTimeLaunch := true
    }
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
*/
createDefaultConfigFile(pBooleanCreateBackup := true, pBooleanShowPrompt := false)
{
    If (pBooleanShowPrompt)
    {
        result := MsgBox("Do you really want to replace the current config file with a new one ?", "GTAV Tweaks - Replace Config File?", "YN Icon! 262144")
        If (result = "No" || result = "Timeout")
        {
            Return
        }
    }
    If (pBooleanCreateBackup)
    {
        If (!DirExist(SplitPath(configFileLocation, , &outDir)))
        {
            DirCreate(outDir)
        }
        If (FileExist(configFileLocation))
        {
            FileMove(configFileLocation, configFileLocation . "_old", true)
        }
    }
    FileAppend("#Important note: When changing the config file, the script has to be reloaded for the changes to take effect!`n"
        . "#You can find a hotkey list here: (https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols)", configFileLocation)
    ; In case you forget to specify a section for EACH new config file entry this will remind you to do so :D
    If (configVariableNameArray.Length != configSectionNameArray.Length)
    {
        MsgBox("Not every config file entry has been asigned to a section!`n`nPlease fix this by checking both arrays.",
            "GTAV Tweaks - Config File Status - Error!", "O IconX 262144")
        MsgBox("Script terminated.", "GTAV Tweaks - Script Status", "O IconX T1.5")
        ExitApp()
    }
    Else
    {
        /*
        This it what it looked like before using an array to define all parameters.
        IniWrite(URL_FILE_LOCATION, configFileLocation, "FileLocations", "URL_FILE_LOCATION")
        */
        Loop configVariableNameArray.Length
        {
            IniWrite(%configVariableNameArray.Get(A_Index)%, configFileLocation, configSectionNameArray.Get(A_Index),
                configVariableNameArray.Get(A_Index))
        }
        If (pBooleanShowPrompt)
        {
            MsgBox("A default config file has been generated.", "GTAV Tweaks - Config File Status", "O Iconi T3")
        }
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
readConfigFile(pOptionName, pBooleanAskForPathCreation := true, pBooleanCheckConfigFileStatus := true)
{
    global configVariableNameArray
    global configFileContentArray
    global booleanFirstTimeLaunch

    If (pBooleanCheckConfigFileStatus)
    {
        checkConfigFileIntegrity()
    }

    Loop (configVariableNameArray.Length)
    {
        ; Searches in the config file for the given option name to then extract the value.
        If (InStr(configVariableNameArray.Get(A_Index), pOptionName, 0))
        {
            ; The following code only applies for path values.
            ; Everything else should be excluded.
            If (InStr(configFileContentArray.Get(A_Index), "\"))
            {
                booleanCreatePathSilent := false
                If (booleanFirstTimeLaunch)
                {
                    pBooleanAskForPathCreation := false
                    booleanCreatePathSilent := true
                }
                If (!validatePath(configFileContentArray.Get(A_Index), pBooleanAskForPathCreation, booleanCreatePathSilent))
                {
                    MsgBox("Check the config file for a valid path at`n["
                        . configVariableNameArray.Get(A_Index) . "]", "GTAV Tweaks - Config File Status - Error!", "O Icon! 262144")
                    MsgBox("Script terminated.", "GTAV Tweaks - Script Status", "O IconX T1.5")
                    ExitApp()
                }
                Else
                {
                    ; This means that there was no error with the path given.
                    Return configFileContentArray.Get(A_Index)
                }
            }
            Else
            {
                Return configFileContentArray.Get(A_Index)
            }
        }
    }
    MsgBox("Could not find " . pOptionName . " in the config file.`nScript terminated.", "GTAV Tweaks - Config File Status - Error!", "O IconX 262144")
    ExitApp()
}

/*
Changes existing values in the config file.
@param pOptionName [String] Should be the name of a config file option for example "ASK_FOR_TUTORIAL".
@param pData [Any] The data to replace the old value with.
*/
editConfigFile(pOptionName, pData)
{
    ; Basically the same as creating the config file.
    Try
    {
        Loop (configVariableNameArray.Length)
        {
            ; Searches in the config file for the given option name to then change the value.
            If (InStr(configVariableNameArray.Get(A_Index), pOptionName, 0))
            {
                Try
                {
                    ; Check just in case the given data is an array.
                    If (pData.Has(1))
                    {
                        dataString := arrayToString(pData)
                        IniWrite(dataString, configFileLocation
                            , configSectionNameArray.Get(A_Index)
                            , configVariableNameArray.Get(A_Index))
                    }
                    Else
                    {
                        IniWrite(pData, configFileLocation
                            , configSectionNameArray.Get(A_Index)
                            , configVariableNameArray.Get(A_Index))
                    }
                }
                Catch
                {
                    ; If the try statement fails the object above cannot be an array.
                    IniWrite(pData, configFileLocation
                        , configSectionNameArray.Get(A_Index)
                        , configVariableNameArray.Get(A_Index))
                }
            }
        }
    }
    Catch As error
    {
        displayErrorMessage(error)
    }
}

; Reads the whole config file and throws an error when something is not right.
checkConfigFileIntegrity()
{
    global booleanFirstTimeLaunch

    Loop (configVariableNameArray.Length)
    {
        Try
        {
            ; Replaces every slot in the configFileContentArray with the value from the config file's content.
            configFileContentArray.InsertAt(A_Index, IniRead(configFileLocation, configSectionNameArray.Get(A_Index)
                , configVariableNameArray.Get(A_Index)))
        }
        Catch
        {
            ; Does not show a prompt when the script is launched for the very first time.
            If (booleanFirstTimeLaunch)
            {
                createDefaultConfigFile()
                Return true
            }
            result := MsgBox("The script config file seems to be corrupted or unavailable!"
                "`n`nDo you want to create a new one using the template?"
                , "GTAV Tweaks - Config File Status - Warning!", "YN Icon! 262144")
            Switch (result)
            {
                Case "Yes":
                    {
                        createDefaultConfigFile()
                        Return true
                    }
                Default:
                    {
                        MsgBox("Script terminated.", "GTAV Tweaks - Script Status", "O IconX T1.5")
                        ExitApp()
                    }
            }
        }
    }
}

/*
Verfies the integrity of a given path or file location.
NOTE: pBooleanAskForPathCreation and pBooleanCreatePathSilent cannot be true at the same time.
@param pPath [String] Should be a path to validate.
@param pBooleanAskForPathCreation [boolean] If set to true, will display a prompt to create the non-existing directory.
@param pBooleanCreatePathSilent [boolean] If set to true, will create any valid directory, if it doesn't exist.
@returns [boolean] True if a path is valid and false otherwise.
*/
validatePath(pPath, pBooleanAskForPathCreation := true, pBooleanCreatePathSilent := false)
{
    If (pBooleanAskForPathCreation && pBooleanCreatePathSilent)
    {
        MsgBox("[" . A_ThisFunc . "()] [ERROR] pBooleanAskForPathCreation and pBooleanCreatePathSilent cannot be true at the "
            . "same time.`nTerminating script.", "GTAV Tweaks - [" . A_ThisFunc . "()]", "IconX 262144")
        ExitApp()
    }

    ; SplitPath makes sure the last part of the whole path is removed.
    ; For example it removes the "\YT_URLS.txt"
    SplitPath(pPath, &outFileName, &outDir, &outExtension, , &outDrive)
    ; Replaces the drive name with empty space, because the "C:" would trigger the parse loop below mistakenly.
    pathWithoutDrive := StrReplace(pPath, outDrive)
    ; Looks for one of the specified characters to identify invalid path names.
    ; Searches for common mistakes in the path name.
    specialChars := '<>"/|?*:'
    Loop Parse (specialChars)
    {
        If (InStr(pathWithoutDrive, A_LoopField))
        {
            Return false
        }
    }
    ; Checks if the path contains two or more or no "\".
    If (RegExMatch(pPath, "\\{2,}") || !InStr(pPath, "\"))
    {
        Return false
    }

    ; This means the path has no file at the end.
    If (outExtension = "")
    {
        If (!DirExist(pPath))
        {
            If (pBooleanAskForPathCreation)
            {
                result := MsgBox("The directory`n[" . pPath . "] does not exist."
                    "`nWould you like to create it ?", "GTAV Tweaks - Config File Status - Warning!", "YN Icon! 262144")
                Switch (result)
                {
                    Case "Yes":
                        {
                            DirCreate(pPath)
                        }
                    Default:
                        {
                            MsgBox("Script terminated.", "GTAV Tweaks - Script Status", "O IconX T1.5")
                            ExitApp()
                        }
                }
            }
            Else If (pBooleanCreatePathSilent)
            {
                DirCreate(pPath)
            }
        }
    }
    ; This means the path has a file at the end, which has to be excluded.
    Else
    {
        If (!DirExist(outDir))
        {
            If (pBooleanAskForPathCreation)
            {
                result := MsgBox("The directory`n[" . outDir . "] does not exist."
                    "`nWould you like to create it ?", "GTAV Tweaks - Config File Status - Warning!", "YN Icon! 262144")
                Switch (result)
                {
                    Case "Yes":
                        {
                            DirCreate(outDir)
                        }
                    Default:
                        {
                            MsgBox("Script terminated.", "GTAV Tweaks - Script Status", "O IconX T1.5")
                            ExitApp()
                        }
                }
            }
            Else If (pBooleanCreatePathSilent)
            {
                DirCreate(outDir)
            }
        }
    }
    Return true
}