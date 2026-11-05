# Acquisition bundles and evidence lineage

A useful acquisition preserves the files and relationships needed to interpret a captured state. A bundle groups those artifacts under one acquisition identifier; it does not assert that every member was captured simultaneously or that the bundle is complete.

The included PowerShell inventory **does not acquire these bundles**. It surveys selected live metadata and writes a report. The recipes below describe requirements for a separately selected acquisition process. No private conversations, images, model contents, or Registry values were acquired to prepare this repository. Reference review date: **2026-11-05**.

## Assign identities before analysis

Create a source acquisition ID, a bundle ID, and an artifact ID for each retained file. Preserve the exact source-to-destination mapping in the private case record; use host, account, volume, and path aliases in public material. An alias identifies context without asserting a person's identity.

Keep three products distinct:

1. **Source acquisition:** the preserved acquisition product, with its method, scope, time range, and limitations.
2. **Analysis copy:** a verified derivative assigned its own ID and linked to the source artifact IDs.
3. **Analytical export:** parsed rows, recovered records, decoded metadata, or rendered previews, with a transformation record and output hashes.

Record whether a hash covers a physical acquisition container, an extracted file, a named stream, or a transformed export. Equal hashes support byte identity of the hashed objects, not completeness, coherent capture, authorship, or successful execution.

## Establish the consistency boundary

Choose and document the consistency mechanism before copying active stores. A sequence of file copies can span multiple application states even when every copy succeeds. Record source activity, acquisition start/end times, included volumes, and any freeze, snapshot, or application coordination.

