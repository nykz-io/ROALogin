#Requires AutoHotkey v2.0

; DPAPI Wrapper for Secure Password Storage
; Uses Windows CryptProtectData/CryptUnprotectData APIs
; Encrypted data is tied to the current Windows user account

class DPAPI {
    ; DATA_BLOB structure for DPAPI
    static BLOB_SIZE := A_PtrSize * 2  ; cbData (DWORD) + pbData (pointer)

    ; Encrypt a string using Windows DPAPI
    ; Returns base64-encoded encrypted data
    static Encrypt(plainText) {
        if (plainText = "")
            return ""

        ; Convert string to UTF-8 bytes
        utf8 := Buffer(StrPut(plainText, "UTF-8"))
        StrPut(plainText, utf8, "UTF-8")

        ; Set up input DATA_BLOB
        dataIn := Buffer(this.BLOB_SIZE, 0)
        NumPut("UInt", utf8.Size, dataIn, 0)
        NumPut("Ptr", utf8.Ptr, dataIn, A_PtrSize)

        ; Output DATA_BLOB
        dataOut := Buffer(this.BLOB_SIZE, 0)

        ; Call CryptProtectData
        ; Flags: CRYPTPROTECT_UI_FORBIDDEN = 0x1 (no UI prompts)
        result := DllCall("Crypt32.dll\CryptProtectData",
            "Ptr", dataIn.Ptr,          ; pDataIn
            "Ptr", 0,                    ; szDataDescr (optional)
            "Ptr", 0,                    ; pOptionalEntropy (optional)
            "Ptr", 0,                    ; pvReserved
            "Ptr", 0,                    ; pPromptStruct
            "UInt", 0x1,                 ; dwFlags (CRYPTPROTECT_UI_FORBIDDEN)
            "Ptr", dataOut.Ptr,          ; pDataOut
            "Int")

        if (!result) {
            throw Error("CryptProtectData failed: " DllCall("Kernel32.dll\GetLastError"))
        }

        ; Extract encrypted data
        cbData := NumGet(dataOut, 0, "UInt")
        pbData := NumGet(dataOut, A_PtrSize, "Ptr")

        ; Copy to buffer
        encryptedBuf := Buffer(cbData)
        DllCall("msvcrt.dll\memcpy", "Ptr", encryptedBuf.Ptr, "Ptr", pbData, "UPtr", cbData)

        ; Free the allocated memory from DPAPI
        DllCall("Kernel32.dll\LocalFree", "Ptr", pbData)

        ; Convert to base64
        return this.ToBase64(encryptedBuf)
    }

    ; Decrypt a base64-encoded DPAPI encrypted string
    ; Returns the original plaintext
    static Decrypt(encryptedBase64) {
        if (encryptedBase64 = "")
            return ""

        ; Decode from base64
        encryptedBuf := this.FromBase64(encryptedBase64)

        ; Set up input DATA_BLOB
        dataIn := Buffer(this.BLOB_SIZE, 0)
        NumPut("UInt", encryptedBuf.Size, dataIn, 0)
        NumPut("Ptr", encryptedBuf.Ptr, dataIn, A_PtrSize)

        ; Output DATA_BLOB
        dataOut := Buffer(this.BLOB_SIZE, 0)

        ; Call CryptUnprotectData
        result := DllCall("Crypt32.dll\CryptUnprotectData",
            "Ptr", dataIn.Ptr,          ; pDataIn
            "Ptr", 0,                    ; ppszDataDescr (optional)
            "Ptr", 0,                    ; pOptionalEntropy (optional)
            "Ptr", 0,                    ; pvReserved
            "Ptr", 0,                    ; pPromptStruct
            "UInt", 0x1,                 ; dwFlags (CRYPTPROTECT_UI_FORBIDDEN)
            "Ptr", dataOut.Ptr,          ; pDataOut
            "Int")

        if (!result) {
            throw Error("CryptUnprotectData failed: " DllCall("Kernel32.dll\GetLastError"))
        }

        ; Extract decrypted data
        cbData := NumGet(dataOut, 0, "UInt")
        pbData := NumGet(dataOut, A_PtrSize, "Ptr")

        ; Read UTF-8 string
        plainText := StrGet(pbData, cbData, "UTF-8")

        ; Free the allocated memory from DPAPI
        DllCall("Kernel32.dll\LocalFree", "Ptr", pbData)

        return plainText
    }

    ; Convert buffer to base64 string
    static ToBase64(buf) {
        ; Get required length
        DllCall("Crypt32.dll\CryptBinaryToStringW",
            "Ptr", buf.Ptr,
            "UInt", buf.Size,
            "UInt", 0x40000001,  ; CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF
            "Ptr", 0,
            "UInt*", &length := 0)

        ; Allocate output buffer
        out := Buffer(length * 2)

        ; Convert
        DllCall("Crypt32.dll\CryptBinaryToStringW",
            "Ptr", buf.Ptr,
            "UInt", buf.Size,
            "UInt", 0x40000001,
            "Ptr", out.Ptr,
            "UInt*", &length)

        return StrGet(out, "UTF-16")
    }

    ; Convert base64 string to buffer
    static FromBase64(str) {
        ; Get required length
        DllCall("Crypt32.dll\CryptStringToBinaryW",
            "Str", str,
            "UInt", 0,
            "UInt", 0x1,  ; CRYPT_STRING_BASE64
            "Ptr", 0,
            "UInt*", &size := 0,
            "Ptr", 0,
            "Ptr", 0)

        ; Allocate buffer
        buf := Buffer(size)

        ; Convert
        DllCall("Crypt32.dll\CryptStringToBinaryW",
            "Str", str,
            "UInt", 0,
            "UInt", 0x1,
            "Ptr", buf.Ptr,
            "UInt*", &size,
            "Ptr", 0,
            "Ptr", 0)

        return buf
    }
}
