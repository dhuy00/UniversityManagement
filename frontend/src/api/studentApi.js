import api from "./axios";

export const getStudents = async ({ page, pageSize, search }) => {
  const response = await api.get("/students", {
    params: {
      page,
      pageSize,
      ...(search ? { search } : {}),
    },
  });
  return response.data;
};

export const createStudent = async (request) => {
  await api.post("/students", request);
};

export const updateStudent = async (studentId, request) => {
  await api.put(`/students/${encodeURIComponent(studentId)}`, request);
};
