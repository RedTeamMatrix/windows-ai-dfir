# Media provenance, remote actions, and transfer evidence

This chapter adds an analytical workflow around the artifact paths. It contains no additional findings from the example workstation. Use benign lab material for the exercises in the [worked cases](worked-cases.md).

## Record relationships between representations

An original image, edited project, re-encoded export, thumbnail, and video frame are different objects. Give each acquired object its own identifier and hash, then record the proposed relationship:

| Relationship | Evidence needed |
|---|---|
| Byte-identical copy | Matching complete-file hashes and documented acquisition context |
| Format conversion or re-encoding | Source/output records, export settings where retained, and contextual comparison |
| Edited derivative | Project/edit history, application records, source references, and acquired output |
| Thumbnail or preview | Cache/database association and separate preview identity |
| Extracted video frame | Source video hash, extraction method/version, stream and frame/time reference |
| Imported gallery item | Import/application record and source-file context |

A similarity result can identify a candidate relationship without establishing byte identity, authorship, or event order. Preserve its algorithm/version and parameters separately from the content hashes.

For video, retain container and stream metadata, duration/timebase, relevant presentation timestamps, audio context where within scope, and the extraction process. A frame number alone can be ambiguous after transcoding or variable-frame-rate handling. Document the decoder and the source-to-frame mapping.

## Preserve raw metadata and normalized interpretations

Keep an unchanged metadata extraction alongside a normalized report. Record the tool/version, invocation or configuration, source hash, extraction time, field name, original value, normalized value, and interpretation rule.

Separate:

- Filesystem timestamps from embedded media timestamps.
- Claimed generation settings from independently observed execution.
- A file's current encoding from its historical processing chain.
- Application account identifiers from operating-system identities.
- Asserted metadata relationships from cryptographically validated records.

Retain conflicting or missing information. Do not fill gaps with an assumed default timezone or an inferred generation date merely because the filename resembles a timestamp.

## Content Credentials and C2PA

Where a media file contains Content Credentials, record the manifest, claims/assertions, ingredient relationships, content bindings, signing credentials, validator version, trust configuration, and validation results.

C2PA defines validation steps for signatures, assertions, timestamps, and content bindings. Record which checks passed, failed, or could not be performed. A valid binding/signature answers a different question from whether every statement about an event is factually correct. [C2PA technical specification, version 2.5](https://spec.c2pa.org/specifications/specifications/2.5/specs/C2PA_Specification.html).

Credentials may be unavailable or an examined representation may differ from the signed asset. Explain the observed condition without classifying all unsigned media as fabricated or all signed media as an independently verified account of events. Preserve external/ingredient references as leads; accessing remote resources is a separate collection action.

## Trace remote actions through both sides

For a Windows editor controlling a WSL/container process or remote tool server, create a host/path map before joining records:

```text
client workspace URI
client account/session and harness run ID
runtime host/account and working directory
mount or path translation
tool request/call ID
server process/action ID
server-side output path and file identity
client-side returned reference or copied file identity
clock offset model, uncertainty, and raw source times
```

A local request can exist even if the remote action failed. A remote success response can exist even if the client never received the output. Preserve both directions and distinguish requested, accepted, executed, persisted, returned, and transferred states.

Where a join uses only timing or a basename, state that weakness. A stable request ID plus independent server records can support a different level of correlation.

## Establish what a transfer record supports

Examine source-side, application/service, and destination-side evidence where available and within scope.

| Observation | Supported conclusion | Remaining question |
|---|---|---|
| A path appears in a file-selection record | A candidate selection/reference was retained | Was it submitted? |
| An upload request was recorded | A transfer was attempted or requested | Was it accepted and completed? |
| A service returned an object/message identifier | The service reported an object/action | Which bytes and destination account did it represent? |
| A destination copy was acquired | A candidate destination object exists | Does it match the source or a transformed derivative? |
| Complete-file hashes match | The acquired objects are byte-identical | Who initiated the transfer and when? |

If the service transcodes, resizes, encrypts, wraps, or otherwise transforms the data, distinguish object identity from file-byte identity. Preserve identifiers, completion/error states, retry history, relevant account context, and the original service export.

For cloud evidence, document acquisition scope, method, timestamps, returned identifiers, integrity checks, and gaps. Provider exports and locally cached records are different acquisition products. Consult [SWGDE cloud-evidence guidance, 23-F-004-1.1](https://www.swgde.org/documents/published-complete-listing/23-f-004-best-practices-for-digital-evidence-acquisition-preservation-and-analysis-from-cloud-service-providers/) for the current referenced document.

## Preserve what the examiner did

Record analysis-generated previews, frame extractions, exports, parser databases, and normalized timelines as derivatives, each linked back to its source. Keep tool-generated timestamps separate from historic evidence timestamps.

The [evidence manifest template](../templates/evidence-manifest.template.json) and [claim/evidence template](../templates/claim-evidence.template.json) provide fields for these relationships. The [worked cases](worked-cases.md) demonstrate fictional joins and explicitly unresolved edges; they are not captures of real application activity.
