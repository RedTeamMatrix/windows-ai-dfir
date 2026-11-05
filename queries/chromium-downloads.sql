-- Run only on an acquired, disposable analysis copy.
-- Verify .schema downloads and .schema downloads_url_chains first.
-- Schema/source reference:
-- https://chromium.googlesource.com/chromium/src/+/main/components/history/core/browser/download_database.cc
-- Keep raw source timestamps; conversion is a separate validated step.

.headers on
.mode csv

SELECT
    id,
    current_path,
    target_path,
    start_time AS start_time_raw,
    end_time AS end_time_raw,
    state,
    received_bytes,
    total_bytes
FROM downloads
ORDER BY start_time DESC
LIMIT 25;

SELECT
    id AS download_id,
    chain_index,
    url
FROM downloads_url_chains
WHERE id IN (
    SELECT id
    FROM downloads
    ORDER BY start_time DESC
    LIMIT 25
)
ORDER BY id, chain_index;
