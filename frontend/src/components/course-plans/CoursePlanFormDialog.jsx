import { useState } from "react";
import { BookOpen, CalendarPlus } from "lucide-react";
import { toast } from "sonner";

import {
  createCoursePlan,
  updateCoursePlan,
} from "@/api/coursePlanApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import CoursePickerDialog from "@/components/course-plans/CoursePickerDialog";
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

const programs = [
  "REGULAR",
  "HIGH_QUALITY",
  "ADVANCED",
  "VIETNAM_FRANCE",
];

export default function CoursePlanFormDialog({
  mode,
  plan,
  onClose,
  onSaved,
}) {
  const isEdit = mode === "edit";
  const [form, setForm] = useState({
    courseId: plan?.courseId ?? "",
    courseName: plan?.courseName ?? "",
    semester: String(plan?.semester ?? 1),
    academicYear: plan?.academicYear ?? new Date().getFullYear(),
    startDate:
      plan?.startDate?.slice(0, 10) ?? new Date().toISOString().slice(0, 10),
    programId: plan?.programId ?? "REGULAR",
  });
  const [pickerOpen, setPickerOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const updateField = (key, value) => {
    setForm((current) => ({ ...current, [key]: value }));
  };

  const handleSave = async () => {
    const request = {
      courseId: form.courseId.trim().toUpperCase(),
      semester: Number(form.semester),
      academicYear: Number(form.academicYear),
      startDate: form.startDate,
      programId: form.programId,
    };

    if (!request.courseId) {
      setError("Course ID is required.");
      return;
    }

    try {
      setSaving(true);
      setError("");
      if (isEdit) {
        await updateCoursePlan(plan, request);
      } else {
        await createCoursePlan(request);
      }
      await onSaved();
      toast.success(isEdit ? "Course plan updated" : "Course plan created", {
        description: `${request.courseId} · Semester ${request.semester}/${request.academicYear}`,
      });
      onClose();
    } catch (requestError) {
      setError(
        requestError.response?.data?.title ||
        "Unable to save the course plan. Check its key and references.",
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <Dialog
        open
        onOpenChange={(open) => {
          if (!open && !saving && !pickerOpen) onClose();
        }}
      >
        <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-2xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <CalendarPlus className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                {isEdit ? "Edit course plan" : "Create course plan"}
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                Start date controls the 14-day enrollment adjustment window.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

          <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-2 sm:col-span-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Course
            </span>
            <div className="flex flex-col gap-2 sm:flex-row">
              <div className="flex min-h-10 flex-1 items-center rounded-md border border-[#3f4650] bg-[#0b0e11] px-4 text-sm">
                {form.courseId ? (
                  <span>
                    <strong className="text-[#fcd535]">{form.courseId}</strong>
                    {form.courseName && (
                      <span className="ml-2 text-[#929aa5]">
                        {form.courseName}
                      </span>
                    )}
                  </span>
                ) : (
                  <span className="text-[#707a8a]">No course selected</span>
                )}
              </div>
              <Button
                type="button"
                variant="outline"
                disabled={saving}
                onClick={() => setPickerOpen(true)}
              >
                <BookOpen />
                Choose course
              </Button>
            </div>
          </div>

          <div className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Program
            </span>
            <Select
              value={form.programId}
              onValueChange={(value) => updateField("programId", value)}
              disabled={saving}
            >
              <SelectTrigger className="h-10 w-full border-[#3f4650] bg-[#0b0e11] text-[#eaecef]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent alignItemWithTrigger={false}>
                <SelectGroup>
                  {programs.map((program) => (
                    <SelectItem key={program} value={program}>
                      {program}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Semester
            </span>
            <Select
              value={form.semester}
              onValueChange={(value) => updateField("semester", value)}
              disabled={saving}
            >
              <SelectTrigger className="h-10 w-full border-[#3f4650] bg-[#0b0e11] text-[#eaecef]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent alignItemWithTrigger={false}>
                <SelectGroup>
                  {["1", "2", "3"].map((semester) => (
                    <SelectItem key={semester} value={semester}>
                      Semester {semester}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>

          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Academic year
            </span>
            <Input
              type="number"
              min="2000"
              max="9999"
              value={form.academicYear}
              onChange={(event) =>
                updateField("academicYear", event.target.value)}
              disabled={saving}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>
          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Start date
            </span>
            <Input
              type="date"
              value={form.startDate}
              onChange={(event) => updateField("startDate", event.target.value)}
              disabled={saving}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>
          </div>

        {error && (
          <div role="alert" className="rounded-md border border-[#3f4650] bg-[#2b3139] px-3 py-2 text-sm">
            {error}
          </div>
        )}

        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={saving}>Cancel</Button>}
          />
          <Button onClick={handleSave} disabled={saving}>
            {saving
              ? <LoadingSpinner label="Saving..." />
              : isEdit ? "Update plan" : "Create plan"}
          </Button>
        </DialogFooter>
        </DialogContent>
      </Dialog>

      {pickerOpen && (
        <CoursePickerDialog
          selectedCourseId={form.courseId}
          onSelect={(course) =>
            setForm((current) => ({
              ...current,
              courseId: course.courseId,
              courseName: course.courseName,
            }))}
          onClose={() => setPickerOpen(false)}
        />
      )}
    </>
  );
}
