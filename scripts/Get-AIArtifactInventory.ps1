<#
.SYNOPSIS
Produces a metadata-only inventory of selected Windows and AI artifact locations.
.DESCRIPTION
Current-user scope. Reports path/key presence, aggregate direct-file statistics,
known artifact-file metadata, and environment override presence as booleans.
Does not read file contents, Registry value data, chats, logs, cookies, credentials,
browser database records, or account identifiers. Does not use the network,
elevate, alter Registry keys, or change logging settings.

This is live triage, not forensic acquisition. Running PowerShell and querying
the live system can create or change operating-system and application traces.
Directory enumeration is direct only. Reparse-point directories are skipped.
Defaults and fixed candidates can miss portable installs, redirected locations,
other users, remote systems, cloud records, WSL, containers, and deleted data.

Without -OutputPath, emits JSON to stdout. With -OutputPath, creates a new UTF-8
JSON file and its parent directory if necessary. Existing files are refused;
creation uses FileMode.CreateNew to prevent an overwrite race.
.PARAMETER OutputPath
Optional new JSON output file. Existing destinations are never overwritten.
Its path is not included in the inventory.
.EXAMPLE
.\Get-AIArtifactInventory.ps1
.EXAMPLE
.\Get-AIArtifactInventory.ps1 -OutputPath .\workstation-metadata.json
#>
[CmdletBinding()]
param([string]$OutputPath)

$ErrorActionPreference = 'Stop'

function Get-ObservationStatus {
    param([System.Management.Automation.ErrorRecord]$Record)
    $denied = $Record.CategoryInfo.Category -eq 'PermissionDenied'
    $notFound = $Record.CategoryInfo.Category -eq 'ObjectNotFound'
    $exception = $Record.Exception
    while ($null -ne $exception) {
        if (($exception -is [System.UnauthorizedAccessException]) -or
            ($exception -is [System.Security.SecurityException])) { $denied = $true }
        if (($exception -is [System.Management.Automation.ItemNotFoundException]) -or
            ($exception -is [System.IO.FileNotFoundException]) -or
            ($exception -is [System.IO.DirectoryNotFoundException])) { $notFound = $true }
        $exception = $exception.InnerException
    }
    if ($denied) { return 'access_denied' }
    if ($notFound) { return 'not_found_at_checked_path' }
    return 'error'
}

