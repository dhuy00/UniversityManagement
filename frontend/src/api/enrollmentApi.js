import api from "./axios";

export const getEnrollments = async () => {
  const response = await api.get("/enrollments");
  return response.data;
};

export const getCoursePlanEnrollments = async (plan) => {
  const response = await api.get("/enrollments/course-plan", {
    params: {
      courseId: plan.courseId,
      semester: plan.semester,
      academicYear: plan.academicYear,
      programId: plan.programId,
    },
  });
  return response.data;
};

export const updateEnrollmentScores = async (request) => {
  await api.put("/enrollments/scores", request);
};

export const getRegistrationOptions = async () => {
  const response = await api.get("/enrollments/registration-options");
  return response.data;
};

export const createEnrollment = async (request) => {
  await api.post("/enrollments", request);
};

export const deleteEnrollment = async (request) => {
  await api.delete("/enrollments", { data: request });
};
