#Requires AutoHotkey v2.0
#SingleInstance Force

; ROALogin - Rise of Agon Auto-Login
; Automatically fills the password when the game launcher starts

#Include "lib\dpapi.ahk"
#Include "lib\config.ahk"

; Check command-line arguments
global RunSetup := false
for arg in A_Args {
    if (arg = "--setup" || arg = "-s" || arg = "/setup")
        RunSetup := true
}

; Main entry point
Main()

Main() {
    ; If --setup flag or no credentials, run setup
    if (RunSetup || !Config.HasCredentials()) {
        RunSetupMode()
        return
    }

    ; Normal operation: launch game and fill password
    RunAutoLogin()
}

RunSetupMode() {
    ; Include and run the setup GUI
    #Include "setup.ahk"
}

RunAutoLogin() {
    ; Get game path
    gamePath := Config.GetGamePath()
    if (gamePath = "" || !FileExist(gamePath)) {
        MsgBox("Could not find Rise of Agon installation.`n`nPlease run setup to configure the game path.",
            "ROALogin - Error", "Icon!")
        RunSetupMode()
        return
    }

    ; Read and decrypt password
    try {
        encryptedPassword := FileRead(Config.CredentialFile)
        password := DPAPI.Decrypt(encryptedPassword)
    } catch as e {
        MsgBox("Failed to read saved password.`n`nPlease run setup again.`n`nError: " e.Message,
            "ROALogin - Error", "Icon!")
        RunSetupMode()
        return
    }

    if (password = "") {
        MsgBox("No password found. Please run setup to save your password.",
            "ROALogin - Error", "Icon!")
        RunSetupMode()
        return
    }

    ; Launch the game
    try {
        Run('"' gamePath '"')
    } catch as e {
        MsgBox("Failed to launch game.`n`nPath: " gamePath "`n`nError: " e.Message,
            "ROALogin - Error", "Icon!")
        return
    }

    ; Wait for the login window using window class (most reliable)
    SetTitleMatchMode(2)  ; Partial match for titles

    ; Try to find window by class first (most reliable), then by title
    hwnd := WinWait(Config.WindowClass, , Config.WindowWaitTimeout / 1000)

    if (!hwnd) {
        ; Try by exe name
        hwnd := WinWait(Config.WindowExe, , 5)
    }

    if (!hwnd) {
        ; Try by title as last resort
        for title in Config.WindowTitles {
            hwnd := WinWait(title, , 5)
            if (hwnd)
                break
        }
    }

    if (!hwnd) {
        ; Window didn't appear in time - exit silently
        ExitApp()
    }

    ; Give the window time to fully load
    Sleep(Config.WindowLoadDelay)

    ; Activate the window
    WinActivate(hwnd)
    Sleep(200)

    ; Fill the password directly into Edit2 control
    FillPassword(password, hwnd)

    ; Clear password from memory
    password := ""

    ; Exit
    ExitApp()
}

FillPassword(password, hwnd) {
    ; Method 1: Direct control text (most reliable, no focus needed)
    try {
        ControlSetText(password, Config.PasswordControl, hwnd)
        return
    }

    ; Method 2: ControlSend to the password field
    try {
        ControlFocus(Config.PasswordControl, hwnd)
        Sleep(Config.KeystrokeDelay)
        ControlSendText(password, Config.PasswordControl, hwnd)
        return
    }

    ; Method 3: Tab from username and type (fallback)
    try {
        ControlFocus(Config.UsernameControl, hwnd)
        Sleep(Config.KeystrokeDelay)
        SendInput("{Tab}")
        Sleep(Config.KeystrokeDelay)
        SendText(password)
        return
    }

    ; Method 4: Clipboard paste as last resort
    try {
        oldClipboard := A_Clipboard
        A_Clipboard := password
        Sleep(100)
        ControlFocus(Config.PasswordControl, hwnd)
        Sleep(Config.KeystrokeDelay)
        Send("^v")
        Sleep(100)
        A_Clipboard := oldClipboard
    }
}
