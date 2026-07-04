import { Search } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function DataPageHeader({
  eyebrow,
  title,
  description,
  icon: Icon,
  searchValue,
  onSearchChange,
  onSearchSubmit,
  searchPlaceholder = "Search",
  searchDisabled = false,
}) {
  const handleSubmit = (event) => {
    event.preventDefault();
    onSearchSubmit?.(event);
  };

  return (
    <header className=" px-4 py-4 pl-14 sm:px-6 lg:px-8">
      <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
        <div className="flex items-start gap-4">
          <div className="mt-0.5 flex size-11 shrink-0 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
            <Icon className="size-5" />
          </div>
          <div>
            <h1 className={eyebrow
              ? "mt-1 text-lg font-semibold tracking-tight text-white"
              : "text-lg font-semibold tracking-tight text-white"}
            >
              {title}
            </h1>
            <p className="max-w-2xl text-sm text-[#929aa5]">
              {description}
            </p>
          </div>
        </div>

        <form className="flex w-full max-w-md gap-2" onSubmit={handleSubmit}>
          <Input
            value={searchValue}
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder={searchPlaceholder}
            disabled={searchDisabled}
            className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
          />
          <Button type="submit" variant="outline" disabled={searchDisabled}>
            <Search />
            Search
          </Button>
        </form>
      </div>
    </header>
  );
}
