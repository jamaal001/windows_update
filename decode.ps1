Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Decrypt-Image {
    $keyString = "secretKey123".PadRight(16)
    $key = [System.Text.Encoding]::UTF8.GetBytes($keyString)
    $iv = @(0..15 | ForEach-Object { 0 })  # 16-byte zero IV

    $tempPath = [System.IO.Path]::GetTempPath()
    $hiddenDir = Join-Path $tempPath "hidden"
    $inputFile = Join-Path $hiddenDir "photo.dat"
    $outputFile = Join-Path $hiddenDir "photo.jpg"

    if (-Not (Test-Path $inputFile)) {
        Write-Host "❌ Encrypted file not found at: $inputFile"
        return
    }

    try {
        $cipherBytes = [System.IO.File]::ReadAllBytes($inputFile)

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv

        $decryptor = $aes.CreateDecryptor()
        $ms = New-Object System.IO.MemoryStream
        $cs = New-Object System.Security.Cryptography.CryptoStream($ms, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)

        $cs.Write($cipherBytes, 0, $cipherBytes.Length)
        $cs.FlushFinalBlock()
        $cs.Close()

        $plainBytes = $ms.ToArray()
        [System.IO.File]::WriteAllBytes($outputFile, $plainBytes)

        Write-Host "✅ Decrypted image saved to: $outputFile"
    }
    catch {
        Write-Host "⚠️ Error:" $_.Exception.Message
    }
}

Decrypt-Image
