import { useEffect, useState } from "react";
import { ChevronLeft, ChevronRight, UsersRound } from "lucide-react";

import { getStudents } from "@/api/studentApi";
import DataPageHeader from "@/components/common/DataPageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getAuthSession } from "@/lib/auth";

const PAGE_SIZE = 20;

const formatDate = (value) =>
  new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(value));

export default function Students() {
  const session = getAuthSession();
  const [result, setResult] = useState(null);
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const isStudent = session?.roleCode === "STUDENT";

  useEffect(() => {
    let active = true;

    getStudents({ page, pageSize: PAGE_SIZE, search })
      .then((data) => {
        if (active) setResult(data);
      })
      .catch(() => {
        if (active) setError("Unable to load students.");
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [page, search]);

  const handleSearch = () => {
    const nextSearch = searchInput.trim();
    if (page === 1 && search === nextSearch) return;

    setLoading(true);
    setError("");
    setPage(1);
    setSearch(nextSearch);
  };

  const changePage = (nextPage) => {
    setLoading(true);
    setError("");
    setPage(nextPage);
  };

  const students = result?.items ?? [];
  const totalPages = result?.totalPages ?? 0;

  return (
    <div className="dashboard-page">
      <DataPageHeader
        eyebrow="Student records"
        title={isStudent ? "My Student Record" : "Students"}
        description="Results are filtered by the Oracle STUDENTS VPD policy."
        icon={UsersRound}
        searchValue={searchInput}
        onSearchChange={setSearchInput}
        onSearchSubmit={handleSearch}
        searchPlaceholder="Search by student ID or name"
        searchDisabled={loading}
      />

      <div className="dashboard-content">
        {error && (
          <div role="alert" className="rounded-lg border border-[#3f4650] bg-[#1e2329] p-5 text-sm text-[#eaecef]">
            {error}
          </div>
        )}

        {!error && loading && (
          <div className="flex min-h-48 items-center justify-center rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <LoadingSpinner label="Loading students..." />
          </div>
        )}

        {!error && !loading && result && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Student ID</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Full name</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Gender</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Date of birth</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Phone</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Program</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Major</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Credits</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">GPA</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Campus</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {students.map((student) => (
                  <TableRow
                    key={student.studentId}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {student.studentId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {student.fullName}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {student.gender}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {formatDate(student.dateOfBirth)}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {student.phone ?? "—"}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {student.programId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {student.majorId}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {student.accumulatedCredits}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {student.cumulativeGpa}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {student.campusId}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {students.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No students match the current search.
              </p>
            )}

            <footer className="flex flex-col gap-3 border-t border-[#2b3139] px-4 py-4 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-sm text-[#707a8a]">
                {result.totalItems} visible student record(s)
              </p>
              <div className="flex items-center gap-3">
                <span className="text-sm text-[#707a8a]">
                  Page {result.page} of {Math.max(totalPages, 1)}
                </span>
                <div className="flex gap-1.5">
                  <Button
                    type="button"
                    variant="outline"
                    size="icon-sm"
                    aria-label="Previous page"
                    disabled={result.page <= 1}
                    onClick={() => changePage(result.page - 1)}
                  >
                    <ChevronLeft />
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    size="icon-sm"
                    aria-label="Next page"
                    disabled={totalPages === 0 || result.page >= totalPages}
                    onClick={() => changePage(result.page + 1)}
                  >
                    <ChevronRight />
                  </Button>
                </div>
              </div>
            </footer>
          </div>
        )}
      </div>
    </div>
  );
}
