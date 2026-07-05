import { useEffect, useMemo, useState } from "react";
import { Pencil, Plus, Presentation, Trash2 } from "lucide-react";

import { getTeachingAssignments } from "@/api/teachingAssignmentApi";
import DataPageHeader from "@/components/common/DataPageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import TeachingAssignmentDeleteDialog from "@/components/teaching-assignments/TeachingAssignmentDeleteDialog";
import TeachingAssignmentFormDialog from "@/components/teaching-assignments/TeachingAssignmentFormDialog";
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
  ASSIGNMENT_CREATE_DELETE_ROLES,
  ASSIGNMENT_UPDATE_ROLES,
} from "@/lib/roles";
import { prioritizeItem } from "@/lib/prioritizeItem";

const assignmentKey = (assignment) =>
  `${assignment.lecturerId}|${assignment.courseId}|${assignment.semester}|${assignment.academicYear}|${assignment.programId}`;

export default function TeachingAssignments() {
  const session = getAuthSession();
  const [assignments, setAssignments] = useState(null);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [formMode, setFormMode] = useState(null);
  const [editingAssignment, setEditingAssignment] = useState(null);
  const [deletingAssignment, setDeletingAssignment] = useState(null);
  const canCreateDelete = hasAnyRole(
    session,
    ASSIGNMENT_CREATE_DELETE_ROLES,
  );
  const canUpdate = hasAnyRole(session, ASSIGNMENT_UPDATE_ROLES);
  const canManageAssignment = (assignment) => {
    if (session?.roleCode === "UNIT_HEAD") {
      return assignment.unitId === session.unitId;
    }
    return assignment.unitId === "OFFICE";
  };

  useEffect(() => {
    let active = true;

    getTeachingAssignments()
      .then((data) => {
        if (active) setAssignments(data);
      })
      .catch((requestError) => {
        if (!active) return;
        setError(
          requestError.response?.status === 403
            ? "Your role cannot access teaching assignments."
            : "Unable to load teaching assignments.",
        );
      });

    return () => {
      active = false;
    };
  }, []);

  const refreshAssignments = async (createdAssignmentKey) => {
    const data = await getTeachingAssignments();
    setAssignments(prioritizeItem(
      data,
      createdAssignmentKey,
      assignmentKey,
    ));
  };

  const visibleAssignments = useMemo(() => {
    if (!assignments) return [];
    const term = search.trim().toLowerCase();
    if (!term) return assignments;

    return assignments.filter((assignment) =>
      [
        assignment.lecturerId,
        assignment.courseId,
        assignment.courseName,
        assignment.programId,
        assignment.semester,
        assignment.academicYear,
      ].some((value) => String(value).toLowerCase().includes(term)));
  }, [assignments, search]);

  return (
    <div className="dashboard-page">
      <DataPageHeader
        eyebrow="Teaching operations"
        title="Teaching Assignments"
        description="Rows are restricted by your Oracle role and VPD context."
        icon={Presentation}
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search lecturer, course, program, or term"
        searchDisabled={assignments === null}
        actions={canCreateDelete && (
          <Button
            type="button"
            onClick={() => {
              setEditingAssignment(null);
              setFormMode("create");
            }}
          >
            <Plus />
            Create assignment
          </Button>
        )}
      />

      <div className="dashboard-content">
        {error && (
          <div role="alert" className="rounded-lg border border-[#3f4650] bg-[#1e2329] p-5 text-sm text-[#eaecef]">
            {error}
          </div>
        )}

        {!error && assignments === null && (
          <div className="flex min-h-48 items-center justify-center rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <LoadingSpinner label="Loading teaching assignments..." />
          </div>
        )}

        {assignments && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Lecturer</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course name</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Semester</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Year</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Program</TableHead>
                  {(canUpdate || canCreateDelete) && (
                    <TableHead className="px-4 text-right text-[#929aa5]">
                      Action
                    </TableHead>
                  )}
                </TableRow>
              </TableHeader>
              <TableBody>
                {visibleAssignments.map((assignment) => (
                  <TableRow
                    key={`${assignment.lecturerId}-${assignment.courseId}-${assignment.semester}-${assignment.academicYear}-${assignment.programId}`}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {assignment.lecturerId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {assignment.courseId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {assignment.courseName}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {assignment.semester}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {assignment.academicYear}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {assignment.programId}
                    </TableCell>
                    {(canUpdate || canCreateDelete) && (
                      <TableCell className="px-4 text-right">
                        <div className="flex justify-end gap-2">
                          {canUpdate && canManageAssignment(assignment) && (
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              onClick={() => {
                                setEditingAssignment(assignment);
                                setFormMode("edit");
                              }}
                            >
                              <Pencil />
                              Edit
                            </Button>
                          )}
                          {canCreateDelete &&
                            canManageAssignment(assignment) && (
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              onClick={() => setDeletingAssignment(assignment)}
                            >
                              <Trash2 />
                              Delete
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {visibleAssignments.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No teaching assignments are visible to this identity.
              </p>
            )}
          </div>
        )}
      </div>
      {formMode && (
        <TeachingAssignmentFormDialog
          mode={formMode}
          assignment={editingAssignment}
          onClose={() => {
            setFormMode(null);
            setEditingAssignment(null);
          }}
          onSaved={refreshAssignments}
        />
      )}
      {deletingAssignment && (
        <TeachingAssignmentDeleteDialog
          assignment={deletingAssignment}
          onClose={() => setDeletingAssignment(null)}
          onDeleted={refreshAssignments}
        />
      )}
    </div>
  );
}
