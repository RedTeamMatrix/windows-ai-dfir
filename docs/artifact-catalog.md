# Artifact catalog

**Checked: 2026-11-05.** This compact index links the storage chapters to a [searchable JSON catalog](../catalog/artifacts.json). It is a selection of 40 high-value entries, not a complete product inventory or a list of indicators of wrongdoing. Resolve every path in the examined account, runtime, version, and effective configuration.

## Evidence-status legend

| Label | JSON value | Meaning |
|---|---|---|
| D | `documented` | A documented default or candidate. No local presence is asserted. |
| S | `source_defined` | A reviewed implementation defines the candidate. Match that implementation to the installed version before applying it. |
| O | `observed_metadata` | The exact path was present in an existing example JSON. This establishes only the recorded metadata; payloads were not analyzed. |

An O label does not validate a parser, establish successful use, or prove that a file contains what its name suggests. Wildcard/session-specific templates are not marked observed merely because their parent root existed. D/S rows can also have negative checks in the workstation examples: their catalog status does not override those results. Missing at a checked default, inaccessible, and outside scope remain different observations.

For O rows, `observation_reference` identifies the checked-in JSON collection and the field containing an exact path/key match. Review that record's time, traversal bounds, errors, and limitations. The initial and expanded inventories are separate live observations.

## Local models, conversations, and image workflows

