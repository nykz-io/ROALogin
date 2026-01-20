#Requires AutoHotkey v2.0

; ROALogin Setup GUI
; First-time setup for password storage and shortcut creation

; This file is included by roa_login.ahk when setup is needed
; It can also be run standalone

; Only run setup GUI if this file is the main script or RunSetup is true
if (A_ScriptName = "setup.ahk" || (IsSet(RunSetup) && RunSetup) || !Config.HasCredentials()) {
    ShowSetupGUI()
}

ShowSetupGUI() {
    ; Create the setup window
    setupGui := Gui("+AlwaysOnTop", "ROALogin Setup")
    setupGui.SetFont("s10")

    ; Password section
    setupGui.Add("Text", "w300", "Enter your Rise of Agon password:")
    passwordEdit := setupGui.Add("Edit", "w300 Password vPassword")

    setupGui.Add("Text", "w300 y+15", "Confirm password:")
    confirmEdit := setupGui.Add("Edit", "w300 Password vConfirmPassword")

    ; Game path section
    setupGui.Add("Text", "w300 y+20", "Game executable path:")

    ; Try to auto-detect path
    detectedPath := Config.GetGamePath()
    pathEdit := setupGui.Add("Edit", "w230 vGamePath", detectedPath)
    browseBtn := setupGui.Add("Button", "x+5 w60", "Browse")
    browseBtn.OnEvent("Click", BrowseForGame)

    ; Status indicator for path
    pathStatus := setupGui.Add("Text", "x10 w300 cGreen vPathStatus",
        detectedPath != "" && FileExist(detectedPath) ? "Game found" : "")

    ; Shortcut option
    setupGui.Add("Text", "x10 y+20 w300", "")
    shortcutCheck := setupGui.Add("Checkbox", "vCreateShortcut Checked", "Create desktop shortcut")

    ; Buttons
    setupGui.Add("Text", "w300 y+20", "")  ; Spacer
    saveBtn := setupGui.Add("Button", "x10 w140 Default", "Save && Launch Game")
    saveBtn.OnEvent("Click", SaveSettings)

    cancelBtn := setupGui.Add("Button", "x+20 w140", "Cancel")
    cancelBtn.OnEvent("Click", (*) => ExitApp())

    ; Handle window close
    setupGui.OnEvent("Close", (*) => ExitApp())

    ; Show the GUI
    setupGui.Show()

    ; Browse button handler
    BrowseForGame(*) {
        selectedFile := FileSelect(1, , "Select Darkfall_RoA.exe", "Executable (*.exe)")
        if (selectedFile != "") {
            pathEdit.Value := selectedFile
            if FileExist(selectedFile)
                pathStatus.Value := "Game found"
            else
                pathStatus.Value := ""
        }
    }

    ; Save settings handler
    SaveSettings(*) {
        ; Get values
        data := setupGui.Submit(false)  ; Don't hide the GUI yet

        ; Validate password
        if (data.Password = "") {
            MsgBox("Please enter a password.", "Validation Error", "Icon!")
            return
        }

        if (data.Password != data.ConfirmPassword) {
            MsgBox("Passwords do not match.", "Validation Error", "Icon!")
            return
        }

        ; Validate game path
        if (data.GamePath = "" || !FileExist(data.GamePath)) {
            MsgBox("Please select a valid game executable.", "Validation Error", "Icon!")
            return
        }

        ; Ensure directories exist
        Config.EnsureCredentialDir()

        ; Encrypt and save password
        try {
            encryptedPassword := DPAPI.Encrypt(data.Password)
            FileDelete(Config.CredentialFile)  ; Remove old file if exists
        } catch {
            ; File might not exist, that's OK
        }

        try {
            FileAppend(encryptedPassword, Config.CredentialFile)
        } catch as e {
            MsgBox("Failed to save password.`n`nError: " e.Message, "Error", "Icon!")
            return
        }

        ; Save game path
        Config.SaveGamePath(data.GamePath)

        ; Create shortcut if requested
        if (data.CreateShortcut) {
            CreateDesktopShortcut()
        }

        ; Show success message
        MsgBox("Settings saved successfully!`n`nYour password has been encrypted and stored securely.",
            "ROALogin Setup", "Iconi")

        ; Close setup and launch game
        setupGui.Destroy()

        ; If we have everything set up, run the auto-login
        if (Config.HasCredentials()) {
            RunAutoLogin()
        }
    }
}

CreateDesktopShortcut() {
    ; Get desktop path
    desktopPath := A_Desktop

    ; Get current script path (or compiled exe path)
    if A_IsCompiled
        exePath := A_ScriptFullPath
    else
        exePath := A_AhkPath '" "' A_ScriptDir '\roa_login.ahk'

    shortcutPath := desktopPath "\Rise of Agon (Auto-Login).lnk"

    ; Create shortcut using COM
    try {
        shell := ComObject("WScript.Shell")
        shortcut := shell.CreateShortcut(shortcutPath)

        if A_IsCompiled {
            shortcut.TargetPath := A_ScriptFullPath
            shortcut.WorkingDirectory := A_ScriptDir
        } else {
            shortcut.TargetPath := A_AhkPath
            shortcut.Arguments := '"' A_ScriptDir '\roa_login.ahk"'
            shortcut.WorkingDirectory := A_ScriptDir
        }

        shortcut.Description := "Launch Rise of Agon with auto-login"

        ; Try to use the game icon
        gamePath := Config.GetGamePath()
        if (gamePath != "" && FileExist(gamePath))
            shortcut.IconLocation := gamePath ",0"

        shortcut.Save()
    } catch as e {
        MsgBox("Could not create desktop shortcut.`n`nError: " e.Message, "Warning", "Icon!")
    }
}
