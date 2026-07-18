# PostgreSQL database design

This design replaces the Oracle-specific model with a PostgreSQL schema named
`university`. It preserves the existing university domain while moving identity
and authorization into the API.

```mermaid
erDiagram
    CAMPUSES {
        varchar campus_id PK
        varchar campus_name UK
    }

    PROGRAMS {
        varchar program_id PK
        varchar program_name UK
    }

    MAJORS {
        varchar major_id PK
        varchar major_name UK
    }

    ROLES {
        varchar role_code PK
        varchar role_name UK
        text description
    }

    PERMISSIONS {
        varchar permission_code PK
        varchar description
    }

    APP_USERS {
        bigint user_id PK
        varchar username UK
        varchar password_hash
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    ROLE_PERMISSIONS {
        varchar role_code PK,FK
        varchar permission_code PK,FK
    }

    APP_USER_ROLES {
        bigint user_id PK,FK
        varchar role_code PK,FK
        timestamptz granted_at
        bigint granted_by FK
    }

    UNITS {
        varchar unit_id PK
        varchar unit_name UK
        varchar head_staff_id FK
    }

    STAFF {
        varchar staff_id PK
        bigint user_id FK,UK
        varchar full_name
        varchar gender
        date date_of_birth
        numeric allowance
        varchar phone
        varchar unit_id FK
        varchar campus_id FK
        timestamptz created_at
        timestamptz updated_at
    }

    STUDENTS {
        varchar student_id PK
        bigint user_id FK,UK
        varchar full_name
        varchar gender
        date date_of_birth
        varchar address
        varchar phone
        varchar program_id FK
        varchar major_id FK
        smallint accumulated_credits
        numeric cumulative_gpa
        varchar campus_id FK
        timestamptz created_at
        timestamptz updated_at
    }

    COURSES {
        varchar course_id PK
        varchar course_name
        smallint credits
        smallint theory_periods
        smallint practice_periods
        smallint max_students
        varchar unit_id FK
        timestamptz created_at
        timestamptz updated_at
    }

    COURSE_PLANS {
        varchar course_id PK,FK
        smallint semester PK
        smallint academic_year PK
        varchar program_id PK,FK
        date start_date
    }

    TEACHING_ASSIGNMENTS {
        varchar lecturer_id PK,FK
        varchar course_id PK,FK
        smallint semester PK,FK
        smallint academic_year PK,FK
        varchar program_id PK,FK
    }

    ENROLLMENTS {
        varchar student_id PK,FK
        varchar lecturer_id PK,FK
        varchar course_id PK,FK
        smallint semester PK,FK
        smallint academic_year PK,FK
        varchar program_id PK,FK
        numeric practice_score
        numeric process_score
        numeric final_exam_score
        numeric final_score
    }

    NOTIFICATIONS {
        bigint notification_id PK
        text content
        timestamptz created_at
        bigint created_by FK
    }

    ROLES ||--o{ ROLE_PERMISSIONS : grants
    PERMISSIONS ||--o{ ROLE_PERMISSIONS : contains
    APP_USERS ||--o{ APP_USER_ROLES : receives
    ROLES ||--o{ APP_USER_ROLES : assigned_as
    APP_USERS o|--o{ APP_USER_ROLES : grants

    APP_USERS ||--o| STAFF : identifies
    APP_USERS ||--o| STUDENTS : identifies
    APP_USERS ||--o{ NOTIFICATIONS : creates

    CAMPUSES ||--o{ STAFF : locates
    CAMPUSES ||--o{ STUDENTS : locates
    PROGRAMS ||--o{ STUDENTS : enrolls_in
    MAJORS ||--o{ STUDENTS : majors_in

    UNITS ||--o{ STAFF : contains
    STAFF o|--o{ UNITS : heads
    UNITS ||--o{ COURSES : manages
    COURSES ||--o{ COURSE_PLANS : scheduled_as
    PROGRAMS ||--o{ COURSE_PLANS : offers

    STAFF ||--o{ TEACHING_ASSIGNMENTS : teaches
    COURSE_PLANS ||--o{ TEACHING_ASSIGNMENTS : staffed_by
    STUDENTS ||--o{ ENROLLMENTS : registers
    TEACHING_ASSIGNMENTS ||--o{ ENROLLMENTS : receives
```

## Authentication and authorization

`app_users` is the sole authentication table. It stores a BCrypt hash and an
active flag. Roles are normalized through `app_user_roles`; permissions are
granted through `role_permissions`. `staff` and `students` each have a
one-to-one link to `app_users` and deliberately contain no duplicate role
column. The API connects to PostgreSQL with one application connection string;
it must not create a PostgreSQL server account for every student or staff
member.

The initial role codes are `BASIC_STAFF`, `LECTURER`, `ACADEMIC_AFFAIRS`,
`UNIT_HEAD`, `DEAN`, and `STUDENT`. The script also seeds the permission
catalogue and role-to-permission mapping. API authorization will load those
permissions into JWT claims. PostgreSQL row-level security can be added in a
later script after the Npgsql repository migration is complete.

## Apply locally

Start the container first, then run the schema as the `postgres` database user:

```powershell
docker compose -f script/docker-compose.postgres.yml up -d
Get-Content script/postgres/01_schema.sql | docker exec -i university-postgres psql -U postgres -d university_management -v ON_ERROR_STOP=1
```

The script first executes `DROP SCHEMA university CASCADE`, so it recreates the
schema from scratch and permanently deletes all data in that schema. It seeds
only stable reference data and the RBAC catalogue; demo users and university
data are separate follow-up steps.
