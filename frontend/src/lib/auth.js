const AUTH_SESSION_KEY = "auth_session";
const SESSION_DURATION_MS = 8 * 60 * 60 * 1000;

export const getAuthSession = () => {
  try {
    const value = localStorage.getItem(AUTH_SESSION_KEY);
    if (!value) return null;

    const session = JSON.parse(value);
    if (
      !session?.username ||
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

export const saveAuthSession = (username) => {
  const now = Date.now();
  const session = {
    username,
    signedInAt: new Date(now).toISOString(),
    expiresAt: new Date(now + SESSION_DURATION_MS).toISOString(),
  };

  localStorage.setItem(AUTH_SESSION_KEY, JSON.stringify(session));
  localStorage.removeItem("token");
  localStorage.removeItem("user");
  return session;
};

export const clearAuthSession = () => {
  localStorage.removeItem(AUTH_SESSION_KEY);
  localStorage.removeItem("token");
  localStorage.removeItem("user");
};

export const isAuthenticated = () => getAuthSession() !== null;
