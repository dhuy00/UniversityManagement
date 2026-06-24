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
import {
  createUser,
  getUserPrivileges,
  updateUserPassword,
  updateUserStatus,
} from "@/api/userApi";
import {
  getSystemPrivileges,
  getTables,
  grantPermission,
  grantSystemPrivilege,
} from "@/api/permissionApi";
import UserRoleDialog from "./UserRoleDialog";
import { toast } from "sonner";

const initialPrivileges = [];

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

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const USERNAME_PATTERN = /^[A-Za-z][A-Za-z0-9_$#]{0,127}$/;

const buildTablePermissionRequests = (privileges, username) => {
  return privileges.flatMap((row) => {
    const requests = [];

    if (row.select) {
      requests.push({
        permission_type: "SELECT",
        table_name: row.tableName,
        target: username,
        is_grant_option: 0,
        list_column: row.selectColumns,
      });
    }

    if (row.insert) {
      requests.push({
        permission_type: "INSERT",
        table_name: row.tableName,
        target: username,
        is_grant_option: 0,
        list_column: [],
      });
    }

    if (row.update) {
      requests.push({
        permission_type: "UPDATE",
        table_name: row.tableName,
        target: username,
        is_grant_option: 0,
        list_column: row.updateColumns,
      });
    }

    if (row.delete) {
      requests.push({
        permission_type: "DELETE",
        table_name: row.tableName,
        target: username,
        is_grant_option: 0,
        list_column: [],
      });
    }

    return requests;
  });
};

const normalizePrivilegeName = (privilege) =>
  privilege?.toUpperCase().replaceAll(" ", "_") ?? "";

const getPrivilegeField = (privilege, camelName, pascalName = camelName) =>
  privilege?.[camelName] ?? privilege?.[pascalName] ?? "";

const buildPrivilegeState = (tables, userPrivileges = []) => {
  const tablePrivileges = userPrivileges.filter(
    (privilege) => privilege.privilegeType === "TABLE" || privilege.PrivilegeType === "TABLE",
  );
  const columnPrivileges = userPrivileges.filter(
    (privilege) => privilege.privilegeType === "COLUMN" || privilege.PrivilegeType === "COLUMN",
  );

  return (tables ?? []).map((table) => {
    const tableName = `${table.owner}.${table.tableName}`;
    const matches = tablePrivileges.filter(
      (privilege) =>
        getPrivilegeField(privilege, "owner", "Owner") === table.owner &&
        getPrivilegeField(privilege, "tableName", "TableName") === table.tableName,
    );
    const columnMatches = columnPrivileges.filter(
      (privilege) =>
        getPrivilegeField(privilege, "owner", "Owner") === table.owner &&
        getPrivilegeField(privilege, "tableName", "TableName") === table.tableName,
    );

    const hasPrivilege = (privilegeName) =>
      matches.some(
        (privilege) =>
          getPrivilegeField(privilege, "privilege", "Privilege").toUpperCase() === privilegeName,
      );
    const getPrivilegeColumns = (privilegeName) =>
      columnMatches
        .filter(
          (privilege) =>
            getPrivilegeField(privilege, "privilege", "Privilege").toUpperCase() === privilegeName,
        )
        .map((privilege) => getPrivilegeField(privilege, "columnName", "ColumnName"))
        .filter(Boolean);

    const selectColumns = hasPrivilege("SELECT")
      ? table.columns ?? []
      : getPrivilegeColumns("SELECT");
    const updateColumns = hasPrivilege("UPDATE")
      ? table.columns ?? []
      : getPrivilegeColumns("UPDATE");

    return {
      tableName,
      columns: table.columns ?? [],
      select: hasPrivilege("SELECT") || selectColumns.length > 0,
      selectColumns,
      update: hasPrivilege("UPDATE") || updateColumns.length > 0,
      updateColumns,
      insert: hasPrivilege("INSERT"),
      delete: hasPrivilege("DELETE"),
    };
  });
};

const buildCommonPrivilegeState = (systemPrivileges, userPrivileges = []) => {
  const grantedSystemPrivileges = new Set(
    userPrivileges
      .filter((privilege) => privilege.privilegeType === "SYSTEM" || privilege.PrivilegeType === "SYSTEM")
      .map((privilege) =>
        normalizePrivilegeName(getPrivilegeField(privilege, "privilege", "Privilege")),
      ),
  );

  return Object.fromEntries(
    (systemPrivileges ?? []).map((privilege) => [
      privilege,
      grantedSystemPrivileges.has(privilege),
    ]),
  );
};

const createInitialFormData = (user = null) => ({
  name: user?.username ?? "",
  password: "",
  confirmPassword: "",
  roles: splitRoles(user?.role),
  originalRoles: splitRoles(user?.role),
  selectedRole: "",
  status: user ? getEditableStatus(user.status) : "LOCKED",

  privileges: initialPrivileges,

  commonPrivileges: {
  },
});

const UserDialog = ({ open, setOpen, mode = "create", user = null, onSaved }) => {
  const isEditMode = mode === "edit";
  const [formData, setFormData] = useState(createInitialFormData(user));
  const [roles, setRoles] = useState([]);
  const [systemPrivileges, setSystemPrivileges] = useState([]);
  const [openRoleDialog, setOpenRoleDialog] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (open) {
      setFormData(createInitialFormData(user));
    }
  }, [open, user]);

  useEffect(() => {
    if (!open) return;

    const fetchDialogData = async () => {
      try {
        const [rolesRes, tablesRes, systemPrivilegesRes, userPrivilegesRes] = await Promise.all([
          getRoles(),
          getTables(),
          getSystemPrivileges(),
          isEditMode && user?.username
            ? getUserPrivileges(user.username)
            : Promise.resolve({ data: [] }),
        ]);

        setRoles(rolesRes.data ?? []);
        setSystemPrivileges(systemPrivilegesRes.data ?? []);
        setFormData((prev) => ({
          ...prev,
          privileges: buildPrivilegeState(
            tablesRes.data ?? [],
            userPrivilegesRes.data ?? [],
          ),
          commonPrivileges: buildCommonPrivilegeState(
            systemPrivilegesRes.data ?? [],
            userPrivilegesRes.data ?? [],
          ),
        }));
      } catch (error) {
        console.error(error);
        toast.error("Failed to load user form data", {
          description: getErrorMessage(error),
        });
      }
    };

    fetchDialogData();
  }, [open]);

  const handleSubmit = async () => {
    const username = formData.name.trim().toUpperCase();

    if (!username) {
      toast.error("Username is required");
      return;
    }

    if (!USERNAME_PATTERN.test(formData.name.trim())) {
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

    const originalRoles = splitRoles(user?.role).map((role) => role.toUpperCase());
    const rolesToGrant = formData.roles.filter(
      (role) => !originalRoles.includes(role.toUpperCase()),
    );
    const selectedRoleKeys = formData.roles.map((role) => role.toUpperCase());
    const rolesToRevoke = splitRoles(user?.role).filter(
      (role) => !selectedRoleKeys.includes(role.toUpperCase()),
    );
    const tablePermissionRequests = buildTablePermissionRequests(
      formData.privileges,
      username,
    );
    const systemPrivilegeRequests = Object.entries(formData.commonPrivileges)
      .filter(([, checked]) => checked)
      .map(([privilegeName]) => ({
        privilegeName,
        target: username,
      }));

    try {
      setSaving(true);

      if (isEditMode) {
        await Promise.all([
          updateUserStatus({
            username,
            status: formData.status,
          }),
          ...(formData.password
            ? [
                updateUserPassword({
                  username,
                  password: formData.password,
                }),
              ]
            : []),
          ...rolesToGrant.map((role) =>
            grantRoleToUser({
              username,
              rolename: role,
            }),
          ),
          ...rolesToRevoke.map((role) =>
            revokeRoleFromUser({
              username,
              rolename: role,
            }),
          ),
          ...tablePermissionRequests.map((request) =>
            grantPermission(request),
          ),
          ...systemPrivilegeRequests.map((request) =>
            grantSystemPrivilege(request),
          ),
        ]);
      } else {
        await createUser({
          username,
          password: formData.password,
        });

        await Promise.all([
          updateUserStatus({
            username,
            status: formData.status,
          }),
          ...formData.roles.map((role) =>
            grantRoleToUser({
              username,
              rolename: role,
            }),
          ),
          ...tablePermissionRequests.map((request) =>
            grantPermission(request),
          ),
          ...systemPrivilegeRequests.map((request) =>
            grantSystemPrivilege(request),
          ),
        ]);
      }

      await onSaved?.();
      toast.success(isEditMode ? "User updated" : "User created", {
        description: username,
      });
      setOpen(false);
    } catch (error) {
      console.error(error);
      toast.error("Failed to save user changes", {
        description: getErrorMessage(error),
      });
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
      commonPrivileges:
        typeof commonPrivileges === "function"
          ? commonPrivileges(prev.commonPrivileges)
          : commonPrivileges,
    }));
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="!max-w-none w-[calc(100vw-2rem)] sm:w-[860px] max-h-[calc(100vh-2rem)] overflow-hidden text-[13px]">
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
            systemPrivileges={systemPrivileges}
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
