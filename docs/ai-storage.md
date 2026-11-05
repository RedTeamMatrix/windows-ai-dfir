# AI application storage on Windows

**Reference checked: 2026-11-05.** Paths below are documented defaults or source-defined candidates, not observations from the example computer. Consult the repository's local-observation notes for findings actually verified on that host. Links containing `main`, `master`, or `latest` are moving references checked on this date; behavior remains application-, build-, and version-dependent. Record the installed version and pin relevant source links to a commit when reproducing a finding.

The useful question is where an application stores each part of a workflow. Its executable, downloaded models, conversations, temporary material, generated outputs, and exported files may occupy different directories. A user-selected export folder is only one destination worth examining. A configured path also needs to be resolved in the context of the account and process that used it.

## Storage categories

| Category | Typical contents | Finding it can support |
|---|---|---|
| Installation | Executables, libraries, updater files | Application availability and version |
| Model storage | Weights, manifests, tokenizer/configuration files | Model acquisition or availability |
| Conversation storage | Messages, timestamps, attachments, tool records | Recorded interactions, subject to validation |
| Generated output | Images, documents, scripts, saved responses | A candidate result of a workflow |
| Temporary/cache storage | Previews, downloads, intermediate material | Additional copies or partial activity |
| Export destination | User-selected files and archives | An export or subsequent handling step |

Use these categories when recording findings. A model filename cannot establish which prompt was submitted, and a copied output does not identify the computer that generated it.

## Ollama: separate models, desktop chats, and CLI history

