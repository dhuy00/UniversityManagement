import { useEffect, useState } from "react";
import { toast } from "sonner";

import { deleteRole, getRoles } from "@/api/roleApi";
import RoleDeleteDialog from "@/components/roles/RoleDeleteDialog";
import RoleDialog from "@/components/roles/RoleDialog";
import RoleEditDialog from "@/components/roles/RoleEditDialog";
import RoleHeader from "@/components/roles/RoleHeader";
import RoleTable from "@/components/roles/RoleTable";
import { Button } from "@/components/ui/button";

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const Roles = () => {
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openCreateDialog, setOpenCreateDialog] = useState(false);
  const [selectedRole, setSelectedRole] = useState(null);
  const [openEditDialog, setOpenEditDialog] = useState(false);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const fetchRoles = async () => {
    try {
      setLoading(true);
      const response = await getRoles();
      setRoles(response.data ?? []);
    } catch (error) {
      console.error(error);
      toast.error("Failed to load roles", {
        description: getErrorMessage(error),
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let cancelled = false;

    getRoles()
      .then((response) => {
        if (!cancelled) setRoles(response.data ?? []);
      })
      .catch((error) => {
        if (cancelled) return;
        console.error(error);
        toast.error("Failed to load roles", {
          description: getErrorMessage(error),
        });
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  const handleDeleteRole = async () => {
    if (!selectedRole) return;

    try {
      setDeleting(true);
      await deleteRole(selectedRole.role);
      toast.success("Role deleted", { description: selectedRole.role });
      setOpenDeleteDialog(false);
      await fetchRoles();
      setSelectedRole(null);
    } catch (error) {
      console.error(error);
      toast.error("Failed to delete role", {
        description: getErrorMessage(error),
      });
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="dashboard-page">
      <RoleHeader />
      <div className="dashboard-content">
        <div className="flex items-center justify-between rounded-t-xl border border-b-0 border-[#2b3139] bg-[#1e2329] px-5 py-5 sm:px-6">
          <div>
            <h2 className="text-base font-semibold text-white">All roles</h2>
            <p className="mt-1 text-xs text-[#707a8a]">
              {loading ? "Loading roles..." : `${roles.length} roles total`}
            </p>
          </div>
          <Button
            size="sm"
            className="px-4"
            onClick={() => setOpenCreateDialog(true)}
          >
            Create role
          </Button>
        </div>
        <RoleTable
          roles={roles}
          loading={loading}
          onEditRole={(role) => {
            setSelectedRole(role);
            setOpenEditDialog(true);
          }}
          onDeleteRole={(role) => {
            setSelectedRole(role);
            setOpenDeleteDialog(true);
          }}
        />
      </div>
      <RoleDialog
        open={openCreateDialog}
        setOpen={setOpenCreateDialog}
        onSaved={fetchRoles}
      />
      <RoleEditDialog
        key={selectedRole?.role ?? "edit-role"}
        open={openEditDialog}
        setOpen={setOpenEditDialog}
        role={selectedRole}
        onSaved={fetchRoles}
      />
      <RoleDeleteDialog
        open={openDeleteDialog}
        setOpen={setOpenDeleteDialog}
        role={selectedRole}
        deleting={deleting}
        onConfirm={handleDeleteRole}
      />
    </div>
  );
};

export default Roles;
