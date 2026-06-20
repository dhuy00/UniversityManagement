import SearchBar from "./SearchBar";
import { Button } from "@/components/ui/button";
import { ButtonGroup } from "@/components/ui/button-group";
import { Field, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
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
        <Field>
          <ButtonGroup>
            <Input className={`bg-background placeholder:text-[12px]`} id="input-button-group" placeholder="Type to search..." />
            <Button className={`text-[13px]`} variant="outline">Search</Button>
          </ButtonGroup>
        </Field>
      
      </div>
    </div>
  );
};

export default UserHeader;
