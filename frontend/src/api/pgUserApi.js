import api from "./axios";

export const getPgUsers = (params = {}) => {
  return api.get("/pg/user", { params });
};

export const createPgUser = (data) => {
  return api.post("/pg/user", data);
};

export const deletePgUser = (username) => {
  return api.delete(`/pg/user/${encodeURIComponent(username)}`);
};

export const updatePgUserStatus = (data) => {
  return api.patch("/pg/user/status", data);
};

export const updatePgUserPassword = (data) => {
  return api.patch("/pg/user/password", data);
};
