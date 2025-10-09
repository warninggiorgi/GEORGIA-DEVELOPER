# =========================================
# PowerShell Script: Auto Optional Updates on Startup
# =========================================

# Проверка прав администратора
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Запусти этот скрипт от имени администратора!"
    exit
}

# Папка для скрипта
$scriptFolder = "$env:ProgramData\AutoOptionalUpdates"
if (-not (Test-Path $scriptFolder)) {
    New-Item -ItemType Directory -Path $scriptFolder -Force | Out-Null
}

$scriptPath = Join-Path $scriptFolder "AutoOptionalUpdates.ps1"

# --- Если скрипт ещё не создан, создаём файл для автозапуска ---
if (-not (Test-Path $scriptPath)) {

    $scriptContent = @"
# =========================================
# Auto Optional Updates Script
# =========================================

# Проверка и включение службы Windows Update
\$service = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
if (\$service.Status -ne "Running") { Start-Service wuauserv }

# Поиск Optional Updates
\$UpdateSession = New-Object -ComObject "Microsoft.Update.Session"
\$UpdateSearcher = \$UpdateSession.CreateUpdateSearcher()
\$SearchResult = \$UpdateSearcher.Search("IsInstalled=0 and Type='Software'")

\$OptionalUpdates = @()
foreach (\$update in \$SearchResult.Updates) {
    if (\$update.MsrcSeverity -eq \$null -or \$update.MsrcSeverity -eq "") { \$OptionalUpdates += \$update }
}

if (\$OptionalUpdates.Count -gt 0) {
    \$UpdateInstaller = \$UpdateSession.CreateUpdateInstaller()
    \$UpdateInstaller.Updates = \$OptionalUpdates
    \$UpdateInstaller.Install()
}

exit
"@

    # Сохраняем скрипт в файл
    $scriptContent | Set-Content -Path $scriptPath -Force

    # Создаём задачу в Планировщике
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "AutoOptionalUpdates" -Description "Automatically install Optional Updates on startup" -User "SYSTEM" -RunLevel Highest -Force
}

# --- Выполнение текущего скрипта сразу ---
# Проверка и включение службы Windows Update
$service = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
if ($service.Status -ne "Running") { Start-Service wuauserv }

# Поиск Optional Updates
$UpdateSession = New-Object -ComObject "Microsoft.Update.Session"
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")

$OptionalUpdates = @()
foreach ($update in $SearchResult.Updates) {
    if ($update.MsrcSeverity -eq $null -or $update.MsrcSeverity -eq "") { $OptionalUpdates += $update }
}

if ($OptionalUpdates.Count -gt 0) {
    $UpdateInstaller = $UpdateSession.CreateUpdateInstaller()
    $UpdateInstaller.Updates = $OptionalUpdates
    $UpdateInstaller.Install()
}

exit
