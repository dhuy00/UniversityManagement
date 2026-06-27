import api from "./axios";

export const getRoles = () => {
  return api.get("/role");
};

export const createRole = (data) => {
  return api.post("/role", data);
};

export const grantRoleToUser = (data) => {
  return api.post("/role/grant", data);
};

export const revokeRoleFromUser = (data) => {
  return api.post("/role/revoke", data);
};
