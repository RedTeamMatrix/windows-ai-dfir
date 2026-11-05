# Applying the artifact map to CSAM investigations

**Research checked November 5, 2026.** This chapter concerns evidence identification, provenance, and reconstruction. It uses no abusive examples and makes no claim of offending activity on the example workstation.

## Distinguish documented misuse from a general-purpose examination candidate

The IWF's [October 2023 public report](https://www.iwf.org.uk/media/q4zll2ya/iwf-ai-csam-report_public-oct23v1.pdf) documents misuse of the Stable Diffusion ecosystem in AI CSAM production. Its [2026 report](https://www.iwf.org.uk/media/hl1nvdti/iwf-ai-csam-report-2026.pdf) describes the circulation of adapted models and the possible value, and limitations, of retained model/output metadata.

Those findings support examining the relevant model, adapter, workflow, and output artifacts in an authorized investigation. They do not establish that every image application, training interface, or model file listed in this repository is associated with abuse.

Use two separate labels in a report:

| Label | Required support |
|---|---|
| Documented misuse in a cited source | A primary report or case record supports the particular statement and its date |
| General-purpose forensic candidate | Software documentation establishes a storage/processing behavior relevant to the examination |

The [image-generation reference](image-generation-artifacts.md) uses the second label for InvokeAI, Fooocus, Forge, SwarmUI, kohya_ss, OneTrainer, and Diffusers. The existing [AI-storage reference](ai-storage.md) covers ComfyUI and AUTOMATIC1111. Their inclusion supplies an artifact map, not a prevalence ranking or a finding about their users.

## Separate acquisition, training, generation, and handling

An examination should establish which stage each artifact can address:

| Stage | Candidate artifacts | Question to test |
|---|---|---|
| Acquisition | Download records, repository revisions, cache manifests, acquired file hashes | What material or software was acquired, and when? |
| Adaptation/training | Existing run configurations, input-path references, caption files, run logs, saved state | Was a run configured, started, or completed, and what output can be linked to it? |
| Generation | Workflow records, application database entries, retained parameters, process and file-write evidence | Which process/request can be connected to a particular output? |
| Import/editing | Gallery imports, image-editing project records, filesystem identity | Could this computer have received or modified the artifact rather than generated it? |
| Viewing | Relevant interaction records and derived previews | What level of interaction is actually supported? |
| Export/transfer | Export destinations, archive records, transfer completion and destination evidence | Which exact bytes were handled or transferred? |

Keep these stages separate even when an application supports several of them. A downloaded adapter establishes possession of a candidate file, not local training. A saved training configuration establishes intended settings, not a successful run. A gallery thumbnail establishes a derived representation, not a complete original or its origin.

## Model and adapter files

Record file identity and context before drawing conclusions from a filename:

- Acquired path and volume/account context.
- File size, content hash, and actual format identification.
- Associated repository revision or manifest where available.
- Model/adapter relationships claimed in retained configuration or metadata.
- Associated run records and observed process activity.
- Whether the file was downloaded, copied, imported, or produced locally, if the evidence resolves that question.

The `.safetensors` format has a length-prefixed JSON header and permits a `__metadata__` string map. A format-aware examination can inspect candidate metadata without performing inference. The metadata is supplied with the file and is not an authentication mechanism. Validate boundaries and retain the raw acquired file. [Safetensors format specification](https://github.com/safetensors/safetensors#format).

Some model/checkpoint loading paths involve deserialization with execution risks. PyTorch explicitly cautions against loading untrusted data through `torch.load`. An extension such as `.ckpt` or `.pt` alone does not identify the internal format. [PyTorch loading documentation](https://docs.pytorch.org/docs/2.15/generated/torch.load.html).

Static identification and contextual examination should come before any decision to execute or test a recovered model. This write-up provides no generation or training instructions for suspect material.

## Workflow and output metadata

Examine application-specific records with their format semantics intact:

- ComfyUI's `prompt` field represents execution nodes and inputs; it is not necessarily a single text prompt.
- Fooocus can retain a local `log.html` with file/parameter relationships.
- WebUI-family applications can distinguish normal generation destinations from a later Save-button copy.
- InvokeAI's gallery database and managed image files can provide different evidence layers.
- SwarmUI's `Users.ldb` is LiteDB in the reviewed implementation; a `.ldb` suffix alone does not identify Chromium LevelDB.

Sources and exact path/setting references are in the [AI-storage](ai-storage.md) and [image-generation](image-generation-artifacts.md) chapters. Treat metadata as an asserted relationship to test against file identity, application records, and operating-system evidence. Re-encoding, imports, copied metadata, manual edits, and removed fields complicate provenance.

An apparently matching parameter set or seed does not independently establish the originating machine, operator, or an exact historic generation event.

## Link a coding harness to an image workflow only when evidence supports the link

A coding agent may create scripts, edit configuration, invoke a tool, or interact with an image service. The presence of Claude Code or another agent on the same computer as image software is insufficient to establish that relationship.

Look for a supported sequence connecting a harness session/run, requested tool call, actual process or service action, effective working directory, input/output paths, and acquired file identity. Preserve failures and retries: a requested action, a tool's reported result, and a completed external action are separate observations.

Use the [CLI-agent](coding-cli-artifacts.md), [IDE-agent](ide-agent-artifacts.md), and [harness](agent-harnesses.md) references to locate the relevant records. Remote model or tool services may require authorized service-side evidence; a local record may retain only an identifier or URL.

## Derived and secondary records

Thumbnails, temporary files, browser caches, crash records, Recycle Bin metadata, and virtual disks can contain related evidence with different completeness and time semantics. Their paths and limits are covered in [secondary residue](secondary-residue.md).

Do not equate a retained preview with possession of every source-file byte, or a missing original with proof of deliberate removal. Record which representation was actually acquired and what can be corroborated.

## Report the person, action, and artifact links separately

A defensible finding identifies the observed record, its source and time meaning, its supported relationship to the artifact/action, and unresolved alternatives. Use neutral descriptions such as:

> A configuration referenced a training input directory. The survey did not inspect its contents or establish that a run completed.

> An application record and the acquired output shared a filename. Content identity and generation provenance remained unestablished.

> A harness transcript recorded a requested tool action. Process and destination evidence were required to determine whether that action completed.

Keep victim-identifying information and case payloads in the authorized evidence environment. Public examples can demonstrate the same analytical structure with benign markers, generic paths, sanitized metadata, and synthetic timelines.
