import api from "./axios";

export const getPgRoles = () => {
  return api.get("/pg/role");
};

export const createPgRole = (data) => {
  return api.post("/pg/role", data);
};

export const deletePgRole = (roleCode) => {
  return api.delete(`/pg/role/${encodeURIComponent(roleCode)}`);
};

export const grantPgRoleToUser = (data) => {
  return api.post("/pg/role/grant", data);
};

export const revokePgRoleFromUser = (data) => {
  return api.post("/pg/role/revoke", data);
};
