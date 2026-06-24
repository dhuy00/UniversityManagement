import api from "./axios";

export const getUsers = () => {
  return api.get("/user");
};

export const getUserById = (id) => {
  return api.get(`/user/${id}`);
};

export const getUserPrivileges = (username) => {
  return api.get(`/user/privilege/${encodeURIComponent(username)}`);
};

export const createUser = (data) => {
  return api.post("/user", data);
};

export const updateUser = (id, data) => {
  return api.put(`/user/${id}`, data);
};

export const updateUserStatus = (data) => {
  return api.post("/user/status", data);
};

export const updateUserPassword = (data) => {
  return api.post("/user/password", data);
};

export const deleteUser = (username) => {
  return api.delete(`/user/${encodeURIComponent(username)}`);
};
