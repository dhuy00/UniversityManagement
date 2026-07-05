# Oracle SQL Installation

## Quick start

Use Oracle SQL Developer **Run Script (F5)**. Do not use Run Statement
(`Ctrl+Enter`) for runner files.

The installation requires three runner executions because Oracle administration
and application ownership must remain separate.

### 1. Bootstrap as SYS

Connect:

```text
User: SYS
Role: SYSDBA
Service: XEPDB1
```

Run:

```text
runners/01_sys_bootstrap.sql
```

Save the generated password shown in Script Output:

- `UNIVERSITY_APP`

The local demo-user password is fixed to:

```text
123
```

### 2. Install as application owner

Reconnect:

```text
User: UNIVERSITY_APP
Service: XEPDB1
```

Run:

```text
runners/02_app_install.sql
```

Warning: this runner drops and recreates application tables.

For an existing installation that must keep its data, connect as
`UNIVERSITY_APP` and run only:

```text
16_enable_domain_workflows.sql
```

Then reconnect as `SYS AS SYSDBA` and rerun:

```text
12b_create_context_and_logon_trigger.sql
```

This creates the trusted context used by the atomic create-unit-and-assign-head
workflow. Reconnect all demo-user sessions afterward.

To provision Oracle accounts for all existing `STAFF` and `STUDENTS` rows,
reconnect as `SYS AS SYSDBA` and run:

```text
12d_provision_all_data_users.sql
```

### 3. Finalize as SYS

Reconnect as `SYS AS SYSDBA` to `XEPDB1`.

Run:

```text
runners/03_sys_finalize.sql
```

Runner 3 creates or updates an Oracle account for every seeded staff member and
student, grants the role matching their application identity, and sets the
local-demo password to `123`. It then activates the secure context and database
logon trigger. Provisioning thousands of local users can take some time.

Reconnect data users before verification.

## Verification

For each staff account, connect as that user and run:

```text
runners/90_verify_staff_user.sql
```

Recommended accounts:

```text
BASIC01
LECTURER01
AFFAIRS01
HEAD_IS01
DEAN01
```

For each student account, connect as that user and run:

```text
runners/91_verify_student_user.sql
```

Accounts:

```text
STUDENT01
STUDENT02
```

All verification DML uses savepoints and rollback.

## Why three installation runners are required

`SYS` is required to:

- Create Oracle users and roles.
- Grant `SYS.DBMS_RLS`.
- Create the secure application context.
- Create the database logon trigger.

`UNIVERSITY_APP` is required to:

- Own tables, packages, triggers, and policies.
- Grant privileges on its own objects.
- Prevent application objects and data from being owned by `SYS`.

A single SQL connection cannot safely represent both responsibilities. Do not
grant broad SYS privileges to `UNIVERSITY_APP` to avoid switching connections.

## Directory layout

```text
script/sql/
├── runners/       Installation and verification entry points
├── legacy/        Original generic admin-console procedures
├── 00-06          Schema, reference data, and bulk data
├── 10-15          RBAC, secure context, CS#1-CS#5
├── 20-23          CS#6 VPD
└── 30a-30c        OLS preparation (currently deferred)
```

## Optional one-time cleanup

If application tables were accidentally created in `SYS`, run the following
once as `SYS` in `XEPDB1`:

```text
00_cleanup_misplaced_sys_objects.sql
```

Do not include this destructive cleanup in normal installation.

## OLS status

Oracle Label Security is deferred because the current XE image reports:

```text
V$OPTION Oracle Label Security = FALSE
```

Do not run `30b_configure_ols.sql` until an OLS-capable Oracle environment is
available.

## Legacy scripts

Files under `legacy/` are used only by the original generic user/role admin
API. They are not included in the university security installation.
