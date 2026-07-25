namespace UniversityManagementAPI.Repositories.Interfaces;

public interface IPostgresCourseRepository
{
    Task<IReadOnlyList<CourseDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task CreateAsync(
        SaveCourseRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateAsync(
        string courseId,
        SaveCourseRequest request,
        CancellationToken cancellationToken = default);
}
