import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

import {
  assignPgPermission,
  getPgPermissions,
  getPgPermissionsByRole,
  revokePgPermission,
} from "@/api/pgPermissionApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { ShieldCheck } from "lucide-react";

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const RoleEditDialog = ({ open, setOpen, role, onSaved }) => {
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);
  const [saving, setSaving] = useState(false);
  const [allPermissions, setAllPermissions] = useState([]);
  const [selectedPermissions, setSelectedPermissions] = useState(new Set());
  const [initialPermissions, setInitialPermissions] = useState(new Set());
  const [description, setDescription] = useState("");

  const roleCode = role?.role ?? "";

  useEffect(() => {
    if (!open || !roleCode) return;

    let cancelled = false;

    const loadData = async () => {
      try {
        const [allResponse, roleResponse] = await Promise.all([
          getPgPermissions(),
          getPgPermissionsByRole(roleCode),
        ]);

        if (cancelled) return;

        const permissions = allResponse.data ?? [];
        const rolePermissions = new Set(
          (roleResponse.data ?? []).map((p) => p.permissionCode),
        );

        setAllPermissions(permissions);
        setSelectedPermissions(rolePermissions);
        setInitialPermissions(rolePermissions);
        setDescription(role?.description ?? "");
        setLoadError(false);
      } catch (error) {
        if (cancelled) return;
        setLoadError(true);
        console.error(error);
        toast.error("Failed to load role permissions", {
          description: getErrorMessage(error),
        });
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    loadData();
    return () => {
      cancelled = true;
    };
  }, [open, roleCode, role?.description]);

  const handleOpenChange = useCallback(
    (nextOpen) => {
      if (!nextOpen && saving) return;
      if (!nextOpen) {
        setLoading(true);
        setLoadError(false);
        setSelectedPermissions(new Set());
        setInitialPermissions(new Set());
        setAllPermissions([]);
        setDescription("");
      }
      setOpen(nextOpen);
    },
    [saving, setOpen],
  );

  const handleTogglePermission = useCallback((permissionCode, checked) => {
    setSelectedPermissions((current) => {
      const next = new Set(current);
      if (checked) {
        next.add(permissionCode);
      } else {
        next.delete(permissionCode);
      }
      return next;
    });
  }, []);

  const handleSubmit = async () => {
    if (loadError) {
      toast.error("Role data is not available", {
        description: "Close and reopen the dialog to retry.",
      });
      return;
    }

    const toGrant = [...selectedPermissions].filter(
      (p) => !initialPermissions.has(p),
    );
    const toRevoke = [...initialPermissions].filter(
      (p) => !selectedPermissions.has(p),
    );

    if (toGrant.length === 0 && toRevoke.length === 0) {
      toast.info("No permission changes to save");
      return;
    }

    try {
      setSaving(true);

      for (const permissionCode of toGrant) {
        await assignPgPermission({
          roleCode,
          permissionCode,
        });
      }

      for (const permissionCode of toRevoke) {
        await revokePgPermission({
          roleCode,
          permissionCode,
        });
      }

      await onSaved?.();
      toast.success("Role updated", { description: roleCode });
      handleOpenChange(false);
    } catch (error) {
      console.error(error);
      toast.error("Failed to update role", {
        description: `${getErrorMessage(error)}. Reopen the dialog before retrying.`,
      });
    } finally {
      setSaving(false);
    }
  };

  // Group permissions by their category prefix (e.g., "USER_" -> "USER", "ROLE_" -> "ROLE")
  const groupedPermissions = allPermissions.reduce((groups, permission) => {
    const parts = permission.permissionCode.split("_");
    const category = parts.length > 1 ? parts[0] : "OTHER";
    if (!groups[category]) {
      groups[category] = [];
    }
    groups[category].push(permission);
    return groups;
  }, {});

  const sortedCategories = Object.keys(groupedPermissions).sort();

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-h-[calc(100vh-2rem)] w-[calc(100vw-2rem)] !max-w-none overflow-hidden text-[13px] sm:w-[720px]">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <ShieldCheck className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg leading-tight text-white">
                Edit role
              </DialogTitle>
            </div>
          </div>
        </DialogHeader>

        {loading && (
          <div className="rounded-md border border-[#f0b90b]/30 bg-[#fcd535]/15 px-3 py-2 text-[#181a20]">
            <LoadingSpinner label="Loading role data..." />
          </div>
        )}
        {loadError && (
          <div
            role="alert"
            className="rounded-md border border-[#3f4650] bg-[#2b3139] px-3 py-2 text-[#eaecef]"
          >
            Role data could not be loaded. Close and reopen the dialog to retry.
          </div>
        )}

        <div
          className={
            saving ? "pointer-events-none opacity-70" : undefined
          }
        >
          <div className="max-h-[calc(100vh-300px)] overflow-y-auto rounded-lg border border-[#2b3139] bg-[#0b0e11] p-5">
            <Field className="mb-5">
              <FieldLabel htmlFor="edit-role-code">Role code</FieldLabel>
              <Input id="edit-role-code" value={roleCode} disabled />
            </Field>

            {!loading && !loadError && (
              <>
                <div className="mb-4 flex items-center justify-between">
                  <FieldLabel>Permissions</FieldLabel>
                  <span className="text-xs text-[#707a8a]">
                    {selectedPermissions.size} of {allPermissions.length} selected
                  </span>
                </div>

                {allPermissions.length === 0 ? (
                  <p className="py-4 text-center text-sm text-[#707a8a]">
                    No permissions available
                  </p>
                ) : (
                  <div className="space-y-4">
                    {sortedCategories.map((category) => (
                      <div key={category}>
                        <div className="mb-2 flex items-center gap-2">
                          <span className="text-xs font-semibold uppercase tracking-wider text-[#fcd535]">
                            {category}
                          </span>
                          <div className="h-px flex-1 bg-[#2b3139]" />
                        </div>
                        <div className="grid gap-2 pl-2">
                          {groupedPermissions[category]
                            .sort((a, b) =>
                              a.permissionCode.localeCompare(b.permissionCode),
                            )
                            .map((permission) => {
                              const isSelected = selectedPermissions.has(
                                permission.permissionCode,
                              );
                              return (
                                <label
                                  key={permission.permissionCode}
                                  className="flex cursor-pointer items-start gap-3 rounded-md px-2 py-2 hover:bg-[#1e2329]"
                                >
                                  <Checkbox
                                    checked={isSelected}
                                    onCheckedChange={(checked) =>
                                      handleTogglePermission(
                                        permission.permissionCode,
                                        !!checked,
                                      )
                                    }
                                    className="mt-0.5 shrink-0"
                                  />
                                  <div className="min-w-0 flex-1">
                                    <span className="font-medium text-white">
                                      {permission.permissionCode}
                                    </span>
                                    {permission.permissionDescription && (
                                      <p className="mt-0.5 text-xs text-[#707a8a]">
                                        {permission.permissionDescription}
                                      </p>
                                    )}
                                  </div>
                                </label>
                              );
                            })}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </>
            )}
          </div>
        </div>

        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={saving}>Cancel</Button>}
          />
          <Button
            onClick={handleSubmit}
            disabled={loading || loadError || saving}
          >
            {saving ? (
              <LoadingSpinner label="Updating..." />
            ) : (
              "Update role"
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default RoleEditDialog;
