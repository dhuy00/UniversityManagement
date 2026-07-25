# Data migration guide

This document covers the one-off transition from the archived
Oracle/React branch (`backup-postgres-feature-from-main`) to the current
PostgreSQL implementation.  It assumes the schema scripts (`01_*.sql` to
`14_*.sql`) and seed scripts (`15_*.sql`, `16_*.sql`) have already been
applied.

## 1. Phase the move

The two databases should not run side-by-side for long.  Pick a
maintenance window of ~30 minutes for the cut-over:

1. Freeze writes on the Oracle instance (point API at a read-only
   `Maintenance` page).
2. Export the final snapshot.
3. Run the migration SQL bundle.
4. Cut the API over to PostgreSQL.
5. Verify row counts against the snapshot.

## 2. Export from Oracle

The archived branch produces these canonical join projects.  Produce one
tab-separated file per table:

```sql
SET HEADING OFF
SET PAGESIZE 0
SET LINESIZE 4000
SET TRIMSPOOL ON
SET TRIMOUT ON

-- Reference data
SELECT campus_id || chr(9) || campus_name FROM app_campuses;
SELECT program_id || chr(9) || program_name FROM app_programs;
SELECT major_id   || chr(9) || major_name   FROM app_majors;
SELECT unit_id    || chr(9) || unit_name    FROM app_units;

-- Users + roles
SELECT username || chr(9) || password_hash || chr(9) || is_active
FROM app_users;
SELECT username || chr(9) || role_code FROM app_user_roles;

-- Domain data
SELECT staff_id   || chr(9) || username || chr(9) || full_name FROM app_staff;
SELECT student_id || chr(9) || username || chr(9) || full_name FROM app_students;
```

Save the spool as `oracle-snapshot-<timestamp>.txt`.  This is the
authoritative source for reconciliation — keep it for at least one
quarter.

## 3. Rehash Oracle password hashes

The Oracle branch stored passwords in the legacy Oracle wallet format.
PostgreSQL uses BCrypt.  Build a one-off C# console utility that:

1. Reads `oracle-snapshot-<timestamp>.txt`.
2. For each `app_users` row, generates a BCrypt hash from the captured
   plaintext (or alternatively forces a password reset by emitting a
   strongly-system-generated temporary password and marking the row
   `is_active = false`).
3. Emits a `migration_load.tsv` ready for `\copy`.

The API's `BCryptPasswordVerifier` is the only verifier in the codebase,
so **the legacy Oracle hashes cannot be carried over**.  Either re-hash
the plaintext or reset.

## 4. Load into PostgreSQL

The cleanest loader is a single `\copy` script.  Scaffolding:

```sql
-- Inside psql as a superuser
\copy university.campuses (campus_id, campus_name) FROM 'campus.txt' WITH (FORMAT text, DELIMITER E'\t', NULL '')
\copy university.programs (program_id, program_name) FROM 'program.txt' WITH (FORMAT text, DELIMITER E'\t', NULL '')
\copy university.majors   (major_id,   major_name)   FROM 'major.txt'   WITH (FORMAT text, DELIMITER E'\t', NULL '')
\copy university.units    (unit_id,    unit_name)    FROM 'unit.txt'    WITH (FORMAT text, DELIMITER E'\t', NULL '')

\copy university.app_users (username, password_hash, is_active) FROM 'app_users.txt' WITH (FORMAT text, DELIMITER E'\t', NULL '')
\copy university.app_user_roles (col_key, ...) FROM 'app_user_roles.txt' WITH (FORMAT text, DELIMITER E'\t', NULL '')
```

Adjust the column list to match the snapshot.  The order in the
referenced schema commit is canonical.

## 5. Reconcile

```sql
SELECT
    (SELECT COUNT(*) FROM university.app_users)   AS app_users,
    (SELECT COUNT(*) FROM university.app_user_roles) AS app_user_roles,
    (SELECT COUNT(*) FROM university.staff)       AS staff,
    (SELECT COUNT(*) FROM university.students)    AS students,
    (SELECT COUNT(*) FROM university.courses)     AS courses,
    (SELECT COUNT(*) FROM university.course_plans) AS course_plans,
    (SELECT COUNT(*) FROM university.teaching_assignments) AS teaching_assignments,
    (SELECT COUNT(*) FROM university.enrollments) AS enrollments;
```

Compare each row against the equivalent Oracle query.  Anything other
than `equal` is a tracking bug — resolve before going live.

## 6. Cut over

1. Stop the API.
2. Snapshot the live database (`backup.ps1`).
3. Restart the API against the new connection string.
4. Smoke-test the lookup path (`14_verify_authentication_lookup.sql`).
5. Run the application test suite.

## 7. Decommission

- Mark the Oracle host `RETIRED` in the inventory but keep one read-only
  replica running for a quarter in case reconciliation finds a defect.
- Once decommissioned, move the spool directory to cold storage.
