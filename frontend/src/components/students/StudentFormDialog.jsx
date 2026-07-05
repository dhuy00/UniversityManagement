import { useState } from "react";
import { UserRoundPlus } from "lucide-react";
import { toast } from "sonner";

import { createStudent, updateStudent } from "@/api/studentApi";
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

const selectOptions = {
  gender: ["MALE", "FEMALE", "OTHER"],
  programId: ["REGULAR", "HIGH_QUALITY", "ADVANCED", "VIETNAM_FRANCE"],
  majorId: ["IS", "SE", "CS", "IT", "CV", "NET"],
  campusId: ["CAMPUS_1", "CAMPUS_2"],
};

function FormSelect({ label, value, options, disabled, onChange }) {
  return (
    <div className="space-y-2">
      <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
        {label}
      </span>
      <Select value={value} onValueChange={onChange} disabled={disabled}>
        <SelectTrigger className="!h-10 w-full border-[#3f4650] bg-[#0b0e11] text-[#eaecef]">
          <SelectValue />
        </SelectTrigger>
        <SelectContent alignItemWithTrigger={false}>
          <SelectGroup>
            {options.map((option) => (
              <SelectItem key={option} value={option}>
                {option}
              </SelectItem>
            ))}
          </SelectGroup>
        </SelectContent>
      </Select>
    </div>
  );
}

export default function StudentFormDialog({
  mode,
  student,
  onClose,
  onSaved,
}) {
  const isEdit = mode === "edit";
  const [form, setForm] = useState({
    studentId: student?.studentId ?? "",
    fullName: student?.fullName ?? "",
    gender: student?.gender ?? "MALE",
    dateOfBirth: student?.dateOfBirth?.slice(0, 10) ?? "",
    address: student?.address ?? "",
    phone: student?.phone ?? "",
    programId: student?.programId ?? "REGULAR",
    majorId: student?.majorId ?? "IS",
    accumulatedCredits: String(student?.accumulatedCredits ?? 0),
    cumulativeGpa: String(student?.cumulativeGpa ?? 0),
    oracleUsername: "",
    campusId: student?.campusId ?? "CAMPUS_1",
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const updateField = (key, value) => {
    setForm((current) => ({ ...current, [key]: value }));
  };

  const handleSave = async () => {
    const commonRequest = {
      fullName: form.fullName.trim(),
      gender: form.gender,
      dateOfBirth: form.dateOfBirth,
      address: form.address.trim() || null,
      phone: form.phone.trim() || null,
      programId: form.programId,
      majorId: form.majorId,
      accumulatedCredits: Number(form.accumulatedCredits),
      cumulativeGpa: Number(form.cumulativeGpa),
      campusId: form.campusId,
    };

    if (!commonRequest.fullName || !commonRequest.dateOfBirth) {
      setError("Full name and date of birth are required.");
      return;
    }

    if (!isEdit && (!form.studentId.trim() || !form.oracleUsername.trim())) {
      setError("Student ID and Oracle username are required.");
      return;
    }

    try {
      setSaving(true);
      setError("");

      if (isEdit) {
        await updateStudent(student.studentId, commonRequest);
      } else {
        await createStudent({
          ...commonRequest,
          studentId: form.studentId.trim().toUpperCase(),
          oracleUsername: form.oracleUsername.trim().toUpperCase(),
        });
      }

      await onSaved(isEdit ? null : form.studentId.trim().toUpperCase());
      toast.success(isEdit ? "Student updated" : "Student created", {
        description: `${form.studentId.trim().toUpperCase()} · ${commonRequest.fullName}`,
      });
      onClose();
    } catch (requestError) {
      setError(getApiErrorMessage(
        requestError,
        "Unable to save the student. Check IDs and field values.",
      ));
    } finally {
      setSaving(false);
    }
  };

  const textField = (
    label,
    key,
    {
      type = "text",
      min,
      max,
      step,
      maxLength,
      disabled = false,
      className = "",
    } = {},
  ) => (
    <label className={`space-y-2 ${className}`}>
      <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
        {label}
      </span>
      <Input
        type={type}
        min={min}
        max={max}
        step={step}
        maxLength={maxLength}
        value={form[key]}
        onChange={(event) => updateField(
          key,
          key === "phone"
            ? event.target.value.replace(/\D/g, "")
            : event.target.value,
        )}
        inputMode={key === "phone" ? "numeric" : undefined}
        pattern={key === "phone" ? "[0-9]*" : undefined}
        disabled={saving || disabled}
        className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
      />
    </label>
  );

  return (
    <Dialog
      open
      onOpenChange={(open) => {
        if (!open && !saving) onClose();
      }}
    >
      <DialogContent className="max-h-[90vh] overflow-y-auto bg-[#1e2329] text-[#eaecef] sm:!max-w-3xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <UserRoundPlus className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                {isEdit ? "Edit student" : "Create student"}
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                Student ID and Oracle username cannot be changed after creation.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="grid gap-4 sm:grid-cols-2">
          {textField("Student ID", "studentId", {
            maxLength: 20,
            disabled: isEdit,
          })}
          {!isEdit && textField("Oracle username", "oracleUsername", {
            maxLength: 128,
          })}
          {textField("Full name", "fullName", {
            maxLength: 150,
            className: isEdit ? "" : "sm:col-span-2",
          })}
          <FormSelect
            label="Gender"
            value={form.gender}
            options={selectOptions.gender}
            disabled={saving}
            onChange={(value) => updateField("gender", value)}
          />
          {textField("Date of birth", "dateOfBirth", { type: "date" })}
          {textField("Phone", "phone", { maxLength: 20 })}
          {textField("Address", "address", {
            maxLength: 500,
            className: "sm:col-span-2",
          })}
          <FormSelect
            label="Program"
            value={form.programId}
            options={selectOptions.programId}
            disabled={saving}
            onChange={(value) => updateField("programId", value)}
          />
          <FormSelect
            label="Major"
            value={form.majorId}
            options={selectOptions.majorId}
            disabled={saving}
            onChange={(value) => updateField("majorId", value)}
          />
          {textField("Accumulated credits", "accumulatedCredits", {
            type: "number",
            min: 0,
            max: 300,
          })}
          {textField("Cumulative GPA", "cumulativeGpa", {
            type: "number",
            min: 0,
            max: 10,
            step: 0.01,
          })}
          <FormSelect
            label="Campus"
            value={form.campusId}
            options={selectOptions.campusId}
            disabled={saving}
            onChange={(value) => updateField("campusId", value)}
          />
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
          <Button type="button" onClick={handleSave} disabled={saving}>
            {saving
              ? <LoadingSpinner label="Saving..." />
              : isEdit ? "Update student" : "Create student"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
