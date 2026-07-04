import { useEffect, useMemo, useState } from "react";
import { BookOpen, Pencil, Plus } from "lucide-react";

import { getCourses } from "@/api/courseApi";
import DataPageHeader from "@/components/common/DataPageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import CourseFormDialog from "@/components/courses/CourseFormDialog";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getAuthSession, hasAnyRole } from "@/lib/auth";
import { COURSE_WRITE_ROLES } from "@/lib/roles";

export default function Courses() {
  const session = getAuthSession();
  const [courses, setCourses] = useState(null);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [formMode, setFormMode] = useState(null);
  const [editingCourse, setEditingCourse] = useState(null);
  const canManageCourses = hasAnyRole(session, COURSE_WRITE_ROLES);

  useEffect(() => {
    let active = true;

    getCourses()
      .then((data) => {
        if (active) setCourses(data);
      })
      .catch(() => {
        if (active) setError("Unable to load courses.");
      });

    return () => {
      active = false;
    };
  }, []);

  const refreshCourses = async () => {
    const data = await getCourses();
    setCourses(data);
  };

  const visibleCourses = useMemo(() => {
    if (!courses) return [];
    const term = search.trim().toLowerCase();
    if (!term) return courses;

    return courses.filter((course) =>
      [course.courseId, course.courseName, course.unitId]
        .some((value) => value.toLowerCase().includes(term)));
  }, [courses, search]);

  return (
    <div className="dashboard-page">
      <DataPageHeader
        title="Courses"
        description="Read-only course information available to your Oracle role."
        icon={BookOpen}
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search by code, name, or unit"
        searchDisabled={courses === null}
        actions={canManageCourses && (
          <Button
            type="button"
            onClick={() => {
              setEditingCourse(null);
              setFormMode("create");
            }}
          >
            <Plus />
            Create course
          </Button>
        )}
      />

      <div className="dashboard-content">
        {error && (
          <div role="alert" className="rounded-lg border border-[#3f4650] bg-[#1e2329] p-5 text-sm text-[#eaecef]">
            {error}
          </div>
        )}

        {!error && courses === null && (
          <div className="flex min-h-48 items-center justify-center rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <LoadingSpinner label="Loading courses..." />
          </div>
        )}

        {courses && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Code</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course name</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Credits</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Theory</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Practice</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Capacity</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Unit</TableHead>
                  {canManageCourses && (
                    <TableHead className="px-4 text-right text-[#929aa5]">
                      Action
                    </TableHead>
                  )}
                </TableRow>
              </TableHeader>
              <TableBody>
                {visibleCourses.map((course) => (
                  <TableRow
                    key={course.courseId}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {course.courseId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {course.courseName}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {course.credits}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {course.theoryPeriods}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {course.practicePeriods}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {course.maxStudents}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {course.unitId}
                    </TableCell>
                    {canManageCourses && (
                      <TableCell className="px-4 text-right">
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          aria-label={`Edit ${course.courseId}`}
                          title="Edit course"
                          onClick={() => {
                            setEditingCourse(course);
                            setFormMode("edit");
                          }}
                        >
                          <Pencil />
                          Edit
                        </Button>
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {visibleCourses.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No courses are available.
              </p>
            )}
          </div>
        )}
      </div>
      {formMode && (
        <CourseFormDialog
          mode={formMode}
          course={editingCourse}
          onClose={() => {
            setFormMode(null);
            setEditingCourse(null);
          }}
          onSaved={refreshCourses}
        />
      )}
    </div>
  );
}
