import { Navigate, Outlet, useLocation } from "react-router-dom";

import { getAuthSession, isSystemAdministrator } from "@/lib/auth";

export default function SystemAdminRoute() {
  const location = useLocation();
  const session = getAuthSession();

  return isSystemAdministrator(session)
    ? <Outlet />
    : <Navigate
        to="/forbidden"
        replace
        state={{ attemptedPath: location.pathname }}
      />;
}
