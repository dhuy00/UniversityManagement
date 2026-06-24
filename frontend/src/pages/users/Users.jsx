import { useState, useEffect } from 'react'
import UserHeader from '../../components/users/UserHeader'
import UserTable from '../../components/users/UserTable'
import { Button } from "@/components/ui/button"
import UserDialog from '@/components/users/UserDialog'
import { getUsers } from '@/api/userApi'

const Users = () => {
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [users, setUsers] = useState([]);

    useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await getUsers();
        setUsers(res.data)
      } catch (error) {
        console.error(error);
      }
    };

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
        <UserTable users={users} onEditUser={handleEditUser}/>
      </div>
      <UserDialog
        open={openDialog}
        setOpen={setOpenDialog}
        mode={selectedUser ? "edit" : "create"}
        user={selectedUser}
      />
    </div>
  )
}

export default Users
