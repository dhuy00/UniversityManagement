import { useState } from "react";
import { ContactRound } from "lucide-react";
import { toast } from "sonner";

import { updateProfileContact } from "@/api/profileApi";
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

export default function ProfileContactDialog({ profile, onClose, onSaved }) {
  const isStudent = profile.identityType === "STUDENT";
  const [phone, setPhone] = useState(profile.phone ?? "");
  const [address, setAddress] = useState(profile.address ?? "");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const handleSave = async () => {
    if (phone.length > 20) {
      setError("Phone must not exceed 20 characters.");
      return;
    }
    if (isStudent && address.length > 500) {
      setError("Address must not exceed 500 characters.");
      return;
    }

    try {
      setSaving(true);
      setError("");
      const request = {
        phone: phone.trim() || null,
        address: isStudent ? address.trim() || null : null,
      };
      await updateProfileContact(request);
      onSaved(request);
      toast.success("Contact information updated");
      onClose();
    } catch (requestError) {
      setError(
        requestError.response?.data?.title ||
        "Unable to update contact information.",
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
      <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <ContactRound className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                Edit contact information
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                {isStudent
                  ? "Students may update their address and phone."
                  : "Staff may update their phone number."}
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <label className="space-y-2">
          <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
            Phone
          </span>
          <Input
            value={phone}
            onChange={(event) => setPhone(event.target.value)}
            maxLength={20}
            disabled={saving}
            className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
          />
        </label>

        {isStudent && (
          <label className="space-y-2">
            <span className="text-xs font-semibold uppercase tracking-[0.1em] text-[#929aa5]">
              Address
            </span>
            <textarea
              value={address}
              onChange={(event) => setAddress(event.target.value)}
              maxLength={500}
              rows={4}
              disabled={saving}
              className="w-full resize-y rounded-md border border-[#3f4650] bg-[#0b0e11] px-4 py-3 text-sm text-[#eaecef] outline-none focus:border-[#fcd535] disabled:opacity-60"
            />
          </label>
        )}

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
            {saving ? <LoadingSpinner label="Saving..." /> : "Save changes"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
