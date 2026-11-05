# Collection and analysis

This workflow turns a directory survey into a set of testable findings. The commands below are lab/analysis examples. No conversation, browser, image, event, or Registry-value contents from the example workstation were analyzed to produce this repository.

## 1. Choose the acquisition product before collecting

Decide whether the examination requires live triage, a logical collection, a filesystem/volume acquisition, or memory capture. Record the authority, scope, source, collector version, time, timezone, and acquisition method.

A live metadata survey is useful for locating candidates. It does not preserve deleted records, unallocated space, locked hives, alternate streams, or a coherent database transaction state. The included helper deliberately does not attempt raw-volume access or elevation.

Use an established acquisition process for the required evidence. Preserve originals, work from verified copies, and document transformations. NIST describes collection, examination, analysis, and reporting as separate forensic activities. [NIST SP 800-86](https://csrc.nist.gov/pubs/sp/800/86/final).

Keep examination-generated traces in the timeline. Starting a shell, reading directories, writing a report, launching a viewer, or closing an application can affect the live system. Do not silently treat those events as preexisting subject activity.

## 2. Resolve storage in the target account's context

Record:

- Examined Windows profile and hive provenance.
- Executable path, version, and relevant launch configuration.
- User, machine, and process path overrides where available.
- Junctions, symbolic links, redirected known folders, and unavailable volumes.
- Whether a tool runs on Windows, in WSL, in a container, or on a remote system.

The current environment cannot establish every historical process environment. A configuration reference to `D:\outputs` does not establish that the volume was attached or that the application wrote a file there.

The included survey reports only whether selected override names are set. It does not disclose their values and does not resolve application settings. Manually following a redirect is a separate examination step, with its own scope and recorded result.

See [secondary residue and alternate storage](secondary-residue.md) for known-folder redirection, virtual disks, and related candidates.

## 3. Run the bounded metadata inventory

From the repository root:

```powershell
.\scripts\Get-AIArtifactInventory.ps1 -OutputPath .\inventory-private.json
```

Use a new destination. The helper refuses to overwrite an existing output file. It runs as the current account and returns a fixed list of candidate paths and keys, direct directory statistics, known-file metadata, browser artifact metadata, and environment-presence booleans.

It does not:

- Parse conversations, browser databases, logs, images, or model files.
- Export Registry values, personal filenames, hostnames, or SIDs.
- Traverse arbitrary directory trees or follow reparse-point paths.
- Detect wrongdoing or establish a complete application inventory.

Interpret statuses literally. `access_denied` means the query was blocked. `not_found_at_checked_path` describes a particular lookup. Neither status answers whether an artifact exists somewhere else.

Counts are also narrow: direct-file counts exclude descendant directories; immediate subkey counts are not counts of actions. The checked-in example is [sanitized JSON](../examples/workstation-metadata.json), not raw case evidence.

## 4. Preserve database and hive context

Acquire SQLite artifacts coherently, including relevant WAL/SHM files. A database, its WAL, and its SHM belong to a captured state; a simple sequential live copy can race ongoing writes. Preserve the acquired set and parse disposable analysis copies.

Do not checkpoint, vacuum, repair, or open the original application against original evidence merely to make a database convenient to read. The WAL may contain changes missing from the main file. [SQLite WAL behavior](https://www.sqlite.org/wal.html).

For Registry evidence, retain the hive and relevant transaction logs. Record whether a parser replayed logs or recovered data, and keep the pre-recovery originals. Live Registry queries and offline hive parsing can yield different views.

If hashing an acquired analysis file:

```powershell
$analysisCopy = 'E:\analysis\acquired\History'
Get-FileHash -LiteralPath $analysisCopy -Algorithm SHA256
```

This computes a file hash; it does not prove completeness, coherent capture, authorship, or unchanged source state during acquisition. [Get-FileHash documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-7.5).

## 5. Examine schemas before writing queries

On a disposable analysis copy, using an already-available SQLite CLI:

```powershell
sqlite3 -readonly 'E:\analysis\Chrome\History' '.tables'
sqlite3 -readonly 'E:\analysis\Chrome\History' '.schema downloads'
sqlite3 -readonly 'E:\analysis\Chrome\History' '.schema downloads_url_chains'
```

The read-only option limits writes to the opened database. It is not a substitute for preserving originals; journal handling, temporary files, and tool behavior still belong on the analysis side of the workflow. [SQLite CLI documentation](https://www.sqlite.org/cli.html).

After verifying that the captured schema has the referenced columns, run:

```powershell
sqlite3 -readonly 'E:\analysis\Chrome\History' '.read queries/chromium-downloads.sql'
```

The [example query](../queries/chromium-downloads.sql) returns recorded current/target paths, download state, byte counts, source timing values, and redirect-chain records. It intentionally retains raw timestamp values; convert them using a validated parser or conversion appropriate to that schema.

These columns are defined in Chromium's [download database implementation](https://chromium.googlesource.com/chromium/src/+/main/components/history/core/browser/download_database.cc). A target path is a recorded destination. Establish completion using state, received/expected bytes where meaningful, and corroborating filesystem evidence. A successful download still does not establish AI generation or later human review.

For application databases such as the observed Codex SQLite candidates, use `.tables` and `.schema` on acquired copies first. Do not invent a universal `messages` table or reuse a query merely because another application also uses SQLite.

## 6. Parse non-SQLite artifacts with the right tools

| Artifact | Appropriate examination |
|---|---|
| `Local Storage\leveldb`, IndexedDB storage | Format-aware parser; preserve related files and sequence context |
| Conversation JSON/JSONL | Validate the application version, record type, role, identifiers, and timestamps |
| Compressed session candidates | Identify the compression/container first; record decompression tool and hash both forms |
| Workflow-bearing images | Extract metadata on analysis copies; retain raw fields before interpreting nodes |
| LNK / Jump Lists | Parse container records, target metadata, and application identifiers separately |
| User Registry hives | Parse hive-relative keys with the appropriate source hive and transaction context |

A browser cache entry may be a resource, an error response, or stale application data. A saved conversation may have been imported or edited. An embedded workflow may describe parameters without proving that the local machine executed it. Evaluate provenance before assigning behavior.

Original tool-author references for Windows parsing include [RECmd](https://github.com/EricZimmerman/RECmd), [LECmd](https://github.com/EricZimmerman/LECmd), [JLECmd](https://github.com/EricZimmerman/JLECmd), and [PECmd](https://github.com/EricZimmerman/PECmd). Match the parser to the artifact and record the exact version used. These tools were not run against private payloads for this example.

## 7. Build a timeline that preserves the claim behind each row

Use fields such as:

```text
source_artifact
source_path_or_acquisition_id
record_identifier
raw_timestamp
timestamp_semantics
normalized_utc
account_or_session_context
process_or_file_identifier
observation
supported_claim
limitations
```

Separate host filesystem times from embedded record times. Preserve a process identifier with enough context to handle PID reuse. Distinguish a directory-entry rename from a content modification, and a configured action from its successful completion.

Avoid deriving a whole sequence from one shared timestamp or basename. Use content hashes where they genuinely establish byte identity, and document when identity cannot be established.

## 8. Benign reconstruction example

**The sequence below is synthetic. It was not observed on the example computer.**

A recovered conversation requests a CSV parsing utility. A script named `csv_report.py` appears in a project, a process event records Python launching that path, and a report file appears shortly afterward.

| Evidence | Supported observation | Additional work |
|---|---|---|
| Conversation request | A record contains the request | Establish provenance, submission status, account/session, and record integrity |
| Project script | A candidate script exists | Compare its content with the recorded response; check for later edits |
| Process record | A process launched with that command line | Resolve executable, working directory, parent/session context, and retention gaps |
| Filesystem record | The report was created/changed | Link the write to the process where telemetry permits |
| Archive or transfer record | A path or transfer is recorded | Establish file identity, completion, and destination control |

Only state the relationships supported by the examined evidence. Byte-identical script content can support a link to a response, but copied files and imported conversations remain alternatives to investigate.

## 9. Keep the publication separate from the case record

A public write-up can show generic paths, artifact types, sanitized metadata, benign lab markers, and documented limits. Private evidence should remain in the authorized evidence store.

Before publishing an example, review filenames, screenshots, paths, URLs, conversation titles, account identifiers, access tokens, and recovered content. A path reference can identify a person even when the file payload is omitted.

This repository includes only generic path aliases and bounded workstation observations. The source-specific reference pages identify documented candidates; the local example identifies which candidates were actually checked.
