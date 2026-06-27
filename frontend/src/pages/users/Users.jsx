import { useState, useEffect } from 'react'
import UserHeader from '../../components/users/UserHeader'
import UserTable from '../../components/users/UserTable'
import { Button } from "@/components/ui/button"
import UserDialog from '@/components/users/UserDialog'
import UserDeleteDialog from '@/components/users/UserDeleteDialog'
import { deleteUser, getUsers } from '@/api/userApi'
import { toast } from 'sonner'

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const Users = () => {
  const [openDialog, setOpenDialog] = useState(false);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [users, setUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(true);

  const fetchUsers = async () => {
    try {
      setLoadingUsers(true);
      const res = await getUsers();
      setUsers(res.data)
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
    let cancelled = false;

    getUsers()
      .then((res) => {
        if (!cancelled) setUsers(res.data);
      })
      .catch((error) => {
        if (cancelled) return;
        console.error(error);
        toast.error("Failed to load users", {
          description: getErrorMessage(error),
        });
      })
      .finally(() => {
        if (!cancelled) setLoadingUsers(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

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
      await deleteUser(selectedUser.username);
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

  return (
    <div className="dashboard-page">
      <UserHeader/>
      <div className="dashboard-content">
        <div className="flex items-center justify-between rounded-t-xl border border-b-0 border-[#2b3139] bg-[#1e2329] px-5 py-5 sm:px-6">
          <div>
            <h2 className="text-base font-semibold text-white">All users</h2>
            <p className="mt-1 text-xs text-[#707a8a]">
              {loadingUsers ? "Loading accounts..." : `${users.length} accounts total`}
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
