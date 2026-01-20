#Requires AutoHotkey v2.0

; Configuration for ROALogin
; Modify these values if needed for your specific setup

class Config {
    ; Credential storage location
    static CredentialFile := A_AppData "\ROALogin\credentials.dat"
    static ConfigFile := A_AppData "\ROALogin\config.ini"

    ; Possible game installation paths to search
    static GamePaths := [
        "C:\Program Files (x86)\Steam\steamapps\common\Rise of Agon\Darkfall_RoA.exe",
        "C:\Program Files\Steam\steamapps\common\Rise of Agon\Darkfall_RoA.exe",
        "D:\Steam\steamapps\common\Rise of Agon\Darkfall_RoA.exe",
        "D:\SteamLibrary\steamapps\common\Rise of Agon\Darkfall_RoA.exe",
        "E:\Steam\steamapps\common\Rise of Agon\Darkfall_RoA.exe",
        "E:\SteamLibrary\steamapps\common\Rise of Agon\Darkfall_RoA.exe",
        "C:\Games\Rise of Agon\Darkfall_RoA.exe",
        "D:\Games\Rise of Agon\Darkfall_RoA.exe"
    ]

    ; Window detection - exact values from Window Spy
    static WindowClass := "ahk_class wxWindowClassNR"
    static WindowExe := "ahk_exe Darkfall_RoA.exe"

    ; Window title patterns (will try in order)
    ; Use SetTitleMatchMode 2 for partial matching
    static WindowTitles := [
        "Darkfall: Rise Of Agon",
        "Rise of Agon",
        "Darkfall"
    ]

    ; Control ClassNN for direct input (more reliable than Tab)
    static UsernameControl := "Edit1"
    static PasswordControl := "Edit2"

    ; Process name to wait for (as backup detection)
    static ProcessName := "Darkfall_RoA.exe"

    ; Timing configuration (milliseconds)
    static WindowWaitTimeout := 60000      ; Max time to wait for login window
    static WindowLoadDelay := 500          ; Delay after window appears before typing
    static KeystrokeDelay := 50            ; Delay between keystrokes
    static RetryDelay := 1000              ; Delay between retry attempts

    ; Number of retry attempts for password entry
    static MaxRetries := 3

    ; Get the saved game path or try to auto-detect
    static GetGamePath() {
        ; First check if we have a saved path
        if FileExist(this.ConfigFile) {
            savedPath := IniRead(this.ConfigFile, "Settings", "GamePath", "")
            if (savedPath != "" && FileExist(savedPath))
                return savedPath
        }

        ; Try to auto-detect from common locations
        for path in this.GamePaths {
            if FileExist(path)
                return path
        }

        ; Try Steam registry
        try {
            steamPath := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath")
            if (steamPath) {
                gamePath := steamPath "\steamapps\common\Rise of Agon\Darkfall_RoA.exe"
                if FileExist(gamePath)
                    return gamePath
            }
        }

        return ""
    }

    ; Save the game path to config
    static SaveGamePath(path) {
        ; Ensure directory exists
        SplitPath(this.ConfigFile, , &dir)
        if !DirExist(dir)
            DirCreate(dir)

        IniWrite(path, this.ConfigFile, "Settings", "GamePath")
    }

    ; Check if credentials exist
    static HasCredentials() {
        return FileExist(this.CredentialFile)
    }

    ; Ensure the credential directory exists
    static EnsureCredentialDir() {
        SplitPath(this.CredentialFile, , &dir)
        if !DirExist(dir)
            DirCreate(dir)
    }
}
