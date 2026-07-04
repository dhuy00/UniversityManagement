import { useEffect, useMemo, useState } from "react";
import { CalendarRange, FileText, Pencil, Plus } from "lucide-react";

import { getCoursePlans } from "@/api/coursePlanApi";
import DataPageHeader from "@/components/common/DataPageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import CoursePlanFormDialog from "@/components/course-plans/CoursePlanFormDialog";
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
import {
  COURSE_PLAN_WRITE_ROLES,
  ENROLLMENT_ROLES,
} from "@/lib/roles";

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
  const [formMode, setFormMode] = useState(null);
  const [editingPlan, setEditingPlan] = useState(null);
  const [search, setSearch] = useState("");
  const canViewEnrollments = hasAnyRole(session, ENROLLMENT_ROLES);
  const canManagePlans = hasAnyRole(session, COURSE_PLAN_WRITE_ROLES);

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

  const refreshPlans = async () => {
    const data = await getCoursePlans();
    setPlans(data);
  };

  const visiblePlans = useMemo(() => {
    if (!plans) return [];
    const term = search.trim().toLowerCase();
    if (!term) return plans;

    return plans.filter((plan) =>
      [
        plan.courseId,
        plan.courseName,
        plan.programId,
        plan.semester,
        plan.academicYear,
      ].some((value) => String(value).toLowerCase().includes(term)));
  }, [plans, search]);

  return (
    <div className="dashboard-page">
      <DataPageHeader
        title="Course Plans"
        description="Student results are restricted to their program by Oracle VPD."
        icon={CalendarRange}
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search course, program, semester, or year"
        searchDisabled={plans === null}
        actions={canManagePlans && (
          <Button
            type="button"
            onClick={() => {
              setEditingPlan(null);
              setFormMode("create");
            }}
          >
            <Plus />
            Create plan
          </Button>
        )}
      />

      <div className="dashboard-content">
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
                  {(canViewEnrollments || canManagePlans) && (
                    <TableHead className="px-4 text-right text-[#929aa5]">
                      Action
                    </TableHead>
                  )}
                </TableRow>
              </TableHeader>
              <TableBody>
                {visiblePlans.map((plan) => (
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
                    {(canViewEnrollments || canManagePlans) && (
                      <TableCell className="px-4 text-right">
                        <div className="flex justify-end gap-2">
                          {canViewEnrollments && (
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
                          )}
                          {canManagePlans && (
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              aria-label="Edit course plan"
                              title="Edit course plan"
                              onClick={() => {
                                setEditingPlan(plan);
                                setFormMode("edit");
                              }}
                            >
                              <Pencil />
                              Edit
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {visiblePlans.length === 0 && (
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
      {formMode && (
        <CoursePlanFormDialog
          mode={formMode}
          plan={editingPlan}
          onClose={() => {
            setFormMode(null);
            setEditingPlan(null);
          }}
          onSaved={refreshPlans}
        />
      )}
    </div>
  );
}
