import api from "./axios";

export const getPgCourses = () => {
  return api.get("/pg/course");
};

export const createPgCourse = (data) => {
  return api.post("/pg/course", data);
};

export const updatePgCourse = (courseId, data) => {
  return api.put(`/pg/course/${encodeURIComponent(courseId)}`, data);
};
