import { useEffect, useMemo, useState } from "react";
import { BookOpen, Search } from "lucide-react";

import { getCourses } from "@/api/courseApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export default function CoursePickerDialog({
  selectedCourseId,
  onSelect,
  onClose,
}) {
  const [courses, setCourses] = useState(null);
  const [search, setSearch] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    getCourses()
      .then((data) => {
        if (active) setCourses(data);
      })
      .catch(() => {
        if (active) setError("Unable to load courses.");
      });

    return () => {
      active = false;
    };
  }, []);

  const visibleCourses = useMemo(() => {
    if (!courses) return [];
    const term = search.trim().toLowerCase();
    if (!term) return courses;

    return courses.filter((course) =>
      [course.courseId, course.courseName, course.unitId]
        .some((value) => value.toLowerCase().includes(term)));
  }, [courses, search]);

  return (
    <Dialog open onOpenChange={(open) => {
      if (!open) onClose();
    }}>
      <DialogContent className="max-h-[calc(100vh-2rem)] overflow-hidden bg-[#1e2329] text-[#eaecef] sm:!max-w-4xl">
        <DialogHeader>
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
              <BookOpen className="size-5" />
            </div>
            <div>
              <DialogTitle className="text-lg text-white">
                Select a course
              </DialogTitle>
              <DialogDescription className="mt-1 text-[#929aa5]">
                Choose one course for the course plan.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-[#707a8a]" />
          <Input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search by course ID, name, or unit"
            className="border-[#3f4650] bg-[#0b0e11] pl-9 text-[#eaecef]"
          />
        </div>

        {error && (
          <div role="alert" className="rounded-md border border-[#3f4650] bg-[#2b3139] p-4">
            {error}
          </div>
        )}

        {!error && courses === null && (
          <div className="flex min-h-48 items-center justify-center">
            <LoadingSpinner label="Loading courses..." />
          </div>
        )}

        {courses && (
          <div className="max-h-[60vh] overflow-auto rounded-lg border border-[#2b3139]">
            <Table>
              <TableHeader className="sticky top-0 bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Course ID</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Course name</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Credits</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Unit</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {visibleCourses.map((course) => (
                  <TableRow
                    key={course.courseId}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {course.courseId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {course.courseName}
                    </TableCell>
                    <TableCell className="px-4 text-right text-[#eaecef]">
                      {course.credits}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {course.unitId}
                    </TableCell>
                    <TableCell className="px-4 text-right">
                      <Button
                        type="button"
                        size="sm"
                        variant={
                          selectedCourseId === course.courseId
                            ? "secondary"
                            : "outline"
                        }
                        onClick={() => {
                          onSelect(course);
                          onClose();
                        }}
                      >
                        {selectedCourseId === course.courseId
                          ? "Selected"
                          : "Select"}
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {visibleCourses.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No courses match the current search.
              </p>
            )}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
