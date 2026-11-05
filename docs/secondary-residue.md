# Secondary residue: beyond the explicit output directory

An application can save a deliverable in one directory while the operating system, browser, runtime, or virtual environment retains related material elsewhere. These are **documented examination candidates, not observed findings** from the example workstation. Sources were retrieved on **2026-11-05**. Their presence does not establish AI involvement, intent, or operator identity.

## Explorer thumbnail databases

```text
%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db
```

This path and file mask appear in the original [KAPE ThumbCache target](https://github.com/EricZimmerman/KapeFiles/blob/master/Targets/Windows/ThumbCache.tkape). The [libwtcdb format specification](https://github.com/libyal/libwtcdb/blob/main/documentation/Windows%20Explorer%20Thumbnail%20Cache%20database%20format.asciidoc) documents multiple cache formats and size categories. Use a parser compatible with the acquired format.

A thumbnail is a derived representation, not the original file. Its appearance alone cannot establish who created the source, whether AI generated it, or its complete contents. Associate cache identifiers with independent path evidence where possible. [Thumbcache Viewer's author](https://thumbcacheviewer.github.io/) documents mapping against Windows Search databases and notes that mapping methods have operating-system and source-system dependencies. Preserve provenance for both the database and any extracted preview.

## Temporary storage

```text
%TEMP%
%TMP%
%LOCALAPPDATA%\Temp\
```

The last path is a common candidate, not a universal location. Runtime and account context matter: [Microsoft's GetTempPath documentation](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppatha) describes environment-based resolution. Modern [.NET temp-path behavior](https://learn.microsoft.com/en-us/dotnet/api/system.io.path.gettemppath?view=net-10.0) can use GetTempPath2 instead.

Application working copies, interrupted downloads, staging files, and intermediate renders are hypotheses to test here. A `.tmp` extension does not identify format or purpose; inspect acquired content using appropriate tools. Compare candidate files with output hashes, application records, and timestamps. An empty temp directory at examination time says little about earlier activity.

## Crash dumps and application memory

```text
%LOCALAPPDATA%\CrashDumps\
HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps
HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\<Application.exe>
```

Microsoft documents `DumpFolder` as an expandable path, `DumpType` as custom (`0`), mini (`1`), or full (`2`), and `DumpCount` as retention control. Per-application settings can override global settings; service-account paths differ. This collection mechanism is not enabled by default. See [Collecting User-Mode Dumps](https://learn.microsoft.com/en-us/windows/win32/wer/collecting-user-mode-dumps).

Depending on dump type and process state, memory may retain relevant fragments. Treat recovered strings as contextual leads, not a complete conversation history or proof that an operation completed. Applications with custom crash handlers may use other stores. Inspect existing configuration and acquired files; do not deliberately crash an application or enable dumping to reconstruct the past.

## Recycle Bin metadata and retained payload

```text
<volume>:\$Recycle.Bin\<SID>\$I*
<volume>:\$Recycle.Bin\<SID>\$R*
```

The original [libyal Recycle.Bin format documentation](https://github.com/libyal/dtformats/blob/main/documentation/Windows%20Recycle.Bin%20file%20formats.asciidoc) distinguishes `$I` metadata from `$R` original data. Documented metadata includes original filename, original size, and deletion time; layouts differ by format version.

Examine relevant volumes and account directories rather than assuming everything is under the system volume. A metadata record can survive without a usable payload, and a file can be removed without ever entering this mechanism. Preserve the metadata and data relationship before naming a recovered item. The account directory provides context, not conclusive attribution to a person.

## Alternate streams and download-zone context

```text
<file>:Zone.Identifier
```

This is an alternate data stream, not an ordinary adjacent file. Microsoft documents its association with downloaded-file zone information and confirms that it can be removed. See the [PowerShell documentation describing Zone.Identifier](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell-5.1). The linked command is not part of the collection workflow.

Preserve named streams during acquisition. Their absence cannot establish local creation, and their contents are not immutable provenance. Microsoft also notes that streams lack independent file times; file timestamps can change when any stream changes. See [NTFS file streams](https://learn.microsoft.com/en-us/windows/win32/fileio/file-streams). Correlate zone context with browser download records and the file's identity.

## Redirected known folders

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
    {374DE290-123F-4565-9164-39C4925E467B}  # Downloads value name
```

The GUID is a value name under this key, not a child key. [Microsoft's folder-location troubleshooting reference](https://learn.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/change-personal-folder-location-fails) lists this mapping and defaults for other known folders.

Inspect the examined account's configured destination before treating `%USERPROFILE%\Downloads` or `Documents` as complete coverage. An application can also use its own save location. Current redirection does not establish the historic destination, so correlate it with application settings and filesystem records. This examination requires reading existing settings, not restoring defaults.

## WSL and Docker virtual disks

WSL 2 can store an entire Linux filesystem inside a virtual disk. Microsoft documents discovery through:

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Lxss\{GUID}
    DistributionName
    BasePath
<BasePath>\ext4.vhdx
```

See [Microsoft's WSL disk-space reference](https://learn.microsoft.com/en-us/windows/wsl/disk-space). Linux application outputs and caches inside that filesystem will not appear in an ordinary recursive listing of Windows application folders. WSL 1 and custom installations require separate handling.

Current [Docker backup documentation](https://docs.docker.com/desktop/settings-and-maintenance/backup-and-restore/) lists backend-specific defaults:

| Backend | Candidate virtual disk |
|---|---|
| WSL 2 | `%LOCALAPPDATA%\Docker\wsl\disk\docker_data.vhdx` |
| Hyper-V | `%PROGRAMDATA%\DockerDesktop\vm-data\DockerDesktop.vhdx` |
| Docker VMM | `%LOCALAPPDATA%\Docker\vm-data\DockerDesktop.vhdx` |

Configured disk locations and version history can differ. Docker's [WSL backend documentation](https://docs.docker.com/desktop/features/wsl/) identifies the default Windows data root and its configurability. Bind mounts can place outputs elsewhere on the host; named volumes require separate consideration.

Treat a virtual disk as a container requiring consistent acquisition and filesystem-aware analysis, not as a normal folder. This write-up does not launch distributions, start containers, mount disks, repair filesystems, or supply commands that change their state.
