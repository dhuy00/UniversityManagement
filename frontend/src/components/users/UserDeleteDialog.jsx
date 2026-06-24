import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

const UserDeleteDialog = ({ open, setOpen, user, deleting, onConfirm }) => {
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="w-[420px] text-[13px]">
        <DialogHeader>
          <DialogTitle className="text-sm leading-none">Delete user</DialogTitle>
        </DialogHeader>

        <div className="space-y-2 text-slate-600">
          <p>
            Are you sure you want to delete{" "}
            <span className="font-semibold text-slate-900">
              {user?.username}
            </span>
            ?
          </p>
          <p className="text-xs text-slate-500">
            This action drops the database user and cannot be undone.
          </p>
        </div>

        <DialogFooter>
          <DialogClose render={<Button variant="outline">Cancel</Button>} />
          <Button
            variant="destructive"
            disabled={deleting}
            onClick={onConfirm}
          >
            Delete user
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default UserDeleteDialog;
