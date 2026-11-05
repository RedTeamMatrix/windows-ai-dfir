# Ground-truth lab validation plan

**Status: planned; no application capture described here has been performed.** The existing helper/runtime checks in [VALIDATION](../VALIDATION.md) establish inventory and query behavior within their stated limits. They do not validate vendor application schemas or prove end-to-end artifact production. The [worked cases](worked-cases.md) and their [JSON](../examples/worked-cases.synthetic.json) are synthetic analytical fixtures, not results of this plan.

## Evidence labels

Use these labels per finding, not merely per document:

| Tag | Meaning |
| --- | --- |
| `DOC_ONLY` | A cited source describes the behavior; the lab has not tested it. |
| `SYNTHETIC_FIXTURE` | Invented exercise records or payloads; not software capture. |
| `LAB_OBSERVED` | A preserved lab artifact demonstrates the stated observation. |
| `LAB_NEGATIVE` | A controlled failed/absent/unavailable case with its scope recorded. |
| `VERSION_SPECIFIC` | A finding applies only to the captured build/configuration. |
| `SERVICE_REPORTED` | A service claims an outcome; independent destination/content verification may remain open. |
| `BYTE_IDENTITY_VERIFIED` | Acquired representations were compared with recorded cryptographic hashes. |
| `PROVENANCE_UNRESOLVED` | The available records do not establish an origin or transformation edge. |

An expected artifact is a test hypothesis. Keep it `DOC_ONLY` until a capture supports it. A missing artifact can be a successful negative test, an unexpected result, a collection gap, or a version difference; record which interpretation the evidence supports.

## Pending application test schedule

Every row below is **pending ground-truth capture**. Select and record exact versions before testing. Do not substitute “latest” for a build identifier or inherit the example workstation's OS version as the lab version.

| Application/runtime | Pending tests | Expected evidence to check, not assume |
| --- | --- | --- |
| Claude Code | Request/edit, shell edit, failure, resume, imported/copied transcript control | Session records, file-history boundaries, project path resolution, effective configuration |
| Gemini CLI | Request/edit, failure, resume, checkpointing off/on in separate disposable baselines | Session tree, optional checkpoint/shadow-repository artifacts, retention/configuration context |
| GitHub Copilot CLI | Session, failure, resume, copied session control | Session event files versus cross-session index, effective home/cache/log roots |
| OpenCode and Aider | One successful benign project edit, failure, restart/resume | Installed-version data formats, repository-local histories, cache versus transcript distinctions |
| VS Code with Cline, Roo Code, and Continue; Cursor | Separate extension/app baselines; task start/failure/resume; workspace copy | Actual extension storage, workspace identifiers, configuration, task state and output destination |
| WSL 2 plus one container runtime | Bound project write, unavailable mount, runtime restart | Host/guest path mapping, process identity, runtime/mount records, timestamps and output aliases |
| One selected MCP-capable harness and a LAB-controlled MCP service | Failure then retry; returned text then local file write | Client/server correlation, tool result versus execution, working-directory and destination evidence |
| ComfyUI and AUTOMATIC1111 | Benign source/reference, output, import, failed operation, edit/re-encode | Configured paths, output metadata, application records, failure-side artifacts and derivative metadata changes |
| Fooocus, InvokeAI, Forge, SwarmUI | Separate clean baselines; default/custom destination; import; failed operation | Documented path candidates, gallery/history records, manual-save destinations, thumbnails and backend boundaries |
| kohya_ss and OneTrainer | Configuration-only and deliberately failed run first; benign successful/resumed run only if separately scoped | Saved run configuration, cache/log/checkpoint/export distinctions, input references and resume-side records |
| A Diffusers-based benign script | In-memory result, explicit image save, explicit pipeline export, failure | Actual caller-controlled destinations and cache-versus-output distinctions |

Use the [CLI](coding-cli-artifacts.md), [IDE](ide-agent-artifacts.md), [harness](agent-harnesses.md), [AI-storage](ai-storage.md), and [image](image-generation-artifacts.md) references to formulate each test's hypotheses. A result for one fork or extension does not validate another row.

