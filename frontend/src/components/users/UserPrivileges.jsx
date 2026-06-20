import { useState } from "react";
import { TabsContent } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Checkbox } from "@/components/ui/checkbox";
import { Button } from "@/components/ui/button";
import { ChevronDown, ChevronRight } from "lucide-react";

const initialPrivileges = [
  {
    tableName: "Users",
    columns: ["id", "username", "email", "phone"],
    select: true,
    selectColumns: ["id", "username"],
    update: false,
    updateColumns: [],
    delete: false,
  },
  {
    tableName: "Roles",
    columns: ["id", "name", "description"],
    select: true,
    selectColumns: ["id", "name"],
    update: true,
    updateColumns: ["name"],
    delete: false,
  },
  {
    tableName: "Permissions",
    columns: ["id", "permission_name", "resource"],
    select: false,
    selectColumns: [],
    update: false,
    updateColumns: [],
    delete: false,
  },
  {
    tableName: "Products",
    columns: ["id", "name", "price", "stock"],
    select: true,
    selectColumns: ["id", "name"],
    update: true,
    updateColumns: ["price"],
    delete: true,
  },
  {
    tableName: "Orders",
    columns: ["id", "customer_id", "total", "status"],
    select: true,
    selectColumns: ["id", "status"],
    update: false,
    updateColumns: [],
    delete: false,
  },
];

const UserPrivileges = () => {
  const [privileges, setPrivileges] = useState(initialPrivileges);
  const [expandedRows, setExpandedRows] = useState({});

  const toggleExpanded = (tableName) => {
    setExpandedRows((prev) => ({
      ...prev,
      [tableName]: !prev[tableName],
    }));
  };

  const handleCheckboxChange = (tableName, permission, checked) => {
    setPrivileges((prev) =>
      prev.map((row) =>
        row.tableName === tableName
          ? {
              ...row,
              [permission]: checked,
              ...(permission === "select" && !checked
                ? { selectColumns: [] }
                : {}),
              ...(permission === "update" && !checked
                ? { updateColumns: [] }
                : {}),
            }
          : row,
      ),
    );
  };

  const handleColumnChange = (tableName, permissionType, column, checked) => {
    setPrivileges((prev) =>
      prev.map((row) => {
        if (row.tableName !== tableName) return row;

        const key =
          permissionType === "select" ? "selectColumns" : "updateColumns";

        return {
          ...row,
          [key]: checked
            ? [...row[key], column]
            : row[key].filter((c) => c !== column),
        };
      }),
    );
  };

  return (
    <TabsContent value="privileges" className="mt-4">
      <span>Table Privileges</span>

      <div className="rounded-lg border bg-background my-2 max-h-[300px] overflow-y-auto">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="text-muted-foreground">
                TABLE NAME
              </TableHead>
              <TableHead className="text-muted-foreground">SELECT</TableHead>
              <TableHead className="text-muted-foreground">UPDATE</TableHead>
              <TableHead className="text-muted-foreground">DELETE</TableHead>
            </TableRow>
          </TableHeader>

          <TableBody>
            {privileges.map((row) => (
              <TableRowWrapper
                key={row.tableName}
                row={row}
                expanded={expandedRows[row.tableName]}
                toggleExpanded={toggleExpanded}
                handleCheckboxChange={handleCheckboxChange}
                handleColumnChange={handleColumnChange}
              />
            ))}
          </TableBody>
        </Table>
      </div>

      <span>Common Privileges</span>

      <div className="grid grid-cols-2 text-normal mt-2 gap-2">
        <div className="flex justify-between border-gray-300 border px-2 py-2 rounded-md">
          <span>CONNECT</span>
          <Checkbox className="border-gray-400" />
        </div>

        <div className="flex justify-between border-gray-300 border px-2 py-2 rounded-md">
          <span>CREATE</span>
          <Checkbox className="border-gray-400" />
        </div>

        <div className="flex justify-between border-gray-300 border px-2 py-2 rounded-md">
          <span>TEMPORARY</span>
          <Checkbox className="border-gray-400" />
        </div>

        <div className="flex justify-between border-gray-300 border px-2 py-2 rounded-md">
          <span>EXECUTE</span>
          <Checkbox className="border-gray-400" />
        </div>
      </div>
    </TabsContent>
  );
};

const TableRowWrapper = ({
  row,
  expanded,
  toggleExpanded,
  handleCheckboxChange,
  handleColumnChange,
}) => {
  return (
    <>
      <TableRow>
        <TableCell className="font-medium">
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="icon"
              className="h-6 w-6"
              onClick={() => toggleExpanded(row.tableName)}
            >
              <ChevronRight
                className={`h-4 w-4 transition-transform duration-300 ${
                  expanded ? "rotate-90" : ""
                }`}
              />
            </Button>

            <span>{row.tableName}</span>
          </div>
        </TableCell>

        <TableCell>
          <Checkbox
            className="border-gray-400"
            checked={row.select}
            onCheckedChange={(checked) =>
              handleCheckboxChange(row.tableName, "select", !!checked)
            }
          />
        </TableCell>

        <TableCell>
          <Checkbox
            className="border-gray-400"
            checked={row.update}
            onCheckedChange={(checked) =>
              handleCheckboxChange(row.tableName, "update", !!checked)
            }
          />
        </TableCell>

        <TableCell>
          <Checkbox
            className="border-gray-400"
            checked={row.delete}
            onCheckedChange={(checked) =>
              handleCheckboxChange(row.tableName, "delete", !!checked)
            }
          />
        </TableCell>
      </TableRow>

      <TableRow className="border-0">
        <TableCell colSpan={4} className="p-0">
          <div
            className={`
        overflow-hidden
        transition-all
        duration-300
        ease-in-out
        bg-muted/30
        ${
          expanded && (row.select || row.update)
            ? "max-h-[1000px] opacity-100"
            : "max-h-0 opacity-0"
        }
      `}
          >
            <div className="p-4 space-y-4">
              {row.select && (
                <div>
                  <p className="text-sm font-medium mb-2">Select Columns</p>

                  <div className="flex flex-wrap gap-4">
                    {row.columns.map((column) => (
                      <label
                        key={`select-${column}`}
                        className="flex items-center gap-2 cursor-pointer"
                      >
                        <Checkbox
                          checked={row.selectColumns.includes(column)}
                          onCheckedChange={(checked) =>
                            handleColumnChange(
                              row.tableName,
                              "select",
                              column,
                              !!checked,
                            )
                          }
                        />
                        <span className="text-sm">{column}</span>
                      </label>
                    ))}
                  </div>
                </div>
              )}

              {row.update && (
                <div>
                  <p className="text-sm font-medium mb-2">Update Columns</p>

                  <div className="flex flex-wrap gap-4">
                    {row.columns.map((column) => (
                      <label
                        key={`update-${column}`}
                        className="flex items-center gap-2 cursor-pointer"
                      >
                        <Checkbox
                          checked={row.updateColumns.includes(column)}
                          onCheckedChange={(checked) =>
                            handleColumnChange(
                              row.tableName,
                              "update",
                              column,
                              !!checked,
                            )
                          }
                        />
                        <span className="text-sm">{column}</span>
                      </label>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        </TableCell>
      </TableRow>
    </>
  );
};

export default UserPrivileges;
