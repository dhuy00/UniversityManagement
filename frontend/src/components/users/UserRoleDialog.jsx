import { useEffect, useState } from "react";

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

  useEffect(() => {
    if (open) {
      setDraftRoles(selectedRoles);
    }
  }, [open, selectedRoles]);

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
      <DialogContent className="!max-w-none w-[620px] text-[13px]">
        <DialogHeader>
          <DialogTitle className="text-sm leading-none">
            Manage user roles
          </DialogTitle>
        </DialogHeader>

        <div className="max-h-[420px] overflow-auto rounded-lg border border-border">
          <Table>
            <TableHeader>
              <TableRow className="bg-slate-50 hover:bg-slate-50">
                <TableHead className="w-[64px] text-center text-[11px] font-semibold uppercase text-slate-500">
                  Use
                </TableHead>
                <TableHead className="text-[11px] font-semibold uppercase text-slate-500">
                  Role
                </TableHead>
                <TableHead className="text-[11px] font-semibold uppercase text-slate-500">
                  Authentication
                </TableHead>
                <TableHead className="text-[11px] font-semibold uppercase text-slate-500">
                  Common
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {availableRoles.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} className="h-24 text-center text-slate-500">
                    No roles available
                  </TableCell>
                </TableRow>
              ) : (
                availableRoles.map((role) => (
                  <TableRow key={role.role} className="hover:bg-slate-50/70">
                    <TableCell className="text-center">
                      <Checkbox
                        checked={hasRole(draftRoles, role.role)}
                        onCheckedChange={(checked) =>
                          handleToggleRole(role.role, !!checked)
                        }
                      />
                    </TableCell>
                    <TableCell className="font-medium text-slate-900">
                      {role.role}
                    </TableCell>
                    <TableCell className="text-slate-600">
                      {role.authenticationType}
                    </TableCell>
                    <TableCell className="text-slate-600">{role.common}</TableCell>
                  </TableRow>
                ))
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
