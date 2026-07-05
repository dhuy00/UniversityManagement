import { useEffect, useState } from "react";
import { UserCog } from "lucide-react";
import { toast } from "sonner";

import { createStaff, updateStaff } from "@/api/staffApi";
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

const options = {
  gender: ["MALE", "FEMALE", "OTHER"],
  roleCode: [
    "BASIC_STAFF",
    "LECTURER",
    "ACADEMIC_AFFAIRS",
    "UNIT_HEAD",
    "DEAN",
  ],
  campusId: ["CAMPUS_1", "CAMPUS_2"],
};

function FieldSelect({ label, value, items, disabled, onChange }) {
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
            {items.map((item) => (
              <SelectItem key={item.value ?? item} value={item.value ?? item}>
                {item.label ?? item}
              </SelectItem>
            ))}
          </SelectGroup>
        </SelectContent>
      </Select>
    </div>
  );
}

export default function StaffFormDialog({ mode, staff, onClose, onSaved }) {
  const isEdit = mode === "edit";
  const [units, setUnits] = useState(null);
  const [form, setForm] = useState({
    staffId: staff?.staffId ?? "",
    fullName: staff?.fullName ?? "",
    gender: staff?.gender ?? "MALE",
    dateOfBirth: staff?.dateOfBirth?.slice(0, 10) ?? "",
    allowance: String(staff?.allowance ?? 0),
    phone: staff?.phone ?? "",
    roleCode: staff?.roleCode ?? "BASIC_STAFF",
    unitId: staff?.unitId ?? "",
    oracleUsername: staff?.oracleUsername ?? "",
    campusId: staff?.campusId ?? "CAMPUS_1",
  });
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

  const setField = (key, value) =>
    setForm((current) => ({ ...current, [key]: value }));

  const handleSave = async () => {
    const request = {
      fullName: form.fullName.trim(),
      gender: form.gender,
      dateOfBirth: form.dateOfBirth,
      allowance: Number(form.allowance),
      phone: form.phone.trim() || null,
      roleCode: form.roleCode,
      unitId: form.unitId,
      campusId: form.campusId,
    };

    if (!request.fullName || !request.dateOfBirth || !request.unitId) {
      setError("Full name, date of birth, and unit are required.");
      return;
    }

    try {
      setSaving(true);
      setError("");
      if (isEdit) {
        await updateStaff(staff.staffId, request);
      } else {
        await createStaff({
          ...request,
          staffId: form.staffId.trim().toUpperCase(),
          oracleUsername: form.oracleUsername.trim().toUpperCase(),
        });
      }
      await onSaved(isEdit ? null : form.staffId.trim().toUpperCase());
      toast.success(isEdit ? "Staff updated" : "Staff created", {
        description: `${form.staffId.trim().toUpperCase()} · ${request.fullName}`,
      });
      onClose();
    } catch (requestError) {
      setError(getApiErrorMessage(
        requestError,
        "Unable to save staff. Check references and unique values.",
      ));
    } finally {
      setSaving(false);
    }
  };

  const input = (label, key, props = {}) => (
    <label className="space-y-2">
      <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
        {label}
      </span>
      <Input
        {...props}
        value={form[key]}
        onChange={(event) => setField(
          key,
          key === "phone"
            ? event.target.value.replace(/\D/g, "")
            : event.target.value,
        )}
        inputMode={key === "phone" ? "numeric" : undefined}
        pattern={key === "phone" ? "[0-9]*" : undefined}
        disabled={saving || props.disabled}
        className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
      />
    </label>
  );

  return (
    <Dialog open onOpenChange={(open) => !open && !saving && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto bg-[#1e2329] text-[#eaecef] sm:!max-w-3xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <UserCog className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-white">
                {isEdit ? "Edit staff" : "Create staff"}
              </DialogTitle>
              <DialogDescription className="text-[#929aa5]">
                Staff ID and Oracle username are immutable after creation.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="grid gap-4 sm:grid-cols-2">
          {input("Staff ID", "staffId", { disabled: isEdit, maxLength: 20 })}
          {input("Oracle username", "oracleUsername", {
            disabled: isEdit,
            maxLength: 128,
          })}
          {input("Full name", "fullName", { maxLength: 150 })}
          {input("Date of birth", "dateOfBirth", { type: "date" })}
          <FieldSelect
            label="Gender"
            value={form.gender}
            items={options.gender}
            disabled={saving}
            onChange={(value) => setField("gender", value)}
          />
          <FieldSelect
            label="Role"
            value={form.roleCode}
            items={options.roleCode}
            disabled={saving}
            onChange={(value) => setField("roleCode", value)}
          />
          <FieldSelect
            label="Unit"
            value={form.unitId}
            items={(units ?? []).map((unit) => ({
              value: unit.unitId,
              label: `${unit.unitId} · ${unit.unitName}`,
            }))}
            disabled={saving || units === null}
            onChange={(value) => setField("unitId", value)}
          />
          <FieldSelect
            label="Campus"
            value={form.campusId}
            items={options.campusId}
            disabled={saving}
            onChange={(value) => setField("campusId", value)}
          />
          {input("Allowance", "allowance", { type: "number", min: 0 })}
          {input("Phone", "phone", { maxLength: 20 })}
        </div>

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
            onClick={handleSave}
            disabled={saving || units === null}
          >
            {saving
              ? <LoadingSpinner label="Saving..." />
              : isEdit ? "Update staff" : "Create staff"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
