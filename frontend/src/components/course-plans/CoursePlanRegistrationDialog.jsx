import { useEffect, useMemo, useState } from "react";
import { GraduationCap } from "lucide-react";
import { toast } from "sonner";

import {
  createEnrollment,
  getRegistrationOptions,
} from "@/api/enrollmentApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { getAuthSession } from "@/lib/auth";

const matchesPlan = (option, plan) =>
  option.courseId === plan.courseId &&
  option.semester === plan.semester &&
  option.academicYear === plan.academicYear &&
  option.programId === plan.programId;

export default function CoursePlanRegistrationDialog({ plan, onClose }) {
  const session = getAuthSession();
  const [options, setOptions] = useState(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    getRegistrationOptions()
      .then((data) => {
        if (active) setOptions(data);
      })
      .catch(() => {
        if (active) setError("Unable to load teaching assignments.");
      });
    return () => {
      active = false;
    };
  }, []);

  const assignment = useMemo(
    () => options?.find(
      (option) => matchesPlan(option, plan) && option.registrationOpen,
    ),
    [options, plan],
  );

  const handleConfirm = async () => {
    if (!assignment || !session?.studentId) {
      setError(
        plan.registrationOpen
          ? "This course plan does not have an available teaching assignment."
          : "The registration window is closed.",
      );
      return;
    }

    try {
      setSaving(true);
      setError("");
      await createEnrollment({
        studentId: session.studentId,
        lecturerId: assignment.lecturerId,
        courseId: assignment.courseId,
        semester: assignment.semester,
        academicYear: assignment.academicYear,
        programId: assignment.programId,
      });
      toast.success("Course registered", {
        description: `${assignment.courseId} · ${assignment.courseName}`,
      });
      onClose();
    } catch (requestError) {
      setError(
        requestError.response?.data?.title ||
        "Unable to register this course. You may already be enrolled.",
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog
      open
      onOpenChange={(open) => {
        if (!open && !saving) onClose();
      }}
    >
      <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-md">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <GraduationCap className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-white">
                Confirm course registration
              </DialogTitle>
              <DialogDescription className="text-[#929aa5]">
                Oracle will validate your program and registration window.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="rounded-md border border-[#2b3139] bg-[#0b0e11] p-4 text-sm">
          <p className="font-semibold text-[#fcd535]">{plan.courseId}</p>
          <p className="mt-1 text-[#eaecef]">{plan.courseName}</p>
          <p className="mt-2 text-[#929aa5]">
            Semester {plan.semester}/{plan.academicYear} · {plan.programId}
          </p>
          {assignment && (
            <p className="mt-1 text-[#929aa5]">
              Lecturer: {assignment.lecturerId}
            </p>
          )}
        </div>

        {options === null && !error && (
          <LoadingSpinner label="Checking availability..." />
        )}
        {options && !assignment && !error && (
          <div role="alert" className="rounded-md bg-[#2b3139] px-3 py-2 text-sm">
            No open teaching assignment is available for this course plan.
          </div>
        )}
        {error && (
          <div role="alert" className="rounded-md bg-[#2b3139] px-3 py-2 text-sm">
            {error}
          </div>
        )}

        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={saving}>Cancel</Button>}
          />
          <Button
            type="button"
            onClick={handleConfirm}
            disabled={saving || options === null || !assignment}
          >
            {saving
              ? <LoadingSpinner label="Registering..." />
              : "Confirm registration"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
