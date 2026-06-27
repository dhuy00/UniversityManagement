import { useMemo, useState } from "react";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import LoadingSpinner from "@/components/common/LoadingSpinner";

import {
  ChevronLeft,
  ChevronRight,
  Pencil,
  Trash2,
  UsersRound,
} from "lucide-react";

const ITEMS_PER_PAGE = 5;
const MAX_VISIBLE_ROLES = 3;

const splitRoles = (role) => {
  if (!role || role === "No Role") return [];

  if (Array.isArray(role)) {
    return role.filter(Boolean);
  }

  return role
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
};

const getStatusMeta = (status) => {
  const normalizedStatus = status?.toUpperCase() ?? "";

  if (normalizedStatus === "OPEN") {
    return {
      label: "OPEN",
      className: "border-[#0ecb81]/30 bg-[#0ecb81]/10 text-[#0ecb81]",
    };
  }

  if (normalizedStatus.includes("LOCKED")) {
    return {
      label: normalizedStatus,
      className: "border-[#f6465d]/30 bg-[#f6465d]/10 text-[#f6465d]",
    };
  }

  return {
    label: status || "Unknown",
    className: "border-[#fcd535]/30 bg-[#fcd535]/10 text-[#fcd535]",
  };
};

const getTimeAgo = (dateString) => {
  if (!dateString) return "Never";

  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return "Invalid date";

  const diffMs = Date.now() - date.getTime();
  const minutes = Math.floor(diffMs / 60000);
  const hours = Math.floor(diffMs / 3600000);
  const days = Math.floor(diffMs / 86400000);

  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes} min ago`;
  if (hours < 24) return `${hours} hour${hours > 1 ? "s" : ""} ago`;

  return `${days} day${days > 1 ? "s" : ""} ago`;
};

export default function UserTable({
  users = [],
  loading = false,
  onEditUser,
  onDeleteUser,
}) {
  const [page, setPage] = useState(1);

  const totalPages = Math.max(1, Math.ceil(users.length / ITEMS_PER_PAGE));

  const currentUsers = useMemo(() => {
    const startIndex = (page - 1) * ITEMS_PER_PAGE;
    return users.slice(startIndex, startIndex + ITEMS_PER_PAGE);
  }, [page, users]);

  const handleEdit = (user) => {
    onEditUser?.(user);
  };

  const handleDelete = (user) => {
    onDeleteUser?.(user);
  };

  return (
    <div className="overflow-hidden rounded-b-xl border border-[#2b3139] bg-[#1e2329]">
      <div className="overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow className="border-[#2b3139] bg-[#181a20] hover:bg-[#181a20]">
              <TableHead className="w-[110px] px-5 py-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                User ID
              </TableHead>
              <TableHead className="min-w-[200px] py-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Username
              </TableHead>
              <TableHead className="min-w-[260px] py-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Roles
              </TableHead>
              <TableHead className="min-w-[170px] py-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Status
              </TableHead>
              <TableHead className="min-w-[140px] py-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Last login
              </TableHead>
              <TableHead className="w-[96px] py-3 pr-5 text-right text-[11px] font-semibold uppercase tracking-[0.08em] text-[#707a8a]">
                Actions
              </TableHead>
            </TableRow>
          </TableHeader>

          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={6} className="h-48 text-center text-[#929aa5]">
                  <LoadingSpinner label="Loading users..." />
                </TableCell>
              </TableRow>
            ) : currentUsers.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="h-48 text-center">
                  <div className="mx-auto flex max-w-sm flex-col items-center gap-3 text-[#707a8a]">
                    <div className="flex size-12 items-center justify-center rounded-lg bg-[#2b3139] text-[#929aa5]">
                      <UsersRound className="size-6" />
                    </div>
                    <div>
                      <p className="font-medium text-[#eaecef]">No users found</p>
                      <p className="mt-1 text-sm">
                        Create a user or refresh the data source.
                      </p>
                    </div>
                  </div>
                </TableCell>
              </TableRow>
            ) : (
              currentUsers.map((user) => {
                const roles = splitRoles(user.role);
                const visibleRoles = roles.slice(0, MAX_VISIBLE_ROLES);
                const hiddenRoleCount = roles.length - visibleRoles.length;
                const statusMeta = getStatusMeta(user.status);

                return (
                  <TableRow
                    key={user.userId || user.username}
                    className="border-[#2b3139] hover:bg-[#252a31]"
                  >
                    <TableCell className="number-font px-5 py-3">
                      <span className="text-sm font-medium text-[#929aa5]">
                        {user.userId}
                      </span>
                    </TableCell>

                    <TableCell className="py-3">
                      <div className="min-w-0">
                        <p className="truncate font-medium text-white">
                          {user.username}
                        </p>
                        <p className="text-xs text-[#707a8a]">Database account</p>
                      </div>
                    </TableCell>

                    <TableCell className="py-3">
                      {roles.length > 0 ? (
                        <div className="flex max-w-[360px] flex-wrap gap-1">
                          {visibleRoles.map((role) => (
                            <Badge
                              key={role}
                              variant="outline"
                              className="h-5 border-[#3f4650] bg-[#2b3139] px-2 text-[11px] text-[#eaecef]"
                            >
                              {role}
                            </Badge>
                          ))}
                          {hiddenRoleCount > 0 && (
                            <Badge
                              variant="outline"
                              className="h-5 border-[#3f4650] bg-[#181a20] px-2 text-[11px] text-[#929aa5]"
                            >
                              +{hiddenRoleCount} more
                            </Badge>
                          )}
                        </div>
                      ) : (
                        <span className="text-sm text-[#707a8a]">No role assigned</span>
                      )}
                    </TableCell>

                    <TableCell className="py-3">
                      <Badge
                        variant="outline"
                        className={`h-5 rounded-full px-2 text-[11px] ${statusMeta.className}`}
                      >
                        {statusMeta.label}
                      </Badge>
                    </TableCell>

                    <TableCell className="number-font py-3">
                      <div className="text-sm text-[#929aa5]">
                        {getTimeAgo(user.lastLogin)}
                      </div>
                    </TableCell>

                    <TableCell className="py-3 pr-5 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <Button
                          className="border-[#3f4650] bg-transparent text-[#929aa5] hover:bg-[#2b3139] hover:text-white"
                          variant="outline"
                          size="icon-sm"
                          aria-label={`Edit ${user.username}`}
                          onClick={() => handleEdit(user)}
                        >
                          <Pencil className="size-3.5" />
                        </Button>

                        <Button
                          variant="destructive"
                          size="icon-sm"
                          aria-label={`Delete ${user.username}`}
                          onClick={() => handleDelete(user)}
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
            "Loading user count..."
          ) : (
            <>
              Showing{" "}
              <span className="number-font font-medium text-[#eaecef]">{currentUsers.length}</span>{" "}
              of <span className="number-font font-medium text-[#eaecef]">{users.length}</span>{" "}
              users
            </>
          )}
        </p>

        <div className="flex items-center gap-3">
          <span className="number-font text-sm text-[#707a8a]">
            Page {page} of {totalPages}
          </span>
          <div className="flex gap-1.5">
            <Button
              variant="outline"
              size="icon-sm"
              disabled={loading || page === 1}
              aria-label="Previous page"
              onClick={() => setPage((prev) => Math.max(1, prev - 1))}
            >
              <ChevronLeft className="size-4" />
            </Button>

            <Button
              variant="outline"
              size="icon-sm"
              disabled={loading || page === totalPages}
              aria-label="Next page"
              onClick={() => setPage((prev) => Math.min(totalPages, prev + 1))}
            >
              <ChevronRight className="size-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
