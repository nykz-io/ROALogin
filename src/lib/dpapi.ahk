; DPAPI Wrapper for Secure Password Storage
; Uses Windows CryptProtectData/CryptUnprotectData APIs
; Encrypted data is tied to the current Windows user account

DPAPI_Encrypt(plainText) {
    if (plainText = "")
        return ""

    ; Convert string to UTF-8 bytes
    VarSetCapacity(utf8, StrPut(plainText, "UTF-8"), 0)
    StrPut(plainText, &utf8, "UTF-8")
    utf8Size := StrPut(plainText, "UTF-8") - 1

    ; Set up input DATA_BLOB (cbData + pbData)
    VarSetCapacity(dataIn, A_PtrSize * 2, 0)
    NumPut(utf8Size, dataIn, 0, "UInt")
    NumPut(&utf8, dataIn, A_PtrSize, "Ptr")

    ; Output DATA_BLOB
    VarSetCapacity(dataOut, A_PtrSize * 2, 0)

    ; Call CryptProtectData
    ; Flags: CRYPTPROTECT_UI_FORBIDDEN = 0x1 (no UI prompts)
    result := DllCall("Crypt32.dll\CryptProtectData"
        , "Ptr", &dataIn          ; pDataIn
        , "Ptr", 0                ; szDataDescr (optional)
        , "Ptr", 0                ; pOptionalEntropy (optional)
        , "Ptr", 0                ; pvReserved
        , "Ptr", 0                ; pPromptStruct
        , "UInt", 0x1             ; dwFlags (CRYPTPROTECT_UI_FORBIDDEN)
        , "Ptr", &dataOut         ; pDataOut
        , "Int")

    if (!result) {
        return ""
    }

    ; Extract encrypted data
    cbData := NumGet(dataOut, 0, "UInt")
    pbData := NumGet(dataOut, A_PtrSize, "Ptr")

    ; Copy to our buffer
    VarSetCapacity(encryptedBuf, cbData, 0)
    DllCall("msvcrt.dll\memcpy", "Ptr", &encryptedBuf, "Ptr", pbData, "UPtr", cbData)

    ; Free the allocated memory from DPAPI
    DllCall("Kernel32.dll\LocalFree", "Ptr", pbData)

    ; Convert to base64
    return DPAPI_ToBase64(encryptedBuf, cbData)
}

DPAPI_Decrypt(encryptedBase64) {
    if (encryptedBase64 = "")
        return ""

    ; Decode from base64
    encryptedSize := DPAPI_FromBase64(encryptedBase64, encryptedBuf)
    if (encryptedSize = 0)
        return ""

    ; Set up input DATA_BLOB
    VarSetCapacity(dataIn, A_PtrSize * 2, 0)
    NumPut(encryptedSize, dataIn, 0, "UInt")
    NumPut(&encryptedBuf, dataIn, A_PtrSize, "Ptr")

    ; Output DATA_BLOB
    VarSetCapacity(dataOut, A_PtrSize * 2, 0)

    ; Call CryptUnprotectData
    result := DllCall("Crypt32.dll\CryptUnprotectData"
        , "Ptr", &dataIn          ; pDataIn
        , "Ptr", 0                ; ppszDataDescr (optional)
        , "Ptr", 0                ; pOptionalEntropy (optional)
        , "Ptr", 0                ; pvReserved
        , "Ptr", 0                ; pPromptStruct
        , "UInt", 0x1             ; dwFlags (CRYPTPROTECT_UI_FORBIDDEN)
        , "Ptr", &dataOut         ; pDataOut
        , "Int")

    if (!result) {
        return ""
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

DPAPI_ToBase64(ByRef buf, size) {
    ; Get required length
    DllCall("Crypt32.dll\CryptBinaryToStringW"
        , "Ptr", &buf
        , "UInt", size
        , "UInt", 0x40000001  ; CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF
        , "Ptr", 0
        , "UInt*", length)

    ; Allocate output buffer
    VarSetCapacity(out, length * 2, 0)

    ; Convert
    DllCall("Crypt32.dll\CryptBinaryToStringW"
        , "Ptr", &buf
        , "UInt", size
        , "UInt", 0x40000001
        , "Ptr", &out
        , "UInt*", length)

    return StrGet(&out, "UTF-16")
}

DPAPI_FromBase64(str, ByRef buf) {
    ; Get required length
    DllCall("Crypt32.dll\CryptStringToBinaryW"
        , "Str", str
        , "UInt", 0
        , "UInt", 0x1  ; CRYPT_STRING_BASE64
        , "Ptr", 0
        , "UInt*", size
        , "Ptr", 0
        , "Ptr", 0)

    ; Allocate buffer
    VarSetCapacity(buf, size, 0)

    ; Convert
    DllCall("Crypt32.dll\CryptStringToBinaryW"
        , "Str", str
        , "UInt", 0
        , "UInt", 0x1
        , "Ptr", &buf
        , "UInt*", size
        , "Ptr", 0
        , "Ptr", 0)

    return size
}
