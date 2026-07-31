import { useState, useEffect } from 'react'
import UserHeader from '../../components/users/UserHeader'
import UserTable from '../../components/users/UserTable'
import { Button } from "@/components/ui/button"
import UserDialog from '@/components/users/UserDialog'
import UserDeleteDialog from '@/components/users/UserDeleteDialog'
import { createPgUser, deletePgUser, getPgUsers } from '@/api/pgUserApi'
import { grantPgRoleToUser, revokePgRoleFromUser } from '@/api/pgRoleApi'
import { updatePgUserStatus, updatePgUserPassword } from '@/api/pgUserApi'
import { getPgRoles } from '@/api/pgRoleApi'
import { toast } from 'sonner'

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const Users = () => {
  const [openDialog, setOpenDialog] = useState(false);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [users, setUsers] = useState([]);
  const [totalItems, setTotalItems] = useState(0);
  const [loadingUsers, setLoadingUsers] = useState(true);
  const [search, setSearch] = useState("");

  const fetchUsers = async (overrideSearch) => {
    try {
      setLoadingUsers(true);
      const res = await getPgUsers({
        page: 1,
        pageSize: 100,
        search: overrideSearch ?? search,
      });
      setUsers(res.data?.items ?? []);
      setTotalItems(res.data?.totalItems ?? 0);
    } catch (error) {
      console.error(error);
      toast.error("Failed to load users", {
        description: getErrorMessage(error),
      });
    } finally {
      setLoadingUsers(false);
    }
  };

  useEffect(() => {
    fetchUsers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleSearch = (value) => {
    setSearch(value);
    fetchUsers(value);
  };

  const handleCreateUser = () => {
    setSelectedUser(null);
    setOpenDialog(true);
  };

  const handleEditUser = (user) => {
    setSelectedUser(user);
    setOpenDialog(true);
  };

  const handleDeleteUser = (user) => {
    setSelectedUser(user);
    setOpenDeleteDialog(true);
  };

  const handleConfirmDelete = async () => {
    if (!selectedUser) return;

    try {
      setDeleting(true);
      await deletePgUser(selectedUser.username);
      toast.success("User deleted", {
        description: selectedUser.username,
      });
      setOpenDeleteDialog(false);
      setSelectedUser(null);
      await fetchUsers();
    } catch (error) {
      console.error(error);
      toast.error("Failed to delete user", {
        description: getErrorMessage(error),
      });
    } finally {
      setDeleting(false);
    }
  };

  const handleSaveUser = async (formData) => {
    const username = formData.username.trim().toUpperCase();
    const isEdit = Boolean(formData.isEdit);

    const originalRoles = (formData.originalRoles ?? []).map((r) => r.toUpperCase());
    const nextRoles = (formData.roles ?? []).map((r) => r.toUpperCase());
    const rolesToGrant = nextRoles.filter((r) => !originalRoles.includes(r));
    const rolesToRevoke = originalRoles.filter((r) => !nextRoles.includes(r));

    if (!isEdit) {
      const created = await createPgUser({
        username,
        password: formData.password,
      });
      if (!created.data?.success) {
        throw new Error(created.data?.message ?? "Failed to create user");
      }
    }

    const statusTasks = [
      updatePgUserStatus({ username, status: formData.status }),
    ];
    if (formData.password) {
      statusTasks.push(updatePgUserPassword({ username, password: formData.password }));
    }

    await Promise.all(statusTasks);

    for (const role of rolesToGrant) {
      await grantPgRoleToUser({ username, rolename: role });
    }
    for (const role of rolesToRevoke) {
      await revokePgRoleFromUser({ username, rolename: role });
    }
  };

  return (
    <div className="dashboard-page">
      <UserHeader onSearch={handleSearch} search={search} />
      <div className="dashboard-content">
        <div className="flex items-center justify-between rounded-t-xl border border-b-0 border-[#2b3139] bg-[#1e2329] px-5 py-5 sm:px-6">
          <div>
            <h2 className="text-base font-semibold text-white">All users</h2>
            <p className="mt-1 text-xs text-[#707a8a]">
              {loadingUsers ? "Loading accounts..." : `${totalItems} accounts total`}
            </p>
          </div>
          <Button size="sm" className="px-4" onClick={handleCreateUser}>
            Create user
          </Button>
        </div>
        <UserTable
          users={users}
          loading={loadingUsers}
          onEditUser={handleEditUser}
          onDeleteUser={handleDeleteUser}
        />
      </div>
      <UserDialog
        key={selectedUser?.username ?? "create"}
        open={openDialog}
        setOpen={setOpenDialog}
        mode={selectedUser ? "edit" : "create"}
        user={selectedUser}
        onSaved={fetchUsers}
        onSave={handleSaveUser}
      />
      <UserDeleteDialog
        open={openDeleteDialog}
        setOpen={setOpenDeleteDialog}
        user={selectedUser}
        deleting={deleting}
        onConfirm={handleConfirmDelete}
      />
    </div>
  );
}

export default Users
