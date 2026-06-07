import SearchBar from "./SearchBar";
import { FaRegBell } from "react-icons/fa";

const UserHeader = () => {
  return (
    <div className="flex justify-between h-14 border-b border-border-primary w-full px-4 items-center">
      <div className="flex flex-col justify-center">
        <span className="text-text-primary font-semibold">Dashboard</span>
        <span className="font-normal text-small text-text-secondary">
          Welcome back, Emily
        </span>
      </div>
      <div className="flex items-center gap-2">
        <SearchBar />
        <div
          className="relative flex items-center justify-center w-8 h-8 bg-background-input rounded-lg
          border border-border-primary cursor-pointer"
        >
          <FaRegBell size={15} color="#4a5568" />
          <div
            className="absolute rounded-full w-[8px] h-[8px] bg-[#28536b] top-[6px] right-[6px]"
          
          />
        </div>
      </div>
    </div>
  );
};

export default UserHeader;
