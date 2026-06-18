import React, { useState } from 'react'
import UserHeader from '../../components/users/UserHeader'
import UserTable from '../../components/users/UserTable'
import { Button } from "@/components/ui/button"
import UserDialog from '@/components/common/UserDialog'

const Users = () => {
  const [openDialog, setOpenDialog] = useState(false);

  return (
    <div className='bg-background-secondary flex-1 w-full h-screen'>
      <UserHeader/>
      {/* Content */}
      <div className='px-4 mt-4 drop-shadow-small'>
        <div className='flex justify-between bg-background-table px-4 py-3 items-center rounded-t-xl
        border border-border-primary border-b-0'>
          <div className='flex flex-col'>
            <span className='text-text-primary font-semibold text-[14px]'>All users</span>
            <span className='text-small text-text-secondary'>8 members total</span>
          </div>
          <Button className='py-2 text-[12px]'  onClick={() => setOpenDialog(true)}>Create user</Button>
        </div>
        <UserTable/>
      </div>
      <UserDialog open={openDialog} setOpen={setOpenDialog} />
    </div>
  )
}

export default Users
