; Configuration for ROALogin
; Modify these values if needed for your specific setup

; Credential storage location
global Config_CredentialFile := A_AppData "\ROALogin\credentials.dat"
global Config_ConfigFile := A_AppData "\ROALogin\config.ini"

; Window detection - exact values from Window Spy
global Config_WindowClass := "ahk_class wxWindowClassNR"
global Config_WindowExe := "ahk_exe Darkfall_RoA.exe"
global Config_WindowTitle := "Darkfall: Rise Of Agon"

; Control ClassNN for direct input
global Config_UsernameControl := "Edit1"
global Config_PasswordControl := "Edit2"

; Process name
global Config_ProcessName := "Darkfall_RoA.exe"

; Timing configuration (milliseconds)
global Config_WindowWaitTimeout := 60  ; seconds for WinWait
global Config_WindowLoadDelay := 500
global Config_KeystrokeDelay := 50

; Possible game installation paths to search
Config_GetGamePath() {
    ; First check if we have a saved path
    if FileExist(Config_ConfigFile) {
        IniRead, savedPath, %Config_ConfigFile%, Settings, GamePath, ""
        if (savedPath != "" && FileExist(savedPath))
            return savedPath
    }

    ; Try common locations
    paths := ["C:\Program Files (x86)\Steam\steamapps\common\Rise of Agon\Darkfall_RoA.exe"
            , "C:\Program Files\Steam\steamapps\common\Rise of Agon\Darkfall_RoA.exe"
            , "D:\Steam\steamapps\common\Rise of Agon\Darkfall_RoA.exe"
            , "D:\SteamLibrary\steamapps\common\Rise of Agon\Darkfall_RoA.exe"
            , "E:\Steam\steamapps\common\Rise of Agon\Darkfall_RoA.exe"
            , "E:\SteamLibrary\steamapps\common\Rise of Agon\Darkfall_RoA.exe"
            , "C:\Games\Rise of Agon\Darkfall_RoA.exe"
            , "D:\Games\Rise of Agon\Darkfall_RoA.exe"]

    for index, path in paths {
        if FileExist(path)
            return path
    }

    ; Try Steam registry
    RegRead, steamPath, HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam, InstallPath
    if (steamPath != "") {
        gamePath := steamPath "\steamapps\common\Rise of Agon\Darkfall_RoA.exe"
        if FileExist(gamePath)
            return gamePath
    }

    return ""
}

Config_SaveGamePath(path) {
    ; Ensure directory exists
    SplitPath, Config_ConfigFile, , dir
    if !InStr(FileExist(dir), "D")
        FileCreateDir, %dir%

    IniWrite, %path%, %Config_ConfigFile%, Settings, GamePath
}

Config_HasCredentials() {
    return FileExist(Config_CredentialFile)
}

Config_EnsureCredentialDir() {
    SplitPath, Config_CredentialFile, , dir
    if !InStr(FileExist(dir), "D")
        FileCreateDir, %dir%
}
