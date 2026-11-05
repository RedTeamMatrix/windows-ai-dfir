# Expanded workstation example: coding agents and harnesses

**Observation date:** November 5, 2026.  
**Collector:** `Get-AIArtifactInventory.ps1`, revision `1.1.0`.  
**Scope:** Additional owner-authorized metadata checks on the same live Windows workstation.

The [expanded JSON](../examples/expanded-workstation-metadata.json) is a new snapshot. The [initial example](local-example.md) and its JSON remain as originally collected. Live counts can differ between snapshots; the new file is not a coherent historical image.

No transcripts, prompts, model payloads, images, Registry value data, or event contents were examined for these checks. Fixed known-file metadata and aggregate direct directory counts were used. No conclusion about offending activity is made.

## 1. Claude Code defaults were not found at the checked paths

The inventory did not find the checked `%USERPROFILE%\.claude` root, its listed transcript/state subdirectories, `%USERPROFILE%\.claude.json`, or the checked default `%TEMP%\claude` directory.

This is a bounded native-Windows observation. It does not resolve a custom `CLAUDE_CONFIG_DIR`, another account, an earlier installation, WSL/container execution, remote execution, or cloud records. The metadata helper does not follow override values. The [Claude Code reference](coding-cli-artifacts.md#claude-code) supplies the documented candidates for an appropriate environment.

Checked Gemini CLI, OpenCode, Continue, Cursor, and current home-based Cline candidates were also not found at their listed default locations. None of those results establish that a tool was never used.

## 2. Copilot had configuration and a log candidate, but no checked session store

| Checked candidate | Result |
|---|---|
| `%USERPROFILE%\.copilot` | Present: one direct file and one immediate directory |
| `%USERPROFILE%\.copilot\config.json` | Present |
| `%USERPROFILE%\.copilot\logs` | Present: one direct file |
| `%USERPROFILE%\.copilot\settings.json` | Not found at checked path |
| `%USERPROFILE%\.copilot\session-state` | Not found at checked path |
| `%USERPROFILE%\.copilot\session-store.db` and checked sidecars | Not found at checked paths |

The config and log contents were not read. Their presence alone does not establish a completed coding session or any particular model/tool activity. The current product reference also distinguishes user settings from internal/legacy configuration; names should not be interpreted without version context.

## 3. VS Code and Roo Code candidates were present

```text
%APPDATA%\Code\User\globalStorage
%APPDATA%\Code\User\globalStorage\state.vscdb
%APPDATA%\Code\User\workspaceStorage
%APPDATA%\Code\User\globalStorage\rooveterinaryinc.roo-cline\tasks
```

The global-storage root had five direct files and four immediate directories. Workspace storage had two immediate directories. The Roo Code task candidate had one direct file and two immediate directories.

No workspace IDs, task IDs, filenames, editor database records, or task payloads are published. These observations establish candidate state locations. They do not establish what work occurred, who initiated it, or whether the retained state is current.

The checked legacy Cline `saoudrizwan.claude-dev\tasks` location was absent. It would be inaccurate to combine that negative result with the positive Roo Code path and report a recovered Cline task history.

## 4. Native Hermes state differed from the Unix-style home candidate

| Candidate | Result |
|---|---|
| `%USERPROFILE%\.hermes` | Not found at checked path |
| `%LOCALAPPDATA%\hermes` | Present |
| `%LOCALAPPDATA%\hermes\state.db` | Present |
| `%LOCALAPPDATA%\hermes\state.db-wal` | Present |
| `%LOCALAPPDATA%\hermes\state.db-shm` | Present |
| `%LOCALAPPDATA%\hermes\config.yaml` | Present |
| `%LOCALAPPDATA%\hermes\profiles` | Present: four immediate directories |
| `%APPDATA%\Hermes\Local Storage\leveldb` | Present |

This matches the current native-Windows home candidate described in the [harness reference](agent-harnesses.md#hermes-native-windows-has-a-different-default). The database schema, content, profile configuration, and relationship to the roaming application data were not examined.

The observation demonstrates a concrete coverage problem: a search confined to `%USERPROFILE%\.hermes` would miss the checked native database location on this computer.

## 5. OpenClawTray folders did not establish a local Gateway store

Both `%APPDATA%\OpenClawTray` and `%LOCALAPPDATA%\OpenClawTray` existed. The checked `%USERPROFILE%\.openclaw` root and `agents` candidate were absent.

No tray configuration was read. The inventory therefore did not establish a Gateway location, an active connection, a workspace, a session database, or whether state was local or remote. A desktop integration's files and a Gateway's canonical state are separate questions.

## 6. Additional image defaults were reference candidates

The checked `%USERPROFILE%\invokeai` root and its listed default output/database paths were not found. This does not resolve an `INVOKEAI_ROOT` override, portable installation, active virtual environment, another account, or alternate volume.

Fooocus, Forge, SwarmUI, kohya_ss, and OneTrainer use configurable/repository-relative roots. The expanded survey did not search all repositories or volumes to locate them. Their chapters are documentation references, not findings that those applications are installed.

## What changed in the inventory

Revision 1.1.0 adds fixed candidates for coding CLIs, IDE storage, native Hermes, gateway applications, and selected image roots, plus boolean checks for additional path-override names. It retains the same metadata-only collection model, reparse-point handling, error distinctions, and refusal to overwrite an existing output file.

The expanded snapshot contains 101 directory candidates, 42 known-file candidates, 18 Registry-key checks, 67 browser-artifact rows, and 31 environment-variable names. A candidate count measures the survey list, not the number of tools installed.
