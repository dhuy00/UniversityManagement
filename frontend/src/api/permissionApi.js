import api from "./axios";

export const getTables = () => {
  return api.get("/permission/tables");
};

export const getSystemPrivileges = () => {
  return api.get("/permission/system-privileges");
};

export const grantPermission = (data) => {
  return api.post("/permission", data);
};

export const grantSystemPrivilege = (data) => {
  return api.post("/permission/system", data);
};
