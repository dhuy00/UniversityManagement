import { useState } from "react";
import { Building2 } from "lucide-react";
import { toast } from "sonner";

import { createUnit, updateUnit } from "@/api/unitApi";
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

export default function UnitFormDialog({ mode, unit, onClose, onSaved }) {
  const isEdit = mode === "edit";
  const [unitId, setUnitId] = useState(unit?.unitId ?? "");
  const [unitName, setUnitName] = useState(unit?.unitName ?? "");
  const [headStaffId, setHeadStaffId] = useState(unit?.headStaffId ?? "");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const handleSave = async () => {
    const normalizedId = unitId.trim().toUpperCase();
    const normalizedName = unitName.trim();
    if (!normalizedId || !normalizedName) {
      setError("Unit ID and unit name are required.");
      return;
    }

    try {
      setSaving(true);
      setError("");
      if (isEdit) {
        await updateUnit(unit.unitId, {
          unitName: normalizedName,
          headStaffId: headStaffId.trim().toUpperCase() || null,
        });
      } else {
        await createUnit({
          unitId: normalizedId,
          unitName: normalizedName,
          headStaffId: headStaffId.trim().toUpperCase() || null,
        });
      }
      await onSaved(isEdit ? null : normalizedId);
      toast.success(isEdit ? "Unit updated" : "Unit created", {
        description: `${normalizedId} · ${normalizedName}`,
      });
      onClose();
    } catch (requestError) {
      setError(getApiErrorMessage(
        requestError,
        "Unable to save the unit. Check its ID and head staff.",
      ));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open onOpenChange={(open) => !open && !saving && onClose()}>
      <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-lg">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <Building2 className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                {isEdit ? "Edit unit" : "Create unit"}
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                A selected head is reassigned to this unit atomically.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="grid gap-4 sm:grid-cols-2">
          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Unit ID
            </span>
            <Input
              value={unitId}
              onChange={(event) => setUnitId(event.target.value)}
              disabled={saving || isEdit}
              maxLength={20}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>
          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Unit name
            </span>
            <Input
              value={unitName}
              onChange={(event) => setUnitName(event.target.value)}
              disabled={saving}
              maxLength={150}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>
          <label className="space-y-2 sm:col-span-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Head staff ID
            </span>
            <Input
              value={headStaffId}
              onChange={(event) => setHeadStaffId(event.target.value)}
              disabled={saving}
              maxLength={20}
              placeholder={isEdit
                ? "Optional; staff must belong to this unit"
                : "Optional; selected head will move to this unit"}
              className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
            />
          </label>
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
          <Button type="button" onClick={handleSave} disabled={saving}>
            {saving
              ? <LoadingSpinner label="Saving..." />
              : isEdit ? "Update unit" : "Create unit"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
