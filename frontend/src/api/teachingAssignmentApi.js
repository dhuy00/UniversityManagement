import api from "./axios";

export const getTeachingAssignments = async () => {
  const response = await api.get("/teaching-assignments");
  return response.data;
};

export const createTeachingAssignment = async (request) => {
  await api.post("/teaching-assignments", request);
};

export const updateTeachingAssignment = async (original, request) => {
  await api.put("/teaching-assignments", request, {
    params: {
      originalLecturerId: original.lecturerId,
      originalCourseId: original.courseId,
      originalSemester: original.semester,
      originalAcademicYear: original.academicYear,
      originalProgramId: original.programId,
    },
  });
};

export const deleteTeachingAssignment = async (assignment) => {
  await api.delete("/teaching-assignments", {
    params: {
      lecturerId: assignment.lecturerId,
      courseId: assignment.courseId,
      semester: assignment.semester,
      academicYear: assignment.academicYear,
      programId: assignment.programId,
    },
  });
};
