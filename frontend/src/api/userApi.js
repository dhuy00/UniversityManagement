import api from "./axios";

export const getUsers = () => {
  return api.get("/user");
};

export const getUserById = (id) => {
  return api.get(`/user/${id}`);
};

export const createUser = (data) => {
  return api.post("/user", data);
};

export const updateUser = (id, data) => {
  return api.put(`/user/${id}`, data);
};

export const updateUserStatus = (data) => {
  return api.patch("/user/status", data);
};

export const deleteUser = (id) => {
  return api.delete(`/user/${id}`);
};
