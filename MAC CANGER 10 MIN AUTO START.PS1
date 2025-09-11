# === Путь нового скрипта ===
$newScriptPath = "$env:APPDATA\mac_changer_all.ps1"

# === Текст нового скрипта (смена MAC на всех активных адаптерах каждые 10 минут) ===
$newScriptContent = @'
function Get-RandomMac {
    $hex = "0123456789ABCDEF"
    $mac = ""
    for ($i = 0; $i -lt 12; $i++) {
        $mac += $hex[(Get-Random -Minimum 0 -Maximum 16)]
    }
    return ($mac -replace "(.{2})(?!$)",'$1:')
}

while ($true) {
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    foreach ($adapter in $adapters) {
        $newMac = Get-RandomMac
        Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Меняю MAC на $newMac (адаптер: $($adapter.Name))"
        Set-NetAdapter -Name $adapter.Name -MacAddress $newMac -Confirm:$false
        Restart-NetAdapter -Name $adapter.Name
    }
    Start-Sleep -Seconds 600   # 10 минут
}
'@

# === Сохраняем новый скрипт ===
$newScriptContent | Set-Content -Path $newScriptPath -Encoding UTF8

# === Создаём ярлык в автозагрузку ===
$newShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\mac_changer_all.lnk"
$wshell = New-Object -ComObject WScript.Shell
$shortcut = $wshell.CreateShortcut($newShortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$newScriptPath`""
$shortcut.Save()

Write-Output "✅ Новый скрипт сохранён: $newScriptPath"
Write-Output "✅ Ярлык добавлен в автозагрузку: $newShortcutPath"
Write-Output "Теперь при каждой загрузке Windows MAC будет меняться каждые 10 минут на всех активных адаптерах!"
