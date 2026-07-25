# Point-in-time Recovery (PITR) procedure

This procedure rebuilds the `university` PostgreSQL instance up to a chosen
timestamp using a `pg_basebackup` snapshot plus the WAL archive emitted by
`postgresql.wal.conf`.  It depends on the following assumptions:

- A healthy base backup (see "Base backup" below).
- WAL archive directory mounted at `/var/lib/postgresql/wal-archive` inside
  the postgres container (or the equivalent path on a physical host).
- A target recovery timestamp **strictly later** than the base-backup
  start time, **strictly earlier** than the moment of disaster.

The whole PITR workflow runs inside the container, so the operator needs
the `docker` CLI and access to the WAL archive directory on the host.

## 1. Prepare

```powershell
# Stop the application — no traffic against the database during recovery.
docker compose -f script/docker-compose.postgres.yml stop university-postgres || true

# Make space for the recovered cluster.
docker run --rm -v postgres-data:/from -v postgres-recovery:/to `
    alpine:3.19 sh -c "rm -rf /to/* && cp -a /from/. /to/"
```

The latter command leaves the corrupted cluster at `/from`.  Don't delete it
until the recovery is verified.

## 2. Take a base backup (skip when restoring an existing backup)

```powershell
docker exec -e PGPASSWORD=123 -u postgres university-postgres pg_basebackup `
    -D /var/lib/postgresql/backup `
    -Ft -z -Xs -P `
    --checkpoint=fast
```

Compress and copy the produced tarballs off the container:

```powershell
docker cp university-postgres:/var/lib/postgresql/backup ./base-<timestamp>
```

Store `./base-<timestamp>` alongside the WAL archive at the same path that
`postgresql.wal.conf` references.  Without those tarballs the PITR step
below cannot reconstruct the cluster.

## 3. Configure the recovery

Create `/var/lib/postgresql/recovery.signal` inside the container to declare
that the next start is a recovery run:

```powershell
docker exec -u postgres university-postgres touch /var/lib/postgresql/recovery.signal
```

Append the recovery target to `postgresql.auto.conf` so the cluster knows
*when* to stop:

```powershell
docker exec -u postgres university-postgres psql -d postgres -c "
    ALTER SYSTEM SET recovery_target_time = '2026-07-25 12:30:00+00';
    ALTER SYSTEM SET recovery_target_action = 'promote';
    ALTER SYSTEM SET restore_command = 'cp /var/lib/postgresql/wal-archive/%f %p';
"
```

The timestamps above are illustrative.  Use the actual moment you want to
restore to, expressed in UTC and careful to pick a point in time that you
know is *before* the corruption/data-loss event.

## 4. Start the recovery

```powershell
docker start university-postgres
```

Watch the logs:

```powershell
docker logs -f university-postgres
```

You should see PostgreSQL replay WAL until it reaches the configured
`recovery_target_time`, then `promote` the server and tear down WAL
reception.  When the log line
`database system is ready to accept connections` appears, the database is
live and writable.

## 5. Verify

```powershell
docker exec -e PGPASSWORD=123 -u postgres university-postgres psql `
    -d university_management -c "
        SELECT COUNT(*) AS app_users FROM university.app_users;
        SELECT now() - ts AS recovery_lag FROM (
            SELECT max(created_at) AS ts FROM university.notifications
        ) x;
    "
```

If `recovery_lag` reports a sensible value relative to your target
timestamp and the row counts match what you expect at that moment, the
recovery succeeded.

## 6. Cut over

- Re-point the API (`ConnectionStrings:PostgreSQL`) to the recovered
  container.
- Run `script/postgres/14_verify_authentication_lookup.sql` to make sure
  the restricted API role still resolves users correctly.
- After observation, delete `postgres-recovery` if no further recovery
  is needed.

## 7. Repeat backups routinely

- Cron `backup.ps1` hourly: produce a logical dump for ad-hoc restoration.
- Daily `pg_basebackup` plus WAL retention: enable PITR back at least
  seven days for a typical university workload.
- Once a quarter, validate the procedure by performing a deliberate
  PITR into a scratch cluster.
