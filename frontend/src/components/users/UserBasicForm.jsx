import { Field, FieldGroup, FieldLabel } from "@/components/ui/field";
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
      <TabsContent value="basic-info">
        <FieldGroup>
          <Field>
            <FieldLabel htmlFor="fieldgroup-name">Username</FieldLabel>
            <Input
              value={formData.name}
              onChange={(e) => handleInputChange("name", e.target.value)}
              id="fieldgroup-name"
              placeholder="USER_NAME"
              disabled={isEditMode}
            />
            {!isEditMode && (
              <p className="text-xs text-slate-500">
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
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="fieldgroup-role">Role</FieldLabel>
            <div className="space-y-2">
              <div className="flex min-h-8 flex-wrap gap-1.5 rounded-lg border border-border bg-slate-50 p-2">
                {selectedRoles.length > 0 ? (
                  selectedRoles.map((role) => (
                    <Badge
                      key={role}
                      variant="outline"
                      className="h-6 border-blue-100 bg-blue-50 px-2 text-blue-700"
                    >
                      {role}
                    </Badge>
                  ))
                ) : (
                  <span className="text-sm text-slate-400">No role assigned</span>
                )}
              </div>
              <Button type="button" variant="outline" onClick={onManageRoles}>
                Manage roles
              </Button>
            </div>
          </Field>
          <Field>
            <FieldLabel htmlFor="fieldgroup-status">Status</FieldLabel>
            <Select
              value={formData.status}
              onValueChange={(value) => handleInputChange("status", value)}
            >
              <SelectTrigger id="fieldgroup-status" className="w-full">
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
        </FieldGroup>
      </TabsContent>
    </>
  );
};

export default UserBasicForm;
