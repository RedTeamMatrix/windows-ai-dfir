# Bounded static model-header inspection

This chapter supplies a small, reproducible extraction example. It is a tested repository utility, not a validated forensic model-identification system.

## What the reader does

`scripts/read_safetensors_header.py` reads the length-prefixed JSON header of a regular, non-symlink analysis file. It does not import an ML framework, instantiate tensors, load a model, or perform inference.

The Safetensors specification defines an eight-byte little-endian header length, a JSON header containing tensor descriptions, and an optional `__metadata__` string map. [Original format specification](https://github.com/safetensors/safetensors#format).

The reader:

- Caps the declared header before allocating/reading it: 1 MiB by default, with a hard 16 MiB ceiling.
- Rejects truncated prefixes/headers, duplicate JSON keys, invalid UTF-8, and non-finite JSON constants.
- Checks metadata types, basic tensor-entry structure, shape limits, and offset bounds.
- Emits raw metadata as JSON data, with control characters escaped.
- Optionally hashes the complete analysis file using streaming SHA-256.
- Refuses an existing output destination, including the input itself.
- Reports its own version and its limited inspection scope.

It does **not** validate dtype semantics, tensor shape-to-byte consistency, overlapping ranges, every format requirement, model architecture, training provenance, or file-content classification. A successful inspection establishes only the reported header checks.

## Run the benign fixture

From the repository root, using Python 3.10 or newer:

```powershell
python -B scripts/read_safetensors_header.py examples/fixtures/benign-toy.safetensors --hash-file
```

The fixture contains one two-element floating-point tensor represented by eight zero bytes and a benign metadata marker. It is not an operational generative model. Its expected extraction is checked in beside it:

```text
examples/fixtures/benign-toy.safetensors
examples/fixtures/benign-toy.expected.json
```

The expected JSON contains measured hashes of this generated teaching fixture. Those hashes are unrelated to the fictional placeholders in the worked cases.

To create a new extraction report on an acquired analysis copy:

```powershell
python -B scripts/read_safetensors_header.py E:/analysis/model-copy.safetensors --hash-file --output E:/analysis/model-header-new.json
```

The output parent must already exist. `--hash-file` reads the whole file and can take time for large files. Without it, `sha256` is null; `header_sha256` always refers only to the bytes of the extracted header.

## Interpret the output narrowly

| Field | Meaning |
|---|---|
| `input_name` | Basename of the supplied analysis file; not a source acquisition identifier |
| `file_bytes` | Size observed through the opened handle |
| `header_bytes` | Declared header length after configured bounds checks |
| `header_sha256` | Hash of the exact header bytes read |
| `sha256` | Complete-file hash only when explicitly requested |
| `metadata` | Untrusted string map supplied by the file |
| `tensors` | Reported names, dtype labels, shapes, and offset pairs after basic checks |
| `inspection_level` | Explicit description of the checks performed |

Metadata can name a base model, training run, input path, or software package without authenticating those claims. Keep source assertions separate from conclusions supported by manifests, application records, and process/file evidence.

Do not execute text recovered from metadata, prompts, tool results, or workflow fields. If an AI assistant helps interpret an export, provide the export as untrusted evidence and preserve the original extraction independently.

## Tests and limits

Run:

```powershell
python -B -m unittest discover -s tests -p "test_*.py" -v
```

The tests use temporary synthetic files. They cover valid extraction, optional hashing, truncated/oversized headers, duplicate keys, invalid UTF-8, invalid metadata, bad ranges/shapes, non-finite values, output refusal, and input preservation.

The source and output are analysis artifacts. The before/after size and mtime check can detect some concurrent changes but does not establish a coherent acquisition or protect against every adversarial race. Preserve acquired evidence through the workflow in [Acquisition bundles](acquisition-bundles.md).

No recovered model from the example workstation was parsed. Application-specific lab captures remain separate work, tracked in the [lab validation plan](lab-validation-plan.md).
