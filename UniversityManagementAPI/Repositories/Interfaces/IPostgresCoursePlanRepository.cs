namespace UniversityManagementAPI.Repositories.Interfaces;

public interface IPostgresCoursePlanRepository
{
    Task<IReadOnlyList<CoursePlanDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task CreateAsync(
        SaveCoursePlanRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateAsync(
        string originalCourseId,
        int originalSemester,
        int originalAcademicYear,
        string originalProgramId,
        SaveCoursePlanRequest request,
        CancellationToken cancellationToken = default);
}