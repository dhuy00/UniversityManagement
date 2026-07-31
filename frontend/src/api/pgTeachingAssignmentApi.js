import api from "./axios";

export const getPgTeachingAssignments = () => {
  return api.get("/pg/teaching-assignment");
};

export const createPgTeachingAssignment = (data) => {
  return api.post("/pg/teaching-assignment", data);
};

export const updatePgTeachingAssignment = (original, data) => {
  return api.put("/pg/teaching-assignment", data, {
    params: {
      originalLecturerId: original.lecturerId,
      originalCourseId: original.courseId,
      originalSemester: original.semester,
      originalAcademicYear: original.academicYear,
      originalProgramId: original.programId,
    },
  });
};

export const deletePgTeachingAssignment = (assignment) => {
  return api.delete("/pg/teaching-assignment", {
    params: {
      lecturerId: assignment.lecturerId,
      courseId: assignment.courseId,
      semester: assignment.semester,
      academicYear: assignment.academicYear,
      programId: assignment.programId,
    },
  });
};