The official Windows guide identifies the following locations. These paths should be treated as candidates until the installation and effective configuration have been checked. [Ollama Windows documentation](https://docs.ollama.com/windows).

| Candidate | Purpose |
|---|---|
| `%LOCALAPPDATA%\Programs\Ollama` | Installed binaries |
| `%LOCALAPPDATA%\Ollama\app.log` | Desktop application log |
| `%LOCALAPPDATA%\Ollama\server.log` | Server log |
| `%LOCALAPPDATA%\Ollama\upgrade.log` | Upgrade log |
| `%USERPROFILE%\.ollama` | Models and configuration root |
| `%TEMP%\ollama*` | Possible temporary executable directories |

`OLLAMA_MODELS` can redirect model storage. Current desktop settings code additionally maintains a persisted model-directory setting, making the actual application state relevant when an environment variable and observed location differ. The source defaults to `<user-home>\.ollama\models` when no configured value is available. [Ollama settings source](https://raw.githubusercontent.com/ollama/ollama/main/app/store/store.go).

Current source defines the Windows desktop database as `%LOCALAPPDATA%\Ollama\db.sqlite`. This is a source-defined, version-dependent desktop artifact; it should not be assumed to exist after a CLI-only installation. [Database path source](https://raw.githubusercontent.com/ollama/ollama/main/internal/onboarding/app_state.go).

The current schema includes `chats`, `messages`, `tool_calls`, `attachments`, `settings`, and `users`, and opens SQLite in WAL mode. Attachment data and account rows can contain private material. Inspect the captured schema before constructing queries, and keep public examples to sanitized metadata. [Ollama database source](https://raw.githubusercontent.com/ollama/ollama/main/app/store/database.go).

The CLI has a different artifact: `%USERPROFILE%\.ollama\history`. Current readline code maintains input history with a default limit of 100 entries. Treat it as bounded input history, rather than a timestamped transcript of every response. [Readline history source](https://raw.githubusercontent.com/ollama/ollama/main/readline/history.go). Operational logs likewise require inspection before claiming that they record prompt contents.

## LM Studio: conversations and models are distinct

Current documentation places Windows conversations in `%USERPROFILE%\.lmstudio\conversations`. They are JSON files, and the vendor explicitly cautions against relying on their structure. Preserve the original files, identify the application version, and validate the fields used by a parser. [LM Studio chat documentation](https://lmstudio.ai/docs/app/basics/chat).

The documented model import structure is:

```text
%USERPROFILE%\.lmstudio\models\
  <publisher>\
    <model>\
      <model-file.gguf>
```

This structure can help connect a downloaded model file to a publisher/model identifier, subject to renaming and manual imports. [LM Studio model import documentation](https://lmstudio.ai/docs/app/advanced/import-model).

Users can change the model directory through **My Models**. A missing default directory therefore warrants configuration review, rather than a conclusion that models were never present. [LM Studio download documentation](https://lmstudio.ai/docs/app/basics/download-model). Older `.cache\lm-studio` paths should be labeled legacy/version-dependent candidates unless supported by the examined installation. Do not assign undocumented meanings to neighboring files merely because their names resemble uploads, attachments, or caches.

## Hugging Face: repository cache is not generated output

The Hub library's default home is `~/.cache/huggingface`, normally `%USERPROFILE%\.cache\huggingface` on Windows. Configuration can redirect this hierarchy. Environment variables are read when the library is imported, so the investigator's present shell may differ from the process environment used during the activity. [Hugging Face environment-variable reference](https://huggingface.co/docs/huggingface_hub/main/package_reference/environment_variables).

| Setting | Default relationship | Role |
|---|---|---|
| `HF_HOME` | `~/.cache/huggingface`, unless `XDG_CACHE_HOME` affects the default | Library data root |
| `HF_HUB_CACHE` | `<HF_HOME>\hub` | Cached model, dataset, and Space repositories |
| `HF_ASSETS_CACHE` | `<HF_HOME>\assets` | Assets produced by downstream libraries |
| `HF_XET_CACHE` | `<HF_HOME>\xet` | Xet cache/staging data |

The home directory can also contain authentication material. Document configuration paths without copying token values into a public report.

A cached repository commonly resembles:

```text
<hub>\models--<owner>--<repository>\
  refs\
  blobs\
  snapshots\<commit>\
```

`refs` maps named references to revisions, `blobs` stores content, and `snapshots` exposes revision-specific views. Windows environments without symlink support can store files directly in snapshots. Account for that distinction before interpreting duplication or storage size. [Hugging Face cache guide](https://huggingface.co/docs/huggingface_hub/main/guides/manage-cache).

A cached repository supports availability or acquisition. Establishing inference requires separate records connecting a process, model, input, and output.

## ComfyUI: locate the effective base and output directories

The source/portable layout derives standard directories from a base path. Desktop deployments can choose different installation and data roots; the directory names alone do not establish an absolute Windows location. [ComfyUI directory source](https://raw.githubusercontent.com/Comfy-Org/ComfyUI/master/folder_paths.py).

| Relative candidate | Investigative use |
|---|---|
| `<base>\output` | Saved generated files |
| `<base>\input` | Candidate input assets |
| `<base>\temp` | Temporary material |
| `<base>\user` | User-specific application data |
| `<base>\models` | Model hierarchy |
| `<base>\previews` | Preview storage defined in current source |
| `<base>\custom_nodes` | Added node packages; examine version and behavior separately |

Check launch arguments and launch scripts for `--base-directory`, `--output-directory`, `--input-directory`, `--temp-directory`, `--user-directory`, and `--models-directory`. Additional model-path configurations can point outside the base tree. [ComfyUI startup flags](https://docs.comfy.org/development/comfyui-server/startup-flags).

Saved files may carry useful workflow metadata. ComfyUI commonly embeds `workflow` and `prompt` JSON fields; the latter represents execution-oriented nodes and inputs, rather than necessarily one natural-language prompt. PNG output can hold these in text metadata. Support depends on the save node and format. Metadata may be disabled, edited, or removed by re-encoding, and it is not a signature establishing authorship. [ComfyUI workflow metadata](https://docs.comfy.org/development/api-development/workflow-metadata).

For a benign test, use a distinctive marker such as `LAB-MARKER-20261105` in a supported text field. Compare the saved file's metadata with the recovered workflow and filesystem timeline. Perform this experiment in a separate lab installation, preserving the examined evidence.

## AUTOMATIC1111: settings determine output destinations

The source defaults the data root to the repository root, with model and output paths derived from it. `--data-dir` and `--models-dir` can alter those relationships. [Path-resolution source](https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/modules/paths_internal.py).

Documented/source-defined candidates include:

```text
<data>\outputs\txt2img-images
<data>\outputs\img2img-images
<data>\outputs\extras-images
<data>\outputs\txt2img-grids
<data>\outputs\img2img-grids
```

Review effective `outdir_*` options, filename/subdirectory patterns, temporary-directory settings, and extension behavior. A neighboring `outputs` directory may be incomplete when a user configured another destination. [Output-settings source](https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/modules/shared_options.py).

Default configuration candidates include `<data>\config.json`, `ui-config.json`, and `params.txt`. Command-line options can redirect the settings files. Where enabled, `params.txt` concerns the last generation's parameters; treating it as a complete generation history would overstate its coverage. [Official command-line reference](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Command-Line-Arguments-and-Settings).

## Browser and Electron storage

Chrome's default Windows user-data root is `%LOCALAPPDATA%\Google\Chrome\User Data`. Each profile occupies a subdirectory, commonly `Default`; other profiles and release channels have separate locations. `chrome://version` reports the active profile path, while `--user-data-dir` can override the root. Avoid launching a browser on original evidence merely to discover that setting. [Chromium user-data documentation](https://chromium.googlesource.com/chromium/src/+/main/docs/user_data_dir.md).

History and download records can help identify destinations missed by a Downloads-only search. Chromium's download database source includes target/current paths, timing, state, byte counts, and redirect-chain records. Validate completion state and filesystem evidence before asserting that a target file was successfully downloaded. [Chromium download database source](https://chromium.googlesource.com/chromium/src/+/main/components/history/core/browser/download_database.cc).

Electron defaults `userData` to the platform application-data directory plus the application name: commonly `%APPDATA%\<application-name>` on Windows. Applications can override paths. Chromium-related subdirectories such as `Cache`, `GPUCache`, and `Local Storage` may coexist with application-specific files. These are search candidates, not a universal transcript layout. [Electron application-path documentation](https://www.electronjs.org/docs/latest/api/app#appgetpathname).

## Collection and interpretation

For SQLite artifacts, preserve the database and existing `-wal` and `-shm` companions coherently. Committed changes may remain in the WAL; separating it from the main database can omit state. Closing an application can trigger checkpointing and alter files. Analyze copies acquired through an appropriate collection method. [SQLite WAL documentation](https://www.sqlite.org/wal.html).

For each candidate, record the resolved path, account context, version, acquisition method, file size, timestamps, and hash where collected. Distinguish a missing file from an inaccessible path or unexamined location. Follow configuration redirects, but record junctions and symbolic links before crossing them. Keep a separate distinction between path existence, recorded interaction, demonstrated execution, generated-file provenance, and operator attribution.
