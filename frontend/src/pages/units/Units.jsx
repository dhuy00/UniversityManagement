import { useEffect, useMemo, useState } from "react";
import { Building2, Pencil } from "lucide-react";

import { getUnits } from "@/api/unitApi";
import DataPageHeader from "@/components/common/DataPageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import UnitFormDialog from "@/components/units/UnitFormDialog";
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
import { UNIT_WRITE_ROLES } from "@/lib/roles";

export default function Units() {
  const session = getAuthSession();
  const [units, setUnits] = useState(null);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [editingUnit, setEditingUnit] = useState(null);
  const canManageUnits = hasAnyRole(session, UNIT_WRITE_ROLES);

  useEffect(() => {
    let active = true;

    getUnits()
      .then((data) => {
        if (active) setUnits(data);
      })
      .catch(() => {
        if (active) setError("Unable to load units.");
      });

    return () => {
      active = false;
    };
  }, []);

  const refreshUnits = async () => {
    const data = await getUnits();
    setUnits(data);
  };

  const visibleUnits = useMemo(() => {
    if (!units) return [];

    const term = search.trim().toLowerCase();
    if (!term) return units;

    return units.filter((unit) =>
      [unit.unitId, unit.unitName, unit.headStaffId, unit.headStaffName]
        .filter(Boolean)
        .some((value) => value.toLowerCase().includes(term)),
    );
  }, [search, units]);

  return (
    <div className="dashboard-page">
      <DataPageHeader
        title="Units"
        description="Read-only academic unit information available to staff."
        icon={Building2}
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search by code, unit, or head name"
        searchDisabled={units === null}
      />

      <div className="dashboard-content">
        {error && (
          <div
            role="alert"
            className="rounded-lg border border-[#3f4650] bg-[#1e2329] p-5 text-sm text-[#eaecef]"
          >
            {error}
          </div>
        )}

        {!error && units === null && (
          <div className="flex min-h-48 items-center justify-center rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <LoadingSpinner label="Loading units..." />
          </div>
        )}

        {units && (
          <div className="overflow-hidden rounded-xl border border-[#2b3139] bg-[#1e2329]">
            <Table>
              <TableHeader className="bg-[#181a20]">
                <TableRow className="border-[#2b3139] hover:bg-[#181a20]">
                  <TableHead className="px-4 text-[#929aa5]">Code</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">Unit name</TableHead>
                  <TableHead className="px-4 text-[#929aa5]">
                    Head staff ID
                  </TableHead>
                  <TableHead className="px-4 text-[#929aa5]">
                    Head staff name
                  </TableHead>
                  {canManageUnits && (
                    <TableHead className="px-4 text-right text-[#929aa5]">
                      Action
                    </TableHead>
                  )}
                </TableRow>
              </TableHeader>
              <TableBody>
                {visibleUnits.map((unit) => (
                  <TableRow
                    key={unit.unitId}
                    className="border-[#2b3139] hover:bg-[#2b3139]/40"
                  >
                    <TableCell className="px-4 font-semibold text-[#fcd535]">
                      {unit.unitId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {unit.unitName}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {unit.headStaffId}
                    </TableCell>
                    <TableCell className="px-4 text-[#eaecef]">
                      {unit.headStaffName || "—"}
                    </TableCell>
                    {canManageUnits && (
                      <TableCell className="px-4 text-right">
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          aria-label={`Edit ${unit.unitId}`}
                          title="Edit unit"
                          onClick={() => setEditingUnit(unit)}
                        >
                          <Pencil />
                          Edit
                        </Button>
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {visibleUnits.length === 0 && (
              <p className="p-8 text-center text-sm text-[#929aa5]">
                No units are available.
              </p>
            )}
          </div>
        )}
      </div>
      {editingUnit && (
        <UnitFormDialog
          unit={editingUnit}
          onClose={() => setEditingUnit(null)}
          onSaved={refreshUnits}
        />
      )}
    </div>
  );
}
