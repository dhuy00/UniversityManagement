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
