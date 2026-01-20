#SingleInstance Force
#NoEnv
SetBatchLines, -1

; ROALogin - Rise of Agon Auto-Login
; Automatically fills the password when the game launcher starts

#Include %A_ScriptDir%\lib\dpapi.ahk
#Include %A_ScriptDir%\lib\config.ahk

; Check command-line arguments
global RunSetup := false
for n, arg in A_Args {
    if (arg = "--setup" || arg = "-s" || arg = "/setup")
        RunSetup := true
}

; Main entry point
Main()
return

Main() {
    ; If --setup flag or no credentials, run setup
    if (RunSetup || !Config_HasCredentials()) {
        ShowSetupGUI()
        return
    }

    ; Normal operation: launch game and fill password
    RunAutoLogin()
}

RunAutoLogin() {
    ; Get game path
    gamePath := Config_GetGamePath()
    if (gamePath = "" || !FileExist(gamePath)) {
        MsgBox, 48, ROALogin - Error, Could not find Rise of Agon installation.`n`nPlease run setup to configure the game path.
        ShowSetupGUI()
        return
    }

    ; Read and decrypt password
    FileRead, encryptedPassword, %Config_CredentialFile%
    if (ErrorLevel || encryptedPassword = "") {
        MsgBox, 48, ROALogin - Error, Failed to read saved password.`n`nPlease run setup again.
        ShowSetupGUI()
        return
    }

    password := DPAPI_Decrypt(encryptedPassword)
    if (password = "") {
        MsgBox, 48, ROALogin - Error, No password found. Please run setup to save your password.
        ShowSetupGUI()
        return
    }

    ; Launch the game
    Run, "%gamePath%", , , gamePID
    if (ErrorLevel) {
        MsgBox, 48, ROALogin - Error, Failed to launch game.`n`nPath: %gamePath%
        return
    }

    ; Wait for the login window using window class (most reliable)
    SetTitleMatchMode, 2  ; Partial match for titles

    ; Try to find window by class first
    WinWait, %Config_WindowClass%, , %Config_WindowWaitTimeout%
    hwnd := WinExist()

    if (!hwnd) {
        ; Try by exe name
        WinWait, %Config_WindowExe%, , 5
        hwnd := WinExist()
    }

    if (!hwnd) {
        ; Try by title
        WinWait, %Config_WindowTitle%, , 5
        hwnd := WinExist()
    }

    if (!hwnd) {
        ; Window didn't appear in time - exit silently
        ExitApp
    }

    ; Give the window time to fully load
    Sleep, %Config_WindowLoadDelay%

    ; Activate the window
    WinActivate, ahk_id %hwnd%
    Sleep, 200

    ; Fill the password directly into Edit2 control
    FillPassword(password, hwnd)

    ; Clear password from memory
    password := ""

    ; Exit
    ExitApp
}

FillPassword(password, hwnd) {
    ; Method 1: Direct control text (most reliable)
    ControlSetText, %Config_PasswordControl%, %password%, ahk_id %hwnd%
    if (!ErrorLevel)
        return

    ; Method 2: ControlSend to the password field
    ControlFocus, %Config_PasswordControl%, ahk_id %hwnd%
    Sleep, %Config_KeystrokeDelay%
    ControlSend, %Config_PasswordControl%, %password%, ahk_id %hwnd%
    if (!ErrorLevel)
        return

    ; Method 3: Tab from username and type (fallback)
    ControlFocus, %Config_UsernameControl%, ahk_id %hwnd%
    Sleep, %Config_KeystrokeDelay%
    Send, {Tab}
    Sleep, %Config_KeystrokeDelay%
    SendRaw, %password%
}

; Include setup GUI
#Include %A_ScriptDir%\setup.ahk
