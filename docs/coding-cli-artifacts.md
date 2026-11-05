# Coding-agent CLI artifacts

**Reference checked: 2026-11-05.** This document describes documented defaults and source-defined candidates. It does not establish that any listed tool is installed or used on the example workstation. The [local example](local-example.md) and checked-in observation JSON provide the separate evidence layer. Links to `main`, `master`, `dev`, or current documentation are moving references; preserve the examined binary version and pin source commits when reproducing a finding.

Coding agents can leave records in a home-directory state tree, the working repository, temporary storage, and external services. A generated source file may be written directly into a project without a separate export operation. The transcript can therefore be a useful link between an instruction, a proposed edit, and the resulting file, provided each transition is corroborated.

## Resolve the execution environment first

For a native Windows process, the home-directory candidates below normally resolve beneath `%USERPROFILE%`. For a CLI running inside WSL, `~` refers to that Linux account's home, such as `/home/<user>`, rather than the Windows profile. WSL can also operate on mounted Windows paths. Microsoft documents these separate filesystem contexts and the `\\wsl$` namespace. [Windows and WSL filesystems](https://learn.microsoft.com/en-us/windows/wsl/filesystems).

Record executable path, account, working directory, environment overrides, and whether execution was native, WSL, containerized, remote, or cloud-hosted. The absence of a native Windows state directory does not resolve those alternatives. Do not launch an agent against original evidence merely to discover its storage path: initialization can create directories, migrate records, authenticate, or contact services.

## Claude Code

### Transcript and configuration roots

The documented CLI transcript default is:

```text
%USERPROFILE%\.claude\projects\<encoded-project>\<session-id>.jsonl
```

