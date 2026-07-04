import { useEffect, useState } from "react";
import { BookOpen } from "lucide-react";

import { getCourses } from "@/api/courseApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export default function Courses() {
  const [courses, setCourses] = useState(null);
  const [error, setError] = useState("");

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

  return (
    <div className="dashboard-page">
      <header className="flex min-h-20 items-center border-b border-[#2b3139] pl-14 pr-4 sm:px-6 lg:px-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#707a8a]">
            Academic catalog
          </p>
          <h1 className="mt-1 text-lg font-semibold tracking-tight text-white">
            Courses
          </h1>
        </div>
      </header>

      <div className="dashboard-content">
        <section className="mb-6 flex items-center gap-4">
          <div className="flex size-11 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
            <BookOpen className="size-5" />
          </div>
          <div>
            <h2 className="text-xl font-semibold text-white">Course catalog</h2>
            <p className="mt-1 text-sm text-[#929aa5]">
              Read-only course information available to your Oracle role.
            </p>
          </div>
        </section>

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
                </TableRow>
              </TableHeader>
              <TableBody>
                {courses.map((course) => (
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
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {courses.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No courses are available.
              </p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
