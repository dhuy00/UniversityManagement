import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

import {
  getRolePrivileges,
  revokeRolePrivileges,
  updateRolePassword,
} from "@/api/roleApi";
import {
  getSystemPrivileges,
  getTables,
  grantPermission,
  grantSystemPrivilege,
} from "@/api/permissionApi";
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
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import UserPrivileges from "@/components/users/UserPrivileges";

const emptyPrivilegeState = {
  privileges: [],
  commonPrivileges: {},
};

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const getField = (item, camelName, pascalName = camelName) =>
  item?.[camelName] ?? item?.[pascalName] ?? "";

const normalizePrivilegeName = (privilege) =>
  privilege?.toUpperCase().replaceAll(" ", "_") ?? "";

const buildPrivilegeState = (tables, rolePrivileges) => {
  const privilegesByTable = new Map();

  rolePrivileges.forEach((privilege) => {
    const type = getField(
      privilege,
      "privilegeType",
      "PrivilegeType",
    ).toUpperCase();
    if (type !== "TABLE" && type !== "COLUMN") return;

    const key = `${getField(privilege, "owner", "Owner")}.${getField(
      privilege,
      "tableName",
      "TableName",
    )}`;
    const current = privilegesByTable.get(key) ?? { table: [], column: [] };
    current[type.toLowerCase()].push(privilege);
    privilegesByTable.set(key, current);
  });

  return tables.map((table) => {
    const tableName = `${table.owner}.${table.tableName}`;
    const matches = privilegesByTable.get(tableName) ?? {
      table: [],
      column: [],
    };
    const hasTablePrivilege = (name) =>
      matches.table.some(
        (item) =>
          getField(item, "privilege", "Privilege").toUpperCase() === name,
      );
    const getColumns = (name) =>
      matches.column
        .filter(
          (item) =>
            getField(item, "privilege", "Privilege").toUpperCase() === name,
        )
        .map((item) => getField(item, "columnName", "ColumnName"))
        .filter(Boolean);

    const selectColumns = hasTablePrivilege("SELECT")
      ? table.columns ?? []
      : getColumns("SELECT");
    const updateColumns = hasTablePrivilege("UPDATE")
      ? table.columns ?? []
      : getColumns("UPDATE");

    return {
      tableName,
      columns: table.columns ?? [],
      select: hasTablePrivilege("SELECT") || selectColumns.length > 0,
      selectColumns,
      insert: hasTablePrivilege("INSERT"),
      update: hasTablePrivilege("UPDATE") || updateColumns.length > 0,
      updateColumns,
      delete: hasTablePrivilege("DELETE"),
    };
  });
};

const buildCommonPrivilegeState = (systemPrivileges, rolePrivileges) => {
  const granted = new Set(
    rolePrivileges
      .filter(
        (item) =>
          getField(item, "privilegeType", "PrivilegeType").toUpperCase() ===
          "SYSTEM",
      )
      .map((item) =>
        normalizePrivilegeName(getField(item, "privilege", "Privilege")),
      ),
  );

  return Object.fromEntries(
    systemPrivileges.map((privilege) => [
      privilege,
      granted.has(normalizePrivilegeName(privilege)),
    ]),
  );
};

const sameColumns = (left = [], right = []) =>
  left.length === right.length &&
  left.every((column) => right.includes(column));

