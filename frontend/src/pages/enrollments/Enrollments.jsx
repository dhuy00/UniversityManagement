import { useEffect, useMemo, useState } from "react";
import { FileText, GraduationCap, Pencil, Trash2 } from "lucide-react";

import { getEnrollments } from "@/api/enrollmentApi";
import DataPageHeader from "@/components/common/DataPageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import EnrollmentDetailDialog from "@/components/enrollments/EnrollmentDetailDialog";
import EnrollmentMaintainDialog from "@/components/enrollments/EnrollmentMaintainDialog";
import EnrollmentScoreDialog from "@/components/enrollments/EnrollmentScoreDialog";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { prioritizeItem } from "@/lib/prioritizeItem";
import { getAuthSession, hasAnyRole } from "@/lib/auth";
import { SCORE_EDIT_ROLES } from "@/lib/roles";

export default function Enrollments() {
  const session = getAuthSession();
  const [enrollments, setEnrollments] = useState(null);
  const [error, setError] = useState("");
  const [selectedEnrollment, setSelectedEnrollment] = useState(null);
  const [scoreEnrollment, setScoreEnrollment] = useState(null);
  const [maintainMode, setMaintainMode] = useState(null);
  const [cancelEnrollment, setCancelEnrollment] = useState(null);
  const [search, setSearch] = useState("");

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
  const canEditScores = hasAnyRole(session, SCORE_EDIT_ROLES);
  const visibleEnrollments = useMemo(() => {
    if (!enrollments) return [];
    const term = search.trim().toLowerCase();
    if (!term) return enrollments;

    return enrollments.filter((enrollment) =>
      [
        enrollment.studentId,
        enrollment.studentName,
        enrollment.lecturerId,
        enrollment.courseId,
        enrollment.courseName,
        enrollment.programId,
        enrollment.semester,
        enrollment.academicYear,
      ].some((value) => String(value).toLowerCase().includes(term)));
  }, [enrollments, search]);

  return (
    <div className="dashboard-page">
      <DataPageHeader
        title={isStudent ? "My Enrollments" : "Enrollments"}
        description="Rows are restricted by your Oracle identity and VPD policy."
        icon={GraduationCap}
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search student, lecturer, course, program, or term"
        searchDisabled={enrollments === null}
      />

      <div className="dashboard-content">
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
                {visibleEnrollments.map((enrollment) => (
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
                      <div className="flex justify-end gap-2">
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
                        {canEditScores &&
                          session?.staffId === enrollment.lecturerId && (
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              aria-label="Edit enrollment scores"
                              title="Edit enrollment scores"
                              onClick={() => setScoreEnrollment(enrollment)}
                            >
                              <Pencil />
                              Edit
                            </Button>
                          )}
                        {isStudent && (
                          <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              setCancelEnrollment(enrollment);
                              setMaintainMode("delete");
                            }}
                          >
                            <Trash2 />
                            Cancel
                          </Button>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {visibleEnrollments.length === 0 && (
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
      {scoreEnrollment && (
        <EnrollmentScoreDialog
          enrollment={scoreEnrollment}
          onClose={() => setScoreEnrollment(null)}
          onSaved={(updatedEnrollment) => {
            setEnrollments((current) =>
              current.map((item) =>
                item.studentId === updatedEnrollment.studentId &&
                item.lecturerId === updatedEnrollment.lecturerId &&
                item.courseId === updatedEnrollment.courseId &&
                item.semester === updatedEnrollment.semester &&
                item.academicYear === updatedEnrollment.academicYear &&
                item.programId === updatedEnrollment.programId
                  ? updatedEnrollment
                  : item));
          }}
        />
      )}
      {maintainMode && (
        <EnrollmentMaintainDialog
          mode={maintainMode}
          enrollment={cancelEnrollment}
          onClose={() => {
            setMaintainMode(null);
            setCancelEnrollment(null);
          }}
          onSaved={async (createdEnrollment) => {
            const data = await getEnrollments();
            const createdKey = createdEnrollment
              ? [
                createdEnrollment.studentId,
                createdEnrollment.lecturerId,
                createdEnrollment.courseId,
                createdEnrollment.semester,
                createdEnrollment.academicYear,
                createdEnrollment.programId,
              ].join("|")
              : null;
            setEnrollments(prioritizeItem(
              data,
              createdKey,
              (item) => [
                item.studentId,
                item.lecturerId,
                item.courseId,
                item.semester,
                item.academicYear,
                item.programId,
              ].join("|"),
            ));
          }}
        />
      )}
    </div>
  );
}
