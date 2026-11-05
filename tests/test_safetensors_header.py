"""Synthetic malformed-input and no-overwrite tests. No real models required."""

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "read_safetensors_header.py"
SPEC = importlib.util.spec_from_file_location("header_reader", SCRIPT)
READER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(READER)


class HeaderTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.path = self.root / "toy.safetensors"

    def tearDown(self):
        self.temporary.cleanup()

    def write(self, header=None, raw=None, data=b"\0" * 8):
        if raw is None:
            if header is None:
                header = {
                    "__metadata__": {"purpose": "benign static-inspection fixture"},
                    "toy": {"dtype": "F32", "shape": [2], "data_offsets": [0, 8]},
                }
            raw = json.dumps(header, separators=(",", ":")).encode("utf-8")
        self.path.write_bytes(struct.pack("<Q", len(raw)) + raw + data)

    def test_valid_metadata_and_full_hash(self):
        self.write()
        result = READER.inspect_header(self.path, hash_file=True)
        self.assertEqual(result["data_bytes"], 8)
        self.assertEqual(len(result["sha256"]), 64)
        self.assertEqual(result["tensors"][0]["name"], "toy")

    def test_published_fixture_matches_expected_extraction(self):
        fixtures = Path(__file__).resolve().parents[1] / "examples" / "fixtures"
        expected = json.loads((fixtures / "benign-toy.expected.json").read_text(encoding="utf-8"))
        actual = READER.inspect_header(fixtures / "benign-toy.safetensors", hash_file=True)
        self.assertEqual(actual, expected)

    def test_hash_is_optional(self):
        self.write()
        self.assertIsNone(READER.inspect_header(self.path)["sha256"])

    def test_truncated_prefix(self):
        self.path.write_bytes(b"tiny")
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_oversized_header_rejected_before_read(self):
        self.path.write_bytes(struct.pack("<Q", 2**63))
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_truncated_header(self):
        self.path.write_bytes(struct.pack("<Q", 100) + b"{}")
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_duplicate_keys(self):
        self.write(raw=b'{"__metadata__":{},"__metadata__":{}}')
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_bad_utf8(self):
        self.write(raw=b'{"bad":"\xff"}')
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_nonstr_metadata(self):
        self.write(header={"__metadata__": {"value": 7}})
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_range_outside_file(self):
        self.write(header={"toy": {"dtype": "F32", "shape": [2], "data_offsets": [0, 99]}})
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_boolean_offset(self):
        self.write(header={"toy": {"dtype": "F32", "shape": [2], "data_offsets": [False, 8]}})
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_invalid_shape(self):
        self.write(header={"toy": {"dtype": "F32", "shape": [-1], "data_offsets": [0, 8]}})
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_nonfinite_json(self):
        self.write(raw=b'{"bad":NaN}')
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path)

    def test_header_limit(self):
        self.write()
        with self.assertRaises(READER.HeaderError):
            READER.inspect_header(self.path, max_header_bytes=1)

    def test_existing_output_and_input_unchanged(self):
        self.write()
        original = self.path.read_bytes()
        output = self.root / "existing.json"
        output.write_bytes(b"sentinel")
        with contextlib.redirect_stderr(io.StringIO()):
            status = READER.main([str(self.path), "--output", str(output)])
        self.assertEqual(status, 2)
        self.assertEqual(output.read_bytes(), b"sentinel")
        self.assertEqual(self.path.read_bytes(), original)

    def test_input_cannot_be_output(self):
        self.write()
        original = self.path.read_bytes()
        with contextlib.redirect_stderr(io.StringIO()):
            status = READER.main([str(self.path), "--output", str(self.path)])
        self.assertEqual(status, 2)
        self.assertEqual(self.path.read_bytes(), original)

    def test_new_output(self):
        self.write()
        output = self.root / "new.json"
        self.assertEqual(READER.main([str(self.path), "--output", str(output)]), 0)
        self.assertEqual(json.loads(output.read_text())["tool_version"], "1.0.0")


if __name__ == "__main__":
    unittest.main()
