# Observed workstation example

**Observation date:** November 5, 2026.  
**Platform:** Windows 11 Pro, version 10.0.26200, build 26200.  
**Scope:** Owner-authorized, bounded examination of the current user's live workstation.

This is a storage-layout example, with no finding of malicious activity. Paths use environment-variable aliases. Personal filenames, model names, conversation identifiers, account identifiers, and contents are omitted.

The [portable helper output](../examples/workstation-metadata.json) records a current-user metadata inventory. [Supplemental observations](../examples/supplemental-observations.json) record additional bounded checks performed during preparation. Supplemental checks included two allowlisted configuration path values; the portable helper does not read configuration contents.

The observations were collected sequentially while applications were running. They are neither an atomic snapshot nor a forensic acquisition. Counts and sizes can change during collection. Supplemental traversal counts describe files observed within stated depth limits; those traversals suppressed enumeration errors and are not complete censuses. The portable helper reports errors explicitly.

## 1. LM Studio has separate conversation, model, and desktop state locations

The running LM Studio executable reported file version `0.4.28+2`. The following locations were present:

| Observed path | Observation | Supported conclusion |
|---|---|---|
| `%USERPROFILE%\.lmstudio\conversations` | One direct `.json` file | A candidate conversation record exists at the documented location |
| `%USERPROFILE%\.lmstudio\models` | Five `.gguf` files within the bounded traversal | Model files are available in this tree |
| `%USERPROFILE%\.lmstudio\user-files` | Directory present; no direct files or directories | The checked directory was empty at observation |
| `%USERPROFILE%\.lmstudio\server-logs` | Directory present | Candidate service-log location; content unexamined |
| `%APPDATA%\LM Studio\Local Storage\leveldb` | Directory present | Separate browser-engine storage candidate |
| `%APPDATA%\LM Studio\Session Storage` | Directory present | Separate session-storage candidate |
| `%APPDATA%\LM Studio\Network\Cookies` | File present; contents unexamined | A sensitive browser-engine artifact exists |
| `%APPDATA%\LM Studio\Cache` | Directory present | Cache candidate; response content was not established |

The `downloadsFolder` setting in `%USERPROFILE%\.lmstudio\settings.json` resolved to `%USERPROFILE%\.lmstudio\models`.

