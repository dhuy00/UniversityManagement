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
