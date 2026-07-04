import { useEffect, useMemo, useState } from "react";
import { Presentation } from "lucide-react";

import { getTeachingAssignments } from "@/api/teachingAssignmentApi";
import DataPageHeader from "@/components/common/DataPageHeader";
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
  const [search, setSearch] = useState("");

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

  const visibleAssignments = useMemo(() => {
    if (!assignments) return [];
    const term = search.trim().toLowerCase();
    if (!term) return assignments;

    return assignments.filter((assignment) =>
      [
        assignment.lecturerId,
        assignment.courseId,
        assignment.courseName,
        assignment.programId,
        assignment.semester,
        assignment.academicYear,
      ].some((value) => String(value).toLowerCase().includes(term)));
  }, [assignments, search]);

  return (
    <div className="dashboard-page">
      <DataPageHeader
        eyebrow="Teaching operations"
        title="Teaching Assignments"
        description="Rows are restricted by your Oracle role and VPD context."
        icon={Presentation}
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search lecturer, course, program, or term"
        searchDisabled={assignments === null}
      />

      <div className="dashboard-content">
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
                {visibleAssignments.map((assignment) => (
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

            {visibleAssignments.length === 0 && (
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
