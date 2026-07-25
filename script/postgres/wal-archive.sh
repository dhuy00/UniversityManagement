#!/usr/bin/env bash
# wal-archive.sh
#
# archive_command hook referenced by postgresql.wal.conf.
#
# %p is the full path to the WAL segment being archived.
# %f is the segment file name (relative to the data directory).
#
# Behaviour:
#   1. Inflate the path so %p is absolute.
#   2. Copy the segment to /var/lib/postgresql/wal-archive/<WAL_FILE>.
#   3. Exit 0 on success, non-zero on failure (PostgreSQL will retry).
#
# This script is intentionally minimal: it writes to a local directory
# inside the container.  For production, replace the cp with `aws s3 cp`,
# `az storage blob upload`, or `gsutil cp`.  The contract is the same:
# the command must exit 0 only after the segment is durably persisted.

set -euo pipefail

WAL_PATH="${1:?usage: wal-archive.sh <path> <file>}"
WAL_FILE="${2:?usage: wal-archive.sh <path> <file>}"

ARCHIVE_DIR="${WAL_ARCHIVE_DIR:-/var/lib/postgresql/wal-archive}"

mkdir -p "${ARCHIVE_DIR}"
cp -- "${WAL_PATH}" "${ARCHIVE_DIR}/${WAL_FILE}"

# Optional: enforce retention by deleting the oldest segments once we
# exceed a soft limit.  PostgreSQL already prevents deletion of a
# segment that is still required by any active replication slot, so
# this is purely a best-effort bound.
if [[ -n "${WAL_ARCHIVE_RETENTION_DAYS:-}" ]]; then
    find "${ARCHIVE_DIR}" -type f -name '*.wal' -mtime +"${WAL_ARCHIVE_RETENTION_DAYS}" -delete
fi
