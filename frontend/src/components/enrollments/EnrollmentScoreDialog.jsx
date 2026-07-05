import { useState } from "react";
import { PencilLine } from "lucide-react";
import { toast } from "sonner";

import { updateEnrollmentScores } from "@/api/enrollmentApi";
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
import { getApiErrorMessage } from "@/lib/apiError";

const scoreFields = [
  ["practiceScore", "Practice score"],
  ["processScore", "Process score"],
  ["finalExamScore", "Final exam score"],
  ["finalScore", "Final score"],
];

const initialScores = (enrollment) => Object.fromEntries(
  scoreFields.map(([key]) => [key, enrollment[key] ?? ""]),
);

const parseScore = (value) => {
  if (value === "") return null;
  const score = Number(value);
  if (!Number.isFinite(score) || score < 0 || score > 10) {
    throw new Error("Every score must be between 0 and 10.");
  }
  return score;
};

export default function EnrollmentScoreDialog({
  enrollment,
  onClose,
  onSaved,
}) {
  const [scores, setScores] = useState(() => initialScores(enrollment));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const handleSave = async () => {
    try {
      setError("");
      const parsedScores = Object.fromEntries(
        scoreFields.map(([key]) => [key, parseScore(scores[key])]),
      );

      setSaving(true);
      await updateEnrollmentScores({
        studentId: enrollment.studentId,
        lecturerId: enrollment.lecturerId,
        courseId: enrollment.courseId,
        semester: enrollment.semester,
        academicYear: enrollment.academicYear,
        programId: enrollment.programId,
        ...parsedScores,
      });
      toast.success("Scores updated", {
        description: `${enrollment.studentName} · ${enrollment.courseId}`,
      });
      onSaved({ ...enrollment, ...parsedScores });
      onClose();
    } catch (requestError) {
      setError(
        requestError.response?.status === 404
          ? "This enrollment is not editable by your Oracle identity."
          : getApiErrorMessage(
            requestError,
            requestError.message || "Unable to update scores.",
          ),
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
              <PencilLine className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                Update scores
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                {enrollment.studentName} · {enrollment.courseId} · Semester{" "}
                {enrollment.semester}/{enrollment.academicYear}
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="grid gap-4 sm:grid-cols-2">
          {scoreFields.map(([key, label]) => (
            <label key={key} className="space-y-2">
              <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
                {label}
              </span>
              <Input
                type="number"
                min="0"
                max="10"
                step="0.01"
                value={scores[key]}
                onChange={(event) =>
                  setScores((current) => ({
                    ...current,
                    [key]: event.target.value,
                  }))}
                disabled={saving}
                className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
              />
            </label>
          ))}
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
            {saving ? <LoadingSpinner label="Saving..." /> : "Save scores"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
