import { useState } from "react";
import { Building2 } from "lucide-react";
import { toast } from "sonner";

import { updateUnit } from "@/api/unitApi";
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

export default function UnitFormDialog({ unit, onClose, onSaved }) {
  const [unitName, setUnitName] = useState(unit.unitName);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const handleSave = async () => {
    const normalizedName = unitName.trim();
    if (!normalizedName) {
      setError("Unit name is required.");
      return;
    }

    try {
      setSaving(true);
      setError("");
      await updateUnit(unit.unitId, { unitName: normalizedName });
      await onSaved();
      toast.success("Unit updated", {
        description: `${unit.unitId} · ${normalizedName}`,
      });
      onClose();
    } catch (requestError) {
      setError(
        requestError.response?.data?.title || "Unable to update the unit.",
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
      <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-lg">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <Building2 className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                Edit unit
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                Unit ID and head staff remain unchanged.
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
              value={unit.unitId}
              disabled
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
              : "Update unit"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
