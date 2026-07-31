import React from "react";
import { Search } from "lucide-react";

const SearchBar = ({ value = "", onChange, placeholder = "Search..." }) => {
  return (
    <div className="relative">
      <Search className="absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-[#707a8a]" />
      <input
        type="text"
        value={value}
        onChange={(event) => onChange?.(event.target.value)}
        className="h-9 w-[240px] rounded-md border border-[#2b3139] bg-[#161a1f] pl-8 pr-2 text-[13px] text-white placeholder:text-[#707a8a] focus:border-[#fcd535] focus:outline-none"
        placeholder={placeholder}
      />
    </div>
  );
};

export default SearchBar;
