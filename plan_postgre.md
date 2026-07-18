# PostgreSQL Migration Plan

## Objective
Migrate the current Oracle-based university management application to PostgreSQL while preserving the existing business workflows and security model as closely as possible.

## Scope
- Backend API and repositories
- Database schema and seed data
- Authentication and session handling
- Role/permission and row-level security behavior
- Frontend integration points

## Current State
- Frontend: React + Vite
- Backend: ASP.NET Core Web API targeting .NET 10
- Database currently used in development: Oracle XE 21c in Docker
- Current implementation is tightly coupled to Oracle-specific packages, procedures, connection factories, and provider libraries

## Phase 1 — Inventory and preparation

### Step 1 checklist: inventory Oracle dependencies and define migration scope

1. Review backend entry points and service registration
   - Open [UniversityManagementAPI/Program.cs](UniversityManagementAPI/Program.cs) and note any Oracle-specific registration or exception handling.
   - Confirm whether the application uses a common connection factory or direct database access in services/controllers.

2. Inventory Oracle-specific packages in the backend project
   - Open [UniversityManagementAPI/UniversityManagementAPI.csproj](UniversityManagementAPI/UniversityManagementAPI.csproj) and note all Oracle provider packages.
   - Record package names and versions that must be replaced or removed for PostgreSQL support.

3. Scan repository files for Oracle API usage
   - Review the files in [UniversityManagementAPI/Repositories](UniversityManagementAPI/Repositories) and search for:
     - `using Oracle.ManagedDataAccess.Client`
     - `OracleCommand`
     - `OracleDbType`
     - `OracleConnectionStringBuilder`
     - references to Oracle PL/SQL packages or procedures
   - Make a list of repositories that need refactoring.

4. Identify database script dependencies
   - Review files under [script/sql](script/sql) and note which scripts are Oracle-specific.
   - Mark scripts that use:
     - Oracle packages/procedures
     - Oracle-specific roles, grants, or triggers
     - VPD/OLS security features
     - Oracle syntax such as `VARCHAR2`, `NUMBER`, `SYSDATE`, `DBMS_*`

5. Classify modules by migration difficulty
   - Easy first: auth, profile, simple CRUD modules
   - Medium: role/permission and teaching assignment flows
   - Hard: security model and any logic tied to Oracle-specific VPD/OLS behavior

6. Create a dependency map
   - For each module, note:
     - repository file(s)
     - service file(s)
     - controller(s)
     - database script(s)
     - expected business behavior

7. Choose a first migration target
   - Pick one module to migrate first, for example: authentication and profile.
   - Keep the scope narrow and verify it end-to-end before moving to the next module.

8. Prepare the local PostgreSQL environment
   - Install or run PostgreSQL locally (Docker recommended).
   - Create a dedicated database for testing migration work.
   - Prepare a connection string and keep it separate from the current Oracle setup.

9. Record findings in a short checklist file or notes
   - Capture the inventory results in this file or a separate notes file so the next step has a clear baseline.

10. Define success criteria for Step 1
   - You should be able to answer:
     - Which files are Oracle-dependent?
     - Which modules are highest priority?
     - Which database scripts need translation first?
     - What PostgreSQL environment is available for testing?

## Phase 2 — Database migration strategy
1. Translate the Oracle schema scripts to PostgreSQL-compatible SQL.
2. Replace Oracle-specific object names and syntax where needed.
3. Map data types and constraints from Oracle to PostgreSQL.
4. Recreate identity/sequence behavior and table relationships in PostgreSQL.
5. Re-seed reference and test data.

## Phase 3 — Backend adaptation
1. Replace Oracle provider packages with PostgreSQL-compatible packages.
2. Update connection management to use PostgreSQL connection settings.
3. Refactor repositories to use PostgreSQL syntax and parameter handling.
4. Replace Oracle-specific exception handling with PostgreSQL-compatible handling where appropriate.
5. Retest authentication, profile, CRUD, and role/permission flows.

## Phase 4 — Security model migration
1. Replace Oracle VPD/OLS concepts with PostgreSQL equivalents or a suitable alternative approach.
2. Reimplement row-level security or application-level access rules in PostgreSQL.
3. Validate that role-based access and identity context remain correct.

## Phase 5 — Verification and rollout
1. Run smoke tests for login, profile, course and enrollment workflows.
2. Validate database migration scripts end-to-end.
3. Compare Oracle and PostgreSQL behavior for key business flows.
4. Switch development environment to PostgreSQL after validation.
5. Prepare rollback steps in case of critical issues.

## Suggested Priority Order
1. Auth and profile modules
2. Basic CRUD modules (staff, students, courses, units)
3. Teaching assignment and enrollment workflows
4. Permission and role management
5. Security model and data access hardening

