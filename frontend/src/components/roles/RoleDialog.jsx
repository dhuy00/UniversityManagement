import { useState } from "react";
import { toast } from "sonner";

import { createPgRole } from "@/api/pgRoleApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FieldGroup, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { ShieldPlus } from "lucide-react";

const ROLE_NAME_PATTERN = /^[A-Za-z][A-Za-z0-9_$#]{0,127}$/;

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const initialFormData = {
  roleCode: "",
  description: "",
};

const RoleDialog = ({ open, setOpen, onSaved }) => {
  const [formData, setFormData] = useState(initialFormData);
  const [saving, setSaving] = useState(false);

  const handleOpenChange = (nextOpen) => {
    if (!nextOpen && saving) return;
    if (!nextOpen) setFormData(initialFormData);
    setOpen(nextOpen);
  };

  const handleChange = (field) => (event) => {
    setFormData((current) => ({
      ...current,
      [field]: event.target.value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    const roleCode = formData.roleCode.trim().toUpperCase();

    if (!roleCode) {
      toast.error("Role code is required");
      return;
    }

    if (!ROLE_NAME_PATTERN.test(formData.roleCode.trim())) {
      toast.error("Invalid role code", {
        description: "Start with a letter. Use letters, numbers, _, $, # only.",
      });
      return;
    }

    try {
      setSaving(true);
      const response = await createPgRole({
        roleCode,
        description: formData.description.trim(),
      });
      if (!response.data?.success) {
        throw new Error(response.data?.message ?? "Failed to create role");
      }
      await onSaved?.();
      toast.success("Role created", { description: roleCode });
      setFormData(initialFormData);
      setOpen(false);
    } catch (error) {
      console.error(error);
      toast.error("Failed to create role", {
        description: getErrorMessage(error),
      });
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="w-[calc(100vw-2rem)] text-[13px] sm:w-[560px]">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <ShieldPlus className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg leading-tight text-white">
                Create role
              </DialogTitle>
            </div>
          </div>
        </DialogHeader>

        <form
          id="create-role-form"
          className="rounded-lg border border-[#2b3139] bg-[#0b0e11] p-5"
          onSubmit={handleSubmit}
        >
          <FieldGroup className="grid gap-5">
            <Field>
              <FieldLabel htmlFor="role-code">Role code</FieldLabel>
              <Input
                id="role-code"
                value={formData.roleCode}
                onChange={handleChange("roleCode")}
                placeholder="ROLE_CODE"
                autoComplete="off"
                disabled={saving}
                autoFocus
              />
              <p className="text-xs leading-5 text-[#929aa5]">
                Start with a letter. Use letters, numbers, _, $, # only.
              </p>
            </Field>

            <Field>
              <FieldLabel htmlFor="role-description">Description</FieldLabel>
              <Textarea
                id="role-description"
                value={formData.description}
                onChange={handleChange("description")}
                placeholder="Brief summary of the role's purpose"
                disabled={saving}
                rows={3}
              />
            </Field>
          </FieldGroup>
        </form>

        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={saving}>Cancel</Button>}
          />
          <Button
            type="submit"
            form="create-role-form"
            disabled={saving}
          >
            {saving ? <LoadingSpinner label="Creating..." /> : "Create role"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default RoleDialog;
