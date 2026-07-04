import { GraduationCap } from "lucide-react";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

const DetailField = ({ label, value }) => (
  <div className="rounded-md border border-[#2b3139] bg-[#181a20] p-4">
    <dt className="text-xs font-semibold uppercase tracking-[0.1em] text-[#707a8a]">
      {label}
    </dt>
    <dd className="mt-1.5 text-sm font-medium text-[#eaecef]">
      {value ?? "—"}
    </dd>
  </div>
);

export default function EnrollmentDetailDialog({ enrollment, onClose }) {
  return (
    <Dialog
      open={Boolean(enrollment)}
      onOpenChange={(open) => {
        if (!open) onClose();
      }}
    >
      <DialogContent className="max-h-[calc(100vh-2rem)] overflow-y-auto bg-[#1e2329] text-[#eaecef] sm:!max-w-3xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <GraduationCap className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                Enrollment details
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                Complete registration and score information.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        {enrollment && (
          <>
            <dl className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              <DetailField label="Student name" value={enrollment.studentName} />
              <DetailField label="Student ID" value={enrollment.studentId} />
              <DetailField label="Lecturer ID" value={enrollment.lecturerId} />
              <DetailField label="Course ID" value={enrollment.courseId} />
              <DetailField label="Course name" value={enrollment.courseName} />
              <DetailField label="Program" value={enrollment.programId} />
              <DetailField label="Semester" value={enrollment.semester} />
              <DetailField label="Academic year" value={enrollment.academicYear} />
            </dl>

            <section>
              <h3 className="mb-3 text-xs font-semibold uppercase tracking-[0.12em] text-[#fcd535]">
                Scores
              </h3>
              <dl className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                <DetailField label="Practice" value={enrollment.practiceScore} />
                <DetailField label="Process" value={enrollment.processScore} />
                <DetailField label="Final exam" value={enrollment.finalExamScore} />
                <DetailField label="Final score" value={enrollment.finalScore} />
              </dl>
            </section>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
