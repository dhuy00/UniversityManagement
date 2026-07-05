import { useState } from "react";
import { toast } from "sonner";

import { deleteStaff } from "@/api/staffApi";
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

export default function StaffDeleteDialog({ staff, onClose, onDeleted }) {
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState("");

  const handleDelete = async () => {
    try {
      setDeleting(true);
      setError("");
      await deleteStaff(staff.staffId);
      await onDeleted();
      toast.success("Staff deleted");
      onClose();
    } catch (requestError) {
      setError(
        requestError.response?.data?.title ||
        "Unable to delete staff that is still referenced.",
      );
    } finally {
      setDeleting(false);
    }
  };

  return (
    <Dialog open onOpenChange={(open) => !open && !deleting && onClose()}>
      <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-md">
        <DialogHeader>
          <DialogTitle>Delete staff</DialogTitle>
        </DialogHeader>
        <p className="text-sm text-[#929aa5]">
          Delete {staff.staffId} · {staff.fullName}?
        </p>
        {error && <div role="alert" className="text-sm">{error}</div>}
        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={deleting}>Cancel</Button>}
          />
          <Button
            type="button"
            variant="destructive"
            disabled={deleting}
            onClick={handleDelete}
          >
            {deleting ? <LoadingSpinner label="Deleting..." /> : "Delete staff"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
