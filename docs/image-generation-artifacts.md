# Image-generation and training artifacts

Reference review date: **2026-11-05**. These are general-purpose candidate tools and storage locations. Their inclusion describes software behavior; it does not establish that a particular offender used them or that their presence indicates child exploitation. This document contains no additional findings from the example computer.

Read [AI storage](ai-storage.md) for ComfyUI, AUTOMATIC1111, and Hugging Face cache fundamentals. Use [Windows artifacts](windows-artifacts.md) and [collection and analysis](collection-and-analysis.md) to corroborate application records with operating-system evidence.

`<root>` means the recovered application/runtime root, `<data>` its effective data directory, and `<workspace>` the configured training-run workspace. These are placeholders, not fixed Windows locations. Establish the executable/script version, launch command, working directory, environment, and configuration before resolving relative paths. A portable install on another volume can be fully functional without a conventional installer entry. Repository branch links below are mutable; record the examined version or commit in an investigation.

## InvokeAI: gallery files and database state

InvokeAI supports a runtime root separate from its Python installation. Its root search considers `--root`, `INVOKEAI_ROOT`, the parent of the active `VIRTUAL_ENV` directory, and a home-directory fallback, normally `%USERPROFILE%\invokeai`. Configuration precedence is command line, environment, YAML, then defaults. Start with `<root>\invokeai.yaml`; `--config` can select another file. Relevant settings include `outputs_dir`, `db_dir`, and `models_dir`, with corresponding `INVOKEAI_OUTPUTS_DIR`, `INVOKEAI_DB_DIR`, and `INVOKEAI_MODELS_DIR` overrides. Relative settings resolve against the root. File logging is conditional: `log_handlers` defaults to console rather than a universal disk log. [InvokeAI configuration reference](https://invoke.ai/configuration/invokeai-yaml/), [CLI argument definitions](https://github.com/invoke-ai/InvokeAI/blob/main/invokeai/frontend/cli/arg_parser.py)

| Candidate | Role |
| --- | --- |
| `<root>\databases\invokeai.db` | Default application database; resolve `db_dir` before using this path. |
| `<outputs_dir>\images\` | Managed image storage. |
| `<outputs_dir>\images\thumbnails\` | Derived gallery thumbnails. |
| `<outputs_dir>\videos\` | Managed video storage in the reviewed implementation. |
| `<root>\workflow_thumbnails\` | Default workflow thumbnail directory. |

The database filename and path resolver are explicit in [configuration source](https://github.com/invoke-ai/InvokeAI/blob/main/invokeai/app/services/config/config_default.py). Service initialization connects the image/video stores to the configured output directory, and image storage maintains its own thumbnail subtree. [Service initialization](https://github.com/invoke-ai/InvokeAI/blob/main/invokeai/app/api/dependencies.py), [image storage implementation](https://github.com/invoke-ai/InvokeAI/blob/main/invokeai/app/services/image_files/image_files_disk.py)

Examine a consistent database acquisition alongside its managed files. A gallery record, thumbnail, and original can support different conclusions. Imported material and generated material can coexist; an entry in this storage tree alone does not distinguish their origin. Preserve relevant SQLite sidecars when present, following the acquisition guidance elsewhere in this repository.

## Fooocus: dated output directories and a local HTML history

Fooocus uses `<root>\config.txt`, which contains JSON despite its extension. The `config_path` environment variable can redirect that file. `path_outputs` selects the output root and `--output-path` takes precedence for that destination. The reviewed source's fallback resolves `../outputs/` relative to its `modules` directory, yielding `<root>\outputs`. Also inspect the selected `presets\<name>.json`, because a preset participates in configuration loading. [Fooocus configuration source](https://github.com/lllyasviel/Fooocus/blob/main/modules/config.py)

| Candidate | Role |
| --- | --- |
| `<path_outputs>\YYYY-MM-DD\<timestamp>_<number>.<extension>` | Dated generated-file pattern. |
| `<path_outputs>\YYYY-MM-DD\log.html` | Local image history with parameter information. |
| `<resolved_temp>\fooocus\` | Default temporary root when Python's temporary directory is used. |
| `<root>\config_modification_tutorial.txt` | Generated/example configuration reference, not proof of a particular run's effective values. |

The date component uses the system's local time. Establish clock and timezone context before placing it on a UTC timeline. [Filename implementation](https://github.com/lllyasviel/Fooocus/blob/main/modules/util.py)

The logger can embed parameters in PNG text or JPEG/WebP metadata, depending on settings and format. It also builds the daily HTML history; temporary-only outputs can follow a different retention path. `temp_path` and `--temp-path` can redirect temporary storage, so `%TEMP%\fooocus` is a candidate rather than a guarantee. Correlate retained history entries with exact filenames and acquired image metadata. The HTML is application-generated text, not an independently authenticated audit record. [Fooocus logger](https://github.com/lllyasviel/Fooocus/blob/main/modules/private_logger.py), [temporary-path resolution](https://github.com/lllyasviel/Fooocus/blob/main/modules/config.py)

## Forge: output and manual-save directories are different

Forge inherits familiar WebUI storage conventions, but verify the installed fork and revision. `--data-dir` sets the user-data base; `--models-dir` can separately redirect model storage. Otherwise models reside in `<data>\models`, and the default output root is `<data>\outputs`. Launch configuration can also enter through `COMMANDLINE_ARGS`. [Forge path definitions](https://github.com/lllyasviel/stable-diffusion-webui-forge/blob/main/modules/paths_internal.py)

The configuration file defaults are `<data>\config.json` via `--ui-settings-file` and `<data>\ui-config.json` via `--ui-config-file`. Capture their effective locations rather than assuming they are beside the executable. [Forge argument definitions](https://github.com/lllyasviel/stable-diffusion-webui-forge/blob/main/modules/cmd_args.py)

| Default candidate | Related setting |
| --- | --- |
| `<data>\outputs\txt2img-images\` | `outdir_txt2img_samples` |
| `<data>\outputs\img2img-images\` | `outdir_img2img_samples` |
| `<data>\outputs\extras-images\` | `outdir_extras_samples` |
| `<data>\outputs\txt2img-grids\` and `img2img-grids\` | Grid destinations |
| `<data>\log\images\` | `outdir_save`, used by the Save button |

Global `outdir_samples`/`outdir_grids` and per-operation settings can change those destinations. The reviewed options also expose `temp_dir`, optional source-image saving, directory-name patterns, and CSV logging for manual saves. Consequently, a search restricted to `outputs` can miss selected copies under `log\images`. Preserve directory configuration and distinguish a generated original from a later manually saved copy. [Forge output options](https://github.com/lllyasviel/stable-diffusion-webui-forge/blob/main/modules/shared_options.py)

## SwarmUI: service data, account state, and backend boundaries

SwarmUI's documented candidates are `Data\Settings.fds` and `Data\Backends.fds`. `--data_dir`, `--settings_file`, and `--backends_file` can redirect them. Preserve backend configuration to identify where work actually ran; a front end's output location does not establish the backend's host or storage path. [SwarmUI command-line reference](https://github.com/mcmonkeyprojects/SwarmUI/blob/master/docs/Command%20Line%20Arguments.md)

`Paths.OutputPath` defaults to `Output`, while `Paths.DataPath` defaults to `Data`. `AppendUserNameToOutputPath` defaults to true, producing a per-user layer beneath the output root; treat that identifier as an application account rather than a Windows logon identity. File logs are disabled by default. If enabled, `Logs.LogsPath` defaults to `Logs/[year]-[month]/[day]-[hour]-[minute].log`, resolved relative to the data directory. [SwarmUI settings source](https://github.com/mcmonkeyprojects/SwarmUI/blob/master/src/Core/Settings.cs), [output-directory implementation](https://github.com/mcmonkeyprojects/SwarmUI/blob/master/src/Accounts/User.cs), [logging implementation](https://github.com/mcmonkeyprojects/SwarmUI/blob/master/src/Utils/Logs.cs)

The reviewed account implementation stores `<data>\Users.ldb` using **LiteDB**, with collections for users, sessions, presets, and other account state. Conditional backups appear under `<data>\UsersBackups\UsersBackup_*.ldb`. The `.ldb` suffix here must not be assumed to mean Chromium LevelDB. Acquire and identify the actual database format before selecting a parser. [SwarmUI account database implementation](https://github.com/mcmonkeyprojects/SwarmUI/blob/master/src/Accounts/SessionHandler.cs)

The output hierarchy can include derivative previews and shared-folder mappings. Reconstruct the application's effective mapping before treating a UI-visible folder as a physical path. [Image-history implementation](https://github.com/mcmonkeyprojects/SwarmUI/blob/master/src/Accounts/UserImageHistoryHelper.cs)

## kohya_ss: separate input references from training products

kohya_ss is a training interface. Recover its existing configuration and historical launch records to distinguish input datasets, cached intermediate data, training logs, and produced weights. The example `config.toml` assigns separate `train_data_dir`, `dataset_config`, `output_dir`, `logging_dir`, and `config_dir` settings. Its example paths include `./outputs`, `./logs`, and `./presets`; these are not compulsory locations. [Maintainer configuration example](https://github.com/bmaltais/kohya_ss/blob/master/config%20example.toml)

The GUI folder code also uses repository-relative `outputs` and `logs` candidates, while allowing configured/custom selections. An existing `logs` directory does not prove that a particular training run enabled TensorBoard logging. [Folder-selection implementation](https://github.com/bmaltais/kohya_ss/blob/master/kohya_gui/class_folders.py)

For the reviewed LoRA GUI, generated run configuration candidates include `<output_dir>\config_lora-<timestamp>.toml` and `<output_dir>\<output_name>_<timestamp>.json`. These records can preserve the intended input/output relationships even if the run failed. The code passes the generated TOML as `--config_file`. [LoRA GUI configuration handling](https://github.com/bmaltais/kohya_ss/blob/master/kohya_gui/lora_gui.py)

Checkpoint exports, resumable state, and logging records serve different purposes. The training documentation distinguishes the state subdirectory used for resume from its containing output directory. Record the resolved paths and save-related configuration of the historical run; avoid inferring a completed training job from a configuration file alone. [Training reference](https://github.com/bmaltais/kohya_ss/blob/master/docs/train_README.md)

## OneTrainer: a run workspace can retain several evidence layers

The reviewed defaults set `workspace_dir` to `workspace/run`, `cache_dir` to `workspace-cache/run`, and `output_model_destination` to `models/model.safetensors`. `huggingface_cache_dir` is separately configurable. Those settings distinguish a training workspace, intermediate cache, dependency cache, and final export; a single search for a folder named `models` will miss other run artifacts. [OneTrainer configuration definitions](https://github.com/Nerogar/OneTrainer/blob/master/modules/util/config/TrainConfig.py)

| Under the resolved workspace | Candidate evidence |
| --- | --- |
| `config\<timestamp>.json` | Serialized run configuration; a prefix can alter names. |
| `tensorboard\<run>\` | Run event files. |
| `samples\...\` | Training sample outputs. |
| `save\...` | Intermediate exports. |
| `backup\<run>\` | Resumable backups when created. |
| `backup\<run>\onetrainer_config\args.json` | Backup-associated configuration. |

Backup configuration can also contain copied `concepts.json` and `samples.json` files when their source files exist. The trainer records workspace configuration at startup and writes the final export to `output_model_destination`, which can be outside the workspace. Rolling backup behavior can affect what survives. [OneTrainer trainer implementation](https://github.com/Nerogar/OneTrainer/blob/master/modules/trainer/GenericTrainer.py)

Treat sample labels, configuration, and dataset references as sensitive evidence. Preserve their relationship to the run without publishing personal paths or media. A backup directory can support evidence of an interrupted process; it does not automatically establish a completed final export or identify its operator.

## Diffusers Python: cached dependencies and explicit saves

Diffusers is a library, so the surrounding script controls persistence. `from_pretrained(..., cache_dir=...)` can select a dependency-cache location. `save_pretrained(save_directory)` saves pipeline components and configuration to a chosen directory; it is different from saving a generated image. A directory containing pipeline weights can therefore be an imported/cache copy or an explicit model export. [Diffusers pipeline API](https://huggingface.co/docs/diffusers/main/en/api/diffusion_pipeline)

Look for `model_index.json` when identifying a pipeline directory; the loader uses it to determine the pipeline class. Keep dependency provenance distinct from output provenance. [Diffusers loading reference](https://huggingface.co/docs/diffusers/main/en/using-diffusers/loading)

The quickstart returns image objects through `.images` and describes video export separately. An investigator must recover the caller's save/export calls and their resolved destinations; there is no universal library-managed directory containing every generated result. [Diffusers quickstart](https://huggingface.co/docs/diffusers/main/en/quicktour)

In analysis, record each recovered path's role: **input reference, dependency cache, intermediate cache, application state, generated output, or model export**. Correlate a claimed operation with file changes, execution records, application state, and account activity. Matching strings across a copied project are useful leads; independent timing and provenance evidence determine how much weight they carry.
