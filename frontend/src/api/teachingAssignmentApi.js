import api from "./axios";

export const getTeachingAssignments = async () => {
  const response = await api.get("/teaching-assignments");
  return response.data;
};