The practical lesson is specific: searching only the model directory would omit both the documented conversation location and the roaming application-data tree. Conversely, finding five model files does not establish which model was loaded or what it generated. See the [sourced application reference](ai-storage.md#lm-studio-conversations-and-models-are-distinct) for documented behavior.

## 2. Ollama model storage and CLI history existed; the checked local directory was empty

```text
%USERPROFILE%\.ollama\
  models\
    blobs\
    manifests\
  history
```

These directory/file names were observed. The `history` file's contents were not read. The model tree contained six files within the bounded traversal; names and payloads were excluded.

`%LOCALAPPDATA%\Ollama` existed with no direct entries at observation. Therefore the survey did not observe the desktop database or logs at that checked root. It would be inaccurate to report a recovered Ollama desktop conversation database on this computer.

`OLLAMA_MODELS` was unset in the process, user, and machine environment scopes checked. That result does not rule out application-specific settings, another process environment, a different account, or a different installation.

See [Ollama storage distinctions](ai-storage.md#ollama-separate-models-desktop-chats-and-cli-history) before interpreting model blobs, CLI history, API use, and desktop chat storage as equivalent evidence.

## 3. Codex had multiple local state candidates

The observed layout included:

```text
%USERPROFILE%\.codex\
  config.toml
  sessions\
  attachments\
  visualizations\
  session_index.jsonl
  state_5.sqlite
  state_5.sqlite-wal
  state_5.sqlite-shm
  thread_history_1.sqlite
  thread_history_1.sqlite-wal
  thread_history_1.sqlite-shm
  logs_2.sqlite
  logs_2.sqlite-wal
  logs_2.sqlite-shm
  sqlite\
    <application database files and sidecars>
```

The filenames are observed facts. Database contents, table definitions, record provenance, and any relationship between stores were not examined. Numerical suffixes are implementation details, not stable forensic identifiers.

A bounded traversal of `sessions` observed 59 `.jsonl` files and 98 `.zst` files. Their extensions do not prove their schemas or contents. A parser that only searches uncompressed `*.jsonl` files could miss candidates on this installation. No decompression or transcript reading was performed.

A bounded traversal of `attachments` observed ten `.txt` files and one `.json` file. No filenames or contents are published. The checked `visualizations` tree contained no files within the traversal limit. Its presence alone would not justify claiming recovered visual output.

Official OpenAI documentation identifies `CODEX_HOME` as the state root, normally `~/.codex`, and documents a separate SQLite location override. The exact versioned filenames above come from this workstation, not a guaranteed product layout. [Codex configuration and state](https://learn.chatgpt.com/docs/config-file/config-advanced), [environment variables](https://learn.chatgpt.com/docs/config-file/environment-variables).

`CODEX_HOME` and `CODEX_SQLITE_HOME` were unset in the checked process, user, and machine scopes. A relevant application configuration option can still affect effective storage. Do not conclude that environment absence rules out all redirection.

## 4. A ComfyUI configuration pointed to a missing workspace

The existing file:

```text
%LOCALAPPDATA%\comfy-cli\config.ini
```

contained a `recent_workspace` path resolving to:

```text
%USERPROFILE%\Documents\comfy\ComfyUI
```

That directory was absent at the checked location. Its expected `output`, `input`, `temp`, `user`, and `models` subpaths were consequently absent there.

This establishes a retained configuration reference. It does not establish that an output was generated, that the workspace still exists elsewhere, or that this was the only installation. The survey did not search all volumes.

## 5. Browser profiles contained multiple storage classes

Chrome and Edge had a checked `Default` profile. Both contained `History`, `IndexedDB`, `Session Storage`, `Sessions`, and cache directories. Chrome also had the checked `Local Storage\leveldb`, `Network\Cookies`, and `Service Worker\CacheStorage` paths.

Two profile directories were also observed under `%APPDATA%\zen\Profiles`; their names and content are excluded. These are local observations about a Firefox-derived browser, not evidence that the standard Mozilla Firefox profile root existed.

No browser databases or web content were parsed. The survey cannot identify visited AI services, downloaded outputs, or conversation content. Existing profile directories define candidates for a later authorized examination.

## 6. An empty Recent root did not mean empty Jump Lists

| Checked path | Direct file count |
|---|---:|
| `%APPDATA%\Microsoft\Windows\Recent` | 0 |
| `...\Recent\AutomaticDestinations` | 4 |
| `...\Recent\CustomDestinations` | 6 |

These are direct counts, not recursive totals. None of the files were parsed. The result demonstrates why a superficial folder view is an incomplete examination of shell activity.

Registry metadata also showed:

- `OpenSavePidlMRU`: five immediate subkeys.
- `LastVisitedPidlMRU`: six direct values.
- `UserAssist`: nine immediate subkeys.
- Modern `BagMRU`: 25 immediate subkeys and 28 direct values.
- Matching `Bags`: 293 immediate subkeys.

Counts include structural metadata where applicable. They are not counts of user actions, documents, searches, or executions. Exact keys and hive assignments are in the [Windows reference](windows-artifacts.md).

## 7. Inaccessible and missing artifacts received different results

`%WINDIR%\Prefetch` and the checked Amcache path returned access denied. A BAM Registry location also returned access denied. No elevation or raw-volume collection was attempted.

Security and Windows PowerShell EVTX files were present at the checked default paths. The checked Sysmon and PowerShellCore Operational EVTX paths were absent. Event contents, logging-policy values, alternate log locations, and forwarded records were not assessed.

An EVTX filename cannot establish which event IDs it contains. An inaccessible artifact cannot be classified as absent. A missing default file does not establish that a product or logging configuration was never used.

## What the example supports

This computer demonstrates that AI-related candidates can be spread across user-profile roots, roaming/local application data, model caches, SQLite sidecars, and Windows interaction artifacts. It also demonstrates stale configuration and access limitations.

It does not establish a particular generation event, executed payload, transfer, intent, or operator attribution. Those findings would require the content analysis and corroboration described in [Collection and analysis](collection-and-analysis.md).
