# ROALogin

Auto-login tool for Rise of Agon. Automatically fills your password when the game launcher starts.

## Features

- **Automatic**: Fills password silently when you launch the game
- **Secure**: Password encrypted using Windows DPAPI (same security as Chrome passwords)
- **Lightweight**: Single ~1MB executable, no dependencies
- **Portable**: Encrypted password tied to your Windows account

## Installation

### Option 1: Pre-built Executable

1. Download `ROALogin.exe` from releases
2. Run `ROALogin.exe`
3. Enter your Rise of Agon password in the setup window
4. Click "Save & Launch Game"
5. Check "Create desktop shortcut" to add a shortcut

### Option 2: Build from Source

Requirements:
- [AutoHotkey v2](https://www.autohotkey.com/download/)

Steps:
1. Clone or download this repository
2. Run `build.bat`
3. Find `ROALogin.exe` in the `dist` folder

## Usage

### First Time Setup

1. Run `ROALogin.exe`
2. Enter your password (and confirm it)
3. Select your game path if not auto-detected
4. Click "Save & Launch Game"

### Daily Use

Just launch the game using the shortcut created by ROALogin. Your password will be filled automatically.

### Changing Password

Run `ROALogin.exe --setup` or delete `%APPDATA%\ROALogin\credentials.dat` and run ROALogin again.

## How It Works

1. You run ROALogin (via the desktop shortcut)
2. ROALogin launches the real game launcher
3. ROALogin waits for the login window to appear
4. ROALogin fills in your saved password
5. ROALogin exits

## Security

- Your password is encrypted using [Windows DPAPI](https://docs.microsoft.com/en-us/windows/win32/api/dpapi/)
- The encrypted password can **only** be decrypted by your Windows user account on your machine
- If someone copies the credentials file to another computer, it's useless
- No data is ever sent over the network
- Source code is available for inspection

## File Locations

- Encrypted password: `%APPDATA%\ROALogin\credentials.dat`
- Configuration: `%APPDATA%\ROALogin\config.ini`

## Troubleshooting

### "Could not find Rise of Agon installation"

Run setup and manually browse to select `Darkfall_RoA.exe`.

### Password not filling correctly

The launcher window may have changed. Try running the game normally and note the exact window title, then file an issue.

### Antivirus false positive

Some antivirus software may flag AutoHotkey executables. This is a false positive. You can:
- Add an exception for ROALogin.exe
- Build from source to verify the code

## License

MIT License - See LICENSE file
