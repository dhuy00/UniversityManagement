import api from "./axios";

export const getCoursePlans = async () => {
  const response = await api.get("/course-plans");
  return response.data;
};

export const createCoursePlan = async (request) => {
  await api.post("/course-plans", request);
};

export const updateCoursePlan = async (originalPlan, request) => {
  await api.put(
    `/course-plans/${encodeURIComponent(originalPlan.courseId)}`,
    request,
    {
      params: {
        semester: originalPlan.semester,
        academicYear: originalPlan.academicYear,
        programId: originalPlan.programId,
      },
    },
  );
};
