import api from "./axios";

export const getPgStaff = () => {
  return api.get("/pg/staff");
};

export const createPgStaff = (data) => {
  return api.post("/pg/staff", data);
};

export const updatePgStaff = (staffId, data) => {
  return api.put(`/pg/staff/${encodeURIComponent(staffId)}`, data);
};

export const deletePgStaff = (staffId) => {
  return api.delete(`/pg/staff/${encodeURIComponent(staffId)}`);
};
