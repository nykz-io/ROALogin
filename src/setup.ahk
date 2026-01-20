; ROALogin Setup GUI
; First-time setup for password storage and shortcut creation
; This file is included by roa_login.ahk

ShowSetupGUI() {
    global

    ; Try to auto-detect path
    detectedPath := Config_GetGamePath()

    ; Create the setup window
    Gui, Setup:New, +AlwaysOnTop, ROALogin Setup
    Gui, Setup:Font, s10

    ; Password section
    Gui, Setup:Add, Text, w300, Enter your Rise of Agon password:
    Gui, Setup:Add, Edit, w300 Password vSetupPassword

    Gui, Setup:Add, Text, w300 y+15, Confirm password:
    Gui, Setup:Add, Edit, w300 Password vSetupConfirmPassword

    ; Game path section
    Gui, Setup:Add, Text, w300 y+20, Game executable path:
    Gui, Setup:Add, Edit, w230 vSetupGamePath, %detectedPath%
    Gui, Setup:Add, Button, x+5 w60 gBrowseForGame, Browse

    ; Status indicator for path
    statusText := (detectedPath != "" && FileExist(detectedPath)) ? "Game found" : ""
    Gui, Setup:Add, Text, x10 w300 cGreen vSetupPathStatus, %statusText%

    ; Shortcut option
    Gui, Setup:Add, Text, x10 y+20 w300
    Gui, Setup:Add, Checkbox, vSetupCreateShortcut Checked, Create desktop shortcut

    ; Buttons
    Gui, Setup:Add, Text, w300 y+20
    Gui, Setup:Add, Button, x10 w140 Default gSaveSettings, Save && Launch Game
    Gui, Setup:Add, Button, x+20 w140 gSetupGuiClose, Cancel

    Gui, Setup:Show
    return

BrowseForGame:
    FileSelectFile, selectedFile, 1, , Select Darkfall_RoA.exe, Executable (*.exe)
    if (selectedFile != "") {
        GuiControl, Setup:, SetupGamePath, %selectedFile%
        if FileExist(selectedFile)
            GuiControl, Setup:, SetupPathStatus, Game found
        else
            GuiControl, Setup:, SetupPathStatus,
    }
    return

SaveSettings:
    Gui, Setup:Submit, NoHide

    ; Validate password
    if (SetupPassword = "") {
        MsgBox, 48, Validation Error, Please enter a password.
        return
    }

    if (SetupPassword != SetupConfirmPassword) {
        MsgBox, 48, Validation Error, Passwords do not match.
        return
    }

    ; Validate game path
    if (SetupGamePath = "" || !FileExist(SetupGamePath)) {
        MsgBox, 48, Validation Error, Please select a valid game executable.
        return
    }

    ; Ensure directories exist
    Config_EnsureCredentialDir()

    ; Encrypt and save password
    encryptedPassword := DPAPI_Encrypt(SetupPassword)
    if (encryptedPassword = "") {
        MsgBox, 48, Error, Failed to encrypt password.
        return
    }

    ; Delete old file if exists
    FileDelete, %Config_CredentialFile%

    ; Write new encrypted password
    FileAppend, %encryptedPassword%, %Config_CredentialFile%
    if (ErrorLevel) {
        MsgBox, 48, Error, Failed to save password.
        return
    }

    ; Save game path
    Config_SaveGamePath(SetupGamePath)

    ; Create shortcut if requested
    if (SetupCreateShortcut)
        CreateDesktopShortcut()

    ; Show success message
    MsgBox, 64, ROALogin Setup, Settings saved successfully!`n`nYour password has been encrypted and stored securely.

    ; Close setup
    Gui, Setup:Destroy

    ; Launch game with auto-login
    if (Config_HasCredentials())
        RunAutoLogin()
    return

SetupGuiClose:
SetupGuiEscape:
    Gui, Setup:Destroy
    ExitApp
    return
}

CreateDesktopShortcut() {
    ; Get desktop path
    desktopPath := A_Desktop

    ; Get current script path (or compiled exe path)
    if (A_IsCompiled)
        exePath := A_ScriptFullPath
    else
        exePath := A_AhkPath

    shortcutPath := desktopPath "\Rise of Agon (Auto-Login).lnk"

    ; Create shortcut using COM
    shell := ComObjCreate("WScript.Shell")
    shortcut := shell.CreateShortcut(shortcutPath)

    if (A_IsCompiled) {
        shortcut.TargetPath := A_ScriptFullPath
        shortcut.WorkingDirectory := A_ScriptDir
    } else {
        shortcut.TargetPath := A_AhkPath
        shortcut.Arguments := """" A_ScriptDir "\roa_login.ahk"""
        shortcut.WorkingDirectory := A_ScriptDir
    }

    shortcut.Description := "Launch Rise of Agon with auto-login"

    ; Try to use the game icon
    gamePath := Config_GetGamePath()
    if (gamePath != "" && FileExist(gamePath))
        shortcut.IconLocation := gamePath ",0"

    shortcut.Save()
}
