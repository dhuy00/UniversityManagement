import { useEffect, useState } from "react";
import { BookPlus } from "lucide-react";
import { toast } from "sonner";

import { createCourse, updateCourse } from "@/api/courseApi";
import { getUnits } from "@/api/unitApi";
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
import { getApiErrorMessage } from "@/lib/apiError";

export default function CourseFormDialog({
  mode,
  course,
  onClose,
  onSaved,
}) {
  const isEdit = mode === "edit";
  const [form, setForm] = useState({
    courseId: course?.courseId ?? "",
    courseName: course?.courseName ?? "",
    credits: String(course?.credits ?? 3),
    theoryPeriods: String(course?.theoryPeriods ?? 30),
    practicePeriods: String(course?.practicePeriods ?? 0),
    maxStudents: String(course?.maxStudents ?? 50),
    unitId: course?.unitId ?? "",
  });
  const [units, setUnits] = useState(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    getUnits()
      .then((data) => {
        if (active) setUnits(data);
      })
      .catch(() => {
        if (active) setError("Unable to load units.");
      });

    return () => {
      active = false;
    };
  }, []);

  const updateField = (key, value) => {
    setForm((current) => ({ ...current, [key]: value }));
  };

  const handleSave = async () => {
    const request = {
      courseId: form.courseId.trim().toUpperCase(),
      courseName: form.courseName.trim(),
      credits: Number(form.credits),
      theoryPeriods: Number(form.theoryPeriods),
      practicePeriods: Number(form.practicePeriods),
      maxStudents: Number(form.maxStudents),
      unitId: form.unitId,
    };

    if (!request.courseId || !request.courseName || !request.unitId) {
      setError("Course ID, course name, and unit are required.");
      return;
    }

    if (request.theoryPeriods + request.practicePeriods === 0) {
      setError("At least one theory or practice period is required.");
      return;
    }

    try {
      setSaving(true);
      setError("");

      if (isEdit) {
        await updateCourse(course.courseId, request);
      } else {
        await createCourse(request);
      }

      await onSaved(isEdit ? null : request.courseId);
      toast.success(isEdit ? "Course updated" : "Course created", {
        description: `${request.courseId} · ${request.courseName}`,
      });
      onClose();
    } catch (requestError) {
      setError(getApiErrorMessage(
        requestError,
        "Unable to save the course. Check its values and unit.",
      ));
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
              <BookPlus className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                {isEdit ? "Edit course" : "Create course"}
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                Course IDs cannot be changed after creation.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="grid gap-4 sm:grid-cols-2">
          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Course ID
            </span>
            <Input
              value={form.courseId}
              onChange={(event) => updateField("courseId", event.target.value)}
              disabled={saving || isEdit}
              maxLength={20}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>

          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Course name
            </span>
            <Input
              value={form.courseName}
              onChange={(event) => updateField("courseName", event.target.value)}
              disabled={saving}
              maxLength={200}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>

          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Credits
            </span>
            <Input
              type="number"
              min="1"
              max="10"
              value={form.credits}
              onChange={(event) => updateField("credits", event.target.value)}
              disabled={saving}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>

          <div className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Unit
            </span>
            <Select
              value={form.unitId}
              onValueChange={(value) => updateField("unitId", value)}
              disabled={saving || units === null}
            >
              <SelectTrigger className="!h-10 w-full border-[#3f4650] bg-[#0b0e11] text-[#eaecef]">
                <SelectValue placeholder="Select a unit" />
              </SelectTrigger>
              <SelectContent alignItemWithTrigger={false}>
                <SelectGroup>
                  {(units ?? []).map((unit) => (
                    <SelectItem key={unit.unitId} value={unit.unitId}>
                      {unit.unitId} · {unit.unitName}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>

          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Theory periods
            </span>
            <Input
              type="number"
              min="0"
              value={form.theoryPeriods}
              onChange={(event) =>
                updateField("theoryPeriods", event.target.value)}
              disabled={saving}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>

          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Practice periods
            </span>
            <Input
              type="number"
              min="0"
              value={form.practicePeriods}
              onChange={(event) =>
                updateField("practicePeriods", event.target.value)}
              disabled={saving}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>

          <label className="space-y-2 sm:col-span-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Maximum students
            </span>
            <Input
              type="number"
              min="1"
              max="1000"
              value={form.maxStudents}
              onChange={(event) =>
                updateField("maxStudents", event.target.value)}
              disabled={saving}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>
        </div>

        {error && (
          <div
            role="alert"
            className="rounded-md border border-[#3f4650] bg-[#2b3139] px-3 py-2 text-sm"
          >
            {error}
          </div>
        )}

        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={saving}>Cancel</Button>}
          />
          <Button
            type="button"
            onClick={handleSave}
            disabled={saving || units === null}
          >
            {saving
              ? <LoadingSpinner label="Saving..." />
              : isEdit ? "Update course" : "Create course"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