## Capture the exact version and baseline

For each run, retain the following in the private lab record:

- Lab case/run ID; operator role; scope; start/end reference time; host/guest clock readings and measured uncertainty.
- OS edition/build, filesystem type, runtime topology, timezone, synchronization state, and relevant mount/redirection layout.
- Application and extension version/build IDs, executable hashes, source commit where applicable, package/lockfile versions, and parser versions.
- Effective configuration provenance and selected path overrides. Keep secrets out of public manifests.
- Before-state snapshots or supported consistent acquisitions of relevant directories, databases with sidecars, and configuration.
- A controlled benign marker unique to the run, such as `LAB-CASE01-RUN01`, with its input manifest and measured input hashes.

Obtain version information without launching tools against original case evidence. All execution belongs in a disposable lab instance or restored lab baseline. Avoid mixing a failed run and retry into one undifferentiated capture.

## Run the controlled comparisons

1. **Baseline and idle control.** Capture the clean before-state, leave the application idle for a recorded interval, then capture again. Identify routine writes that could otherwise be mistaken for task activity.
2. **Successful benign action.** Perform one narrowly defined operation and record the instruction, actual process/service action, effective working directory, and output. Acquire the after-state coherently. Expected result: correlated records tagged `LAB_OBSERVED` and `VERSION_SPECIFIC`, with hashes only for acquired bytes.
3. **Failure and retry.** Use a harmless unavailable test input or intentionally unreachable LAB endpoint. Then perform a separately identified retry. Expected result: failure-side artifacts and explicit request IDs; no conclusion of completed output from the failed request.
4. **Import/copy control.** Import or copy a benign preexisting output with known provenance. Compare the resulting application/gallery/transcript observations with those from a new operation. Expected result: a documented overlap/difference table and `PROVENANCE_UNRESOLVED` wherever the artifacts cannot distinguish origin.
5. **Restart/resume control.** Stop and resume only the disposable lab task using supported behavior. Record what persists, changes, duplicates, or disappears. Expected result: a session/run continuity assessment, not an assumption that IDs or record ordering stay stable.
6. **Media transformation control.** Use benign material to produce a separate edited/re-encoded copy and derived preview; include a short benign video export where the chosen application supports it. Retain raw metadata before normalization and compare representations. Expected result: measured content changes and field survival for that exact tool/version, not a general AI-origin verdict.
7. **Transfer control.** If in scope, transfer a benign artifact to a LAB-controlled destination, capture client and destination records, then acquire the received object. Expected result: separate completion, destination-control, and byte-identity findings. A service thumbnail or transcoded copy is a different representation and needs its own record.

## Service and account boundaries

For tests using a live model, messaging system, remote MCP server, cloud sync, signing service, or upload provider, record the service, account permissions, lab-controlled destination, benign data, and resource limits. Keep service-side collection and destination-side verification distinct from local fixture checks.

Use benign material for these tests. A training-harness failure test can establish configuration persistence without completing training. A successful training/resume test also needs a specified benign dataset with permitted use and recorded resource limits.

## Publish the validation product

Retain a private bundle manifest linking the before/after acquisitions, sidecars, extracted records, raw metadata, normalized timelines, outputs, transfer receipts, and parser results. Measure hashes at the acquisition/derivation steps and retain the commands and tool versions used. Record failures and collection gaps alongside successes.

The public validation report should include exact versions, benign marker IDs, generic paths, fixture/observation tags, expected-versus-observed tables, negative controls, and explicit unresolved edges. Publish no account secrets, private endpoint addresses, personal filenames, or victim material. Include small benign fixtures only when their origin and sharing rights are established.

Promote a reference statement to `LAB_OBSERVED` only for the precise tested claim. Successful JSON parsing, valid timestamp arithmetic, or a working inventory helper does not establish application-schema accuracy, causal attribution, or a complete forensic acquisition.
