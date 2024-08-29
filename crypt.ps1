# Função para gerar uma chave aleatória
function Generate-Key {
    $key = New-Object byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)
    return [Convert]::ToBase64String($key)
}

# Função para criptografar um arquivo
function Encrypt-File {
    param(
        [string]$filePath,
        [string]$key
    )

    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $encryptor = New-Object System.Security.Cryptography.AesManaged
    $encryptor.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $encryptor.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $encryptor.KeySize = 256
    $encryptor.BlockSize = 128

    $encryptor.Key = [System.Convert]::FromBase64String($key)
    $encryptor.GenerateIV()

    $memoryStream = New-Object System.IO.MemoryStream
    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream(
        $memoryStream,
        $encryptor.CreateEncryptor(),
        [System.Security.Cryptography.CryptoStreamMode]::Write
    )

    $cryptoStream.Write($bytes, 0, $bytes.Length)
    $cryptoStream.FlushFinalBlock()

    $encryptedBytes = $encryptor.IV + $memoryStream.ToArray()
    [System.IO.File]::WriteAllBytes($filePath, $encryptedBytes)

    $cryptoStream.Close()
    $memoryStream.Close()
    $encryptor.Clear()
}

# Função para criptografar todos os arquivos em uma pasta
function Encrypt-Folder {
    param(
        [string]$folderPath,
        [string]$key
    )

    $files = Get-ChildItem -Path $folderPath -Recurse -File
    foreach ($file in $files) {
        Encrypt-File -filePath $file.FullName -key $key
        Write-Host "Arquivo criptografado: $($file.FullName)"
    }
}

# Gerar e salvar a chave
$key = Generate-Key
$key | Out-File -FilePath ".\chave.key"

# Pasta a ser criptografada
$targetFolder = "C:\Users\emanuel\Documents\teste"

# Criptografar a pasta
Encrypt-Folder -folderPath $targetFolder -key $key

Write-Host "Criptografia concluída."