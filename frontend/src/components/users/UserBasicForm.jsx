import { Field, FieldGroup, FieldLabel } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { TabsContent } from "@/components/ui/tabs";

const UserBasicForm = ({ formData, setFormData }) => {
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
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="fieldgroup-password">Password</FieldLabel>
            <Input
              value={formData.password}
              id="fieldgroup-password"
              type="password"
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
            <FieldLabel>Role</FieldLabel>
            <Select
              defaultValue="- Select -"
              value={formData.role}
              onValueChange={(value) => handleInputChange("role", value)}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent alignItemWithTrigger={false}>
                <SelectGroup>
                  <SelectItem value="">- Select -</SelectItem>
                  <SelectItem value="apple">Apple</SelectItem>
                  <SelectItem value="banana">Banana</SelectItem>
                  <SelectItem value="blueberry">Blueberry</SelectItem>
                  <SelectItem value="grapes">Grapes</SelectItem>
                  <SelectItem value="pineapple">Pineapple</SelectItem>
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
