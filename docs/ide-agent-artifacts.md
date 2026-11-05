# IDE coding-agent artifacts

An editor can retain a conversation, tool result, or earlier file version outside the repository being edited. Investigate three separate layers: editor state, extension or agent task storage, and actual workspace files. A settings file identifies configuration; a transcript records reported activity; a resulting file supplies evidence about what persisted. Correlating those layers is stronger than treating any one as a complete audit trail.

These are **candidate locations, not findings that these products are installed or were used on the example workstation**. Sources were checked on **2026-11-05**. Source links pinned to commits describe that revision, which can differ from the installed release. For unpinned documentation, record the retrieval date and verify behavior against the examined application version.

## Establish the effective editor data directory

For a standard Windows VS Code installation, start with:

```text
%APPDATA%\Code\User\settings.json
%APPDATA%\Code\User\globalStorage\
%APPDATA%\Code\User\workspaceStorage\
%APPDATA%\Code\logs\
%USERPROFILE%\.vscode\extensions\
```

Extension installation directories contain extension software and manifests, not necessarily their task histories. The [VS Code extension API](https://code.visualstudio.com/api/references/vscode-api#ExtensionContext) distinguishes extension location, global storage, workspace storage, logs, and secrets. These are separate concepts even when their directories share a parent.

The displayed paths assume the usual user-data root. [`--user-data-dir` can redirect that root](https://code.visualstudio.com/docs/configure/command-line), and [portable mode](https://code.visualstudio.com/docs/setup/portable) uses an installation-adjacent `data\user-data` directory. Insiders, editor forks, additional profiles, and remote extension hosts require independent mapping. Do not replace one product name with another and declare the resulting path verified.

## Cursor: global and workspace state

| Candidate path | Examination role |
|---|---|
| `%APPDATA%\Cursor\User\globalStorage\state.vscdb` | Shared SQLite editor and agent state |
| `%APPDATA%\Cursor\User\workspaceStorage\<workspace-id>\state.vscdb` | Workspace-associated SQLite state |
| `%APPDATA%\Cursor\User\workspaceStorage\<workspace-id>\workspace.json` | Workspace-to-project mapping candidate |
| `%APPDATA%\Cursor\logs\<timestamp>\` | Editor and component logs |

A [Cursor support response](https://forum.cursor.com/t/conversation-blobs-missing-after-windows-mac-migration-please-remap-workspace-namespace/168793) identifies the Windows global database as a local conversation store. The original [cursaves storage research](https://github.com/Callum-Ward/cursaves/blob/main/docs/how-cursor-stores-chats.md) documents workspace/global relationships and changes between Cursor generations. That research is a primary examination of an undocumented format, not a vendor compatibility guarantee.

Preserve both database locations and any associated journals or backups that actually exist. Determine tables and record encodings from acquired copies; do not assume that a historical `ItemTable` or `cursorDiskKV` query extracts every relevant record. A workspace index can list a conversation whose content is elsewhere, and moving a project can change its workspace association.

Cursor's [Windows support guidance](https://forum.cursor.com/t/desktop-app-stuck-on-login-screen-after-successful-browser-authentication/164774/9) confirms the timestamped logs root. Logs can identify component failures or session timing, but are not guaranteed to contain complete prompts, responses, or successful tool actions. Avoid opening the live editor merely to make its history easier to inspect.

## VS Code and GitHub Copilot: session files and editing snapshots

Current VS Code source implements these candidate stores under the standard root:

```text
%APPDATA%\Code\User\workspaceStorage\<workspace-id>\chatSessions\
%APPDATA%\Code\User\globalStorage\emptyWindowChatSessions\
%APPDATA%\Code\User\globalStorage\transferredChatSessions\
%APPDATA%\Code\User\workspaceStorage\no-workspace\chatSessions\
```

The last location is a historical empty-window candidate retained in migration logic. The [ChatSessionStore implementation](https://github.com/microsoft/vscode/blob/eda52efccac1f9208aca4d65afdeb7550241cf53/src/vs/workbench/contrib/chat/common/model/chatSessionStore.ts) handles both `.json` and `.jsonl` session files. Session indexes and content files are different objects. Decode the format associated with the installed version; JSONL may represent state updates rather than independent messages.

These stores are editor chat infrastructure. Attribute a record to Copilot or another participant using its actual metadata and extension evidence, rather than labeling every chat directory “Copilot history.” Extension presence alone is insufficient.

Editing-session data supplies a second evidence layer:

```text
%APPDATA%\Code\User\workspaceStorage\<workspace-id>\chatEditingSessions\<session-storage-key>\state.json
%APPDATA%\Code\User\workspaceStorage\<workspace-id>\chatEditingSessions\<session-storage-key>\contents\
```

The [editing-session storage implementation](https://github.com/microsoft/vscode/blob/eda52efccac1f9208aca4d65afdeb7550241cf53/src/vs/workbench/contrib/chat/browser/chatEditing/chatEditingSessionStorage.ts) stores state and referenced content separately. Preserve that relationship. A captured file version may have been proposed, accepted, reverted, or subsequently edited; compare it with the current workspace and independent execution evidence.

Also consider `%APPDATA%\Code\Backups\` for unsaved editor material. [VS Code's hot-exit documentation](https://code.visualstudio.com/docs/editing/codebasics) identifies this standard location. A retained editor buffer does not necessarily correspond to a file ever saved at its displayed path.

## Cline: extension-era tasks and newer home-based storage

Cline's [extension manifest](https://github.com/cline/cline/blob/d3ecc4890e8f9bcb77182b96c77fa90575e8e145/apps/vscode/package.json) retains the identifier `saoudrizwan.claude-dev`. The historical standard VS Code candidate is:

```text
%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\tasks\<task-id>\
```

Within a resolved task directory, examine candidate files:

```text
api_conversation_history.json
ui_messages.json
context_history.json
task_metadata.json
settings.json
```

The [Cline disk-storage implementation](https://github.com/cline/cline/blob/d3ecc4890e8f9bcb77182b96c77fa90575e8e145/apps/vscode/src/core/storage/disk.ts) defines these names and resolves task directories through the host's storage root. Consequently, the extension identifier does not guarantee that a current installation still writes beneath VS Code globalStorage. Keep UI messages, API conversation data, and task settings conceptually separate; their records serve different functions.

Newer source also defines home-based candidates:

```text
%USERPROFILE%\.cline\data\
%USERPROFILE%\.cline\data\sessions\
%USERPROFILE%\.cline\data\db\sessions.db
%USERPROFILE%\.cline\data\logs\
%USERPROFILE%\.cline\data\settings\cline_mcp_settings.json
```

The [shared path resolver](https://github.com/cline/cline/blob/d3ecc4890e8f9bcb77182b96c77fa90575e8e145/sdk/packages/shared/src/storage/paths.ts) supports overrides including `CLINE_DIR`, `CLINE_DATA_DIR`, `CLINE_SESSION_DATA_DIR`, and `CLINE_DB_DATA_DIR`. The [SQLite session-store implementation](https://github.com/cline/cline/blob/d3ecc4890e8f9bcb77182b96c77fa90575e8e145/sdk/packages/core/src/services/storage/sqlite-session-store.ts) derives `sessions.db` from its resolved database directory. These are revision-specific candidates, not a claim that every released Cline surface uses every store.

The [VS Code storage-context implementation](https://github.com/cline/cline/blob/d3ecc4890e8f9bcb77182b96c77fa90575e8e145/apps/vscode/src/shared/storage/storage-context.ts) independently demonstrates the home-based data directory. Establish the installed host and migration state before claiming absence from a single legacy location. SDK session records and extension-era task files require their respective schemas.

## Roo Code: task storage can be redirected

The [Roo Code manifest](https://github.com/RooCodeInc/Roo-Code/blob/b867ec9145750d0ae1ff7f02d35406e9bf2a0b16/src/package.json) identifies `RooVeterinaryInc.roo-cline`. A standard VS Code candidate is:

```text
%APPDATA%\Code\User\globalStorage\rooveterinaryinc.roo-cline\tasks\<task-id>\
```

The [storage resolver](https://github.com/RooCodeInc/Roo-Code/blob/b867ec9145750d0ae1ff7f02d35406e9bf2a0b16/src/utils/storage.ts) honors `roo-cline.customStoragePath`; `tasks`, `settings`, and `cache` can therefore sit beneath another configured base. Preserve the effective setting and its scope.

Roo's [filename definitions](https://github.com/RooCodeInc/Roo-Code/blob/b867ec9145750d0ae1ff7f02d35406e9bf2a0b16/src/shared/globalFileNames.ts) include `api_conversation_history.json`, `ui_messages.json`, `task_metadata.json`, `history_item.json`, and `_index.json`. Determine each file's actual location from the corresponding version's implementation. An index is not interchangeable with task content, and an empty or damaged file is not proof that a task never existed. Similar filenames across Cline and Roo do not establish identical schemas.

## Continue: a separate home directory

```text
%USERPROFILE%\.continue\sessions\<session-id>.json
%USERPROFILE%\.continue\sessions\sessions.json
%USERPROFILE%\.continue\config.yaml
%USERPROFILE%\.continue\config.json
%USERPROFILE%\.continue\logs\
%USERPROFILE%\.continue\dev_data\
%USERPROFILE%\.continue\index\
%USERPROFILE%\.continue\.diffs\
```

Continue's [path implementation](https://github.com/continuedev/continue/blob/5522c6f44ca0ac3528b37244818fbfa39b5af470/core/util/paths.ts) defines these candidates and the `CONTINUE_GLOBAL_DIR` override. `config.json` is a legacy configuration candidate alongside YAML; neither is a substitute for session content. Distinguish the session list from individual session documents, and caches or indexes from authored code. A root override applies before joining these subordinate paths.

## MCP, hooks, and workspace configuration

| Product | Documented configuration candidates |
|---|---|
| Cursor MCP | `%USERPROFILE%\.cursor\mcp.json`; `<workspace>\.cursor\mcp.json` |
| Cursor hooks | `%USERPROFILE%\.cursor\hooks.json`; `<workspace>\.cursor\hooks.json`; `%PROGRAMDATA%\Cursor\hooks.json` |
| Copilot harness MCP | `%USERPROFILE%\.copilot\mcp-config.json`, subject to `COPILOT_HOME` |
| VS Code Local harness MCP | `<workspace>\.vscode\mcp.json`; effective user-profile `mcp.json` |
| Roo MCP | `<resolved-storage-base>\settings\mcp_settings.json`; `<workspace>\.roo\mcp.json` |
| Continue MCP | `<workspace>\.continue\mcpServers\` |

Cursor documents [MCP file locations](https://cursor.com/docs/mcp) and [hook configuration scopes](https://cursor.com/docs/hooks). Current [VS Code MCP documentation](https://code.visualstudio.com/docs/agent-customization/mcp-servers) distinguishes Copilot harness configuration from Local harness files; older releases can behave differently. Roo documents [global and workspace MCP precedence](https://github.com/RooCodeInc/Roo-Code/blob/b867ec9145750d0ae1ff7f02d35406e9bf2a0b16/apps/docs/docs/features/mcp/using-mcp-in-roo.mdx). Continue documents [workspace MCP block files](https://docs.continue.dev/customize/deep-dives/mcp), including YAML and compatible JSON inputs.

Treat these files as configured capability. A command, endpoint, or hook definition does not establish invocation or successful completion. Correlate tool-call results, process telemetry, network evidence, and output-file identity. Inspect configuration on acquired copies and redact secret values before any public example; do not execute referenced commands or connect configured services to validate their presence.

## Collection boundaries

Use source code to understand path resolution, not as an acquisition script. Several referenced helpers create missing directories or initialize files as part of normal application operation. Calling them against an examined profile can manufacture the very location being investigated. Likewise, reopening a task can update indexes, migrate storage, or resume work.

Record each candidate as observed, absent at the checked location, inaccessible, or outside the examination scope. Preserve application and extension versions with those observations. A source-defined path, an installed extension manifest, and a populated task directory are three different findings; the report should identify which evidence supports each statement.

Finally, preserve actual workspace changes separately from editor snapshots. Relate session identifiers, workspace URIs, file hashes, and event times while recording uncertainty. A generated script on disk establishes a stored file. Demonstrating that the script ran and caused a particular effect requires additional evidence.