## Inventory findings from the current codebase

### Backend files with direct Oracle dependency
- [UniversityManagementAPI/Program.cs](UniversityManagementAPI/Program.cs)
- [UniversityManagementAPI/UniversityManagementAPI.csproj](UniversityManagementAPI/UniversityManagementAPI.csproj)
- [UniversityManagementAPI/Exceptions/OracleExceptionHandler.cs](UniversityManagementAPI/Exceptions/OracleExceptionHandler.cs)
- [UniversityManagementAPI/Data/Connection/IDbConnectionFactory.cs](UniversityManagementAPI/Data/Connection/IDbConnectionFactory.cs)
- [UniversityManagementAPI/Data/Connection/OracleConnectionFactory.cs](UniversityManagementAPI/Data/Connection/OracleConnectionFactory.cs)
- [UniversityManagementAPI/Repositories/AuthRepository.cs](UniversityManagementAPI/Repositories/AuthRepository.cs)
- [UniversityManagementAPI/Repositories/CoursePlanRepository.cs](UniversityManagementAPI/Repositories/CoursePlanRepository.cs)
- [UniversityManagementAPI/Repositories/CourseRepository.cs](UniversityManagementAPI/Repositories/CourseRepository.cs)
- [UniversityManagementAPI/Repositories/EnrollmentRepository.cs](UniversityManagementAPI/Repositories/EnrollmentRepository.cs)
- [UniversityManagementAPI/Repositories/PermissionRepository.cs](UniversityManagementAPI/Repositories/PermissionRepository.cs)
- [UniversityManagementAPI/Repositories/ProfileRepository.cs](UniversityManagementAPI/Repositories/ProfileRepository.cs)
- [UniversityManagementAPI/Repositories/RoleRepository.cs](UniversityManagementAPI/Repositories/RoleRepository.cs)
- [UniversityManagementAPI/Repositories/StaffRepository.cs](UniversityManagementAPI/Repositories/StaffRepository.cs)
- [UniversityManagementAPI/Repositories/StudentRepository.cs](UniversityManagementAPI/Repositories/StudentRepository.cs)
- [UniversityManagementAPI/Repositories/TeachingAssignmentRepository.cs](UniversityManagementAPI/Repositories/TeachingAssignmentRepository.cs)
- [UniversityManagementAPI/Repositories/UnitRepository.cs](UniversityManagementAPI/Repositories/UnitRepository.cs)
- [UniversityManagementAPI/Repositories/UserRepository.cs](UniversityManagementAPI/Repositories/UserRepository.cs)

### Oracle-specific constructs found
- `using Oracle.ManagedDataAccess.Client`
- `OracleCommand`
- `OracleDbType`
- `OracleConnectionStringBuilder`
- Oracle exception handling and Oracle-specific error mapping
- Oracle PL/SQL package/procedure calls such as `PERMISSION_GET_TABLES`, `ROLE_CREATE`, `USER_DELETE`, and related procedures

### Database scripts that need PostgreSQL translation
- [script/sql/00_create_app_owner.sql](script/sql/00_create_app_owner.sql)
- [script/sql/01_schema.sql](script/sql/01_schema.sql)
- [script/sql/02_constraints.sql](script/sql/02_constraints.sql)
- [script/sql/03_indexes.sql](script/sql/03_indexes.sql)
- [script/sql/04_seed_reference_data.sql](script/sql/04_seed_reference_data.sql)
- [script/sql/05_generate_bulk_data.sql](script/sql/05_generate_bulk_data.sql)
- [script/sql/10_create_security_roles.sql](script/sql/10_create_security_roles.sql)
- [script/sql/11_grant_object_privileges.sql](script/sql/11_grant_object_privileges.sql)
- [script/sql/12a_security_context_package.sql](script/sql/12a_security_context_package.sql)
- [script/sql/12b_create_context_and_logon_trigger.sql](script/sql/12b_create_context_and_logon_trigger.sql)
- [script/sql/13_vpd_policies_cs1_cs5.sql](script/sql/13_vpd_policies_cs1_cs5.sql)
- [script/sql/14_business_rule_guards.sql](script/sql/14_business_rule_guards.sql)
- [script/sql/20_grant_student_privileges.sql](script/sql/20_grant_student_privileges.sql)
- [script/sql/21_vpd_students_course_plans.sql](script/sql/21_vpd_students_course_plans.sql)
- [script/sql/22_vpd_student_enrollments.sql](script/sql/22_vpd_student_enrollments.sql)

## Risks and Notes
- Oracle VPD/OLS security features do not map 1:1 to PostgreSQL.
- Some repository logic may be tightly coupled to Oracle PL/SQL procedures and will need refactoring.
- Migration should be done incrementally rather than as a single big-bang change.
