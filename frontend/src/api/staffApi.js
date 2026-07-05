import api from "./axios";

export const getStaff = async () => {
  const response = await api.get("/staff");
  return response.data;
};

export const createStaff = async (request) => {
  await api.post("/staff", request);
};

export const updateStaff = async (staffId, request) => {
  await api.put(`/staff/${encodeURIComponent(staffId)}`, request);
};

export const deleteStaff = async (staffId) => {
  await api.delete(`/staff/${encodeURIComponent(staffId)}`);
};
