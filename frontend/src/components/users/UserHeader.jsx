import { CircleCheck } from "lucide-react";
import { getAuthSession } from "@/lib/auth";
import SearchBar from "./SearchBar";

const UserHeader = ({ onSearch, search = "" }) => {
  const username = getAuthSession()?.username || "Administrator";

  return (
    <header className="flex min-h-20 w-full items-center justify-between gap-4 border-b border-[#2b3139] pl-14 pr-4 sm:px-6 lg:px-8">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#707a8a]">
          Account management
        </p>
        <h1 className="mt-1 text-lg font-semibold tracking-tight text-white">
          Users
        </h1>
      </div>
      <div className="flex items-center gap-3">
        <SearchBar value={search} onChange={onSearch} placeholder="Search by username" />
        <div className="hidden items-center gap-2 text-xs text-[#929aa5] sm:flex">
          <CircleCheck className="size-4 text-[#fcd535]" />
          Signed in as <span className="font-semibold text-[#eaecef]">{username}</span>
        </div>
      </div>
    </header>
  );
};

export default UserHeader;