Windows VSS coordinates requesters, writers, and providers. A successful snapshot operation should not be reported as application-consistent without evidence of the relevant coordination. Preserve snapshot IDs and writer/provider results where available, and identify stores outside the captured volume set. See [Microsoft's VSS description](https://learn.microsoft.com/en-us/windows-server/storage/file-server/volume-shadow-copy-service).

Stopping an application may flush buffers, checkpoint databases, rotate logs, or change history. If quiescing is required by the chosen process, document that intervention and its effects. An offline source also needs a recorded provenance and acquisition time; “offline” alone does not establish a clean shutdown.

## SQLite bundle

For a database named `<database>`, retain the observed members and their relative names:

```text
<database>
<database>-wal
<database>-shm
<database>-journal
```

Record a status for each candidate: captured, absent at the checked path, inaccessible, not applicable, or outside scope. Do not manufacture empty sidecars. A WAL can contain committed state absent from the main file. The SHM file is a WAL index with no persistent database content, but retaining an existing copy preserves capture context. Rollback journals serve a different role. [SQLite's temporary-file documentation](https://www.sqlite.org/tempfiles.html) explains these distinctions.

Keep database and relevant journals from the same captured state. Mixing an earlier database with a later WAL can invalidate interpretation. SQLite specifically documents hazards from copying during transactions and mispairing journals. See its [backup and journal consistency guidance](https://www.sqlite.org/howtocorrupt.html).

If a supported database backup mechanism produces a coherent database snapshot, label it as that product and record its method. The [SQLite Online Backup API](https://www.sqlite.org/backup.html) supplies a database snapshot; it is not a filesystem acquisition of every original journal or historical fragment.

Also preserve separately referenced attachment or blob stores when required for the question. Record unresolved references explicitly. On analysis copies, capture schema, parser/SQLite version, query text, transaction or recovery behavior, and whether results came from current records or recovered fragments. Never silently merge results from incompatible captures.

## LevelDB and browser storage bundle

Acquire the database directory as a set, retaining actual names, relative paths, and directory metadata. Candidates include `CURRENT`, `MANIFEST-*`, numbered `.log` files, table files such as `.ldb`, informational `LOG`/`LOG.old`, and any other files present. Include associated external blob directories identified by that application's storage design.

The original [LevelDB implementation notes](https://raw.githubusercontent.com/google/leveldb/main/doc/impl.md) explain that `CURRENT` identifies a manifest, while logs and tables represent related database state. Selecting only `.ldb` files discards that context. Compaction and recovery can change which files participate in the current view; opening a working store with a normal database library can therefore alter it.

Parse disposable copies with a format-aware tool. Preserve keys, sequence information, deletion markers, origin mapping, and parser warnings where available. Distinguish an active logical value from an older retained fragment. A browser profile, extension origin, and external blob reference must remain connected to their respective records. An inaccessible blob is a limitation, not an empty attachment.

## JSON, JSONL, and agent session bundle

Preserve original bytes, encoding, filename, relative directory, and filesystem metadata before decoding. Group a session index, individual transcript files, task metadata, tool-result files, and referenced attachments when the application uses them. Keep parent/subagent relationships and identifiers rather than flattening all records into one conversation.

A JSONL line can represent an event, a state mutation, or part of another application-specific structure. Validate the recorded application version and schema; see the distinctions in [IDE agent artifacts](ide-agent-artifacts.md). An index can reference a missing file without supplying its contents.

For analysis, retain byte offsets or original line numbers, parsing failures, and any incomplete trailing data. Record decompression, decoding, mutation replay, or reconstruction as transformations with new output IDs. Do not repair an original, reorder lines, or discard malformed fragments without documenting what changed. An imported transcript and a locally recorded session remain different provenance possibilities.

## Registry bundle

Preserve the relevant hive and associated transaction logs from the chosen acquisition product. For user activity, maintain the account association and distinguish `NTUSER.DAT` from `UsrClass.dat`. Record the original hive name, source volume, snapshot provenance, and selected Registry view. Microsoft's [hive documentation](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry-hives) identifies backing files and transaction logs; [Windows artifact references](windows-artifacts.md) map the relevant paths and views.

A text `.reg` export records a different product from a hive acquisition. The [reg export documentation](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/reg-export) describes export of keys, entries, and values. Do not treat that output as preservation of every hive structure or historical record.

Replay or recovery belongs on a derivative. Record the parser version, log files supplied, recovery options, warnings, and before/after hashes. Keep hive key LastWrite, embedded artifact times, and filesystem timestamps separately labeled.

## Image, workflow, and model bundle

Retain the original image or media bytes, embedded metadata, any separate workflow/project file, relevant effective configuration, and application-generated history that links them. Record external input paths, model references, adapters, custom components, and output references. Preserve available referenced files under separate artifact IDs; record missing, remote, or out-of-scope dependencies. Product-specific candidates appear in [image-generation artifacts](image-generation-artifacts.md) and [AI storage](ai-storage.md).

A filename such as `model.safetensors` is insufficient to establish exact weights. Hash acquired model files, record their sizes and container formats, and distinguish them from download manifests or cached aliases. A visual preview is not a replacement for original image bytes or metadata. Redaction, transcoding, resizing, and metadata extraction each produce a separately identified derivative.

Configuration and workflow references describe intended relationships. They do not establish that the specified files were available, that those exact weights were loaded, or that a run completed. Link outcomes to logs, recorded tool results, process evidence, and matching output files as available.

## Complete the manifest and claim record

Use [the evidence manifest template](../templates/evidence-manifest.template.json) to record bundle membership, source and analysis IDs, acquisition method, time semantics, per-file hashes, external references, transformations, and limitations. `null` hashes mean unrecorded, never “verified.” Replace placeholders and add one artifact record per retained file or stream. Keep observed absence separate from failed access.

Use [the claim-evidence template](../templates/claim-evidence.template.json) for each material claim. Supply an exact source locator, analysis-run ID, observation, inferential step, alternatives, contradictory evidence, and unresolved limits. Preserve raw timestamps with their source type, units, epoch, timezone context, and clock uncertainty before adding normalized UTC values. Account aliases identify recorded context; attribution to an operator requires additional support.

Verify analysis-copy hashes against their preserved parents, record all parser versions and parameters, and retain warnings. A complete manifest makes the work reviewable; it does not eliminate limitations in the underlying acquisition.
