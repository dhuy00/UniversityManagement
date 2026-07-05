import { useEffect, useMemo, useState } from "react";
import { Pencil, Plus, Trash2, UserCog } from "lucide-react";

import { getStaff } from "@/api/staffApi";
import DataPageHeader from "@/components/common/DataPageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import StaffDeleteDialog from "@/components/staff/StaffDeleteDialog";
import StaffFormDialog from "@/components/staff/StaffFormDialog";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { prioritizeItem } from "@/lib/prioritizeItem";

export default function Staff() {
  const [staff, setStaff] = useState(null);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [formMode, setFormMode] = useState(null);
  const [editingStaff, setEditingStaff] = useState(null);
  const [deletingStaff, setDeletingStaff] = useState(null);

  const loadStaff = async (createdStaffId) => {
    const data = await getStaff();
    setStaff(prioritizeItem(
      data,
      createdStaffId,
      (item) => item.staffId,
    ));
  };

  useEffect(() => {
    let active = true;
    getStaff()
      .then((data) => {
        if (active) setStaff(data);
      })
      .catch(() => {
        if (active) setError("Unable to load staff.");
      });
    return () => {
      active = false;
    };
  }, []);

  const visibleStaff = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!staff || !term) return staff ?? [];
    return staff.filter((item) =>
      [
        item.staffId,
        item.fullName,
        item.roleCode,
        item.unitId,
        item.oracleUsername,
      ].some((value) => value.toLowerCase().includes(term)));
  }, [search, staff]);

  return (
    <div className="dashboard-page">
      <DataPageHeader
        title="Staff Management"
        description="Dean-only staff records protected by Oracle VPD."
        icon={UserCog}
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search ID, name, role, unit, or username"
        searchDisabled={staff === null}
        actions={(
          <Button
            type="button"
            onClick={() => {
              setEditingStaff(null);
              setFormMode("create");
            }}
          >
            <Plus />
            Create staff
          </Button>
        )}
      />
      <div className="dashboard-content">
        {error && <div role="alert">{error}</div>}
        {!error && staff === null && (
          <div className="flex min-h-48 items-center justify-center rounded-xl bg-[#1e2329]">
            <LoadingSpinner label="Loading staff..." />
          </div>
        )}
        {staff && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139]">
                  <TableHead className="px-4 text-[#929aa5]">Staff ID</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Full name</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Role</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Unit</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Username</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Allowance</TableHead>
                  <TableHead className="px-4 text-right text-[#929aa5]">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {visibleStaff.map((item) => (
                  <TableRow key={item.staffId} className="border-[#2b3139]">
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {item.staffId}
                    </TableCell>
                    <TableCell className="px-4">{item.fullName}</TableCell>
                    <TableCell className="px-4">{item.roleCode}</TableCell>
                    <TableCell className="px-4">{item.unitId}</TableCell>
                    <TableCell className="px-4">{item.oracleUsername}</TableCell>
                    <TableCell className="px-4 text-right">
                      {Number(item.allowance).toLocaleString()}
                    </TableCell>
                    <TableCell className="px-4 text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setEditingStaff(item);
                            setFormMode("edit");
                          }}
                        >
                          <Pencil />
                          Edit
                        </Button>
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={() => setDeletingStaff(item)}
                        >
                          <Trash2 />
                          Delete
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {formMode && (
        <StaffFormDialog
          mode={formMode}
          staff={editingStaff}
          onClose={() => {
            setFormMode(null);
            setEditingStaff(null);
          }}
          onSaved={loadStaff}
        />
      )}
      {deletingStaff && (
        <StaffDeleteDialog
          staff={deletingStaff}
          onClose={() => setDeletingStaff(null)}
          onDeleted={loadStaff}
        />
      )}
    </div>
  );
}
