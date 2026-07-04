import api from "./axios";

export const getUnits = async () => {
  const response = await api.get("/units");
  return response.data;
};
