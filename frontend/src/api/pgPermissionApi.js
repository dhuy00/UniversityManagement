import api from "./axios";

export const getPgPermissions = () => {
  return api.get("/pg/permission");
};

export const getPgPermissionsByRole = (roleCode) => {
  return api.get(`/pg/permission/role/${encodeURIComponent(roleCode)}`);
};

export const assignPgPermission = (data) => {
  return api.post("/pg/permission/assign", data);
};

export const revokePgPermission = (data) => {
  return api.post("/pg/permission/revoke", data);
};
