import LoadingSpinner from "@/components/common/LoadingSpinner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

const RoleDeleteDialog = ({
  open,
  setOpen,
  role,
  deleting,
  onConfirm,
}) => (
  <Dialog
    open={open}
    onOpenChange={(nextOpen) => {
      if (!deleting) setOpen(nextOpen);
    }}
  >
    <DialogContent className="w-[calc(100vw-2rem)] text-[13px] sm:w-[420px]">
      <DialogHeader>
        <DialogTitle className="text-sm leading-none">Delete role</DialogTitle>
      </DialogHeader>

      <div className="space-y-2 text-[#929aa5]">
        <p>
          Are you sure you want to delete{" "}
          <span className="font-semibold text-white">{role?.role}</span>?
        </p>
        <p className="text-xs text-[#707a8a]">
          This action drops the database role and revokes it from assigned
          users. It cannot be undone.
        </p>
      </div>

      <DialogFooter>
        <DialogClose
          render={<Button variant="outline" disabled={deleting}>Cancel</Button>}
        />
        <Button
          variant="destructive"
          disabled={deleting}
          onClick={onConfirm}
        >
          {deleting ? <LoadingSpinner label="Deleting..." /> : "Delete role"}
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
);

export default RoleDeleteDialog;
