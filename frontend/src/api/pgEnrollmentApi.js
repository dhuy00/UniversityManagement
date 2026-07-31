import api from "./axios";

export const getPgEnrollments = () => {
  return api.get("/pg/enrollment");
};

export const getPgCoursePlanEnrollments = (plan) => {
  return api.get("/pg/enrollment/course-plan", {
    params: {
      courseId: plan.courseId,
      semester: plan.semester,
      academicYear: plan.academicYear,
      programId: plan.programId,
    },
  });
};

export const updatePgEnrollmentScores = (data) => {
  return api.put("/pg/enrollment/scores", data);
};

export const getPgRegistrationOptions = () => {
  return api.get("/pg/enrollment/registration-options");
};

export const createPgEnrollment = (data) => {
  return api.post("/pg/enrollment", data);
};

export const deletePgEnrollment = (data) => {
  return api.delete("/pg/enrollment", { data });
};
