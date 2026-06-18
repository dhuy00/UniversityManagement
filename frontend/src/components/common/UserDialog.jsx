import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogClose
} from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Field,
  FieldDescription,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Button } from "../ui/button";

const UserDialog = ({ open, setOpen }) => {
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className={`text-[13px]`}>
        <DialogHeader>
          <DialogTitle className="text-sm leading-none">
            Create User
          </DialogTitle>
        </DialogHeader>

        <Tabs defaultValue="basic-info">
          <TabsList>
            <TabsTrigger value="basic-info">Basic Info</TabsTrigger>
            <TabsTrigger value="privileges">Privileges</TabsTrigger>
          </TabsList>
          <TabsContent value="basic-info">
            <FieldGroup>
              <Field>
                <FieldLabel htmlFor="fieldgroup-name">Name</FieldLabel>
                <Input id="fieldgroup-name" placeholder="Jordan Lee" />
              </Field>
              <Field>
                <FieldLabel htmlFor="fieldgroup-email">Email</FieldLabel>
                <Input
                  id="fieldgroup-email"
                  type="email"
                  placeholder="name@example.com"
                />
                <FieldDescription>
                  We&apos;ll send updates to this address.
                </FieldDescription>
              </Field>
            </FieldGroup>
          </TabsContent>
          <TabsContent value="privileges">
            <div>Privileges</div>
          </TabsContent>
        </Tabs>
        <DialogFooter>
            <DialogClose render={<Button variant="outline">Cancel</Button>} />
            <Button type="submit">Save changes</Button>
          </DialogFooter>
      </DialogContent>

    </Dialog>
  );
};

export default UserDialog;
