const RoleHeader = () => (
  <div className="flex h-14 w-full items-center justify-between border-b border-border-primary px-4">
    <div className="flex flex-col justify-center">
      <span className="font-semibold text-text-primary">Role management</span>
      <span className="text-small font-normal text-text-secondary">
        Manage database roles and privileges
      </span>
    </div>
  </div>
);

export default RoleHeader;
