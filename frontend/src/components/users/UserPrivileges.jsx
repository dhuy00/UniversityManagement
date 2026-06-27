import { memo, useCallback, useState } from "react";
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
import { ChevronRight } from "lucide-react";

const UserPrivileges = ({
  privileges,
  setPrivileges,
  commonPrivileges,
  systemPrivileges = [],
  setCommonPrivileges,
  onColumnChange
}) => {
  const [expandedRows, setExpandedRows] = useState({});

  const toggleExpanded = useCallback((tableName) => {
    setExpandedRows((prev) => ({
      ...prev,
      [tableName]: !prev[tableName],
    }));
  }, []);


  const handleCommonPrivilegeChange = (key) => (checked) => {
    setCommonPrivileges((prev) => ({
      ...prev,
      [key]: !!checked,
    }));
  };

  return (
    <TabsContent value="privileges" className="mt-4 max-h-[calc(100vh-290px)] overflow-y-auto pr-1">
      <div>
        <h3 className="text-sm font-semibold text-white">
          Table privileges
        </h3>
        <p className="mt-1 text-xs leading-5 text-[#929aa5]">
          Grant object-level access. Expand a table to configure SELECT and
          UPDATE columns.
        </p>
      </div>

      <div className="mb-6 mt-3 max-h-[280px] w-full max-w-full overflow-auto rounded-lg border border-[#2b3139] bg-[#0b0e11]">
        <Table className="min-w-[680px]">
          <TableHeader>
            <TableRow className="bg-[#181a20] hover:bg-[#181a20]">
              <TableHead className="text-muted-foreground">
                TABLE NAME
              </TableHead>
              <TableHead className="text-muted-foreground">SELECT</TableHead>
              <TableHead className="text-muted-foreground">INSERT</TableHead>
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
                handleCheckboxChange={setPrivileges}
                handleColumnChange={onColumnChange}
              />
            ))}
          </TableBody>
        </Table>
      </div>

      <div>
        <h3 className="text-sm font-semibold text-white">
          System privileges
        </h3>
        <p className="mt-1 text-xs leading-5 text-[#929aa5]">
          Apply database-wide capabilities directly to this principal.
        </p>
      </div>

      <div className="mt-3 grid max-h-[220px] grid-cols-1 gap-2 overflow-y-auto pr-1 text-normal sm:grid-cols-2">
        {systemPrivileges.map((privilege) => (
          <label
            key={privilege}
            className="flex cursor-pointer justify-between rounded-md border border-[#2b3139] bg-[#0b0e11] px-3 py-2.5 text-[#eaecef]"
          >
            <span>{privilege}</span>
            <Checkbox
              className="border-gray-400"
              checked={!!commonPrivileges[privilege]}
              onCheckedChange={handleCommonPrivilegeChange(privilege)}
            />
          </label>
        ))}
      </div>
    </TabsContent>
  );
};

const TableRowWrapper = memo(function TableRowWrapper({
  row,
  expanded,
  toggleExpanded,
  handleCheckboxChange,
  handleColumnChange,
}) {
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
            checked={row.insert}
            onCheckedChange={(checked) =>
              handleCheckboxChange(row.tableName, "insert", !!checked)
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

      {expanded && (row.select || row.update) && (
        <TableRow className="border-0">
          <TableCell colSpan={5} className="bg-[#181a20] p-0">
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
          </TableCell>
        </TableRow>
      )}
    </>
  );
});

export default memo(UserPrivileges);