const buildPermissionChanges = (initialState, nextState, roleName) => {
  const initialRows = new Map(
    initialState.privileges.map((row) => [row.tableName, row]),
  );
  const grants = [];
  const revokes = [];

  nextState.privileges.forEach((row) => {
    const initial = initialRows.get(row.tableName) ?? {};

    ["select", "insert", "update", "delete"].forEach((permission) => {
      const columnKey =
        permission === "select"
          ? "selectColumns"
          : permission === "update"
            ? "updateColumns"
            : null;
      const changed =
        !!initial[permission] !== !!row[permission] ||
        (columnKey &&
          row[permission] &&
          !sameColumns(initial[columnKey], row[columnKey]));

      if (!changed) return;

      if (initial[permission]) {
        revokes.push({
          rolename: roleName,
          table_name: row.tableName,
          privilege: [permission.toUpperCase()],
        });
      }

      if (row[permission]) {
        grants.push({
          permission_type: permission.toUpperCase(),
          table_name: row.tableName,
          target: roleName,
          is_grant_option: 0,
          list_column: columnKey ? row[columnKey] : [],
        });
      }
    });
  });

  const systemPrivilegeNames = new Set([
    ...Object.keys(initialState.commonPrivileges),
    ...Object.keys(nextState.commonPrivileges),
  ]);

  systemPrivilegeNames.forEach((privilegeName) => {
    const wasGranted = !!initialState.commonPrivileges[privilegeName];
    const isGranted = !!nextState.commonPrivileges[privilegeName];
    if (wasGranted === isGranted) return;

    if (wasGranted) {
      revokes.push({
        rolename: roleName,
        table_name: "",
        privilege: [privilegeName.replaceAll("_", " ")],
      });
    } else {
      grants.push({
        privilegeName,
        target: roleName,
        system: true,
      });
    }
  });

  return { grants, revokes };
};

