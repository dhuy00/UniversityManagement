import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogClose,
} from "@/components/ui/dialog";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "../ui/button";
import UserBasicForm from "./UserBasicForm";
import UserPrivileges from "./UserPrivileges";
import { useEffect, useState } from "react";
import { grantRoleToUser, getRoles, revokeRoleFromUser } from "@/api/roleApi";
import { updateUserStatus } from "@/api/userApi";
import UserRoleDialog from "./UserRoleDialog";

const initialPrivileges = [
  {
    tableName: "Users",
    columns: ["id", "username", "email", "phone"],
    select: true,
    selectColumns: ["id", "username"],
    update: false,
    updateColumns: [],
    delete: false,
  },
  {
    tableName: "Roles",
    columns: ["id", "name", "description"],
    select: true,
    selectColumns: ["id", "name"],
    update: true,
    updateColumns: ["name"],
    delete: false,
  },
  {
    tableName: "Permissions",
    columns: ["id", "permission_name", "resource"],
    select: false,
    selectColumns: [],
    update: false,
    updateColumns: [],
    delete: false,
  },
  {
    tableName: "Products",
    columns: ["id", "name", "price", "stock"],
    select: true,
    selectColumns: ["id", "name"],
    update: true,
    updateColumns: ["price"],
    delete: true,
  },
  {
    tableName: "Orders",
    columns: ["id", "customer_id", "total", "status"],
    select: true,
    selectColumns: ["id", "status"],
    update: false,
    updateColumns: [],
    delete: false,
  },
];

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

const getEditableStatus = (status) => {
  const normalizedStatus = status?.toUpperCase() ?? "";
  return normalizedStatus.includes("LOCKED") ? "LOCKED" : "OPEN";
};

const createInitialFormData = (user = null) => ({
  name: user?.username ?? "",
  password: "",
  confirmPassword: "",
  roles: splitRoles(user?.role),
  originalRoles: splitRoles(user?.role),
  selectedRole: "",
  status: user ? getEditableStatus(user.status) : "OPEN",

  privileges: initialPrivileges,

  commonPrivileges: {
    connect: false,
    create: false,
    temporary: false,
    execute: false,
  },
});

const UserDialog = ({ open, setOpen, mode = "create", user = null, onSaved }) => {
  const isEditMode = mode === "edit";
  const [formData, setFormData] = useState(createInitialFormData(user));
  const [roles, setRoles] = useState([]);
  const [openRoleDialog, setOpenRoleDialog] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (open) {
      setFormData(createInitialFormData(user));
    }
  }, [open, user]);

  useEffect(() => {
    if (!open) return;

    const fetchRoles = async () => {
      try {
        const res = await getRoles();
        setRoles(res.data ?? []);
      } catch (error) {
        console.error(error);
      }
    };

    fetchRoles();
  }, [open]);

  const handleSubmit = async () => {
    if (!formData.name.trim()) {
      alert("Name is required");
      return;
    }

    if (!isEditMode && !formData.password) {
      alert("Password is required");
      return;
    }

    if (formData.password && formData.password !== formData.confirmPassword) {
      alert("Passwords do not match");
      return;
    }

    const originalRoles = splitRoles(user?.role).map((role) => role.toUpperCase());
    const rolesToGrant = formData.roles.filter(
      (role) => !originalRoles.includes(role.toUpperCase()),
    );
    const selectedRoleKeys = formData.roles.map((role) => role.toUpperCase());
    const rolesToRevoke = splitRoles(user?.role).filter(
      (role) => !selectedRoleKeys.includes(role.toUpperCase()),
    );

    try {
      setSaving(true);

      if (isEditMode) {
        await Promise.all([
          updateUserStatus({
            username: formData.name,
            status: formData.status,
          }),
          ...rolesToGrant.map((role) =>
            grantRoleToUser({
              username: formData.name,
              rolename: role,
            }),
          ),
          ...rolesToRevoke.map((role) =>
            revokeRoleFromUser({
              username: formData.name,
              rolename: role,
            }),
          ),
        ]);
      } else {
        const payload = {
          username: formData.name,
          password: formData.password,
          roles: formData.roles,

          privileges: formData.privileges.map((table) => ({
            tableName: table.tableName,

            select: table.select,
            selectColumns: table.selectColumns,

            update: table.update,
            updateColumns: table.updateColumns,

            delete: table.delete,
          })),

          commonPrivileges: formData.commonPrivileges,
        };

        console.log(payload);
      }

      await onSaved?.();
      setOpen(false);
    } catch (error) {
      console.error(error);
      alert("Failed to save user changes");
    } finally {
      setSaving(false);
    }
  };

  const handleSetPrivileges = (tableName, permission, checked) => {
    setFormData((prev) => {
      const privileges = prev.privileges || [];

      const next = privileges.map((row) =>
        row.tableName === tableName
          ? {
              ...row,
              [permission]: checked,

              ...(permission === "select" && !checked
                ? { selectColumns: [] }
                : {}),

              ...(permission === "update" && !checked
                ? { updateColumns: [] }
                : {}),
            }
          : row,
      );

      return {
        ...prev,
        privileges: next,
      };
    });
  };

  const handleColumnChange = (tableName, permissionType, column, checked) => {
    setFormData((prev) => {
      const privileges = prev.privileges || [];

      const key =
        permissionType === "select" ? "selectColumns" : "updateColumns";

      const next = privileges.map((row) => {
        if (row.tableName !== tableName) return row;

        const currentList = row[key] || [];

        return {
          ...row,
          [key]: checked
            ? [...currentList, column]
            : currentList.filter((c) => c !== column),
        };
      });

      return {
        ...prev,
        privileges: next,
      };
    });
  };

  const handleSetCommonPrivileges = (commonPrivileges) => {
    setFormData((prev) => ({
      ...prev,
      commonPrivileges,
    }));
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="!max-w-none w-[500px] text-[13px]">
        <DialogHeader>
          <DialogTitle className="text-sm leading-none">
            {isEditMode ? "Edit User" : "Create User"}
          </DialogTitle>
        </DialogHeader>

        <Tabs defaultValue="basic-info">
          <TabsList>
            <TabsTrigger value="basic-info">Basic Info</TabsTrigger>
            <TabsTrigger value="privileges">Privileges</TabsTrigger>
          </TabsList>
          <UserBasicForm
            formData={formData}
            setFormData={setFormData}
            mode={mode}
            onManageRoles={() => setOpenRoleDialog(true)}
          />
          <UserPrivileges
            privileges={formData.privileges}
            setPrivileges={handleSetPrivileges}
            commonPrivileges={formData.commonPrivileges}
            setCommonPrivileges={handleSetCommonPrivileges}
            onColumnChange={handleColumnChange}
          />
        </Tabs>
        <DialogFooter>
          <DialogClose render={<Button variant="outline">Cancel</Button>} />
          <Button onClick={handleSubmit} type="submit" disabled={saving}>
            {isEditMode ? "Update user" : "Save changes"}
          </Button>
        </DialogFooter>
      </DialogContent>
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
    </Dialog>
  );
};

export default UserDialog;
