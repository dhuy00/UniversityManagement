public interface ICoursePlanService
{
    Task<IReadOnlyList<CoursePlanDto>> GetAllAsync(
        CancellationToken cancellationToken);

    Task CreateAsync(
        SaveCoursePlanRequest request,
        CancellationToken cancellationToken);

    Task<bool> UpdateAsync(
        string originalCourseId,
        int originalSemester,
        int originalAcademicYear,
        string originalProgramId,
        SaveCoursePlanRequest request,
        CancellationToken cancellationToken);
}
