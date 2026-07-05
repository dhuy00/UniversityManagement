import { CalendarRange } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

const formatDate = (value) =>
  new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(value));

export default function CoursePlanDetailDialog({
  plan,
  onClose,
  onRegister,
}) {
  const fields = [
    ["Course ID", plan.courseId],
    ["Course name", plan.courseName],
    ["Unit", plan.unitId],
    ["Program", plan.programId],
    ["Semester", plan.semester],
    ["Academic year", plan.academicYear],
    ["Start date", formatDate(plan.startDate)],
    ["Registration", plan.registrationOpen ? "Open" : "Closed"],
  ];

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="bg-[#1e2329] text-[#eaecef] sm:!max-w-2xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <CalendarRange className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-white">
                Course plan details
              </DialogTitle>
              <DialogDescription className="text-[#929aa5]">
                Registration is available for 14 days from the start date.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="grid gap-3 sm:grid-cols-2">
          {fields.map(([label, value]) => (
            <div
              key={label}
              className="rounded-md border border-[#2b3139] bg-[#0b0e11] p-3"
            >
              <p className="text-xs uppercase tracking-[0.1em] text-[#707a8a]">
                {label}
              </p>
              <p className="mt-1 text-sm text-[#eaecef]">{value}</p>
            </div>
          ))}
        </div>

        <DialogFooter>
          <DialogClose render={<Button variant="outline">Close</Button>} />
          <Button
            type="button"
            disabled={!plan.registrationOpen}
            title={plan.registrationOpen
              ? "Register this course"
              : "The registration window is closed"}
            onClick={onRegister}
          >
            Register
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
