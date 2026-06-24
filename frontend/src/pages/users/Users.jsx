import { useState, useEffect } from 'react'
import UserHeader from '../../components/users/UserHeader'
import UserTable from '../../components/users/UserTable'
import { Button } from "@/components/ui/button"
import UserDialog from '@/components/users/UserDialog'
import { deleteUser, getUsers } from '@/api/userApi'
import { toast } from 'sonner'

const getErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || "Unexpected error";

const Users = () => {
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
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

  const handleDeleteUser = async (user) => {
    const confirmed = window.confirm(`Delete user ${user.username}?`);
    if (!confirmed) return;

    try {
      await deleteUser(user.username);
      toast.success("User deleted", {
        description: user.username,
      });
      await fetchUsers();
    } catch (error) {
      console.error(error);
      toast.error("Failed to delete user", {
        description: getErrorMessage(error),
      });
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
        open={openDialog}
        setOpen={setOpenDialog}
        mode={selectedUser ? "edit" : "create"}
        user={selectedUser}
        onSaved={fetchUsers}
      />
    </div>
  )
}

export default Users
