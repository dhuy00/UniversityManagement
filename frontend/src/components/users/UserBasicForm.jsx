import { Field, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { TabsContent } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const UserBasicForm = ({
  formData,
  setFormData,
  mode = "create",
  disabled = false,
  onManageRoles,
}) => {
  const isEditMode = mode === "edit";
  const selectedRoles = formData.roles ?? [];

  const handleInputChange = (field, value) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  return (
    <>
      <TabsContent
        value="basic-info"
        className="max-h-[calc(100vh-290px)] overflow-y-auto pr-1 pt-1"
      >
        <div className="grid gap-5 md:grid-cols-2">
          <Field className="md:col-span-2">
            <FieldLabel htmlFor="fieldgroup-name">Username</FieldLabel>
            <Input
              value={formData.name}
              onChange={(e) => handleInputChange("name", e.target.value)}
              id="fieldgroup-name"
              placeholder="USER_NAME"
              disabled={isEditMode || disabled}
            />
            {!isEditMode && (
              <p className="text-xs leading-5 text-[#929aa5]">
                Start with a letter. Use letters, numbers, _, $, # only.
              </p>
            )}
          </Field>
          <Field>
            <FieldLabel htmlFor="fieldgroup-password">
              {isEditMode ? "New Password" : "Password"}
            </FieldLabel>
            <Input
              value={formData.password}
              id="fieldgroup-password"
              type="password"
              placeholder={isEditMode ? "Leave blank to keep current password" : ""}
              onChange={(e) => handleInputChange("password", e.target.value)}
              disabled={disabled}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="fieldgroup-confirm-password">
              Confirm Password
            </FieldLabel>
            <Input
              value={formData.confirmPassword}
              id="fieldgroup-confirm-password"
              type="password"
              onChange={(e) =>
                handleInputChange("confirmPassword", e.target.value)
              }
              disabled={disabled}
            />
          </Field>
          <Field className="md:col-span-2">
            <div className="flex items-center justify-between gap-4">
              <div>
                <FieldLabel htmlFor="fieldgroup-role">Assigned roles</FieldLabel>
                <p className="mt-1 text-xs text-[#929aa5]">
                  Roles provide reusable permission sets for this account.
                </p>
              </div>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={onManageRoles}
                disabled={disabled}
              >
                Manage roles
              </Button>
            </div>
            <div className="mt-3">
              <div className="flex min-h-12 flex-wrap items-center gap-2 rounded-lg border border-[#2b3139] bg-[#0b0e11] p-3">
                {selectedRoles.length > 0 ? (
                  selectedRoles.map((role) => (
                    <Badge
                      key={role}
                      variant="outline"
                      className="h-6 border-[#3f4650] bg-[#2b3139] px-2.5 text-[#eaecef]"
                    >
                      {role}
                    </Badge>
                  ))
                ) : (
                  <span className="text-sm text-[#929aa5]">No roles assigned</span>
                )}
              </div>
            </div>
          </Field>
          <Field className="md:col-span-2">
            <FieldLabel htmlFor="fieldgroup-status">Account status</FieldLabel>
            <Select
              value={formData.status}
              onValueChange={(value) => handleInputChange("status", value)}
              disabled={disabled}
            >
              <SelectTrigger id="fieldgroup-status" className="h-10 w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent alignItemWithTrigger={false}>
                <SelectGroup>
                  <SelectItem value="OPEN">OPEN</SelectItem>
                  <SelectItem value="LOCKED">LOCKED</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </Field>
        </div>
      </TabsContent>
    </>
  );
};

export default UserBasicForm;
