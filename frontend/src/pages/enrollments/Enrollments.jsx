import { useEffect, useState } from "react";
import { FileText, GraduationCap } from "lucide-react";

import { getEnrollments } from "@/api/enrollmentApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import EnrollmentDetailDialog from "@/components/enrollments/EnrollmentDetailDialog";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getAuthSession } from "@/lib/auth";

export default function Enrollments() {
  const session = getAuthSession();
  const [enrollments, setEnrollments] = useState(null);
  const [error, setError] = useState("");
  const [selectedEnrollment, setSelectedEnrollment] = useState(null);

  useEffect(() => {
    let active = true;

    getEnrollments()
      .then((data) => {
        if (active) setEnrollments(data);
      })
      .catch((requestError) => {
        if (!active) return;
        setError(
          requestError.response?.status === 403
            ? "Your role cannot access enrollments."
            : "Unable to load enrollments.",
        );
      });

    return () => {
      active = false;
    };
  }, []);

  const isStudent = session?.roleCode === "STUDENT";

  return (
    <div className="dashboard-page">
      <header className="flex min-h-20 items-center border-b border-[#2b3139] pl-14 pr-4 sm:px-6 lg:px-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#707a8a]">
            Academic records
          </p>
          <h1 className="mt-1 text-lg font-semibold tracking-tight text-white">
            {isStudent ? "My Enrollments" : "Enrollments"}
          </h1>
        </div>
      </header>

      <div className="dashboard-content">
        <section className="mb-6 flex items-center gap-4">
          <div className="flex size-11 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
            <GraduationCap className="size-5" />
          </div>
          <div>
            <h2 className="text-xl font-semibold text-white">
              Enrollment results
            </h2>
            <p className="mt-1 text-sm text-[#929aa5]">
              Rows are restricted by your Oracle identity and VPD policy.
            </p>
          </div>
        </section>

        {error && (
          <div role="alert" className="rounded-lg border border-[#3f4650] bg-[#1e2329] p-5 text-sm text-[#eaecef]">
            {error}
          </div>
        )}

        {!error && enrollments === null && (
          <div className="flex min-h-48 items-center justify-center rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <LoadingSpinner label="Loading enrollments..." />
          </div>
        )}

        {enrollments && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Student name</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Lecturer</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course name</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Term</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Program</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {enrollments.map((enrollment) => (
                  <TableRow
                    key={`${enrollment.studentId}-${enrollment.lecturerId}-${enrollment.courseId}-${enrollment.semester}-${enrollment.academicYear}-${enrollment.programId}`}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {enrollment.studentName}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {enrollment.lecturerId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {enrollment.courseId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {enrollment.courseName}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {enrollment.semester}/{enrollment.academicYear}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {enrollment.programId}
                    </TableCell>
                    <TableCell className="px-4 text-right">
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        aria-label="View enrollment details"
                        title="View enrollment details"
                        onClick={() => setSelectedEnrollment(enrollment)}
                      >
                        <FileText />
                        Detail
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {enrollments.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No enrollments are visible to this identity.
              </p>
            )}
          </div>
        )}
      </div>
      {selectedEnrollment && (
        <EnrollmentDetailDialog
          enrollment={selectedEnrollment}
          onClose={() => setSelectedEnrollment(null)}
        />
      )}
    </div>
  );
}
