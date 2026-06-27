import { useState } from "react";

import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { UsersRound } from "lucide-react";

const hasRole = (roles, role) =>
  roles.some((item) => item.toUpperCase() === role.toUpperCase());

const UserRoleDialog = ({
  open,
  setOpen,
  availableRoles = [],
  selectedRoles = [],
  onApply,
}) => {
  const [draftRoles, setDraftRoles] = useState(selectedRoles);

  const handleToggleRole = (role, checked) => {
    setDraftRoles((prev) => {
      if (checked) {
        return hasRole(prev, role) ? prev : [...prev, role];
      }

      return prev.filter((item) => item.toUpperCase() !== role.toUpperCase());
    });
  };

  const handleApply = () => {
    onApply(draftRoles);
    setOpen(false);
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="z-[70] w-[calc(100vw-2rem)] !max-w-none text-[13px] sm:w-[920px]">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <UsersRound className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg leading-tight text-white">
                Manage assigned roles
              </DialogTitle>
            </div>
          </div>
        </DialogHeader>

        <div className="max-h-[65vh] overflow-auto rounded-lg border border-[#2b3139]">
          <Table>
            <TableHeader>
              <TableRow className="bg-[#181a20] hover:bg-[#181a20]">
                <TableHead className="w-[64px] text-center text-[11px] font-semibold uppercase text-[#929aa5]">
                  Use
                </TableHead>
                <TableHead className="text-[11px] font-semibold uppercase text-[#929aa5]">
                  Role
                </TableHead>
                <TableHead className="text-[11px] font-semibold uppercase text-[#929aa5]">
                  Authentication
                </TableHead>
                <TableHead className="text-[11px] font-semibold uppercase text-[#929aa5]">
                  Common
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {availableRoles.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} className="h-24 text-center text-[#929aa5]">
                    No roles available
                  </TableCell>
                </TableRow>
              ) : (
                availableRoles.map((role) => {
                  const checked = hasRole(draftRoles, role.role);

                  return (
                  <TableRow
                    key={role.role}
                    className="cursor-pointer hover:bg-[#252a31]"
                    onClick={() => handleToggleRole(role.role, !checked)}
                  >
                    <TableCell className="text-center">
                      <div onClick={(event) => event.stopPropagation()}>
                        <Checkbox
                          checked={checked}
                          onCheckedChange={(checked) =>
                            handleToggleRole(role.role, !!checked)
                          }
                        />
                      </div>
                    </TableCell>
                    <TableCell className="font-medium text-white">
                      {role.role}
                    </TableCell>
                    <TableCell className="text-[#929aa5]">
                      {role.authenticationType}
                    </TableCell>
                    <TableCell className="text-[#929aa5]">{role.common}</TableCell>
                  </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </div>

        <DialogFooter>
          <DialogClose render={<Button variant="outline">Cancel</Button>} />
          <Button onClick={handleApply}>Apply roles</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default UserRoleDialog;
