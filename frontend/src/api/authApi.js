import api from "./axios";

export const login = async (credentials) => {
  const response = await api.post("/pg/auth/login", credentials);
  return response.data;
};

export const logout = async () => {
  await api.post("/pg/auth/logout");
};