The project component derives from the working-directory path, with non-alphanumeric characters replaced by hyphens; sufficiently long names are truncated and hashed. Configuration can change the storage root and project-directory naming. Do not reverse a directory slug into a unique original path without corroboration. Sessions contain conversation and tool records, but retention, compaction, persistence settings, frontend differences, and version changes affect what is available. The CLI documentation explicitly distinguishes its session list from other frontends. [Claude Code sessions](https://code.claude.com/docs/en/sessions).

During authorized transcript analysis, preserve the raw JSONL and record parser errors, line offsets, session identifiers, and parent/child relationships where present. Keep assistant prose, requested tools, returned tool results, and user input distinguishable in the derived timeline. A statement such as “saved the file” should lead to verification of the destination, content hash, and recorded tool outcome. A failed or interrupted request deserves its own finding instead of being merged with a later successful attempt. Validate the parser against the captured version before applying assumptions about record ordering or completeness.

| Configuration scope | Default candidate |
|---|---|
| User | `%USERPROFILE%\.claude\settings.json` |
| Shared project | `<project>\.claude\settings.json` |
| Project local | `<project>\.claude\settings.local.json` |
| Application-maintained state | `%USERPROFILE%\.claude.json` |

`CLAUDE_CONFIG_DIR` relocates the home-directory configuration/state root. Settings have scope and precedence; the nearest file alone may not describe effective behavior. The application-maintained `.claude.json` can contain account details, per-project state, and MCP configuration, so avoid publishing its contents wholesale. Verify relocated layouts against the examined version. [Settings files and precedence](https://code.claude.com/docs/en/settings).

### Additional state and temporary material

The official directory reference identifies the following candidates under the effective `.claude` root. Presence depends on features and version. [Claude directory reference](https://code.claude.com/docs/en/claude-directory).

| Relative candidate | Role |
|---|---|
| `history.jsonl` | Prompt recall records, including project/time context |
| `file-history\<session>\` | Pre-edit file snapshots |
| `plans\` | Saved plans |
| `debug\` | Debug logs when enabled |
| `paste-cache\` | Large pasted material |
| `tasks\` | Task state |

That reference also documents a conditional native Windows scratchpad at `%TEMP%\claude\<encoded-project>\<session-id>\scratchpad\`, relocated through `CLAUDE_CODE_TMPDIR`. Scratchpads depend on account/provider/feature conditions. Recent versions place attached images in per-session temporary `images` directories; v2.1.274 and earlier used `image-cache\<session>`. `todos`, `logs`, and `image-cache` are labeled legacy directories in current documentation. A historical directory can remain after the software changes.

### Memory, checkpoints, hooks, and MCP

User/project instruction candidates include `~/.claude/CLAUDE.md`, `<project>\CLAUDE.md`, `<project>\.claude\CLAUDE.md`, and directory-scoped instruction files. Auto memory normally uses `~/.claude/projects/<project>/memory/`, containing `MEMORY.md` and topic Markdown files; `autoMemoryDirectory` can redirect it. Repository worktrees can share memory despite having distinct transcript directories. Memory is context retained across sessions, not an execution log or reliable statement of who performed an action. [Claude memory documentation](https://code.claude.com/docs/en/memory).

Checkpointing tracks edits made by the agent's file-editing tools and has bounded retained snapshots. It does not provide a complete history of changes made through shell commands or other programs. Correlate a recovered snapshot with the transcript, file hashes, and filesystem activity before interpreting it as a particular edit. [Checkpointing behavior and limits](https://code.claude.com/docs/en/checkpointing).

Hooks can come from user/project/local settings, plugins, skills, and subagents. Their records may supply `session_id`, `transcript_path`, `cwd`, or `scratchpad_dir`; transcript writes are asynchronous. Subagent transcripts can appear beneath `<session-id>\subagents\agent-<id>.jsonl`. A hook definition supports configuration; evidence that it fired requires output or execution corroboration. [Hooks reference](https://code.claude.com/docs/en/hooks).

Project MCP definitions can live in `<project>\.mcp.json`; other scopes can use application-maintained configuration. These definitions can reference commands, paths, environment variables, and endpoints. A configured connector establishes an available integration, rather than successful invocation or transfer. [MCP configuration scopes](https://code.claude.com/docs/en/mcp).

## Gemini CLI

Gemini's documented session location is `~/.gemini/tmp/<project_hash>/chats/`. For native Windows, the default candidate is `%USERPROFILE%\.gemini\tmp\<project_hash>\chats`. The project identifier is based on the project root; validate its relationship using retained records rather than assuming the name is reversible. Sessions can include prompts, responses, tool input/output, and usage data. Retention settings affect coverage. [Gemini session management](https://geminicli.com/docs/cli/session-management/).

| Candidate | Meaning |
|---|---|
| `%USERPROFILE%\.gemini\settings.json` | User settings |
| `<project>\.gemini\settings.json` | Project settings |
| `%PROGRAMDATA%\gemini-cli\system-defaults.json` | System defaults |
| `%PROGRAMDATA%\gemini-cli\settings.json` | System overrides |

`GEMINI_CLI_HOME` replaces the home root used for user storage: the CLI appends `.gemini` to that value. It is therefore different from an override that directly names the final `.gemini` directory. System settings paths have separate overrides. Configuration strings can expand environment variables, so a literal stored path may differ from the path used by a process. [Gemini configuration reference](https://geminicli.com/docs/reference/configuration/).

Checkpointing is a separate, optional feature. Documentation places its shadow Git repository at `~/.gemini/history/<project_hash>` and conversation/tool checkpoint JSON under `~/.gemini/tmp/<project_hash>/checkpoints`. It is disabled by default. Preserve both candidate trees when relevant; an absent checkpoint directory does not establish that no conversation occurred. Avoid restoring checkpoints during evidence examination, because restoration changes project/session state. [Gemini checkpointing](https://geminicli.com/docs/cli/checkpointing/).

## GitHub Copilot CLI

The current CLI state root defaults to `~/.copilot`, normally `%USERPROFILE%\.copilot` for native Windows. `COPILOT_HOME` overrides the configuration and state directory. Logs default beneath `logs`, with a separate `--log-dir` override. Record those effective paths before interpreting a missing default tree. [Copilot CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference).

Current directory documentation defines:

| Relative candidate | Role |
|---|---|
| `session-state\<session-id>\events.jsonl` | Session event log |
| `session-state\<session-id>\` | Plans, checkpoints, tracked files, and other workspace artifacts |
| `session-store.db` | Cross-session SQLite index/data |
| `command-history-state\` | Interactive command recall |
| `logs\` | Session logs |
| `settings.json` | Current user-editable settings |
| `config.json` | Application-managed state; older releases used it differently |

The cache is separate: native Windows defaults to `%LOCALAPPDATA%\copilot`, with `COPILOT_CACHE_HOME` as its override. Current project configuration candidates include `.github\copilot\settings.json` and `settings.local.json`. Credential-bearing files and connector state require restricted handling. [Copilot configuration directory](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference).

The cross-session SQLite store contains a subset of session information; it is not equivalent to the session directories. IDE-started sessions have IDE-specific storage, and cloud sessions have separate host records. [Copilot session-data distinctions](https://docs.github.com/en/copilot/concepts/security-governance-and-network-settings/session-data). Acquire the retained raw session files and index coherently where appropriate. Reindexing is an application operation that writes state and can synchronize data, so perform analysis on acquired copies rather than invoking it as a collection shortcut. [Session-store behavior](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/chronicle).

## OpenCode: XDG paths also matter on Windows

Official documentation gives the native Windows data root as `%USERPROFILE%\.local\share\opencode`. Current candidates include `opencode.db`, `log\`, `snapshot\`, and credential-bearing `auth.json`. Custom database settings and development channels can use other filenames. This layout should not be replaced with an assumed `%LOCALAPPDATA%` equivalent. [OpenCode storage documentation](https://opencode.ai/docs/troubleshooting/).

Current source derives roots from XDG variables, with home-relative fallbacks:

| Root | Default native Windows candidate | Override |
|---|---|---|
| Data | `%USERPROFILE%\.local\share\opencode` | `XDG_DATA_HOME` plus `opencode` |
| Cache | `%USERPROFILE%\.cache\opencode` | `XDG_CACHE_HOME` plus `opencode` |
| Config | `%USERPROFILE%\.config\opencode` | `XDG_CONFIG_HOME` plus `opencode` |
| State | `%USERPROFILE%\.local\state\opencode` | `XDG_STATE_HOME` plus `opencode` |

This is source-defined behavior, not a guarantee for every packaged release. [Current root resolver](https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/util/src/global-roots.ts).

Global `opencode.json`/`opencode.jsonc`, project configuration, `.opencode` directories, `OPENCODE_CONFIG`, and `OPENCODE_CONFIG_DIR` are separate configuration candidates. Configuration overrides should not automatically be treated as relocation of every data artifact. [OpenCode configuration](https://opencode.ai/docs/config/). `OPENCODE_DB` can name a database; relative values resolve under the data directory. [CLI environment reference](https://opencode.ai/docs/cli/).

Older layouts require a different parser. The pinned v1.1.65 storage implementation writes JSON beneath `<data>\storage`, including `session`, `message`, and `part` trees. Its session implementation keys messages by session and parts by message. Treat such trees as version-specific candidates, possibly retained beside a newer database, rather than assuming that every current session is stored there. [v1.1.65 storage implementation](https://raw.githubusercontent.com/anomalyco/opencode/v1.1.65/packages/opencode/src/storage/storage.ts), [v1.1.65 session implementation](https://raw.githubusercontent.com/anomalyco/opencode/v1.1.65/packages/opencode/src/session/index.ts).

## Aider: look inside the working repository

Aider source sets default input/chat histories under the Git root when available, otherwise using relative filenames in the working directory:

```text
<git-root-or-working-directory>\.aider.input.history
<git-root-or-working-directory>\.aider.chat.history.md
```

These are source-defined defaults. A home-directory-only survey can miss both. [Aider argument source](https://raw.githubusercontent.com/Aider-AI/aider/main/aider/args.py).

The history-file options and corresponding `AIDER_INPUT_HISTORY_FILE`, `AIDER_CHAT_HISTORY_FILE`, and `AIDER_LLM_HISTORY_FILE` variables can redirect records. The optional LLM history file should not be assumed present. [Aider options reference](https://aider.chat/docs/config/options.html). Configuration candidates include `.aider.conf.yml` in the home, Git-root, and current directories; the documented loading order gives later files priority, and an explicit configuration file changes selection. [Aider YAML configuration](https://aider.chat/docs/config/aider_conf.html).

Current repository-map source uses a project-root `.aider.tags.cache.v3` or `.v4` directory depending on parser support. It caches source tags and modification context, rather than providing the conversation transcript. [Aider repository-map source](https://raw.githubusercontent.com/Aider-AI/aider/main/aider/repomap.py). Compare edits with working-tree files and Git history, while accounting for manual changes and copied repositories.

## Reporting boundaries

For each candidate, distinguish documented default, source-defined behavior, locally observed metadata, parsed content, and corroborated action. Preserve existing database sidecars, nested agent records, and referenced project paths within authorized scope. Inventory paths without disclosing credentials or private prompts in public examples. A stored tool request can show what was requested; process telemetry, tool results, filesystem changes, and destination evidence are needed to establish what completed and who controlled it.
