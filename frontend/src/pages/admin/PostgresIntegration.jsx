import { useState } from "react";
import { Button } from "@/components/ui/button";
import { getPgUsers } from "@/api/pgUserApi";
import { getPgRoles } from "@/api/pgRoleApi";
import { getPgPermissions } from "@/api/pgPermissionApi";
import { toast } from "sonner";

const CHANNEL = {
  USER: "user",
  ROLE: "role",
  PERMISSION: "permission",
};

const PostgresIntegration = () => {
  const [users, setUsers] = useState(null);
  const [roles, setRoles] = useState(null);
  const [permissions, setPermissions] = useState(null);
  const [loadingChannel, setLoadingChannel] = useState(null);

  const fetchChannel = async (channel) => {
    setLoadingChannel(channel);
    try {
      if (channel === CHANNEL.USER) {
        const res = await getPgUsers({ page: 1, pageSize: 50 });
        setUsers(res.data);
      } else if (channel === CHANNEL.ROLE) {
        const res = await getPgRoles();
        setRoles(res.data);
      } else if (channel === CHANNEL.PERMISSION) {
        const res = await getPgPermissions();
        setPermissions(res.data);
      }
      toast.success(`PostgreSQL ${channel} channel OK`);
    } catch (error) {
      console.error(error);
      toast.error(`PostgreSQL ${channel} channel failed`, {
        description:
          error?.response?.data?.message || error?.message || "Unexpected error",
      });
    } finally {
      setLoadingChannel(null);
    }
  };

  const fetchAll = async () => {
    await fetchChannel(CHANNEL.USER);
    await fetchChannel(CHANNEL.ROLE);
    await fetchChannel(CHANNEL.PERMISSION);
  };

  return (
    <div className="dashboard-page">
      <div className="dashboard-content">
        <div className="rounded-t-xl border border-b-0 border-[#2b3139] bg-[#1e2329] px-5 py-5 sm:px-6">
          <h2 className="text-base font-semibold text-white">PostgreSQL integration</h2>
          <p className="mt-1 text-xs text-[#707a8a]">
            Live wire-up check against the Postgres controllers (/api/pg/...).
            Requires a valid Postgres-backed authentication session.
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            <Button size="sm" onClick={fetchAll} disabled={loadingChannel !== null}>
              Run all checks
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => fetchChannel(CHANNEL.USER)}
              disabled={loadingChannel !== null}
            >
              {loadingChannel === CHANNEL.USER ? "Loading..." : "Check users"}
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => fetchChannel(CHANNEL.ROLE)}
              disabled={loadingChannel !== null}
            >
              {loadingChannel === CHANNEL.ROLE ? "Loading..." : "Check roles"}
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => fetchChannel(CHANNEL.PERMISSION)}
              disabled={loadingChannel !== null}
            >
              {loadingChannel === CHANNEL.PERMISSION
                ? "Loading..."
                : "Check permissions"}
            </Button>
          </div>
        </div>
        <div className="grid grid-cols-1 gap-4 border border-[#2b3139] bg-[#161a1f] p-5 md:grid-cols-3">
          <ResultPanel
            title="Users (app_users)"
            data={users}
            empty="No check run yet."
          />
          <ResultPanel
            title="Roles (roles)"
            data={roles}
            empty="No check run yet."
          />
          <ResultPanel
            title="Permissions (permissions + role_permissions)"
            data={permissions}
            empty="No check run yet."
          />
        </div>
      </div>
    </div>
  );
};

const ResultPanel = ({ title, data, empty }) => (
  <div className="rounded-lg border border-[#2b3139] bg-[#1e2329] p-4">
    <h3 className="text-sm font-semibold text-white">{title}</h3>
    <p className="mt-1 text-xs text-[#707a8a]">
      {data === null
        ? empty
        : Array.isArray(data)
          ? `${data.length} record(s) returned.`
          : `Page ${data.page} of ${Math.ceil(data.totalItems / data.pageSize)} — ${data.totalItems} total.`}
    </p>
    {data !== null && (
      <pre className="mt-2 max-h-64 overflow-auto rounded bg-[#0f1216] p-2 text-[11px] text-[#cfd6e0]">
        {JSON.stringify(data, null, 2)}
      </pre>
    )}
  </div>
);

export default PostgresIntegration;
