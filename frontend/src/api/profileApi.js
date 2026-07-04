import api from "./axios";

export const getCurrentProfile = async () => {
  const response = await api.get("/profile");
  return response.data;
};

export const updateProfileContact = async (request) => {
  await api.put("/profile/contact", request);
};
