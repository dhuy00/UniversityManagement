import api from "./axios";

export const getUnits = async () => {
  const response = await api.get("/units");
  return response.data;
};

export const updateUnit = async (unitId, request) => {
  await api.put(`/units/${encodeURIComponent(unitId)}`, request);
};

export const createUnit = async (request) => {
  await api.post("/units", request);
};