| ID | Product / artifact | Status | Path or locator | Detail |
|---|---|---|---|---|
| `lmstudio-conversations` | LM Studio conversations | O | `%USERPROFILE%\.lmstudio\conversations` | [Storage](ai-storage.md#lm-studio-conversations-and-models-are-distinct) |
| `lmstudio-models` | LM Studio models | O | `%USERPROFILE%\.lmstudio\models` | [Storage](ai-storage.md#lm-studio-conversations-and-models-are-distinct) |
| `ollama-cli-history` | Ollama input history | S | `%USERPROFILE%\.ollama\history` | [Storage](ai-storage.md#ollama-separate-models-desktop-chats-and-cli-history) |
| `ollama-desktop-db` | Ollama desktop database | S | `%LOCALAPPDATA%\Ollama\db.sqlite` | [Storage](ai-storage.md#ollama-separate-models-desktop-chats-and-cli-history) |
| `huggingface-hub-cache` | Hub repository cache | D | `%USERPROFILE%\.cache\huggingface\hub` | [Storage](ai-storage.md#hugging-face-repository-cache-is-not-generated-output) |
| `comfyui-output` | ComfyUI saved output | S | `<effective-base>\output` | [Storage](ai-storage.md#comfyui-locate-the-effective-base-and-output-directories) |
| `comfyui-workflow-metadata` | ComfyUI embedded workflow | D | Optional fields inside a saved PNG | [Metadata](ai-storage.md#comfyui-locate-the-effective-base-and-output-directories) |
| `a1111-output` | WebUI output | S | `<effective-data>\outputs\txt2img-images` | [Storage](ai-storage.md#automatic1111-settings-determine-output-destinations) |
| `invokeai-db` | InvokeAI gallery/application DB | S | `<effective-root>\databases\invokeai.db` | [Image tools](image-generation-artifacts.md#invokeai-gallery-files-and-database-state) |
| `fooocus-output-history` | Fooocus daily history | S | `<path_outputs>\YYYY-MM-DD\log.html` | [Image tools](image-generation-artifacts.md#fooocus-dated-output-directories-and-a-local-html-history) |
| `swarmui-user-db` | SwarmUI account state | S | `<effective-data>\Users.ldb` — LiteDB | [Image tools](image-generation-artifacts.md#swarmui-service-data-account-state-and-backend-boundaries) |
| `onetrainer-run-config` | OneTrainer run settings | S | `<workspace>\config\<prefix><timestamp>.json` | [Training](image-generation-artifacts.md#onetrainer-a-run-workspace-can-retain-several-evidence-layers) |

## Coding CLIs

| ID | Product / artifact | Status | Path or locator | Detail |
|---|---|---|---|---|
| `claude-transcripts` | Claude Code transcript | D | `.claude\projects\<project>\<session>.jsonl` under the effective home root | [CLI](coding-cli-artifacts.md#claude-code) |
| `claude-file-history` | Claude Code snapshots | D | `.claude\file-history\<session>` | [CLI](coding-cli-artifacts.md#claude-code) |
| `claude-memory` | Claude Code auto memory | D | `.claude\projects\<project>\memory` | [CLI](coding-cli-artifacts.md#claude-code) |
| `gemini-chats` | Gemini CLI sessions | D | `.gemini\tmp\<project_hash>\chats` | [CLI](coding-cli-artifacts.md#gemini-cli) |
| `copilot-cli-events` | Copilot session events | D | `.copilot\session-state\<session>\events.jsonl` | [CLI](coding-cli-artifacts.md#github-copilot-cli) |
| `copilot-cli-index` | Copilot cross-session index | D | `.copilot\session-store.db` | [CLI](coding-cli-artifacts.md#github-copilot-cli) |
| `copilot-cli-config` | Copilot state candidate | O | `%USERPROFILE%\.copilot\config.json` | [Observation](expanded-local-example.md#2-copilot-had-configuration-and-a-log-candidate-but-no-checked-session-store) |
| `opencode-db` | OpenCode sessions | D | `.local\share\opencode\opencode.db` under the effective data root | [CLI](coding-cli-artifacts.md#opencode-xdg-paths-also-matter-on-windows) |
| `aider-chat-history` | Aider chat history | S | `<git-root-or-working-directory>\.aider.chat.history.md` | [CLI](coding-cli-artifacts.md#aider-look-inside-the-working-repository) |
| `codex-session-candidates` | Codex session directory | O | `%USERPROFILE%\.codex\sessions` | [Observation](local-example.md#3-codex-had-multiple-local-state-candidates) |

These abbreviated directory names are display aids. Use each JSON row's full `path_template` and `environment` description before collection. A WSL or remote process has a different home and potentially a different evidence host.

## Editors and extensions

| ID | Product / artifact | Status | Path or locator | Detail |
|---|---|---|---|---|
| `vscode-chat-sessions` | VS Code chat infrastructure | S | `<user-data>\User\workspaceStorage\<workspace>\chatSessions` | [IDE](ide-agent-artifacts.md#vs-code-and-github-copilot-session-files-and-editing-snapshots) |
| `vscode-editing-sessions` | VS Code editing state | S | Workspace `chatEditingSessions\<key>` | [IDE](ide-agent-artifacts.md#vs-code-and-github-copilot-session-files-and-editing-snapshots) |
| `cursor-global-state` | Cursor global state | D | `%APPDATA%\Cursor\User\globalStorage\state.vscdb` | [IDE](ide-agent-artifacts.md#cursor-global-and-workspace-state) |
| `cline-extension-tasks` | Cline extension-era tasks | S | VS Code global storage `saoudrizwan.claude-dev\tasks\<task>` | [IDE](ide-agent-artifacts.md#cline-extension-era-tasks-and-newer-home-based-storage) |
| `cline-sdk-db` | Cline home-based sessions | S | `%USERPROFILE%\.cline\data\db\sessions.db` | [IDE](ide-agent-artifacts.md#cline-extension-era-tasks-and-newer-home-based-storage) |
| `roo-tasks` | Roo Code task root | O | VS Code global storage `rooveterinaryinc.roo-cline\tasks` | [Observation](expanded-local-example.md#3-vs-code-and-roo-code-candidates-were-present) |
| `continue-sessions` | Continue sessions | S | `%USERPROFILE%\.continue\sessions` | [IDE](ide-agent-artifacts.md#continue-a-separate-home-directory) |

## Harnesses and gateways

| ID | Product / artifact | Status | Path or locator | Detail |
|---|---|---|---|---|
| `openclaw-runtime-db` | OpenClaw Gateway state | D | `<state>\agents\<agent>\agent\openclaw-agent.sqlite` | [Harness](agent-harnesses.md#openclaw-current-database-versus-legacy-session-files) |
| `hermes-state-db` | Native Hermes state | O | `%LOCALAPPDATA%\hermes\state.db` | [Observation](expanded-local-example.md#4-native-hermes-state-differed-from-the-unix-style-home-candidate) |
| `goose-sessions-db` | goose shared sessions | D | `%APPDATA%\Block\goose\data\sessions\sessions.db` | [Harness](agent-harnesses.md#goose-shared-conversation-store-separate-operational-logs) |

## Browser and Windows corroboration

| ID | Product / artifact | Status | Path or locator | Detail |
|---|---|---|---|---|
| `chrome-history` | Chrome History candidate | O | Checked `Default\History` file | [Observation](local-example.md#5-browser-profiles-contained-multiple-storage-classes) |
| `chrome-local-storage` | Chrome local-storage candidate | O | Checked `Default\Local Storage\leveldb` directory | [Observation](local-example.md#5-browser-profiles-contained-multiple-storage-classes) |
| `windows-automatic-jumplists` | Automatic Jump List root | O | `%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations` | [Windows](windows-artifacts.md#shortcuts-jump-lists-and-program-artifacts) |
| `windows-open-save-mru` | Dialog MRU root | O | Account `HKCU\...\Explorer\ComDlg32\OpenSavePidlMRU` | [Windows](windows-artifacts.md#shell-history-and-file-dialog-references) |
| `windows-modern-shellbags` | Modern BagMRU root | O | Account `HKCU\Software\Classes\Local Settings\...\Shell\BagMRU` | [Windows](windows-artifacts.md#shellbags-and-userassist-interpretation) |
| `windows-prefetch` | Prefetch | D | `%SystemRoot%\Prefetch\*.pf` | [Windows](windows-artifacts.md#shortcuts-jump-lists-and-program-artifacts) |
| `windows-amcache` | Amcache | D | `%SystemRoot%\appcompat\Programs\Amcache.hve` | [Windows](windows-artifacts.md#shortcuts-jump-lists-and-program-artifacts) |
| `windows-sysmon-events` | Sysmon Operational EVTX | D | Sysmon channel/file, subject to configuration | [Windows](windows-artifacts.md#event-logs-and-existing-logging-policy) |

The Registry entries above are keys, not filenames. Use the complete JSON template and detail chapter for exact key/hive mapping. Directory observations also differ from the wildcard file candidates stored beneath them.

## Search and interpret the JSON

From the repository root, this reads only the catalog:

```powershell
$artifactCatalog = Get-Content -LiteralPath '.\catalog\artifacts.json' -Raw | ConvertFrom-Json
$artifactCatalog.artifacts |
    Where-Object { $_.product -match 'Claude|Copilot' } |
    Select-Object id, evidence_status, path_template, storage_format

$artifactCatalog.artifacts |
    Where-Object { $_.evidence_status -eq 'observed_metadata' } |
    Select-Object id, path_template, observation_reference
```

Every row supplies a source URL, source revision or retrieval date, supported claims, limits, and a suggested `collection_bundle`. The bundle is a preservation checklist, not a collection command or proof of coherent capture. Read [collection and analysis](collection-and-analysis.md) before choosing an acquisition method. Referenced files can contain credentials, personal material, or other sensitive data even when only their paths appear here.

For moving references, record the installed version and relevant source commit. For observed rows, preserve the original example record as provenance rather than replacing its historical result with a later live lookup. Add a lab-validation claim only after capturing benign fixtures and recording the exact conditions and expected findings.