const RoleEditDialog = ({ open, setOpen, role, onSaved }) => {
  const [activeTab, setActiveTab] = useState("basic-info");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [systemPrivileges, setSystemPrivileges] = useState([]);
  const [privilegeState, setPrivilegeState] = useState(emptyPrivilegeState);
  const [initialState, setInitialState] = useState(emptyPrivilegeState);
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const roleName = role?.role ?? "";

  useEffect(() => {
    if (!open || !roleName) return;

    let cancelled = false;

    Promise.all([
      getTables(),
      getSystemPrivileges(),
      getRolePrivileges(roleName),
    ])
      .then(([tablesResponse, systemResponse, rolePrivilegesResponse]) => {
        if (cancelled) return;

        const rolePrivileges = rolePrivilegesResponse.data ?? [];
        const nextState = {
          privileges: buildPrivilegeState(
            tablesResponse.data ?? [],
            rolePrivileges,
          ),
          commonPrivileges: buildCommonPrivilegeState(
            systemResponse.data ?? [],
            rolePrivileges,
          ),
        };

        setSystemPrivileges(systemResponse.data ?? []);
        setPrivilegeState(nextState);
        setInitialState(nextState);
      })
      .catch((error) => {
        if (cancelled) return;
        console.error(error);
        toast.error("Failed to load role privileges", {
          description: getErrorMessage(error),
        });
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [open, roleName]);

  const handleOpenChange = useCallback(
    (nextOpen) => {
      if (!nextOpen && saving) return;
      if (!nextOpen) {
        setActiveTab("basic-info");
        setLoading(true);
        setPrivilegeState(emptyPrivilegeState);
        setInitialState(emptyPrivilegeState);
        setPassword("");
        setConfirmPassword("");
      }
      setOpen(nextOpen);
    },
    [saving, setOpen],
  );

  const handleSetPrivileges = useCallback((tableName, permission, checked) => {
    setPrivilegeState((current) => ({
      ...current,
      privileges: current.privileges.map((row) =>
        row.tableName === tableName
          ? {
              ...row,
              [permission]: checked,
              ...(permission === "select"
                ? { selectColumns: checked ? row.columns : [] }
                : {}),
              ...(permission === "update"
                ? { updateColumns: checked ? row.columns : [] }
                : {}),
            }
          : row,
      ),
    }));
  }, []);

  const handleColumnChange = useCallback(
    (tableName, permission, column, checked) => {
      const key =
        permission === "select" ? "selectColumns" : "updateColumns";

      setPrivilegeState((current) => ({
        ...current,
        privileges: current.privileges.map((row) => {
          if (row.tableName !== tableName) return row;
          const columns = row[key] ?? [];
          return {
            ...row,
            [key]: checked
              ? [...columns, column]
              : columns.filter((item) => item !== column),
          };
        }),
      }));
    },
    [],
  );

  const handleSetCommonPrivileges = useCallback((value) => {
    setPrivilegeState((current) => ({
      ...current,
      commonPrivileges:
        typeof value === "function"
          ? value(current.commonPrivileges)
          : value,
    }));
  }, []);

  const handleSubmit = async () => {
    if (password && password !== confirmPassword) {
      toast.error("Passwords do not match");
      return;
    }

    const { grants, revokes } = buildPermissionChanges(
      initialState,
      privilegeState,
      roleName,
    );

    try {
      setSaving(true);

      await Promise.all(revokes.map(revokeRolePrivileges));
      await Promise.all(
        grants.map((request) =>
          request.system
            ? grantSystemPrivilege({
                privilegeName: request.privilegeName,
                target: request.target,
              })
            : grantPermission(request),
        ),
      );
      if (password) {
        await updateRolePassword({
          rolename: roleName,
          password,
        });
      }

      await onSaved?.();
      toast.success("Role updated", { description: roleName });
      handleOpenChange(false);
    } catch (error) {
      console.error(error);
      toast.error("Failed to update role", {
        description: getErrorMessage(error),
      });
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-h-[calc(100vh-2rem)] w-[calc(100vw-2rem)] !max-w-none overflow-hidden text-[13px] sm:w-[860px]">
        <DialogHeader>
          <DialogTitle className="text-sm leading-none">Edit Role</DialogTitle>
        </DialogHeader>

        {loading && (
          <div className="rounded-md border border-blue-100 bg-blue-50 px-3 py-2 text-blue-700">
            <LoadingSpinner label="Loading role data..." />
          </div>
        )}

        <Tabs
          value={activeTab}
          onValueChange={setActiveTab}
          className={saving ? "pointer-events-none opacity-70" : undefined}
        >
          <TabsList>
            <TabsTrigger value="basic-info">Basic Info</TabsTrigger>
            <TabsTrigger value="privileges" disabled={loading}>
              Privileges
            </TabsTrigger>
          </TabsList>

          {activeTab === "basic-info" && (
            <div className="mt-2 max-h-[calc(100vh-260px)] overflow-y-auto pr-1">
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="edit-role-name">Role name</FieldLabel>
                  <Input id="edit-role-name" value={roleName} disabled />
                </Field>
                <Field>
                  <FieldLabel htmlFor="edit-role-authentication">
                    Authentication
                  </FieldLabel>
                  <Input
                    id="edit-role-authentication"
                    value={role?.authenticationType || "NONE"}
                    disabled
                  />
                </Field>
                <Field>
                  <FieldLabel htmlFor="edit-role-password">
                    New password
                  </FieldLabel>
                  <Input
                    id="edit-role-password"
                    type="password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    placeholder="Leave blank to keep current password"
                    autoComplete="new-password"
                    disabled={saving}
                  />
                </Field>
                <Field>
                  <FieldLabel htmlFor="edit-role-confirm-password">
                    Confirm password
                  </FieldLabel>
                  <Input
                    id="edit-role-confirm-password"
                    type="password"
                    value={confirmPassword}
                    onChange={(event) => setConfirmPassword(event.target.value)}
                    autoComplete="new-password"
                    disabled={saving}
                  />
                </Field>
                <Field>
                  <FieldLabel htmlFor="edit-role-scope">Scope</FieldLabel>
                  <Input
                    id="edit-role-scope"
                    value={role?.common === "YES" ? "COMMON" : "LOCAL"}
                    disabled
                  />
                </Field>
              </FieldGroup>
            </div>
          )}

          {activeTab === "privileges" && (
            <UserPrivileges
              privileges={privilegeState.privileges}
              setPrivileges={handleSetPrivileges}
              commonPrivileges={privilegeState.commonPrivileges}
              systemPrivileges={systemPrivileges}
              setCommonPrivileges={handleSetCommonPrivileges}
              onColumnChange={handleColumnChange}
            />
          )}
        </Tabs>

        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={saving}>Cancel</Button>}
          />
          <Button onClick={handleSubmit} disabled={loading || saving}>
            {saving ? <LoadingSpinner label="Updating..." /> : "Update role"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default RoleEditDialog;
