import { useState } from "react";
import { toast } from "sonner";

import { deleteTeachingAssignment } from "@/api/teachingAssignmentApi";
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

export default function TeachingAssignmentDeleteDialog({
  assignment,
  onClose,
  onDeleted,
}) {
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState("");

  const handleDelete = async () => {
    try {
      setDeleting(true);
      setError("");
      await deleteTeachingAssignment(assignment);
      await onDeleted();
      toast.success("Teaching assignment deleted");
      onClose();
    } catch (requestError) {
      setError(
        requestError.response?.data?.title ||
        "Unable to delete an assignment that is restricted or still referenced.",
      );
    } finally {
      setDeleting(false);
    }
  };

  return (
    <Dialog
      open
      onOpenChange={(open) => {
        if (!open && !deleting) onClose();
      }}
    >
      <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-md">
        <DialogHeader>
          <DialogTitle className="text-white">Delete assignment</DialogTitle>
        </DialogHeader>
        <p className="text-sm text-[#929aa5]">
          Delete {assignment.lecturerId} · {assignment.courseId} · Semester{" "}
          {assignment.semester}/{assignment.academicYear}?
        </p>
        {error && (
          <div role="alert" className="rounded-md bg-[#2b3139] px-3 py-2 text-sm">
            {error}
          </div>
        )}
        <DialogFooter>
          <DialogClose
            render={<Button variant="outline" disabled={deleting}>Cancel</Button>}
          />
          <Button
            type="button"
            variant="destructive"
            onClick={handleDelete}
            disabled={deleting}
          >
            {deleting
              ? <LoadingSpinner label="Deleting..." />
              : "Delete assignment"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
