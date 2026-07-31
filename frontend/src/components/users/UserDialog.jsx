import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogClose,
} from "@/components/ui/dialog";
import { Button } from "../ui/button";
import UserBasicForm from "./UserBasicForm";
import { useCallback, useEffect, useState } from "react";
import { getPgRoles } from "@/api/pgRoleApi";
import UserRoleDialog from "./UserRoleDialog";
import { toast } from "sonner";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import { UserRoundCog, UserRoundPlus } from "lucide-react";

const USERNAME_PATTERN = /^[A-Za-z][A-Za-z0-9_$#]{0,127}$/;

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const splitRoles = (role) => {
  if (!role || role === "No Role") return [];

  if (Array.isArray(role)) {
    return role.filter(Boolean);
  }

  return role
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
};

const createInitialFormData = (user = null) => ({
  username: user?.username ?? "",
  password: "",
  confirmPassword: "",
  roles: splitRoles(user?.role),
  originalRoles: splitRoles(user?.role),
  status: user?.status?.toUpperCase() === "OPEN" ? "OPEN" : "EXPIRED",
});

const UserDialog = ({
  open,
  setOpen,
  mode = "create",
  user = null,
  onSaved,
  onSave,
}) => {
  const isEditMode = mode === "edit";
  const [formData, setFormData] = useState(createInitialFormData(user));
  const [roles, setRoles] = useState([]);
  const [openRoleDialog, setOpenRoleDialog] = useState(false);
  const [saving, setSaving] = useState(false);
  const [loadingRoles, setLoadingRoles] = useState(true);

  useEffect(() => {
    if (!open) return;

    let cancelled = false;

    const loadRoles = async () => {
      try {
        const res = await getPgRoles();
        if (cancelled) return;
        setRoles(res.data ?? []);
      } catch (error) {
        if (cancelled) return;
        console.error(error);
        toast.error("Failed to load roles", {
          description: getErrorMessage(error),
        });
      } finally {
        if (!cancelled) setLoadingRoles(false);
      }
    };

    loadRoles();
    return () => {
      cancelled = true;
    };
  }, [open]);

  const handleSubmit = async () => {
    const username = formData.username.trim().toUpperCase();

    if (!username) {
      toast.error("Username is required");
      return;
    }

    if (!USERNAME_PATTERN.test(formData.username.trim())) {
      toast.error("Invalid username", {
        description: "Start with a letter. Use letters, numbers, _, $, # only.",
      });
      return;
    }

    if (!isEditMode && !formData.password) {
      toast.error("Password is required");
      return;
    }

    if (formData.password && formData.password !== formData.confirmPassword) {
      toast.error("Passwords do not match");
      return;
    }

    try {
      setSaving(true);

      await onSave?.({
        username,
        password: formData.password,
        roles: formData.roles,
        originalRoles: formData.originalRoles,
        status: formData.status,
        isEdit: isEditMode,
      });

      await onSaved?.();
      toast.success(isEditMode ? "User updated" : "User created", {
        description: username,
      });
      handleDialogOpenChange(false);
    } catch (error) {
      console.error(error);
      toast.error("Failed to save user", {
        description: getErrorMessage(error),
      });
    } finally {
      setSaving(false);
    }
  };

  const handleDialogOpenChange = useCallback(
    (nextOpen) => {
      if (!nextOpen && saving) return;
      if (!nextOpen) {
        setFormData(createInitialFormData(user));
      }
      setOpen(nextOpen);
    },
    [saving, setOpen, user],
  );

  return (
    <Dialog open={open} onOpenChange={handleDialogOpenChange}>
      <DialogContent className="max-h-[calc(100vh-2rem)] w-[calc(100vw-2rem)] !max-w-none overflow-hidden text-[13px] sm:w-[640px]">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              {isEditMode ? (
                <UserRoundCog className="size-5" />
              ) : (
                <UserRoundPlus className="size-5" />
              )}
            </div>
            <div>
              <DialogTitle className="text-lg leading-tight text-white">
                {isEditMode ? "Edit user" : "Create user"}
              </DialogTitle>
            </div>
          </div>
        </DialogHeader>

        {loadingRoles && (
          <div className="rounded-md border border-[#f0b90b]/30 bg-[#fcd535]/15 px-3 py-2 text-[#181a20]">
            <LoadingSpinner label="Loading roles..." />
          </div>
        )}

        <div className={saving ? "pointer-events-none opacity-70" : undefined}>
          <UserBasicForm
            formData={formData}
            setFormData={setFormData}
            mode={mode}
            disabled={loadingRoles || saving}
            onManageRoles={() => setOpenRoleDialog(true)}
          />
        </div>

        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={saving}>Cancel</Button>}
          />
          <Button
            onClick={handleSubmit}
            type="submit"
            disabled={loadingRoles || saving}
          >
            {saving ? (
              <LoadingSpinner label={isEditMode ? "Updating..." : "Saving..."} />
            ) : isEditMode ? (
              "Update user"
            ) : (
              "Save changes"
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
      {openRoleDialog && (
        <UserRoleDialog
          open={openRoleDialog}
          setOpen={setOpenRoleDialog}
          availableRoles={roles}
          selectedRoles={formData.roles}
          onApply={(nextRoles) =>
            setFormData((prev) => ({
              ...prev,
              roles: nextRoles,
            }))
          }
        />
      )}
    </Dialog>
  );
};

export default UserDialog;
