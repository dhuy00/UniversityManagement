import { useEffect, useState } from "react";
import { CalendarRange, FileText } from "lucide-react";

import { getCoursePlans } from "@/api/coursePlanApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import CoursePlanEnrollmentsDialog from "@/components/enrollments/CoursePlanEnrollmentsDialog";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getAuthSession, hasAnyRole } from "@/lib/auth";
import { ENROLLMENT_ROLES } from "@/lib/roles";

const formatDate = (value) =>
  new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(value));

export default function CoursePlans() {
  const session = getAuthSession();
  const [plans, setPlans] = useState(null);
  const [error, setError] = useState("");
  const [selectedPlan, setSelectedPlan] = useState(null);
  const canViewEnrollments = hasAnyRole(session, ENROLLMENT_ROLES);

  useEffect(() => {
    let active = true;

    getCoursePlans()
      .then((data) => {
        if (active) setPlans(data);
      })
      .catch(() => {
        if (active) setError("Unable to load course plans.");
      });

    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="dashboard-page">
      <header className="flex min-h-20 items-center border-b border-[#2b3139] pl-14 pr-4 sm:px-6 lg:px-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#707a8a]">
            Academic catalog
          </p>
          <h1 className="mt-1 text-lg font-semibold tracking-tight text-white">
            Course Plans
          </h1>
        </div>
      </header>

      <div className="dashboard-content">
        <section className="mb-6 flex items-center gap-4">
          <div className="flex size-11 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
            <CalendarRange className="size-5" />
          </div>
          <div>
            <h2 className="text-xl font-semibold text-white">
              Planned course offerings
            </h2>
            <p className="mt-1 text-sm text-[#929aa5]">
              Student results are restricted to their program by Oracle VPD.
            </p>
          </div>
        </section>

        {error && (
          <div role="alert" className="rounded-lg border border-[#3f4650] bg-[#1e2329] p-5 text-sm text-[#eaecef]">
            {error}
          </div>
        )}

        {!error && plans === null && (
          <div className="flex min-h-48 items-center justify-center rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <LoadingSpinner label="Loading course plans..." />
          </div>
        )}

        {plans && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Course</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course name</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Semester</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Year</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Program</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Start date</TableHead>
                  {canViewEnrollments && (
                    <TableHead className="px-4 text-right text-[#929aa5]">
                      Action
                    </TableHead>
                  )}
                </TableRow>
              </TableHeader>
              <TableBody>
                {plans.map((plan) => (
                  <TableRow
                    key={`${plan.courseId}-${plan.semester}-${plan.academicYear}-${plan.programId}`}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {plan.courseId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {plan.courseName}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {plan.semester}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {plan.academicYear}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {plan.programId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {formatDate(plan.startDate)}
                    </TableCell>
                    {canViewEnrollments && (
                      <TableCell className="px-4 text-right">
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          aria-label="View registered students"
                          title="View registered students"
                          onClick={() => setSelectedPlan(plan)}
                        >
                          <FileText />
                          Detail
                        </Button>
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {plans.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No course plans are visible to this identity.
              </p>
            )}
          </div>
        )}
      </div>
      {selectedPlan && (
        <CoursePlanEnrollmentsDialog
          plan={selectedPlan}
          onClose={() => setSelectedPlan(null)}
        />
      )}
    </div>
  );
}
