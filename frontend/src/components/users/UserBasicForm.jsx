import { Field, FieldGroup, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { TabsContent } from "@/components/ui/tabs";

const UserBasicForm = ({ formData, setFormData, mode = "create" }) => {
  const isEditMode = mode === "edit";

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
            <FieldLabel htmlFor="fieldgroup-name">Name</FieldLabel>
            <Input
              value={formData.name}
              onChange={(e) => handleInputChange("name", e.target.value)}
              id="fieldgroup-name"
              disabled={isEditMode}
            />
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
            <Input
              id="fieldgroup-role"
              value={formData.role}
              placeholder="ADMIN, MANAGER"
              onChange={(e) => handleInputChange("role", e.target.value)}
            />
          </Field>
          {isEditMode && (
            <Field>
              <FieldLabel htmlFor="fieldgroup-status">Status</FieldLabel>
              <Input id="fieldgroup-status" value={formData.status} disabled />
            </Field>
          )}
        </FieldGroup>
      </TabsContent>
    </>
  );
};

export default UserBasicForm;
