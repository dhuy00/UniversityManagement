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

  const fetchUsers = async () => {
    try {
      const res = await getUsers();
      setUsers(res.data)
    } catch (error) {
      console.error(error);
      toast.error("Failed to load users", {
        description: getErrorMessage(error),
      });
    }
  };

  useEffect(() => {
    fetchUsers();
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
    <div className='bg-background-secondary flex-1 w-full min-h-screen'>
      <UserHeader/>
      {/* Content */}
      <div className='px-4 mt-4 drop-shadow-small'>
        <div className='flex justify-between bg-background-table px-5 py-4 items-center rounded-t-xl
        border border-border-primary border-b-0'>
          <div className='flex flex-col'>
            <span className='text-text-primary font-semibold text-[15px]'>All users</span>
            <span className='text-small text-text-secondary'>{users.length} accounts total</span>
          </div>
          <Button className='py-2 text-[12px]' onClick={handleCreateUser}>Create user</Button>
        </div>
        <UserTable
          users={users}
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
  )
}

export default Users
