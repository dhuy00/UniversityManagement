import api from "./axios";

export const getCurrentProfile = async () => {
  const response = await api.get("/profile");
  return response.data;
};
