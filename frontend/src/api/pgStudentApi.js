import api from "./axios";

export const getPgStudents = ({ page, pageSize, search }) => {
  return api.get("/pg/student", {
    params: {
      page,
      pageSize,
      ...(search ? { search } : {}),
    },
  });
};

export const createPgStudent = (data) => {
  return api.post("/pg/student", data);
};

export const updatePgStudent = (studentId, data) => {
  return api.put(`/pg/student/${encodeURIComponent(studentId)}`, data);
};
