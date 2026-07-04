import { Navigate, Outlet, useLocation } from "react-router-dom";

import { getAuthSession, hasAnyRole } from "@/lib/auth";

export default function RoleRoute({ allowedRoles }) {
  const location = useLocation();
  const session = getAuthSession();

  return hasAnyRole(session, allowedRoles)
    ? <Outlet />
    : <Navigate
        to="/forbidden"
        replace
        state={{ attemptedPath: location.pathname }}
      />;
}
