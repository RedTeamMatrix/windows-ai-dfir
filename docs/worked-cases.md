# Worked cases: synthetic evidence correlation

**Both cases are entirely synthetic.** They were not captured on the example workstation, run through the named applications, or validated against vendor event schemas. The accompanying [JSON fixture](../examples/worked-cases.synthetic.json) uses a repository-defined analytical envelope. Its event IDs are fictional labels, not Windows Event IDs. No service was contacted and no media or CSV payload was acquired.

These exercises demonstrate how to separate a request, a reported result, a filesystem observation, a content-identity finding, and operator attribution. They intentionally leave some edges unresolved. The goal is to complete the reasoning, including its limits, rather than turn every adjacent record into a proven relationship.

Use the [collection workflow](collection-and-analysis.md), [coding-agent references](coding-cli-artifacts.md), [harness map](agent-harnesses.md), and [image-artifact reference](image-generation-artifacts.md) for the underlying acquisition questions. The [lab plan](lab-validation-plan.md) describes the ground-truth work still needed.

## Common clock and identity assumptions

All identities are fictional LAB accounts or runtimes. An application account is not a person. Clock offsets are stipulated teaching values, not measurements from this computer:

| Clock | Runtime scope | Recorded wall clock minus reference UTC |
| --- | --- | --- |
| `CLOCK-A` | `HOST-A`, `WSL-A`, `CONTAINER-A` | +90 seconds |
| `CLOCK-B` | Remote MCP service on `HOST-B` | -30 seconds |
| `CLOCK-C` | Test-transfer service on `HOST-C` | -120 seconds |

Interpret the raw timestamp's timezone first, then subtract the stated clock offset. Thus `2026-10-01T11:01:30-04:00` represents wall-clock UTC `15:01:30Z`; applying `CLOCK-A` gives normalized `15:00:00Z`. A `HOST-B` record at `14:59:38Z` normalizes to `15:00:08Z`. Raw values remain in the fixture alongside normalized values.

The fixture assumes constant offsets during each interval and supplies no measured uncertainty. A real report must establish its correction basis, preserve raw values, record uncertainty and drift, and avoid resolving near-simultaneous events more precisely than the evidence permits. Ensure the JSON reader preserves raw timestamp strings and explicit offsets instead of silently converting them to local wall time. Shared clock treatment for the WSL/container runtimes is an explicit scenario assumption, not a universal rule.

Every artifact's `sha256` is **null**. No invented hash, size, or visual comparison stands in for an acquired-byte measurement.

## Case 1: editor → WSL/container → remote MCP → CSV → copy

An editor session requests a benign CSV summary. A tool record dispatches a harness through WSL. Fictional runtime inspection maps `C:\LAB\case01` to `/mnt/c/LAB/case01`, then to `/workspace` in a container. The harness calls a remote MCP service. Its first request fails; a retry receives a reported CSV response. A local process writes a candidate report and a subsequent copy operation creates a review destination.

| Fixture records | Normalized UTC | Observation |
| --- | --- | --- |
| `C01-01`–`C01-03` | 15:00:00–15:00:02 | Editor request, WSL dispatch, and container/runtime mapping |
| `C01-04`–`C01-05` | 15:00:03–15:00:04 | Request `LAB-MCP-R0` fails with no output recorded |
| `C01-06`–`C01-09` | 15:00:06–15:00:09 | Retry `LAB-MCP-R1` links client request, service receipt/result, and client result |
| `C01-10` | 15:00:10 | Process instance `LAB-PROC-C1` has a reported write to `/workspace/outputs/report.csv` |
| `C01-11` | 15:00:15 | The editor records interaction with the Windows output alias |
| `C01-12`–`C01-13` | 15:00:20–15:00:21 | A local copy request reports success and a review destination appears |

The output has three candidate path representations:

```text
C:\LAB\case01\outputs\report.csv
/mnt/c/LAB/case01/outputs/report.csv
/workspace/outputs/report.csv
```

The fictional mount inspection supports the configured/runtime path relationship. It does not establish file content, generation origin, or who controlled the process. The review copy is `C:\LAB\review\case01-report.csv`, a separate candidate artifact.

