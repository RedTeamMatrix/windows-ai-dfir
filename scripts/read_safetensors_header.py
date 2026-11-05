"""Bounded static header inspection. Does not load tensors or run inference."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import struct
import sys

VERSION = "1.0.0"
DEFAULT_MAX_HEADER = 1024 * 1024
ABSOLUTE_MAX_HEADER = 16 * 1024 * 1024
MAX_ENTRIES = 4096
MAX_SHAPE_DIMENSIONS = 64


class HeaderError(ValueError):
    pass


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise HeaderError("duplicate JSON key")
        result[key] = value
    return result


def reject_constant(value):
    raise HeaderError("non-finite JSON constant")


def integer(value):
    return isinstance(value, int) and not isinstance(value, bool)


def inspect_header(path, max_header_bytes=DEFAULT_MAX_HEADER, hash_file=False):
    if not integer(max_header_bytes) or not 1 <= max_header_bytes <= ABSOLUTE_MAX_HEADER:
        raise HeaderError("header limit outside supported bounds")
    path = Path(path)
    if path.is_symlink() or not stat.S_ISREG(path.stat().st_mode):
        raise HeaderError("input must be a regular non-symlink analysis file")
    with path.open("rb") as stream:
        before = os.fstat(stream.fileno())
        if not stat.S_ISREG(before.st_mode):
            raise HeaderError("input is not a regular file")
        prefix = stream.read(8)
        if len(prefix) != 8:
            raise HeaderError("truncated header-length prefix")
        header_length = struct.unpack("<Q", prefix)[0]
        if header_length == 0 or header_length > max_header_bytes:
            raise HeaderError("declared header exceeds configured limit or is empty")
        if header_length > before.st_size - 8:
            raise HeaderError("declared header exceeds available bytes")
        raw = stream.read(header_length)
        if len(raw) != header_length or not raw.startswith(b"{"):
            raise HeaderError("invalid or truncated JSON header")
        try:
            header = json.loads(
                raw.decode("utf-8"),
                object_pairs_hook=unique_object,
                parse_constant=reject_constant,
            )
        except (UnicodeError, json.JSONDecodeError, RecursionError, ValueError) as error:
            raise HeaderError("invalid JSON header") from error
        if not isinstance(header, dict) or len(header) > MAX_ENTRIES:
            raise HeaderError("invalid root or too many header entries")
        metadata = header.get("__metadata__", {})
        if not isinstance(metadata, dict) or not all(
            isinstance(key, str) and isinstance(value, str)
            for key, value in metadata.items()
        ):
            raise HeaderError("metadata must be a string-to-string object")
        data_bytes = before.st_size - 8 - header_length
        tensors = []
        for name, entry in header.items():
            if name == "__metadata__":
                continue
            if not isinstance(entry, dict):
                raise HeaderError("tensor entry must be an object")
            dtype = entry.get("dtype")
            shape = entry.get("shape")
            offsets = entry.get("data_offsets")
            if not isinstance(dtype, str) or not dtype or len(dtype) > 64:
                raise HeaderError("invalid dtype label")
            if not isinstance(shape, list) or len(shape) > MAX_SHAPE_DIMENSIONS:
                raise HeaderError("invalid or excessive shape")
            if not all(integer(dimension) and 0 <= dimension <= 2**63 - 1 for dimension in shape):
                raise HeaderError("invalid shape dimension")
            if not isinstance(offsets, list) or len(offsets) != 2:
                raise HeaderError("invalid data-offset pair")
            if not all(integer(offset) for offset in offsets):
                raise HeaderError("offsets must be integers")
            begin, end = offsets
            if not 0 <= begin <= end <= data_bytes:
                raise HeaderError("tensor range outside available data")
            tensors.append({"name": name, "dtype": dtype, "shape": shape, "data_offsets": offsets})
        digest = None
        if hash_file:
            hasher = hashlib.sha256()
            stream.seek(0)
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                hasher.update(block)
            digest = hasher.hexdigest()
        after = os.fstat(stream.fileno())
        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
            raise HeaderError("input changed during inspection")
    return {
        "schema_version": "1.0",
        "tool": "read_safetensors_header",
        "tool_version": VERSION,
        "input_name": path.name,
        "file_bytes": before.st_size,
        "sha256": digest,
        "header_bytes": header_length,
        "header_sha256": hashlib.sha256(raw).hexdigest(),
        "data_bytes": data_bytes,
        "metadata": metadata,
        "tensors": tensors,
        "inspection_level": "bounded_header_structure_and_range_bounds",
        "limits": [
            "No tensor loading, model execution, inference, or content classification.",
            "Metadata is untrusted file content, not an authenticated assertion.",
            "Dtype semantics, shape-to-byte consistency, overlaps, and full format conformance are not validated.",
            "A before/after stat check is not a coherent acquisition guarantee.",
            "No full-file hash was computed unless sha256 is populated.",
        ],
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("--output", type=Path, help="new JSON destination; existing files are refused")
    parser.add_argument("--max-header-bytes", type=int, default=DEFAULT_MAX_HEADER)
    parser.add_argument("--hash-file", action="store_true", help="stream the entire analysis file for SHA-256")
    args = parser.parse_args(argv)
    try:
        result = inspect_header(args.input, args.max_header_bytes, args.hash_file)
        payload = json.dumps(result, indent=2, ensure_ascii=True) + "\n"
        if args.output:
            with args.output.open("x", encoding="utf-8") as destination:
                destination.write(payload)
        else:
            sys.stdout.write(payload)
        return 0
    except (OSError, HeaderError) as error:
        # Do not include payload strings, private paths, or exception tracebacks.
        label = str(error) if isinstance(error, HeaderError) else type(error).__name__
        sys.stderr.write("inspection failed: " + label + "\n")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
