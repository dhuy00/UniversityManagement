import { useEffect, useMemo, useState } from "react";
import { Presentation } from "lucide-react";
import { toast } from "sonner";

import { getCoursePlans } from "@/api/coursePlanApi";
import {
  createTeachingAssignment,
  updateTeachingAssignment,
} from "@/api/teachingAssignmentApi";
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
import { getApiErrorMessage } from "@/lib/apiError";

const planKey = (plan) =>
  `${plan.courseId}|${plan.semester}|${plan.academicYear}|${plan.programId}`;

export default function TeachingAssignmentFormDialog({
  mode,
  assignment,
  onClose,
  onSaved,
}) {
  const isEdit = mode === "edit";
  const session = getAuthSession();
  const [lecturerId, setLecturerId] = useState(
    assignment?.lecturerId ?? "",
  );
  const [selectedPlanKey, setSelectedPlanKey] = useState(
    assignment ? planKey(assignment) : "",
  );
  const [plans, setPlans] = useState(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    getCoursePlans()
      .then((data) => {
        if (active) setPlans(data);
      })
      .catch(() => {
        if (active) setError("Unable to load course plans.");
      });
    return () => {
      active = false;
    };
  }, []);

  const selectedPlan = useMemo(
    () => plans?.find((plan) => planKey(plan) === selectedPlanKey),
    [plans, selectedPlanKey],
  );
  const manageablePlans = useMemo(() => {
    if (!plans) return [];
    if (!plans.some((plan) => plan.unitId)) {
      return plans;
    }
    if (session?.roleCode === "UNIT_HEAD" && !session?.unitId) {
      return plans;
    }
    const manageableUnit = session?.roleCode === "UNIT_HEAD"
      ? session?.unitId
      : "OFFICE";
    return plans.filter((plan) => plan.unitId === manageableUnit);
  }, [plans, session?.roleCode, session?.unitId]);

  const handleSave = async () => {
    if (!lecturerId.trim() || !selectedPlan) {
      setError("Lecturer ID and course plan are required.");
      return;
    }

    const request = {
      lecturerId: lecturerId.trim().toUpperCase(),
      courseId: selectedPlan.courseId,
      semester: selectedPlan.semester,
      academicYear: selectedPlan.academicYear,
      programId: selectedPlan.programId,
    };

    try {
      setSaving(true);
      setError("");
      if (isEdit) {
        await updateTeachingAssignment(assignment, request);
      } else {
        await createTeachingAssignment(request);
      }
      await onSaved(isEdit
        ? null
        : `${request.lecturerId}|${planKey(request)}`);
      toast.success(
        isEdit ? "Teaching assignment updated" : "Teaching assignment created",
        { description: `${request.lecturerId} · ${request.courseId}` },
      );
      onClose();
    } catch (requestError) {
      setError(getApiErrorMessage(
        requestError,
        "Unable to save the assignment. Check the role, unit, and references.",
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
              <Presentation className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                {isEdit ? "Edit assignment" : "Create assignment"}
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                Oracle VPD enforces the course unit you are allowed to manage.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="grid gap-4">
          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Lecturer ID
            </span>
            <Input
              value={lecturerId}
              onChange={(event) => setLecturerId(event.target.value)}
              disabled={saving}
              maxLength={20}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>

          <div className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Course plan
            </span>
            <Select
              value={selectedPlanKey}
              onValueChange={setSelectedPlanKey}
              disabled={saving || plans === null}
            >
              <SelectTrigger className="!h-10 w-full border-[#3f4650] bg-[#0b0e11] text-[#eaecef]">
                <SelectValue placeholder="Select a course plan" />
              </SelectTrigger>
              <SelectContent alignItemWithTrigger={false}>
                <SelectGroup>
                  {manageablePlans.map((plan) => (
                    <SelectItem key={planKey(plan)} value={planKey(plan)}>
                      {plan.courseId} · Semester {plan.semester}/
                      {plan.academicYear} · {plan.programId}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
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
            disabled={saving || plans === null}
          >
            {saving
              ? <LoadingSpinner label="Saving..." />
              : isEdit ? "Update assignment" : "Create assignment"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
