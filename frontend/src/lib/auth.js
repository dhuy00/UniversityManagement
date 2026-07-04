const AUTH_SESSION_KEY = "auth_session";

export const getAuthSession = () => {
  try {
    const value = localStorage.getItem(AUTH_SESSION_KEY);
    if (!value) return null;

    const session = JSON.parse(value);
    if (
      !session?.username ||
      !session?.accessToken ||
      !session?.expiresAt ||
      Date.parse(session.expiresAt) <= Date.now()
    ) {
      localStorage.removeItem(AUTH_SESSION_KEY);
      return null;
    }

    return session;
  } catch {
    localStorage.removeItem(AUTH_SESSION_KEY);
    return null;
  }
};

export const saveAuthSession = ({ accessToken, expiresAt, user }) => {
  const session = {
    accessToken,
    expiresAt,
    username: user.username,
    identityType: user.identityType,
    roleCode: user.roleCode,
    staffId: user.staffId,
    studentId: user.studentId,
  };

  localStorage.setItem(AUTH_SESSION_KEY, JSON.stringify(session));
  return session;
};

export const clearAuthSession = () => {
  localStorage.removeItem(AUTH_SESSION_KEY);
};

export const isAuthenticated = () => getAuthSession() !== null;

export const isSystemAdministrator = (session = getAuthSession()) =>
  session?.username?.toUpperCase() === "SYS";
