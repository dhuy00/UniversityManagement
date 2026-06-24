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

import {
  ChevronLeft,
  ChevronRight,
  Clock3,
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
      className: "border-emerald-200 bg-emerald-50 text-emerald-700",
    };
  }

  if (normalizedStatus.includes("LOCKED")) {
    return {
      label: normalizedStatus,
      className: "border-rose-200 bg-rose-50 text-rose-700",
    };
  }

  return {
    label: status || "Unknown",
    className: "border-slate-200 bg-slate-50 text-slate-700",
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

export default function UserTable({ users = [], onEditUser }) {
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
    console.log("Delete:", user);
  };

  return (
    <div className="overflow-hidden rounded-b-xl border border-border-primary bg-background-table shadow-small">
      <div className="overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow className="bg-slate-50 hover:bg-slate-50">
              <TableHead className="w-[110px] px-4 py-2 text-[11px] font-semibold uppercase text-slate-500">
                User ID
              </TableHead>
              <TableHead className="min-w-[200px] py-2 text-[11px] font-semibold uppercase text-slate-500">
                Username
              </TableHead>
              <TableHead className="min-w-[260px] py-2 text-[11px] font-semibold uppercase text-slate-500">
                Roles
              </TableHead>
              <TableHead className="min-w-[170px] py-2 text-[11px] font-semibold uppercase text-slate-500">
                Status
              </TableHead>
              <TableHead className="min-w-[140px] py-2 text-[11px] font-semibold uppercase text-slate-500">
                Last login
              </TableHead>
              <TableHead className="w-[96px] py-2 pr-4 text-right text-[11px] font-semibold uppercase text-slate-500">
                Actions
              </TableHead>
            </TableRow>
          </TableHeader>

          <TableBody>
            {currentUsers.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="h-48 text-center">
                  <div className="mx-auto flex max-w-sm flex-col items-center gap-3 text-slate-500">
                    <div className="flex size-12 items-center justify-center rounded-lg bg-slate-100 text-slate-400">
                      <UsersRound className="size-6" />
                    </div>
                    <div>
                      <p className="font-medium text-slate-700">No users found</p>
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
                    className="border-slate-100 hover:bg-slate-50/70"
                  >
                    <TableCell className="px-4 py-2">
                      <span className="font-mono text-sm font-medium text-slate-700">
                        {user.userId}
                      </span>
                    </TableCell>

                    <TableCell className="py-2">
                      <div className="min-w-0">
                        <p className="truncate font-medium text-slate-900">
                          {user.username}
                        </p>
                        <p className="text-xs text-slate-500">Database account</p>
                      </div>
                    </TableCell>

                    <TableCell className="py-2">
                      {roles.length > 0 ? (
                        <div className="flex max-w-[360px] flex-wrap gap-1">
                          {visibleRoles.map((role) => (
                            <Badge
                              key={role}
                              variant="outline"
                              className="h-5 border-blue-100 bg-blue-50 px-2 text-[11px] text-blue-700"
                            >
                              {role}
                            </Badge>
                          ))}
                          {hiddenRoleCount > 0 && (
                            <Badge
                              variant="outline"
                              className="h-5 border-slate-200 bg-slate-50 px-2 text-[11px] text-slate-600"
                            >
                              +{hiddenRoleCount} more
                            </Badge>
                          )}
                        </div>
                      ) : (
                        <span className="text-sm text-slate-400">No role assigned</span>
                      )}
                    </TableCell>

                    <TableCell className="py-2">
                      <Badge
                        variant="outline"
                        className={`h-5 rounded-full px-2 text-[11px] ${statusMeta.className}`}
                      >
                        {statusMeta.label}
                      </Badge>
                    </TableCell>

                    <TableCell className="py-2">
                      <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Clock3 className="size-3.5 text-slate-400" />
                        {getTimeAgo(user.lastLogin)}
                      </div>
                    </TableCell>

                    <TableCell className="py-2 pr-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <Button
                          className="border-slate-200 bg-white text-slate-600 hover:bg-slate-100"
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

      <div className="flex flex-col gap-3 border-t border-slate-100 bg-white px-5 py-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-slate-500">
          Showing{" "}
          <span className="font-medium text-slate-700">{currentUsers.length}</span>{" "}
          of <span className="font-medium text-slate-700">{users.length}</span>{" "}
          users
        </p>

        <div className="flex items-center gap-3">
          <span className="text-sm text-slate-500">
            Page {page} of {totalPages}
          </span>
          <div className="flex gap-1.5">
            <Button
              variant="outline"
              size="icon-sm"
              disabled={page === 1}
              aria-label="Previous page"
              onClick={() => setPage((prev) => Math.max(1, prev - 1))}
            >
              <ChevronLeft className="size-4" />
            </Button>

            <Button
              variant="outline"
              size="icon-sm"
              disabled={page === totalPages}
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
