import api from "./axios";

export const getPgUnits = () => {
  return api.get("/pg/unit");
};

export const createPgUnit = (data) => {
  return api.post("/pg/unit", data);
};

export const updatePgUnit = (unitId, data) => {
  return api.put(`/pg/unit/${encodeURIComponent(unitId)}`, data);
};
