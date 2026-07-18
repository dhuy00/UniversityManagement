-- Enable PostgreSQL row-level security for the first student-access slice.
-- Policies are intentionally added in a later migration. Until then, a
-- non-owner role has no row access because PostgreSQL applies default deny
-- when RLS is enabled and no applicable policy exists.

BEGIN;
SET search_path TO university, public;

ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

COMMIT;