### Supported findings and missing links

Within the scenario assumptions, records link the editor session to a dispatched runtime and distinguish the failed request from the retry. The shared request ID links client and remote service assertions; it also prevents a successful retry from being attributed to the earlier failure. Process-associated write context is stronger than a filename alone.

Two content links remain open: whether the local report contains the service response bytes, and whether the review copy is byte-identical to the local report. Both require acquired content and appropriate comparisons. A process can transform a returned result before writing it; reported copy success is not a measured hash comparison.

The following conclusions are unsupported:

- The remote service's reported CSV was generated on `HOST-A`.
- The person behind the editor account read or understood the entire report.
- The local review copy was an external transfer.
- Matching names or adjacent timestamps establish identical bytes.

A defensible narrative is: “A recorded editor session dispatched the candidate container runtime. A retry has linked client and service success reports, followed by a process-associated output write and a reported local copy. Response-to-file and source-to-copy byte identity remain unverified.”

## Case 2: benign source → claimed generation → edit → preview → test transfer

This scenario begins with a benign green-square image reference. A fictional image-app record queues an operation and reports generation success to `result.png`; a filesystem/gallery observation follows. An editor then reports a JPEG export and the application reports a derived preview. A transfer to a LAB-controlled recipient fails once, then has linked client completion and service stored-object records.

| Fixture records | Normalized UTC | Observation |
| --- | --- | --- |
| `C02-01`–`C02-04` | 15:10:00–15:10:04 | Source reference, requested operation, claimed completion, candidate output/gallery entry |
| `C02-05`–`C02-06` | 15:10:10–15:10:11 | Editor interaction and reported JPEG export/write |
| `C02-07` | 15:10:12 | Application reports a preview derived from the edited path |
| `C02-08`–`C02-09` | 15:10:15–15:10:16 | Initial test transfer fails without a completion receipt |
| `C02-10`–`C02-12` | 15:10:18–15:10:21 | Retry links a client request to a stored-object receipt and client completion |

The candidate chain is:

```text
C:\LAB\case02\input\green-square.png
  -> C:\LAB\case02\output\result.png
  -> C:\LAB\case02\edited\result-review.jpg
  -> C:\LAB\case02\cache\preview.jpg

Edited JPEG -> lab://HOST-C/test-objects/LAB-OBJECT-2
```

Arrows represent claims to evaluate, not verified byte identity. The `lab://` address is a fictional identifier, not a live endpoint.

### Generation and import can leave overlapping observations

The application reports generation, but no acquired output hash or independently validated job schema connects that claim to a particular file. A received/imported image carrying copied parameters can produce an equivalent filename/gallery observation. The candidate generation edge therefore remains `generation_reported_origin_unresolved`.

The JPEG and preview are separate representations. Their reported derivation needs acquired media, editor/project context where available, and an appropriate comparison. Re-encoding can alter metadata and byte identity. The exercise makes no claim that a particular field survived or disappeared. A preview cannot establish the full original's bytes or every detail it contained.

### Transfer completion and content identity are different findings

`LAB-UPLOAD-U0` has a failure record. It must not be folded into the successful retry `LAB-UPLOAD-U1`. The retry's matching transfer/object identifiers support linked client and service reports of storage. They do not establish that the remote object contains the same exact JPEG bytes, that a recipient opened it, or that it moved farther.

A defensible narrative is: “The application reported an image operation and a candidate output/gallery entry exists. Local generation remains unresolved. Subsequent records report an edit, preview, and completed LAB test transfer; derivative relationships and exact transmitted bytes require content verification.”

## Turn the exercise into an evidence-backed case

Preserve each acquired source and its provenance before extracting records. Keep original timestamps, conversion assumptions, identifiers, and negative results. Record parser/version decisions and map each claimed edge to its actual supporting records. Upgrade a content-identity or provenance finding only when the missing evidence has been acquired and evaluated. Do not replace null hashes in this fixture with plausible-looking values.

The cases remain synthetic after their JSON and arithmetic checks pass. Only a separately documented, exact-version benign lab capture can validate real software paths, formats, retention, and behavior.
