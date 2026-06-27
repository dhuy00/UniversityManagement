import { useMemo, useState } from "react";
import { ChevronLeft, ChevronRight, Pencil, ShieldCheck } from "lucide-react";

import LoadingSpinner from "@/components/common/LoadingSpinner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

const ITEMS_PER_PAGE = 5;

const getCommonRoleMeta = (common) => {
  const isCommon = common?.toUpperCase() === "YES";

  return {
    label: isCommon ? "COMMON" : "LOCAL",
    className: isCommon
      ? "border-violet-200 bg-violet-50 text-violet-700"
      : "border-slate-200 bg-slate-50 text-slate-700",
  };
};

const RoleTable = ({ roles = [], loading = false, onEditRole }) => {
  const [page, setPage] = useState(1);
  const totalPages = Math.max(1, Math.ceil(roles.length / ITEMS_PER_PAGE));
  const currentPage = Math.min(page, totalPages);

  const currentRoles = useMemo(() => {
    const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;
    return roles.slice(startIndex, startIndex + ITEMS_PER_PAGE);
  }, [currentPage, roles]);

  return (
    <div className="overflow-hidden rounded-b-xl border border-border-primary bg-background-table shadow-small">
      <div className="overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow className="bg-slate-50 hover:bg-slate-50">
              <TableHead className="min-w-[260px] px-4 py-2 text-[11px] font-semibold uppercase text-slate-500">
                Role
              </TableHead>
              <TableHead className="min-w-[220px] py-2 text-[11px] font-semibold uppercase text-slate-500">
                Authentication
              </TableHead>
              <TableHead className="min-w-[160px] py-2 pr-4 text-[11px] font-semibold uppercase text-slate-500">
                Scope
              </TableHead>
              <TableHead className="w-[72px] py-2 pr-4 text-right text-[11px] font-semibold uppercase text-slate-500">
                Actions
              </TableHead>
            </TableRow>
          </TableHeader>

          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={4} className="h-48 text-center text-slate-500">
                  <LoadingSpinner label="Loading roles..." />
                </TableCell>
              </TableRow>
            ) : currentRoles.length === 0 ? (
              <TableRow>
                <TableCell colSpan={4} className="h-48 text-center">
                  <div className="mx-auto flex max-w-sm flex-col items-center gap-3 text-slate-500">
                    <div className="flex size-12 items-center justify-center rounded-lg bg-slate-100 text-slate-400">
                      <ShieldCheck className="size-6" />
                    </div>
                    <div>
                      <p className="font-medium text-slate-700">No roles found</p>
                      <p className="mt-1 text-sm">
                        No database roles are available.
                      </p>
                    </div>
                  </div>
                </TableCell>
              </TableRow>
            ) : (
              currentRoles.map((role) => {
                const commonMeta = getCommonRoleMeta(role.common);

                return (
                  <TableRow
                    key={role.role}
                    className="border-slate-100 hover:bg-slate-50/70"
                  >
                    <TableCell className="px-4 py-2">
                      <span className="font-medium text-slate-900">
                        {role.role}
                      </span>
                    </TableCell>
                    <TableCell className="py-2 text-sm text-slate-600">
                      {role.authenticationType || "NONE"}
                    </TableCell>
                    <TableCell className="py-2 pr-4">
                      <Badge
                        variant="outline"
                        className={`h-5 rounded-full px-2 text-[11px] ${commonMeta.className}`}
                      >
                        {commonMeta.label}
                      </Badge>
                    </TableCell>
                    <TableCell className="py-2 pr-4 text-right">
                      <Button
                        className="border-slate-200 bg-white text-slate-600 hover:bg-slate-100"
                        variant="outline"
                        size="icon-sm"
                        aria-label={`Edit ${role.role}`}
                        onClick={() => onEditRole?.(role)}
                      >
                        <Pencil className="size-3.5" />
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </div>

      <div className="flex flex-col gap-3 border-t border-slate-100 bg-white px-5 py-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-slate-500">
          {loading ? (
            "Loading role count..."
          ) : (
            <>
              Showing{" "}
              <span className="font-medium text-slate-700">
                {currentRoles.length}
              </span>{" "}
              of <span className="font-medium text-slate-700">{roles.length}</span>{" "}
              roles
            </>
          )}
        </p>

        <div className="flex items-center gap-3">
          <span className="text-sm text-slate-500">
            Page {currentPage} of {totalPages}
          </span>
          <div className="flex gap-1.5">
            <Button
              variant="outline"
              size="icon-sm"
              disabled={loading || currentPage === 1}
              aria-label="Previous page"
              onClick={() => setPage(Math.max(1, currentPage - 1))}
            >
              <ChevronLeft className="size-4" />
            </Button>
            <Button
              variant="outline"
              size="icon-sm"
              disabled={loading || currentPage === totalPages}
              aria-label="Next page"
              onClick={() =>
                setPage(Math.min(totalPages, currentPage + 1))
              }
            >
              <ChevronRight className="size-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RoleTable;
