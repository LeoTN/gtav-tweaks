;@Ahk2Exe-SetCompanyName Made by LeoTN
;@Ahk2Exe-SetCopyright Licence available on my GitHub project (https://github.com/LeoTN/gtav-tweaks)
;@Ahk2Exe-SetDescription GTAV Tweaks
;@Ahk2Exe-SetMainIcon library\assets\icons\1.ico

#SingleInstance Force
#MaxThreadsPerHotkey 2
; This forces all hotkeys created in this script to use the key hook. All hotkeys were no longer recognized while the
; GTA window was active. Probably caused by the changes Rockstar Games made to the Anti Cheat system.
#UseHook true

InstallKeybdHook
SendMode "Input"
CoordMode "Mouse", "Window"

; Imports important functions and variables.
; Sets the directory for all following files.
#Include "includes\"
#Include "ConfigFile.ahk"
#Include "CustomHotkeyOverviewGUI.ahk"
#Include "Functions.ahk"
#Include "HelpGUI.ahk"
#Include "Languages.ahk"
#Include "MacroDatabase.ahk"
#Include "MacroRecorder.ahk"
#Include "MainGUI.ahk"
#Include "NewCustomHotkeyGUI.ahk"
#Include "Tutorials.ahk"
#Include "UpdateGUI.ahk"

onInit()

onInit() {
    global booleanFirstTimeLaunch := false
    global macroRecordHotkey := "F5"

    ; This folder will contain all other files.
    global scriptMainDirectory := A_ScriptDir . "\GTAV_Tweaks"
    global ahkBaseFileLocation := scriptMainDirectory . "\AutoHotkey32.exe"
    global readmeFileLocation := A_ScriptDir . "\README.txt"

    global assetDirectory := scriptMainDirectory . "\assets"
    global iconDirectory := assetDirectory . "\icons"
    global iconFileLocation := iconDirectory . "\gtav_tweaks_icons.dll"

    global autostartDirectory := scriptMainDirectory . "\autostart"
    global psLaunchWithGTAVFileLocation := autostartDirectory . "\launchWithGTAV.ps1"
    global silentAutoStartScriptLauncherExecutableLocation := autostartDirectory .
        "\launchWithGTAV_PowerShell_launcher.exe"
    global psManageAutoStartTaskFileLocation := autostartDirectory . "\manageAutostartScheduledTask.ps1"

    global updateDirectory := scriptMainDirectory . "\update"
    global psUpdateScriptLocation := updateDirectory . "\checkForAvailableUpdates.ps1"
    global currentVersionFileLocation := updateDirectory . "\currentVersion.csv"

    global soundVolumeViewDirectory := scriptMainDirectory . "\soundvolumeview-x64"
    global audioHookFileLocation := soundVolumeViewDirectory . "\SoundVolumeView.exe"

    global macroFilesStorageDirectory := scriptMainDirectory . "\macros"
    global macroConfigFileLocation := macroFilesStorageDirectory . "\GTAV_Tweaks_MACROS.ini"
    global builtInHKLocation_createSololobby := macroFilesStorageDirectory . "\builtInHK_createSololobby.ahk"
    global builtInHKLocation_walkDriveFlyAFK := macroFilesStorageDirectory . "\builtInHK_AFKWalkDriveFly.ahk"

    global macroTemplateFilesStorageDirectory := macroFilesStorageDirectory . "\templates"
    global macroRecorderTemplateFileLocation := macroTemplateFilesStorageDirectory . "\macroRecorderTemplate.txt"

    global recordedMacroFilesStorageDirectory := scriptMainDirectory . "\recorded_macros"

    onInit_checkScriptFileIntegrity()
    ; The version can now be specified because the version file should now be available.
    try
    {
        currentVersionFileMap := readFromCSVFile(currentVersionFileLocation)
        global versionFullName := currentVersionFileMap.Get("CURRENT_VERSION")
    }
    catch {
        ; This is a fallback. If this version occurs, we know there was an error with the version file.
        global versionFullName := "v0.0.1.0"
    }
    ; Changes the tray icon and freezes it.
    TraySetIcon(iconFileLocation, 1, true) ; ICON_DLL_USED_HERE
    ; Runs all onInit() functions from included files.
    ; languages_onInit() is included in configFile_onInit().
    configFile_onInit()
    ; The language module is loaded at this point.
    manageDesktopShortcut()
    functions_onInit()
    objects_onInit()
    macroRecorder_onInit()
    mainGUI_onInit()
    customHotkeyOverviewGUI_onInit()
    newCustomHotkeyGUI_onInit()
    help_onInit()
    tutorials_onInit()

    if (readConfigFile("DISPLAY_LAUNCH_NOTIFICATION")) {
        TrayTip(getLanguageArrayString("generalScriptTrayTip2_1"), getLanguageArrayString("generalScriptTrayTip2_2"),
        "Iconi Mute")
        SetTimer () => TrayTip(), -1500
    }
    if (readConfigFile("ASK_FOR_TUTORIAL")) {
        scriptTutorial()
    }
    if (readConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH") && !booleanFirstTimeLaunch) {
        checkForAvailableUpdates()
    }
    waitForGTAToExist()
    ; Checks every 3 seconds if GTA is still existing and if it is the active window.
    SetTimer(checkForExistingGTA, 3000)
    if (readConfigFile("MUTE_GAME_WHILE_LAUNCH")) {
        muteGTAWhileInLoadingScreen()
    }
}

; Checks if important directories and files are present.
onInit_checkScriptFileIntegrity() {
    SplitPath(scriptMainDirectory, &outFolderName)
    if (!A_IsCompiled && !DirExist(scriptMainDirectory)) {
        MsgBox(
            "You are using a non compiled version of this script.`n`nMake sure that all supportive files are present "
            . "in the [" . outFolderName .
            "] folder.`n`nThis folder needs to exist in the same directory as this script.`n`n"
            "You can achieve this by executing a compiled version in this directory that will create them for you.",
            "GTAV Tweaks - Uncompiled Script Information", "Iconi 262144")
        exitScriptWithNotification(true)
    }
    ; Checks if required folders need to be created.
    if (!DirExist(recordedMacroFilesStorageDirectory)) {
        DirCreate(recordedMacroFilesStorageDirectory)
    }
    ; Creates required files (if possible).
    if (!FileExist(macroConfigFileLocation)) {
        IniWrite("Always back up your files!", macroConfigFileLocation, "CustomHotkeysBelow", "Advice")
    }
    ; Checks if all required files are present.
    fileLocations := [
        ahkBaseFileLocation,
        readmeFileLocation,
        iconFileLocation,
        psLaunchWithGTAVFileLocation,
        silentAutoStartScriptLauncherExecutableLocation,
        psManageAutoStartTaskFileLocation,
        psUpdateScriptLocation,
        currentVersionFileLocation,
        audioHookFileLocation,
        macroConfigFileLocation,
        builtInHKLocation_createSololobby,
        builtInHKLocation_walkDriveFlyAFK,
        macroRecorderTemplateFileLocation
    ]
    for (file in fileLocations) {
        if (!FileExist(file)) {
            MsgBox("The file [" . file .
                "] is missing.`n`nPlease reinstall or repair the software using the .MSI installer.",
                "GTAV Tweaks - Reinstallation required",
                "Icon! 262144")
            exitScriptWithNotification(true)
        }
    }
}
