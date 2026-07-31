import api from "./axios";

export const getPgCurrentProfile = () => {
  return api.get("/pg/profile");
};

export const updatePgProfileContact = (data) => {
  return api.put("/pg/profile/contact", data);
};
