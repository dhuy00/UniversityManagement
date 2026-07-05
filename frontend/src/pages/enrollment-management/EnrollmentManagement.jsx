import { useEffect, useState } from "react";
import { GraduationCap, Plus, Trash2 } from "lucide-react";

import { getRegistrationOptions } from "@/api/enrollmentApi";
import DataPageHeader from "@/components/common/DataPageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import EnrollmentMaintainDialog from "@/components/enrollments/EnrollmentMaintainDialog";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export default function EnrollmentManagement() {
  const [options, setOptions] = useState(null);
  const [error, setError] = useState("");
  const [dialogMode, setDialogMode] = useState(null);
  const [search, setSearch] = useState("");

  const loadOptions = async () => {
    const data = await getRegistrationOptions();
    setOptions(data);
  };

  useEffect(() => {
    let active = true;
    getRegistrationOptions()
      .then((data) => {
        if (active) setOptions(data);
      })
      .catch(() => {
        if (active) setError("Unable to load enrollment options.");
      });
    return () => {
      active = false;
    };
  }, []);

  const term = search.trim().toLowerCase();
  const visibleOptions = (options ?? []).filter((option) =>
    !term ||
    [
      option.courseId,
      option.courseName,
      option.lecturerId,
      option.programId,
    ].some((value) => value.toLowerCase().includes(term)));

  return (
    <div className="dashboard-page">
      <DataPageHeader
        title="Enrollment Requests"
        description="Register or cancel students during the 14-day adjustment window."
        icon={GraduationCap}
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search course, lecturer, or program"
        searchDisabled={options === null}
        actions={(
          <>
            <Button
              type="button"
              variant="outline"
              onClick={() => setDialogMode("delete")}
            >
              <Trash2 />
              Cancel enrollment
            </Button>
            <Button type="button" onClick={() => setDialogMode("create")}>
              <Plus />
              Register student
            </Button>
          </>
        )}
      />

      <div className="dashboard-content">
        {error && (
          <div role="alert" className="rounded-lg bg-[#1e2329] p-5 text-sm">
            {error}
          </div>
        )}
        {!error && options === null && (
          <div className="flex min-h-48 items-center justify-center rounded-xl bg-[#1e2329]">
            <LoadingSpinner label="Loading open assignments..." />
          </div>
        )}
        {options && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139]">
                  <TableHead className="px-4 text-[#929aa5]">Course</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course name</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Lecturer</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Term</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Program</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {visibleOptions.map((option) => (
                  <TableRow
                    key={`${option.lecturerId}-${option.courseId}-${option.semester}-${option.academicYear}-${option.programId}`}
                    className="border-[#2b3139]"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {option.courseId}
                    </TableCell>
                    <TableCell className="px-4">{option.courseName}</TableCell>
                    <TableCell className="px-4">{option.lecturerId}</TableCell>
                    <TableCell className="px-4">
                      {option.semester}/{option.academicYear}
                    </TableCell>
                    <TableCell className="px-4">{option.programId}</TableCell>
                    <TableCell className="px-4">
                      {option.registrationOpen ? "Open" : "Closed"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            {visibleOptions.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No teaching assignments match the current search.
              </p>
            )}
          </div>
        )}
      </div>

      {dialogMode && (
        <EnrollmentMaintainDialog
          mode={dialogMode}
          onClose={() => setDialogMode(null)}
          onSaved={loadOptions}
        />
      )}
    </div>
  );
}
