import { useMemo, useState } from "react";
import {
  ChevronLeft,
  ChevronRight,
  Pencil,
  ShieldCheck,
  Trash2,
} from "lucide-react";

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
      ? "border-[#fcd535]/30 bg-[#fcd535]/10 text-[#fcd535]"
      : "border-[#3b82f6]/30 bg-[#3b82f6]/10 text-[#60a5fa]",
  };
};

const RoleTable = ({
  roles = [],
  loading = false,
  onEditRole,
  onDeleteRole,
}) => {
  const [page, setPage] = useState(1);
  const totalPages = Math.max(1, Math.ceil(roles.length / ITEMS_PER_PAGE));
  const currentPage = Math.min(page, totalPages);

  const currentRoles = useMemo(() => {
    const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;
    return roles.slice(startIndex, startIndex + ITEMS_PER_PAGE);
  }, [currentPage, roles]);

  return (
    <div className="overflow-hidden rounded-b-xl border border-[#2b3139] bg-[#1e2329]">
      <div className="overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow className="border-[#2b3139] bg-[#181a20] hover:bg-[#181a20]">
              <TableHead className="min-w-[260px] px-5 py-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Role
              </TableHead>
              <TableHead className="min-w-[220px] py-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Authentication
              </TableHead>
              <TableHead className="min-w-[160px] py-3 pr-4 text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Scope
              </TableHead>
              <TableHead className="w-[96px] py-3 pr-5 text-right text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Actions
              </TableHead>
            </TableRow>
          </TableHeader>

          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={4} className="h-48 text-center text-[#929aa5]">
                  <LoadingSpinner label="Loading roles..." />
                </TableCell>
              </TableRow>
            ) : currentRoles.length === 0 ? (
              <TableRow>
                <TableCell colSpan={4} className="h-48 text-center">
                  <div className="mx-auto flex max-w-sm flex-col items-center gap-3 text-[#707a8a]">
                    <div className="flex size-12 items-center justify-center rounded-lg bg-[#2b3139] text-[#929aa5]">
                      <ShieldCheck className="size-6" />
                    </div>
                    <div>
                      <p className="font-medium text-[#eaecef]">No roles found</p>
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
                    className="border-[#2b3139] hover:bg-[#252a31]"
                  >
                    <TableCell className="px-5 py-3">
                      <span className="font-medium text-white">
                        {role.role}
                      </span>
                    </TableCell>
                    <TableCell className="py-3 text-sm text-[#929aa5]">
                      {role.authenticationType || "NONE"}
                    </TableCell>
                    <TableCell className="py-3 pr-4">
                      <Badge
                        variant="outline"
                        className={`h-5 rounded-full px-2 text-[11px] ${commonMeta.className}`}
                      >
                        {commonMeta.label}
                      </Badge>
                    </TableCell>
                    <TableCell className="py-3 pr-5 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <Button
                          className="border-[#3f4650] bg-transparent text-[#929aa5] hover:bg-[#2b3139] hover:text-white"
                          variant="outline"
                          size="icon-sm"
                          aria-label={`Edit ${role.role}`}
                          onClick={() => onEditRole?.(role)}
                        >
                          <Pencil className="size-3.5" />
                        </Button>
                        <Button
                          variant="destructive"
                          size="icon-sm"
                          aria-label={`Delete ${role.role}`}
                          onClick={() => onDeleteRole?.(role)}
                        >
                          <Trash2 className="size-3.5" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </div>

      <div className="flex flex-col gap-3 border-t border-[#2b3139] bg-[#1e2329] px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-[#707a8a]">
          {loading ? (
            "Loading role count..."
          ) : (
            <>
              Showing{" "}
              <span className="number-font font-medium text-[#eaecef]">
                {currentRoles.length}
              </span>{" "}
              of <span className="number-font font-medium text-[#eaecef]">{roles.length}</span>{" "}
              roles
            </>
          )}
        </p>

        <div className="flex items-center gap-3">
          <span className="number-font text-sm text-[#707a8a]">
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
