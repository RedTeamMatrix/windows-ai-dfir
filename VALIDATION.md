# Validation record

Checked November 5, 2026.

## Inventory helper

The shipped helper was checked with Windows PowerShell **5.1.26100.9711** and PowerShell **7.6.9**.

The expanded **1.1.0** candidate list was retested in both runtimes. The initial example JSON remained unchanged; the added snapshot is `examples/expanded-workstation-metadata.json`.

- PowerShell parser accepted the script.
- Default stdout and new-file output modes produced valid JSON.
- Existing output files were refused and test sentinel bytes remained unchanged.
- Synthetic nested access-denied, security, item-not-found, file-not-found, and directory-not-found exceptions received the intended classifications.
- Unknown failures remained errors; nested access-denied took precedence over an outer not-found exception.
- Outputs excluded the actual profile path, username, and SID pattern checked.
- The existing example JSON remained unchanged during regression checks.

Tests used scratch output files and metadata-only inventory calls. They did not parse private evidence payloads.

## Documentation and query checks

- Relative Markdown file links and local heading anchors resolve.
- Example JSON files parse.
- Publication wording and local-identifier checks passed.
- Expanded local claims were checked against the separate 1.1.0 metadata snapshot.
- CLI-agent, IDE-agent, image-tool, and harness chapters received independent factual/privacy review.
- The two Chromium SQL queries executed against a benign, in-memory synthetic schema.

The SQL check validates syntax and the demonstrated query behavior. It does not establish compatibility with every Chromium version; inspect the captured schema first.

## Revision 1.2.0 static inspection and teaching fixtures

The new Python header reader was exercised against synthetic valid and malformed files without loading an ML framework or running inference. Seventeen tests cover extraction, hashing, a checked-in expected result, length limits, truncated/invalid JSON input, metadata/range/shape checks, existing-output refusal, and input preservation.

The checked-in 168-byte toy tensor fixture has a measured full-file hash and expected extraction. It is a benign format fixture, not a captured application session or a generative model.

The two worked cases use fictional analytical records and null hash placeholders. Their timestamps, identities, and clock models are explanatory assumptions. No actual cross-host action or media transfer was performed to create those cases.

Application-level tests are specified in the [lab validation plan](docs/lab-validation-plan.md). Their status remains pending until an exact-version benign capture and expected-result comparison are completed.

## Limits

No forensic image, memory capture, raw-volume acquisition, browser-record analysis, conversation analysis, or event-content analysis was performed. Application schemas and storage locations can change. The example is a live metadata survey with the limitations recorded in its JSON and accompanying documentation.
