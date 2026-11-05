# Windows artifact and Registry reference

This reference maps Windows evidence sources to questions about AI-assisted cybercrime, coercion, and child exploitation. It describes candidate examination locations, not findings from any particular computer. Resolve environment variables for the examined profile and installation. An investigator's `HKCU`, `%APPDATA%`, or `%TEMP%` can point somewhere different from the subject account.

All linked sources were retrieved on **2026-11-05**. Paths, schemas, logging behavior, and retention depend on the Windows and application versions. Record those versions alongside the acquisition method and parser versions.

## Profile hives and live Registry views

| On-disk file | Corresponding live view | Purpose |
|---|---|---|
| `%USERPROFILE%\NTUSER.DAT` | `HKU\<SID>` and that account's `HKCU` view | User preferences and shell activity |
| `%LOCALAPPDATA%\Microsoft\Windows\UsrClass.dat` | `HKU\<SID>_Classes`; exposed through `HKCU\Software\Classes` | Per-user classes and shell state |
| `%SystemRoot%\System32\config\SOFTWARE` | `HKLM\SOFTWARE` | Machine software configuration |
| `%SystemRoot%\System32\config\SYSTEM` | `HKLM\SYSTEM` | System configuration |

Preserve the corresponding transaction logs when available, including `.LOG1` and `.LOG2`, and retain untouched originals before any recovery or replay. A mounted live view and a file copied from disk are different acquisition products. Microsoft documents [Registry hive backing files](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry-hives), while its [profile documentation](https://github.com/MicrosoftDocs/SupportArticles-docs/blob/main/support/windows-server/user-profiles-and-logon/desktop-location-unavailable.md) identifies modern user-hive placement.

`HKCR` merges machine and user class registrations; it is not an additional independent hive. Record which source supplies a relevant setting rather than reporting only the merged result. See [Microsoft's HKCR documentation](https://learn.microsoft.com/en-us/windows/win32/sysinfo/hkey-classes-root-key).

## Shell history and file-dialog references

The following live keys belong to the relevant account. For offline `NTUSER.DAT` parsing, remove the `HKCU\` prefix and use the remaining hive-relative path.

| Artifact | Exact live key | Useful question |
|---|---|---|
| RecentDocs | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs` | Which document references remain in shell history? |
| Open/save dialogs | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU` | Which file or folder references appear in common dialogs? |
| Last dialog location | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU` | Which application and directory references are associated? |
| Explorer searches | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery` | Which search strings were retained? |
| Run dialog | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU` | Which command strings were submitted through Run? |
| Typed navigation | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths` | Which paths were typed into Explorer? |
| UserAssist | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{GUID}\Count` | What GUI-related program metadata remains? |

These locations and hive assignments appear in the original [RECmd batch definitions](https://github.com/EricZimmerman/RECmd/blob/master/BatchExamples/RECmd_Batch_MC.reb). An absent key can reflect application behavior, configuration, retention, or version differences; record it as absent at examination rather than concluding that the associated activity never occurred.

RecentDocs has a root list and extension-specific subkeys. Preserve the value names, parsed target names, and `MRUListEx` ordering. The original [RecentDocs parser](https://github.com/EricZimmerman/RegistryPlugins/blob/master/RegistryPlugin.RecentDocs/RecentDocs.cs) demonstrates these structures. Matching a basename is weaker than matching a full path, file identifier, or content hash.

OpenSavePidlMRU contains shell-item data that can expose path components and embedded metadata. LastVisitedPidlMRU can associate an executable name with shell-item directory references. Their original [OpenSavePidlMRU](https://github.com/EricZimmerman/RegistryPlugins/blob/master/RegistryPlugin.OpenSavePidlMRU/OpenSavePidlMRU.cs) and [LastVisitedPidlMRU](https://github.com/EricZimmerman/RegistryPlugins/blob/master/RegistryPlugin.LastVisitedPidlMRU/LastVisitedPidlMRU.cs) parsers provide implementation references. A dialog reference needs corroboration before claiming that an upload, successful save, or content review occurred.

WordWheelQuery is Explorer search history, not general browser or AI prompt history. Its [parser](https://github.com/EricZimmerman/RegistryPlugins/blob/master/RegistryPlugin.WordWheelQuery/WordWheelQuery.cs) associates the key timestamp with the most recent ordered item, rather than assigning that time to every search.

## ShellBags and UserAssist interpretation

Modern ShellBags commonly reside at these **UsrClass.dat-relative** locations:

```text
Local Settings\Software\Microsoft\Windows\Shell\BagMRU
Local Settings\Software\Microsoft\Windows\Shell\Bags
```

Their live equivalents begin with `HKU\<SID>_Classes\`, or with `HKCU\Software\Classes\` for that account. Also examine these **NTUSER.DAT-relative** locations when present:

```text
Software\Microsoft\Windows\Shell\BagMRU
Software\Microsoft\Windows\Shell\Bags
```

The original [ShellBags Explorer discussion](https://github.com/EricZimmerman/Issues/issues/22) illustrates bag hierarchy, parent relationships, and timestamp interpretation. Preserve node relationships and decoded shell-item details rather than flattening everything into an unexplained list of directory names.

ShellBags describe shell interaction and view state; command-line navigation is outside their coverage. Folder-property changes can also create entries. UserAssist value names use ROT13 encoding. On modern Windows, “Open file location” can update UserAssist count and time fields without launching the executable. Correlate focus data and independent telemetry. These cautions are documented in [Microsoft's DFIR guide](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/final/en-us/microsoft-brand/documents/IR-Guidebook-Final.pdf).

## Shortcuts, Jump Lists, and program artifacts

| Artifact | Candidate path | Examination role |
|---|---|---|
| Recent shortcuts | `%APPDATA%\Microsoft\Windows\Recent\*.lnk` | Target and interaction context |
| Automatic Jump Lists | `%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*.automaticDestinations-ms` | Application-linked recent or frequent items |
| Custom Jump Lists | `%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*.customDestinations-ms` | Application-managed destination references |
| Prefetch | `%SystemRoot%\Prefetch\*.pf` | Program execution context, when available |
| Amcache | `%SystemRoot%\appcompat\Programs\Amcache.hve` | Program inventory and presence |

These paths are documented in [Microsoft's DFIR guide](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/final/en-us/microsoft-brand/documents/IR-Guidebook-Final.pdf). Amcache presence alone cannot establish execution. Prefetch availability varies; Windows Server commonly lacks it by default. A shortcut's own filesystem times and its embedded target metadata represent different objects and need separate labels in a timeline.

For example, a reference to `output.png` in a shortcut and another file with that basename in Downloads do not establish identity. Compare available target paths, volume information, file identifiers, sizes, and hashes. Treat unresolved identity as an explicit limitation, particularly when a file was renamed or moved.

## Startup configuration

Examine all four standard locations:

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce
HKLM\Software\Microsoft\Windows\CurrentVersion\Run
HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce
```

Run values configure repeated logon startup; RunOnce values configure a one-time action with deletion behavior. Machine RunOnce has account and logon conditions. Record value names, types, and command strings, but distinguish configuration from successful execution. Legitimate updaters and collaboration applications use these same keys. [Microsoft's Run/RunOnce documentation](https://learn.microsoft.com/en-us/windows/win32/setupapi/run-and-runonce-registry-keys) explains the behavior. This reference intentionally supplies no commands to create or modify these entries.

## Event logs and existing logging policy

| Source | Channel or file | Useful events and requirements |
|---|---|---|
| Windows Security | `%SystemRoot%\System32\winevt\Logs\Security.evtx` | 4688 process creation; Audit Process Creation must be enabled |
| Windows PowerShell | `Microsoft-Windows-PowerShell/Operational` | 4104 script-block logging |
| PowerShell 7 | `PowerShellCore/Operational` | 4104; separate provider and configuration |
| Sysmon | `Microsoft-Windows-Sysmon/Operational` | 1 process creation; 3 network; 11 file create; 12–14 Registry operations |

[Event 4688 documentation](https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4688) explains process and account fields. Command-line data additionally depends on the policy mapped to:

```text
HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit
    ProcessCreationIncludeCmdLine_Enabled
```

The value does not substitute for enabled process-creation auditing. Configuration at examination time also does not establish what was configured during the incident. See [Microsoft's audit policy mapping](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-auditsettings).

For Windows PowerShell, inspect existing settings at:

```text
HKLM\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
    EnableScriptBlockLogging
HKCU\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
    EnableScriptBlockLogging
```

[Microsoft's policy documentation](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowspowershell) describes computer-policy precedence. [PowerShell 7 logging documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_logging_windows?view=powershell-7.5) documents its separate channel. Preserve multipart script blocks and their identifiers before reconstructing text. Logged script processing still requires context to determine which operations completed.

[Sysmon documentation](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) defines its event semantics. Its service must have been installed, relevant events enabled and retained, and filters applicable. Network event 3 is disabled by default. Use ProcessGUID where available to reduce ambiguity from reused process IDs. Enabling logging after an incident supplies no historical records.

## Command history and timestamp boundaries

PSReadLine's default Windows location is:

```text
%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\<HostName>_history.txt
```

`ConsoleHost_history.txt` is a common instance; hosts can use other names, and configuration can redirect storage. [Microsoft's PSReadLine documentation](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.5) also demonstrates adding a history entry without execution. History is therefore a lead for corroboration, not an execution audit. Saving mode, filtering, and host behavior affect coverage.

Registry LastWrite is a key-level timestamp for changes to the key or its value entries. It is not an independent timestamp for every value. [RegQueryInfoKeyW documentation](https://learn.microsoft.com/en-us/windows/win32/api/winreg/nf-winreg-regqueryinfokeyw) defines that boundary. Preserve raw timestamp values, the conversion method, and the displayed timezone in analytical exports.

Report separate findings for artifact presence, application execution, demonstrated AI involvement, completed actions, and operator attribution. An account name identifies a security context. Shared sessions, remote control, background tasks, and automation remain alternative explanations to evaluate with corroborating records.
