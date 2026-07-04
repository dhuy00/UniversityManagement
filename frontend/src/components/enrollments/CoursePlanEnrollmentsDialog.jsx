import { useEffect, useState } from "react";
import { UsersRound } from "lucide-react";

import { getCoursePlanEnrollments } from "@/api/enrollmentApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export default function CoursePlanEnrollmentsDialog({ plan, onClose }) {
  const [enrollments, setEnrollments] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!plan) return;

    let active = true;

    getCoursePlanEnrollments(plan)
      .then((data) => {
        if (active) setEnrollments(data);
      })
      .catch(() => {
        if (active) setError("Unable to load registered students.");
      });

    return () => {
      active = false;
    };
  }, [plan]);

  return (
    <Dialog
      open={Boolean(plan)}
      onOpenChange={(open) => {
        if (!open) onClose();
      }}
    >
      <DialogContent className="max-h-[calc(100vh-2rem)] overflow-hidden bg-[#1e2329] text-[#eaecef] sm:!max-w-4xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <UsersRound className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                Registered students
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                {plan?.courseId} · Semester {plan?.semester}/{plan?.academicYear} ·{" "}
                {plan?.programId}
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        {error && (
          <div role="alert" className="rounded-md border border-[#3f4650] bg-[#2b3139] p-4">
            {error}
          </div>
        )}

        {!error && enrollments === null && (
          <div className="flex min-h-40 items-center justify-center">
            <LoadingSpinner label="Loading registered students..." />
          </div>
        )}

        {enrollments && (
          <div className="max-h-[60vh] overflow-auto rounded-lg border border-[#2b3139]">
            <Table>
              <TableHeader className="sticky top-0 bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Student ID</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Student name</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Lecturer</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {enrollments.map((enrollment) => (
                  <TableRow
                    key={`${enrollment.studentId}-${enrollment.lecturerId}`}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {enrollment.studentId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {enrollment.studentName}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {enrollment.lecturerId}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {enrollments.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No registered students are visible to your role.
              </p>
            )}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
