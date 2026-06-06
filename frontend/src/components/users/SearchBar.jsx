import React from "react";

const SearchBar = () => {
  return (
    <>
      <input
        type="text"
        className="bg-background-input border border-border-primary rounded-md h-8 px-2 text-normal
        focus:outline-none text-text-secondary w-[250px]"
        placeholder="Search..."
      />
    </>
  );
};

export default SearchBar;