function Test-ReparseComponent {
    param([System.IO.FileSystemInfo]$Item)
    if (($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
    if ($Item -is [System.IO.DirectoryInfo]) { $parent = $Item.Parent }
    else { $parent = $Item.Directory }
    while ($null -ne $parent) {
        $parentItem = Get-Item -LiteralPath $parent.FullName -Force -ErrorAction Stop
        if (($parentItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
        $parent = $parent.Parent
    }
    return $false
}

function Get-FileObservation {
    param([string]$LiteralPath, [string]$Alias)
    try {
        $item = Get-Item -LiteralPath $LiteralPath -Force -ErrorAction Stop
        if ($item.PSIsContainer) {
            return [pscustomobject][ordered]@{ path = $Alias; status = 'unexpected_directory' }
        }
        if (Test-ReparseComponent -Item $item) {
            return [pscustomobject][ordered]@{ path = $Alias; status = 'skipped_reparse_point' }
        }
        return [pscustomobject][ordered]@{
            path = $Alias; status = 'present'; bytes = [long]$item.Length
            modified_utc = $item.LastWriteTimeUtc.ToString('o')
        }
    } catch {
        return [pscustomobject][ordered]@{ path = $Alias; status = (Get-ObservationStatus $_) }
    }
}

function Get-DirectoryObservation {
    param([string]$LiteralPath, [string]$Alias)
    try {
        $directory = Get-Item -LiteralPath $LiteralPath -Force -ErrorAction Stop
        if (-not $directory.PSIsContainer) {
            return [pscustomobject][ordered]@{ path = $Alias; status = 'unexpected_file' }
        }
        if (Test-ReparseComponent -Item $directory) {
            return [pscustomobject][ordered]@{ path = $Alias; status = 'skipped_reparse_point' }
        }
        $children = @(Get-ChildItem -LiteralPath $LiteralPath -Force -ErrorAction Stop)
        $files = @($children | Where-Object {
            (-not $_.PSIsContainer) -and
            (($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0)
        })
        $extensionCounts = @{}
        $bytes = [long]0
        foreach ($file in $files) {
            $bytes += [long]$file.Length
            $extension = $file.Extension.ToLowerInvariant()
            if ([string]::IsNullOrEmpty($extension)) { $extension = '(none)' }
            elseif ($extension -notmatch '^\.[a-z0-9]{1,12}$') { $extension = '(other)' }
            if (-not $extensionCounts.ContainsKey($extension)) { $extensionCounts[$extension] = 0 }
            $extensionCounts[$extension]++
        }
        $extensionRows = @(foreach ($extension in @($extensionCounts.Keys | Sort-Object)) {
            [pscustomobject][ordered]@{ extension = $extension; count = $extensionCounts[$extension] }
        })
        $dates = @($files | Sort-Object LastWriteTimeUtc)
        return [pscustomobject][ordered]@{
            path = $Alias; status = 'present'
            direct_file_count = $files.Count; direct_file_bytes = $bytes
            immediate_directory_count = @($children | Where-Object { $_.PSIsContainer }).Count
            reparse_point_count = @($children | Where-Object {
                ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
            }).Count
            oldest_direct_file_modified_utc = $(if ($dates.Count) { $dates[0].LastWriteTimeUtc.ToString('o') } else { $null })
            newest_direct_file_modified_utc = $(if ($dates.Count) { $dates[-1].LastWriteTimeUtc.ToString('o') } else { $null })
            extension_counts = $extensionRows
            direct_wal_suffix_count = @($files | Where-Object { $_.Name -like '*-wal' }).Count
            direct_shm_suffix_count = @($files | Where-Object { $_.Name -like '*-shm' }).Count
        }
    } catch {
        return [pscustomobject][ordered]@{ path = $Alias; status = (Get-ObservationStatus $_) }
    }
}

function Get-RegistryObservation {
    param([string]$LiteralPath)
    try {
        $key = Get-Item -LiteralPath $LiteralPath -ErrorAction Stop
        return [pscustomobject][ordered]@{
            key = $LiteralPath.Replace(':\', '\'); status = 'present'
            direct_value_name_count = @($key.GetValueNames()).Count
            immediate_subkey_count = @($key.GetSubKeyNames()).Count
        }
    } catch {
        return [pscustomobject][ordered]@{
            key = $LiteralPath.Replace(':\', '\'); status = (Get-ObservationStatus $_)
        }
    }
}

function Get-BrowserObservations {
    param([string]$Root, [string]$Alias, [ValidateSet('chromium', 'firefox')][string]$Family)
    $observations = New-Object System.Collections.Generic.List[object]
    $observations.Add((Get-DirectoryObservation -LiteralPath $Root -Alias $Alias))
    if ($observations[0].status -ne 'present') { return @($observations.ToArray()) }
    try {
        $profiles = @(Get-ChildItem -LiteralPath $Root -Directory -Force -ErrorAction Stop | Where-Object {
            (($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) -and
            (($Family -eq 'firefox') -or ($_.Name -match '^(Default|Profile [0-9]+)$'))
        } | Sort-Object Name)
        $observations.Add([pscustomobject][ordered]@{
            path = $Alias; observation = 'profile_discovery'
            candidate_directory_count = $profiles.Count
            profile_limit = 32; profile_limit_reached = ($profiles.Count -gt 32)
            profile_labels = 'Names replaced with ordinal placeholders; ordering is snapshot-specific.'
        })
        $index = 0
        foreach ($profile in @($profiles | Select-Object -First 32)) {
            $index++
            $profileAlias = $Alias + '\<profile-' + $index + '>'
            $observations.Add((Get-DirectoryObservation -LiteralPath $profile.FullName -Alias $profileAlias))
            if ($Family -eq 'chromium') {
                $knownFiles = @('History', 'History-wal', 'History-shm', 'Web Data', 'Web Data-wal',
                    'Web Data-shm', 'Favicons', 'Favicons-wal', 'Favicons-shm', 'Network\Cookies',
                    'Network\Cookies-wal', 'Network\Cookies-shm')
                $knownDirectories = @('IndexedDB', 'Local Storage\leveldb', 'Session Storage',
                    'Service Worker\CacheStorage', 'Cache\Cache_Data')
            } else {
                $knownFiles = @('places.sqlite', 'places.sqlite-wal', 'places.sqlite-shm',
                    'cookies.sqlite', 'cookies.sqlite-wal', 'cookies.sqlite-shm',
                    'favicons.sqlite', 'favicons.sqlite-wal', 'favicons.sqlite-shm')
                $knownDirectories = @('storage\default', 'sessionstore-backups')
            }
            foreach ($relative in $knownFiles) {
                $observations.Add((Get-FileObservation -LiteralPath (Join-Path $profile.FullName $relative) -Alias ($profileAlias + '\' + $relative)))
            }
            foreach ($relative in $knownDirectories) {
                $observations.Add((Get-DirectoryObservation -LiteralPath (Join-Path $profile.FullName $relative) -Alias ($profileAlias + '\' + $relative)))
            }
        }
    } catch {
        $observations.Add([pscustomobject][ordered]@{ path = $Alias; observation = 'profile_discovery'; status = (Get-ObservationStatus $_) })
    }
    return @($observations.ToArray())
}

$directories = @(
    '%USERPROFILE%\.claude', '%USERPROFILE%\.claude\projects',
    '%USERPROFILE%\.claude\file-history', '%USERPROFILE%\.claude\debug',
    '%USERPROFILE%\.claude\tasks', '%USERPROFILE%\.claude\plans',
    '%USERPROFILE%\.claude\paste-cache', '%TEMP%\claude',
    '%USERPROFILE%\.gemini', '%USERPROFILE%\.gemini\tmp',
    '%USERPROFILE%\.gemini\history',
    '%USERPROFILE%\.copilot', '%USERPROFILE%\.copilot\session-state',
    '%USERPROFILE%\.copilot\logs', '%USERPROFILE%\.copilot\command-history-state',
    '%LOCALAPPDATA%\copilot',
    '%USERPROFILE%\.config\opencode', '%USERPROFILE%\.local\share\opencode',
    '%USERPROFILE%\.local\share\opencode\log',
    '%USERPROFILE%\.local\share\opencode\snapshot',
    '%USERPROFILE%\.local\share\opencode\storage',
    '%USERPROFILE%\.local\state\opencode', '%USERPROFILE%\.cache\opencode',
    '%APPDATA%\Code\User\globalStorage', '%APPDATA%\Code\User\workspaceStorage',
    '%APPDATA%\Code\logs',
    '%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\tasks',
    '%APPDATA%\Code\User\globalStorage\rooveterinaryinc.roo-cline\tasks',
    '%USERPROFILE%\.cline', '%USERPROFILE%\.cline\data',
    '%USERPROFILE%\.cline\data\sessions', '%USERPROFILE%\.cline\data\db',
    '%USERPROFILE%\.cline\data\logs',
    '%USERPROFILE%\.continue', '%USERPROFILE%\.continue\sessions',
    '%USERPROFILE%\.continue\logs', '%USERPROFILE%\.continue\dev_data',
    '%USERPROFILE%\.continue\index', '%USERPROFILE%\.continue\.diffs',
    '%APPDATA%\Cursor\User\globalStorage', '%APPDATA%\Cursor\User\workspaceStorage',
    '%APPDATA%\Cursor\logs', '%USERPROFILE%\.cursor\projects',
    '%APPDATA%\Windsurf', '%USERPROFILE%\.codeium',
    '%USERPROFILE%\.openclaw', '%USERPROFILE%\.openclaw\agents',
    '%USERPROFILE%\.hermes', '%LOCALAPPDATA%\hermes',
    '%LOCALAPPDATA%\hermes\profiles', '%APPDATA%\Hermes',
    '%APPDATA%\Hermes\Local Storage\leveldb',
    '%APPDATA%\OpenClawTray', '%LOCALAPPDATA%\OpenClawTray',
    '%APPDATA%\Block\goose\data', '%APPDATA%\Block\goose\data\sessions',
    '%USERPROFILE%\.openhands',
    '%USERPROFILE%\invokeai', '%USERPROFILE%\invokeai\outputs',
    '%USERPROFILE%\invokeai\databases',
    '%USERPROFILE%\.codex', '%USERPROFILE%\.codex\sessions',
    '%USERPROFILE%\.codex\archived_sessions', '%USERPROFILE%\.codex\log',
    '%USERPROFILE%\.codex\tmp', '%USERPROFILE%\.codex\sqlite',
    '%USERPROFILE%\.codex\shell_snapshots',
    '%APPDATA%\Codex', '%APPDATA%\Codex\IndexedDB',
    '%APPDATA%\Codex\Local Storage\leveldb', '%APPDATA%\Codex\Session Storage',
    '%LOCALAPPDATA%\Codex', '%LOCALAPPDATA%\OpenAI',
    '%USERPROFILE%\.ollama', '%USERPROFILE%\.ollama\models',
    '%USERPROFILE%\.ollama\models\manifests', '%USERPROFILE%\.ollama\models\blobs',
    '%LOCALAPPDATA%\Ollama', '%APPDATA%\ollama app.exe',
    '%USERPROFILE%\.lmstudio', '%USERPROFILE%\.lmstudio\models',
    '%USERPROFILE%\.lmstudio\conversations',
    '%APPDATA%\LM Studio', '%APPDATA%\LM Studio\IndexedDB',
    '%APPDATA%\LM Studio\Local Storage\leveldb', '%APPDATA%\LM Studio\Session Storage',
    '%USERPROFILE%\.cache\huggingface', '%USERPROFILE%\.cache\huggingface\hub',
    '%USERPROFILE%\.cache\huggingface\xet', '%USERPROFILE%\.cache\torch\hub',
    '%LOCALAPPDATA%\comfy-cli',
    '%USERPROFILE%\ComfyUI\output', '%USERPROFILE%\ComfyUI\input', '%USERPROFILE%\ComfyUI\temp',
    '%USERPROFILE%\Documents\ComfyUI\output', '%USERPROFILE%\Documents\ComfyUI\input',
    '%USERPROFILE%\Documents\ComfyUI\temp',
    '%APPDATA%\Microsoft\Windows\Recent',
    '%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations',
    '%APPDATA%\Microsoft\Windows\Recent\CustomDestinations',
    '%WINDIR%\Prefetch'
)

$files = @(
    '%USERPROFILE%\.claude.json', '%USERPROFILE%\.claude\settings.json',
    '%USERPROFILE%\.claude\history.jsonl', '%USERPROFILE%\.gemini\settings.json',
    '%USERPROFILE%\.copilot\config.json', '%USERPROFILE%\.copilot\settings.json',
    '%USERPROFILE%\.copilot\session-store.db',
    '%USERPROFILE%\.copilot\session-store.db-wal',
    '%USERPROFILE%\.copilot\session-store.db-shm',
    '%USERPROFILE%\.local\share\opencode\opencode.db',
    '%USERPROFILE%\.local\share\opencode\opencode.db-wal',
    '%USERPROFILE%\.local\share\opencode\opencode.db-shm',
    '%USERPROFILE%\.continue\config.yaml', '%USERPROFILE%\.continue\config.json',
    '%USERPROFILE%\.cline\data\db\sessions.db',
    '%USERPROFILE%\.cline\data\db\sessions.db-wal',
    '%USERPROFILE%\.cline\data\db\sessions.db-shm',
    '%LOCALAPPDATA%\hermes\state.db', '%LOCALAPPDATA%\hermes\state.db-wal',
    '%LOCALAPPDATA%\hermes\state.db-shm', '%LOCALAPPDATA%\hermes\config.yaml',
    '%USERPROFILE%\.openclaw\openclaw.json',
    '%APPDATA%\Block\goose\data\sessions\sessions.db',
    '%APPDATA%\Block\goose\data\sessions\sessions.db-wal',
    '%APPDATA%\Block\goose\data\sessions\sessions.db-shm',
    '%APPDATA%\Code\User\globalStorage\state.vscdb',
    '%APPDATA%\Cursor\User\globalStorage\state.vscdb',
    '%USERPROFILE%\invokeai\invokeai.yaml',
    '%USERPROFILE%\invokeai\databases\invokeai.db',
    '%USERPROFILE%\NTUSER.DAT', '%LOCALAPPDATA%\Microsoft\Windows\UsrClass.dat',
    '%WINDIR%\System32\config\SYSTEM', '%WINDIR%\System32\config\SOFTWARE',
    '%WINDIR%\AppCompat\Programs\Amcache.hve',
    '%WINDIR%\System32\winevt\Logs\Security.evtx',
    '%WINDIR%\System32\winevt\Logs\Windows PowerShell.evtx',
    '%WINDIR%\System32\winevt\Logs\Microsoft-Windows-PowerShell%4Operational.evtx',
    '%WINDIR%\System32\winevt\Logs\PowerShellCore%4Operational.evtx',
    '%WINDIR%\System32\winevt\Logs\Microsoft-Windows-Sysmon%4Operational.evtx',
    '%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt',
    '%PROGRAMDATA%\Microsoft\Search\Data\Applications\Windows\Windows.db',
    '%PROGRAMDATA%\Microsoft\Search\Data\Applications\Windows\Windows.edb'
)

$registryKeys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU',
    'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags',
    'HKCU:\Software\Microsoft\Windows\Shell\BagMRU',
    'HKCU:\Software\Microsoft\Windows\Shell\Bags',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging',
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription',
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription'
)

$directoryRows = @(foreach ($alias in $directories) {
    Get-DirectoryObservation -LiteralPath ([Environment]::ExpandEnvironmentVariables($alias)) -Alias $alias
})
$fileRows = @(foreach ($alias in $files) {
    Get-FileObservation -LiteralPath ([Environment]::ExpandEnvironmentVariables($alias)) -Alias $alias
})
$registryRows = @(foreach ($keyPath in $registryKeys) { Get-RegistryObservation -LiteralPath $keyPath })

$browserRows = @(
    Get-BrowserObservations -Root (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data') -Alias '%LOCALAPPDATA%\Google\Chrome\User Data' -Family chromium
    Get-BrowserObservations -Root (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data') -Alias '%LOCALAPPDATA%\Microsoft\Edge\User Data' -Family chromium
    Get-BrowserObservations -Root (Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles') -Alias '%APPDATA%\Mozilla\Firefox\Profiles' -Family firefox
    Get-BrowserObservations -Root (Join-Path $env:APPDATA 'zen\Profiles') -Alias '%APPDATA%\zen\Profiles' -Family firefox
)

$environmentNames = @(
    'CODEX_HOME', 'CODEX_SQLITE_HOME', 'OLLAMA_MODELS', 'HF_HOME', 'HF_HUB_CACHE',
    'HUGGINGFACE_HUB_CACHE', 'XDG_CACHE_HOME', 'TRANSFORMERS_CACHE', 'TORCH_HOME',
    'CLAUDE_CONFIG_DIR', 'CLAUDE_CODE_TMPDIR', 'GEMINI_CLI_HOME',
    'COPILOT_HOME', 'COPILOT_CACHE_HOME', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME',
    'XDG_STATE_HOME', 'OPENCODE_CONFIG', 'OPENCODE_CONFIG_DIR', 'OPENCODE_DB',
    'CLINE_DIR', 'CLINE_DATA_DIR', 'CLINE_SESSION_DATA_DIR', 'CLINE_DB_DATA_DIR',
    'CONTINUE_GLOBAL_DIR', 'OPENCLAW_HOME', 'OPENCLAW_STATE_DIR',
    'OPENCLAW_CONFIG_PATH', 'HERMES_HOME', 'OH_PERSISTENCE_DIR', 'INVOKEAI_ROOT'
)
$environmentRows = @(foreach ($name in $environmentNames) {
    $row = [ordered]@{ name = $name }
    foreach ($scope in @('Process', 'User', 'Machine')) {
        try {
            $value = [Environment]::GetEnvironmentVariable($name, [EnvironmentVariableTarget]$scope)
            $row[$scope.ToLowerInvariant() + '_nonempty'] = -not [string]::IsNullOrEmpty($value)
        } catch { $row[$scope.ToLowerInvariant() + '_status'] = 'unavailable' }
    }
    [pscustomobject]$row
})

try {
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $os = [pscustomobject][ordered]@{
        caption = $operatingSystem.Caption
        version = $operatingSystem.Version
        build = $operatingSystem.BuildNumber
    }
} catch { $os = [pscustomobject]@{ status = 'unavailable' } }

$result = [pscustomobject][ordered]@{
    schema_version = '1.0'
    collector_version = '1.1.0'
    collected_utc = (Get-Date).ToUniversalTime().ToString('o')
    scope = 'Current user; curated default/candidate locations; live metadata queries only.'
    os = $os
    directories = $directoryRows
    files = $fileRows
    registry = $registryRows
    browsers = $browserRows
    environment_override_presence = $environmentRows
    limitations = @(
        'Live triage changes system traces; this output is not a forensic image or acquisition.',
        'No contents or Registry value data were read. Metadata does not establish use, intent, execution, or attribution.',
        'All directory counts are direct only and exclude file content. Descendant data is outside those counts.',
        'Paths use environment aliases. Browser profile names are replaced by ordinal placeholders.',
        'Environment values are not emitted or followed; nonempty booleans indicate candidates for separate validation.',
        'Missing means not found at the checked path; access denied is reported separately.',
        'Curated candidates are not universal defaults. Other users, custom roots, portable installs, WSL, containers, cloud records, and deleted artifacts are outside scope.',
        'Reparse-point directories are skipped; profile discovery is bounded to 32 immediate candidates per browser.',
        'EVTX-file presence and logging-policy-key presence do not establish that any particular event type was recorded.',
        'A metadata-readable live hive or database may still be locked against consistent copying.'
    )
}

$json = $result | ConvertTo-Json -Depth 12
if ([string]::IsNullOrEmpty($OutputPath)) {
    Write-Output $json
} else {
    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutput)
    if (-not [System.IO.Directory]::Exists($outputDirectory)) {
        [void][System.IO.Directory]::CreateDirectory($outputDirectory)
    }
    $outputBytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($json)
    $outputStream = $null
    try {
        $outputStream = [System.IO.File]::Open($resolvedOutput, [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $outputStream.Write($outputBytes, 0, $outputBytes.Length)
    } finally {
        if ($null -ne $outputStream) { $outputStream.Dispose() }
    }
}
