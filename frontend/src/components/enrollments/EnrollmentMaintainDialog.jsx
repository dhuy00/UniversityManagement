import { useEffect, useMemo, useState } from "react";
import { GraduationCap } from "lucide-react";
import { toast } from "sonner";

import {
  createEnrollment,
  deleteEnrollment,
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
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { getAuthSession } from "@/lib/auth";

const optionKey = (option) =>
  `${option.lecturerId}|${option.courseId}|${option.semester}|${option.academicYear}|${option.programId}`;

export default function EnrollmentMaintainDialog({
  mode,
  enrollment,
  onClose,
  onSaved,
}) {
  const session = getAuthSession();
  const isDelete = mode === "delete";
  const isAffairs = session?.roleCode === "ACADEMIC_AFFAIRS";
  const [studentId, setStudentId] = useState(
    enrollment?.studentId ?? session?.studentId ?? "",
  );
  const [options, setOptions] = useState(enrollment ? [] : null);
  const [selectedKey, setSelectedKey] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (enrollment) return undefined;

    let active = true;
    getRegistrationOptions()
      .then((data) => {
        if (active) setOptions(data);
      })
      .catch(() => {
        if (active) setError("Unable to load open registration options.");
      });
    return () => {
      active = false;
    };
  }, [enrollment]);

  const selectedOption = useMemo(
    () => options?.find((option) => optionKey(option) === selectedKey),
    [options, selectedKey],
  );

  const handleSave = async () => {
    const source = enrollment ?? selectedOption;
    if (!studentId.trim() || !source) {
      setError("Student ID and an open teaching assignment are required.");
      return;
    }

    const request = {
      studentId: studentId.trim().toUpperCase(),
      lecturerId: source.lecturerId,
      courseId: source.courseId,
      semester: source.semester,
      academicYear: source.academicYear,
      programId: source.programId,
    };

    try {
      setSaving(true);
      setError("");
      if (isDelete) {
        await deleteEnrollment(request);
      } else {
        await createEnrollment(request);
      }
      await onSaved();
      toast.success(isDelete ? "Enrollment cancelled" : "Enrollment created", {
        description: `${request.studentId} · ${request.courseId}`,
      });
      onClose();
    } catch (requestError) {
      setError(
        requestError.response?.data?.title ||
        "Unable to change the enrollment. The registration window may be closed.",
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
      <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-2xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <GraduationCap className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                {isDelete ? "Cancel enrollment" : "Register course"}
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                Oracle enforces the program match and 14-day adjustment window.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="grid gap-4">
          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Student ID
            </span>
            <Input
              value={studentId}
              onChange={(event) => setStudentId(event.target.value)}
              disabled={saving || !isAffairs}
              maxLength={20}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>

          {enrollment ? (
            <div className="rounded-md border border-[#3f4650] bg-[#0b0e11] p-3 text-sm">
              <strong className="text-[#fcd535]">{enrollment.courseId}</strong>
              <span className="ml-2 text-[#929aa5]">
                {enrollment.courseName} · {enrollment.lecturerId} · Semester{" "}
                {enrollment.semester}/{enrollment.academicYear}
              </span>
            </div>
          ) : (
            <div className="space-y-2">
              <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
                Open teaching assignment
              </span>
              <Select
                value={selectedKey}
                onValueChange={setSelectedKey}
                disabled={saving || options === null}
              >
                <SelectTrigger className="!h-10 w-full border-[#3f4650] bg-[#0b0e11] text-[#eaecef]">
                  <SelectValue placeholder="Select an assignment" />
                </SelectTrigger>
                <SelectContent alignItemWithTrigger={false}>
                  <SelectGroup>
                    {(options ?? []).map((option) => (
                      <SelectItem
                        key={optionKey(option)}
                        value={optionKey(option)}
                        disabled={!option.registrationOpen}
                      >
                        {option.courseId} · {option.courseName} ·{" "}
                        {option.lecturerId} · {option.programId} ·{" "}
                        {option.registrationOpen ? "Open" : "Closed"}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
          )}
        </div>

        {options?.length === 0 && !enrollment && (
          <p className="text-sm text-[#929aa5]">
            No teaching assignments are currently inside the adjustment window.
          </p>
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
            variant={isDelete ? "destructive" : "default"}
            onClick={handleSave}
            disabled={saving || (!enrollment && options === null)}
          >
            {saving
              ? <LoadingSpinner label="Saving..." />
              : isDelete ? "Cancel enrollment" : "Register course"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
