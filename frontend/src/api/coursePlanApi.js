import api from "./axios";

export const getCoursePlans = async () => {
  const response = await api.get("/course-plans");
  return response.data;
};
