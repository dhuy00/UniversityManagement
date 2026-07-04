import { useEffect, useState } from "react";
import { Presentation } from "lucide-react";

import { getTeachingAssignments } from "@/api/teachingAssignmentApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export default function TeachingAssignments() {
  const [assignments, setAssignments] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    getTeachingAssignments()
      .then((data) => {
        if (active) setAssignments(data);
      })
      .catch((requestError) => {
        if (!active) return;
        setError(
          requestError.response?.status === 403
            ? "Your role cannot access teaching assignments."
            : "Unable to load teaching assignments.",
        );
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
            Teaching operations
          </p>
          <h1 className="mt-1 text-lg font-semibold tracking-tight text-white">
            Teaching Assignments
          </h1>
        </div>
      </header>

      <div className="dashboard-content">
        <section className="mb-6 flex items-center gap-4">
          <div className="flex size-11 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
            <Presentation className="size-5" />
          </div>
          <div>
            <h2 className="text-xl font-semibold text-white">
              Assigned classes
            </h2>
            <p className="mt-1 text-sm text-[#929aa5]">
              Rows are restricted by your Oracle role and VPD context.
            </p>
          </div>
        </section>

        {error && (
          <div role="alert" className="rounded-lg border border-[#3f4650] bg-[#1e2329] p-5 text-sm text-[#eaecef]">
            {error}
          </div>
        )}

        {!error && assignments === null && (
          <div className="flex min-h-48 items-center justify-center rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <LoadingSpinner label="Loading teaching assignments..." />
          </div>
        )}

        {assignments && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Lecturer</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course name</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Semester</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Year</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Program</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {assignments.map((assignment) => (
                  <TableRow
                    key={`${assignment.lecturerId}-${assignment.courseId}-${assignment.semester}-${assignment.academicYear}-${assignment.programId}`}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {assignment.lecturerId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {assignment.courseId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {assignment.courseName}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {assignment.semester}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {assignment.academicYear}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {assignment.programId}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {assignments.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No teaching assignments are visible to this identity.
              </p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
