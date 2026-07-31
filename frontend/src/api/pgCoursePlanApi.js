import api from "./axios";

export const getPgCoursePlans = () => {
  return api.get("/pg/course-plan");
};

export const createPgCoursePlan = (data) => {
  return api.post("/pg/course-plan", data);
};

export const updatePgCoursePlan = (originalPlan, data) => {
  return api.put(
    `/pg/course-plan/${encodeURIComponent(originalPlan.courseId)}`,
    data,
    {
      params: {
        semester: originalPlan.semester,
        academicYear: originalPlan.academicYear,
        programId: originalPlan.programId,
      },
    },
  );
};
