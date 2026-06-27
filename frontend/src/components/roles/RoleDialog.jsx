import { useState } from "react";
import { toast } from "sonner";

import { createRole } from "@/api/roleApi";
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

const ROLE_NAME_PATTERN = /^[A-Za-z][A-Za-z0-9_$#]{0,127}$/;

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const initialFormData = {
  roleName: "",
  password: "",
  confirmPassword: "",
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

    const roleName = formData.roleName.trim().toUpperCase();

    if (!roleName) {
      toast.error("Role name is required");
      return;
    }

    if (!ROLE_NAME_PATTERN.test(formData.roleName.trim())) {
      toast.error("Invalid role name", {
        description: "Start with a letter. Use letters, numbers, _, $, # only.",
      });
      return;
    }

    if (!formData.password) {
      toast.error("Password is required");
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      toast.error("Passwords do not match");
      return;
    }

    try {
      setSaving(true);
      await createRole({
        rolename: roleName,
        password: formData.password,
      });
      await onSaved?.();
      toast.success("Role created", { description: roleName });
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
      <DialogContent className="w-[calc(100vw-2rem)] text-[13px] sm:w-[520px]">
        <DialogHeader>
          <DialogTitle className="text-sm leading-none">Create Role</DialogTitle>
        </DialogHeader>

        <form id="create-role-form" onSubmit={handleSubmit}>
          <FieldGroup>
            <Field>
              <FieldLabel htmlFor="role-name">Role name</FieldLabel>
              <Input
                id="role-name"
                value={formData.roleName}
                onChange={handleChange("roleName")}
                placeholder="ROLE_NAME"
                autoComplete="off"
                disabled={saving}
                autoFocus
              />
              <p className="text-xs text-slate-500">
                Start with a letter. Use letters, numbers, _, $, # only.
              </p>
            </Field>

            <Field>
              <FieldLabel htmlFor="role-password">Password</FieldLabel>
              <Input
                id="role-password"
                type="password"
                value={formData.password}
                onChange={handleChange("password")}
                autoComplete="new-password"
                disabled={saving}
              />
            </Field>

            <Field>
              <FieldLabel htmlFor="role-confirm-password">
                Confirm password
              </FieldLabel>
              <Input
                id="role-confirm-password"
                type="password"
                value={formData.confirmPassword}
                onChange={handleChange("confirmPassword")}
                autoComplete="new-password"
                disabled={saving}
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
