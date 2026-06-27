import { useEffect, useState } from "react";
import { toast } from "sonner";

import { getRoles } from "@/api/roleApi";
import RoleDialog from "@/components/roles/RoleDialog";
import RoleHeader from "@/components/roles/RoleHeader";
import RoleTable from "@/components/roles/RoleTable";
import { Button } from "@/components/ui/button";

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const Roles = () => {
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openCreateDialog, setOpenCreateDialog] = useState(false);

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

  return (
    <div className="min-h-screen w-full flex-1 bg-background-secondary">
      <RoleHeader />
      <div className="mt-4 px-4 drop-shadow-small">
        <div className="flex items-center justify-between rounded-t-xl border border-b-0 border-border-primary bg-background-table px-5 py-4">
          <div className="flex flex-col">
            <span className="text-[15px] font-semibold text-text-primary">
              All roles
            </span>
            <span className="text-small text-text-secondary">
              {loading ? "Loading roles..." : `${roles.length} roles total`}
            </span>
          </div>
          <Button
            className="py-2 text-[12px]"
            onClick={() => setOpenCreateDialog(true)}
          >
            Create role
          </Button>
        </div>
        <RoleTable roles={roles} loading={loading} />
      </div>
      <RoleDialog
        open={openCreateDialog}
        setOpen={setOpenCreateDialog}
        onSaved={fetchRoles}
      />
    </div>
  );
};

export default Roles;
