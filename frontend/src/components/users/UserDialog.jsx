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
import { useState } from "react";

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

const UserDialog = ({ open, setOpen }) => {
  const [formData, setFormData] = useState({
    name: "",
    password: "",
    confirmPassword: "",
    role: "",

    privileges: initialPrivileges,

    commonPrivileges: {
      connect: false,
      create: false,
      temporary: false,
      execute: false,
    },
  });

  const handleSubmit = () => {
    if (!formData.name.trim()) {
      alert("Name is required");
      return;
    }

    if (!formData.password) {
      alert("Password is required");
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      alert("Passwords do not match");
      return;
    }

    const payload = {
      username: formData.name,
      password: formData.password,
      role: formData.role,

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

    // setOpen(false);
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
            Create User
          </DialogTitle>
        </DialogHeader>

        <Tabs defaultValue="basic-info">
          <TabsList>
            <TabsTrigger value="basic-info">Basic Info</TabsTrigger>
            <TabsTrigger value="privileges">Privileges</TabsTrigger>
          </TabsList>
          <UserBasicForm formData={formData} setFormData={setFormData} />
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
          <Button onClick={handleSubmit} type="submit">Save changes</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default UserDialog;
