import api from "./axios";

export const getCourses = async () => {
  const response = await api.get("/courses");
  return response.data;
};

export const createCourse = async (request) => {
  await api.post("/courses", request);
};

export const updateCourse = async (courseId, request) => {
  await api.put(`/courses/${encodeURIComponent(courseId)}`, request);
};
