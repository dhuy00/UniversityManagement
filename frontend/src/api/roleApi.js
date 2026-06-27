import api from "./axios";

export const getRoles = () => {
  return api.get("/role");
};

export const createRole = (data) => {
  return api.post("/role", data);
};

export const getRolePrivileges = (roleName) => {
  return api.get(`/role/privilege/${encodeURIComponent(roleName)}`);
};

export const revokeRolePrivileges = (data) => {
  return api.post("/role/revoke-privilege", data);
};

export const updateRolePassword = (data) => {
  return api.patch("/role/password", data);
};

export const grantRoleToUser = (data) => {
  return api.post("/role/grant", data);
};

export const revokeRoleFromUser = (data) => {
  return api.post("/role/revoke", data);
};
