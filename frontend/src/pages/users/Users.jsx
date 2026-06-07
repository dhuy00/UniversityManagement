import React from 'react'
import UserHeader from '../../components/users/UserHeader'
import UserTable from '../../components/users/UserTable'

const Users = () => {
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
          <button className='bg-background-tertiary h-fit text-white px-4 py-1.5 rounded-md text-small
          cursor-pointer hover:bg-bakcground-tertiary-hover transition-colors'>Create user</button>
        </div>
        <UserTable/>
      </div>
    </div>
  )
}

export default Users
